// Interaction tests for the opaque-ui components, driven through the vapor-ui
// showcase in headless Chrome over the DevTools protocol. Input goes through
// the browser's own pointer and keyboard pipeline (Input.dispatch*), so an
// overlay covering a button or a missing focus is caught, not bypassed.
//
//   zig build test-ui                  (builds the site, then runs these)
//   node tests/run.mjs [text]          (after `zig build`; only tests whose
//                                       name contains text)
//   node tests/run.mjs --dump /ui/x    (lists what a page offers to click)
//   node tests/run.mjs --serve         (serve the site on :8091 to poke at)
//
// No npm dependencies: Node >= 22 provides fetch and WebSocket. Chrome is found
// via $CHROME, then the usual install locations.

import { spawn } from "node:child_process";
import { createServer } from "node:http";
import { existsSync, mkdtempSync, readFileSync, rmSync, statSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, extname, join, normalize, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const siteDir = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const args = process.argv.slice(2);
const flags = new Set(args.filter((a) => a.startsWith("--")));
const positional = args.filter((a) => !a.startsWith("--"));

// ── server ──────────────────────────────────────────────────────────────────

const mime = {
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript",
  ".wasm": "application/wasm",
  ".css": "text/css",
  ".svg": "image/svg+xml",
  ".webp": "image/webp",
  ".jpg": "image/jpeg",
  ".png": "image/png",
  ".woff2": "font/woff2",
  ".json": "application/json",
};

function serve(req, res) {
  let path = decodeURIComponent(new URL(req.url, "http://x").pathname);
  if (path === "/bundle.min.js" || path === "/browser.min.js") path = "/zig-out/bin" + path;
  const file = normalize(join(siteDir, path));
  if (!file.startsWith(siteDir)) return res.writeHead(400).end();
  if (extname(path)) {
    if (!existsSync(file) || !statSync(file).isFile()) return res.writeHead(404).end("not found");
    res.writeHead(200, { "content-type": mime[extname(path)] ?? "application/octet-stream" });
    return res.end(readFileSync(file));
  }
  // Routes are client-side: every extensionless path gets the app shell.
  res.writeHead(200, { "content-type": mime[".html"] });
  res.end(readFileSync(join(siteDir, "template.html")));
}

// ── chrome + CDP ────────────────────────────────────────────────────────────

function findChrome() {
  const found = [
    process.env.CHROME,
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "/usr/bin/google-chrome",
    "/usr/bin/google-chrome-stable",
    "/usr/bin/chromium",
    "/usr/bin/chromium-browser",
  ].filter(Boolean).find((c) => existsSync(c));
  if (!found) throw new Error("Chrome not found; set $CHROME");
  return found;
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function launch() {
  const profile = mkdtempSync(join(tmpdir(), "vapor-ui-test-"));
  const port = 9200 + Math.floor(Math.random() * 700);
  const proc = spawn(findChrome(), [
    "--headless=new",
    "--disable-gpu",
    "--no-first-run",
    "--no-default-browser-check",
    "--no-sandbox", // CI containers run as root
    `--remote-debugging-port=${port}`,
    `--user-data-dir=${profile}`,
    "about:blank",
  ], { stdio: "ignore" });

  let targets;
  for (let i = 0; i < 100 && !targets; i++) {
    try {
      targets = await (await fetch(`http://127.0.0.1:${port}/json`)).json();
    } catch {
      await sleep(100);
    }
  }
  if (!targets) throw new Error("Chrome did not start");
  const ws = new WebSocket(targets.find((t) => t.type === "page").webSocketDebuggerUrl);
  await new Promise((r, j) => { ws.onopen = r; ws.onerror = j; });

  let nextId = 0;
  const pending = new Map();
  const problems = []; // uncaught exceptions and console errors/warnings, per test
  const dialogs = []; // window.alert/confirm messages, accepted as they open
  ws.onmessage = (ev) => {
    const msg = JSON.parse(ev.data);
    if (msg.id && pending.has(msg.id)) {
      pending.get(msg.id)(msg);
      pending.delete(msg.id);
    } else if (msg.method === "Page.javascriptDialogOpening") {
      dialogs.push(msg.params.message);
      ws.send(JSON.stringify({ id: ++nextId, method: "Page.handleJavaScriptDialog", params: { accept: true } }));
    } else if (msg.method === "Runtime.exceptionThrown") {
      const d = msg.params.exceptionDetails;
      problems.push(`exception: ${(d.exception?.description ?? d.text).split("\n").slice(0, 6).join("\n        ")}`);
    } else if (msg.method === "Runtime.consoleAPICalled") {
      // vapor reports its problems through console.log with an [ERROR] or
      // [WARN] label; a showcase page should print nothing of either.
      const text = msg.params.args.map((a) => a.value ?? a.description).join(" ");
      if (msg.params.type === "error" || msg.params.type === "warning" || /\[%c(ERROR|WARN)%c\]/.test(text)) {
        problems.push(`console.${msg.params.type}: ${text.replace(/%c/g, "").slice(0, process.env.LONG ? 4000 : 300)}`);
      }
    }
  };
  const send = (method, params = {}) => new Promise((res, rej) => {
    const id = ++nextId;
    pending.set(id, (m) => (m.error ? rej(new Error(`${method}: ${m.error.message}`)) : res(m.result)));
    ws.send(JSON.stringify({ id, method, params }));
  });
  await send("Runtime.enable");
  await send("Page.enable");
  // Headless pages never have focus, so focus/blur events would not fire.
  await send("Emulation.setFocusEmulationEnabled", { enabled: true });
  await send("Emulation.setDeviceMetricsOverride", { width: 1440, height: 900, deviceScaleFactor: 1, mobile: false });

  const close = () => {
    ws.close();
    proc.kill();
    try { rmSync(profile, { recursive: true, force: true }); } catch {}
  };
  return { send, problems, dialogs, close };
}

// ── page helpers ────────────────────────────────────────────────────────────

// In-page code shared by the helpers: find elements by their visible text.
const finders = `
  window.__ui = {
    visible(e) {
      if (!e || !e.isConnected) return false;
      const r = e.getBoundingClientRect();
      if (r.width === 0 || r.height === 0) return false;
      // What is left of the box after every clipping ancestor (a collapsed
      // panel is usually height 0 with overflow hidden, not display none).
      let left = r.left, top = r.top, right = r.right, bottom = r.bottom;
      for (let n = e; n; n = n.parentElement) {
        const s = getComputedStyle(n);
        if (s.display === "none" || s.visibility === "hidden" || Number(s.opacity) === 0) return false;
        // Only hidden/clip hide content (a scroll area just needs scrolling),
        // and each axis on its own.
        if (n !== e) {
          const c = n.getBoundingClientRect();
          if (/hidden|clip/.test(s.overflowX)) { left = Math.max(left, c.left); right = Math.min(right, c.right); }
          if (/hidden|clip/.test(s.overflowY)) { top = Math.max(top, c.top); bottom = Math.min(bottom, c.bottom); }
          if (right - left < 1 || bottom - top < 1) return false;
        }
      }
      return true;
    },
    // The innermost visible elements whose whole text is \`text\`.
    byText(text, root = document) {
      const all = [...root.querySelectorAll("body *")].filter((e) => e.textContent.trim() === text && this.visible(e));
      return all.filter((e) => !all.some((o) => o !== e && e.contains(o)));
    },
    byLabel(label) {
      return [...document.querySelectorAll("[aria-label]")].filter((e) => e.getAttribute("aria-label") === label && this.visible(e));
    },
  };
`;

function makePage(cdp, origin) {
  const evaluate = async (expression) => {
    const r = await cdp.send("Runtime.evaluate", { expression, returnByValue: true, awaitPromise: true });
    if (r.exceptionDetails) throw new Error(`evaluate failed: ${r.exceptionDetails.exception?.description ?? r.exceptionDetails.text}`);
    return r.result.value;
  };
  const waitFor = async (expression, what, timeout = 5000) => {
    const end = Date.now() + timeout;
    let last;
    while (Date.now() < end) {
      last = await evaluate(expression).catch((e) => e.message);
      if (last === true) return;
      await sleep(25);
    }
    throw new Error(`timed out waiting for ${what ?? expression} (last: ${JSON.stringify(last)})`);
  };
  const q = JSON.stringify;

  // Scrolls the element an expression finds into view and returns the
  // centre of its box, in viewport coordinates, once the box has stopped
  // moving (an element sliding or fading in is not ready to be pressed).
  const centre = async (find, what) => {
    const end = Date.now() + 5000;
    let pos, last;
    while (Date.now() < end) {
      pos = await evaluate(`(() => {
        ${finders}
        const e = (${find});
        if (!e) return null;
        // "nearest" sideways: centring would also scroll clipping boxes
        // such as a carousel's viewport.
        e.scrollIntoView({ block: "center", inline: "nearest" });
        const r = e.getBoundingClientRect();
        return { x: r.left + r.width / 2, y: r.top + r.height / 2 };
      })()`);
      if (pos && last && pos.x === last.x && pos.y === last.y) return pos;
      last = pos;
      await sleep(pos ? 50 : 25);
    }
    if (pos) throw new Error(`${what} never stopped moving`);
    throw new Error(`no ${what} on the page`);
  };
  // What the browser would hit at a point: the test fails if something
  // covers the element it meant to press.
  const hitCheck = async (find, pos, what) => {
    const ok = await evaluate(`(() => {
      ${finders}
      const e = (${find});
      const hit = document.elementFromPoint(${pos.x}, ${pos.y});
      return !!e && !!hit && (e === hit || e.contains(hit) || hit.contains(e));
    })()`);
    if (!ok) throw new Error(`${what} is covered by another element`);
  };
  const mouse = (type, x, y, extra = {}) => cdp.send("Input.dispatchMouseEvent", { type, x, y, button: "left", clickCount: 1, ...extra });

  const page = {
    dialogs: cdp.dialogs,
    async waitDialog(message) {
      const end = Date.now() + 5000;
      while (Date.now() < end) {
        const i = cdp.dialogs.indexOf(message);
        if (i >= 0) return void cdp.dialogs.splice(i, 1);
        await sleep(25);
      }
      throw new Error(`no ${q(message)} dialog (saw ${q(cdp.dialogs)})`);
    },
    // The ARIA state an element exposes, e.g. attr("label", "test-switch", "aria-checked").
    async ariaOf(label, attr, nth = 0) {
      return evaluate(`(() => { ${finders} return __ui.byLabel(${q(label)})[${nth}]?.getAttribute(${q(attr)}) ?? null; })()`);
    },
    // How many `type` listeners the document and window have.
    async listenerCount(type) {
      let n = 0;
      for (const expr of ["document", "window"]) {
        const obj = await cdp.send("Runtime.evaluate", { expression: expr });
        const { listeners } = await cdp.send("DOMDebugger.getEventListeners", { objectId: obj.result.objectId });
        n += listeners.filter((l) => l.type === type).length;
      }
      return n;
    },
    // The box of the innermost element reading `text`.
    async boxOf(text) {
      return evaluate(`(() => { ${finders} const e = __ui.byText(${q(text)})[0]; if (!e) return null; const r = e.getBoundingClientRect(); return { left: r.left, top: r.top, right: r.right, bottom: r.bottom, vw: innerWidth, vh: innerHeight }; })()`);
    },
    async waitAria(label, attr, value) {
      await waitFor(
        `(() => { ${finders} return __ui.byLabel(${q(label)})[0]?.getAttribute(${q(attr)}) === ${q(value)}; })()`,
        `${label} to have ${attr}=${value}`,
      );
    },
    evaluate,
    waitFor,
    async goto(path) {
      await cdp.send("Page.navigate", { url: origin + path });
      await waitFor(`document.readyState === "complete"`, "page load");
      await waitFor(`document.documentElement.hasAttribute("data-vapor-ready")`, "vapor:ready");
      await sleep(100);
    },
    // A real click (press + release) on the innermost visible element whose
    // text is `text`; `nth` picks among several.
    async clickText(text, nth = 0) {
      const find = `__ui.byText(${q(text)})[${nth}]`;
      const pos = await centre(find, `element reading ${q(text)}`);
      await hitCheck(find, pos, `the element reading ${q(text)}`);
      await mouse("mouseMoved", pos.x, pos.y, { button: "none", clickCount: 0 });
      await mouse("mousePressed", pos.x, pos.y);
      await mouse("mouseReleased", pos.x, pos.y);
      await sleep(60);
    },
    // A real click on the visible option (role=option) reading `text`.
    async clickOption(text) {
      // An option scrolled out of its list counts: the click scrolls to it.
      const find = `[...document.querySelectorAll("[role=option]")].filter((e) => e.textContent.trim() === ${q(text)} && __ui.visible(e.closest("[role=listbox]") ?? e))[0]`;
      const pos = await centre(find, `option ${q(text)}`);
      await hitCheck(find, pos, `option ${q(text)}`);
      await mouse("mousePressed", pos.x, pos.y);
      await mouse("mouseReleased", pos.x, pos.y);
      await sleep(60);
    },
    async clickLabel(label, nth = 0) {
      const find = `__ui.byLabel(${q(label)})[${nth}]`;
      const pos = await centre(find, `element labelled ${q(label)}`);
      await hitCheck(find, pos, `the element labelled ${q(label)}`);
      await mouse("mousePressed", pos.x, pos.y);
      await mouse("mouseReleased", pos.x, pos.y);
      await sleep(60);
    },
    async clickSelector(selector, nth = 0) {
      const find = `[...document.querySelectorAll(${q(selector)})].filter((e) => __ui.visible(e))[${nth}]`;
      const pos = await centre(find, selector);
      await hitCheck(find, pos, selector);
      await mouse("mousePressed", pos.x, pos.y);
      await mouse("mouseReleased", pos.x, pos.y);
      await sleep(60);
    },
    // Clicks a point outside every overlay: the page's top-left corner area.
    async clickAway() {
      await mouse("mousePressed", 700, 880);
      await mouse("mouseReleased", 700, 880);
      await sleep(60);
    },
    async mouseTo(x, y) {
      await mouse("mouseMoved", x, y, { button: "none", clickCount: 0 });
      await sleep(60);
    },
    async hoverText(text, nth = 0) {
      const pos = await centre(`__ui.byText(${q(text)})[${nth}]`, `element reading ${q(text)}`);
      await mouse("mouseMoved", pos.x, pos.y, { button: "none", clickCount: 0 });
      await sleep(60);
      return pos;
    },
    async drag(from, to, steps = 8) {
      await mouse("mouseMoved", from.x, from.y, { button: "none", clickCount: 0 });
      await mouse("mousePressed", from.x, from.y);
      for (let i = 1; i <= steps; i++) {
        const x = from.x + ((to.x - from.x) * i) / steps;
        const y = from.y + ((to.y - from.y) * i) / steps;
        await mouse("mouseMoved", x, y, { buttons: 1 });
        await sleep(16);
      }
      await mouse("mouseReleased", to.x, to.y);
      await sleep(60);
    },
    centreOf: (find, what) => centre(find, what),
    async screenshot() {
      const r = await cdp.send("Page.captureScreenshot", { format: "png" });
      return Buffer.from(r.data, "base64");
    },
    // `modifiers` as CDP counts them: Alt 1, Ctrl 2, Meta 4, Shift 8.
    async press(key, code = key, modifiers = 0) {
      const keyCode = { Enter: 13, Escape: 27, ArrowDown: 40, ArrowUp: 38, Tab: 9, " ": 32 }[key] ?? (key.length === 1 ? key.toUpperCase().charCodeAt(0) : 0);
      // Keys that type a character carry it, as a real keyboard's do; Chrome
      // activates a focused button on Enter or Space only then.
      const text = modifiers ? undefined : { Enter: "\r", " ": " " }[key];
      await cdp.send("Input.dispatchKeyEvent", { type: text ? "keyDown" : "rawKeyDown", key, code, modifiers, windowsVirtualKeyCode: keyCode, ...(text ? { text, unmodifiedText: text } : {}) });
      await cdp.send("Input.dispatchKeyEvent", { type: "keyUp", key, code, modifiers, windowsVirtualKeyCode: keyCode });
      await sleep(60);
    },
    async type(text) {
      await cdp.send("Input.insertText", { text });
      await sleep(60);
    },
    // Waits for an element reading `text` to be visible (or, with
    // `gone`, for none to be).
    async waitText(text, { gone = false, timeout } = {}) {
      await waitFor(
        `(() => { ${finders} return __ui.byText(${q(text)}).length ${gone ? "=== 0" : "> 0"}; })()`,
        `${q(text)} to ${gone ? "disappear" : "appear"}`,
        timeout,
      );
    },
    async count(text) {
      return evaluate(`(() => { ${finders} return __ui.byText(${q(text)}).length; })()`);
    },
  };
  return page;
}

function assert(cond, what) {
  if (!cond) throw new Error(what);
}

// ── tests ───────────────────────────────────────────────────────────────────

// Visible controls with no accessible name: no label, text, associated
// <label>, placeholder or title.
const unnamedControls = `(() => {
  ${finders}
  const name = (e) => e.getAttribute("aria-label") || e.textContent.trim() || (e.id && document.querySelector('label[for="' + e.id + '"]')?.textContent.trim()) || e.placeholder || e.title;
  return [...document.querySelectorAll("button, input, textarea, select, a[href], [role=button], [role=tab], [role=checkbox], [role=switch], [role=slider], [role=option]")]
    .filter((e) => __ui.visible(e) && !name(e))
    .map((e) => e.outerHTML.slice(0, 120));
})()`;

// The Kanban column a card sits in. The board's column headers share one
// row (the Backlog header's); a card belongs to the rightmost header that
// starts left of its centre.
const kanbanColumnOf = (title) => `(() => {
  ${finders}
  const card = __ui.byText(${JSON.stringify(title)})[0];
  const backlog = __ui.byText("Backlog")[0];
  if (!card || !backlog) return null;
  const row = backlog.getBoundingClientRect().top;
  const c = card.getBoundingClientRect(), x = c.left + c.width / 2;
  let best = null, bestLeft = -Infinity;
  for (const name of ["Backlog", "To Do", "In Progress", "Review", "Done"]) {
    for (const h of __ui.byText(name)) {
      const r = h.getBoundingClientRect();
      if (Math.abs(r.top - row) > 4) continue;
      if (r.left <= x && r.left > bestLeft) { best = name; bestLeft = r.left; }
    }
  }
  return best;
})()`;

// The button labelled `label` on the card whose title is `title`.
const kanbanCardButton = (title, label) => `(() => {
  ${finders}
  // The card's copy mid-move may have no buttons; use one that does.
  for (const t of __ui.byText(${JSON.stringify(title)})) {
    let n = t;
    while (n && n.querySelectorAll('[aria-label="${label}"]').length !== 1) n = n.parentElement;
    if (n) return n.querySelector('[aria-label="${label}"]');
  }
  return null;
})()`;

const tests = {
  async "accordion: a header opens its panel and closes it again"(p) {
    await p.goto("/ui/accordion");
    const body = "We stand behind our products with a 30-day return policy. If you're not satisfied, simply return the item in its original condition for a full refund.";
    await p.waitText(body, { gone: true });
    await p.clickText("Return Policy");
    await p.waitText(body);
    await p.clickText("Return Policy");
    await p.waitText(body, { gone: true });
  },

  async "accordion: a custom panel's own buttons work"(p) {
    await p.goto("/ui/accordion");
    await p.waitText("Open Account Settings", { gone: true });
    await p.clickText("Security Settings");
    await p.waitText("Open Account Settings");
  },

  async "accordion: triggers report open/closed, items never overlap, closed panels leave the tab order"(p) {
    await p.goto("/ui/accordion");
    const trigger = (t) => `(() => { ${finders} return __ui.byText(${JSON.stringify(t)})[0]?.closest("button[aria-expanded]"); })()`;
    assert(await p.evaluate(`${trigger("Security Settings")}?.getAttribute("aria-expanded")`) === "false", "starts collapsed");
    // A closed panel's buttons cannot take focus (visibility: hidden).
    assert(await p.evaluate(`(() => { const b = [...document.querySelectorAll("button")].find((e) => e.textContent.trim() === "Open Account Settings"); return getComputedStyle(b).visibility; })()`) === "hidden", "a closed panel's button is hidden");
    await p.clickText("Security Settings");
    await p.waitFor(`${trigger("Security Settings")}?.getAttribute("aria-expanded") === "true"`, "the trigger to read expanded");
    await p.waitText("Open Account Settings");
    await sleep(300); // the open animation
    // No item overlaps the next, open or closed.
    const overlaps = await p.evaluate(`(() => { const bs = [...document.querySelectorAll("button[aria-expanded]")].map((b) => b.closest("[style*=grid]").getBoundingClientRect()); let n = 0; for (let i = 1; i < bs.length; i++) if (bs[i].top < bs[i - 1].bottom - 1 && bs[i].left < bs[i - 1].right) n++; return n; })()`);
    assert(overlaps === 0, `${overlaps} accordion items overlap the one before`);
    // The open panel shows all of its content.
    const fits = await p.evaluate(`(() => { const b = [...document.querySelectorAll("button")].find((e) => e.textContent.trim() === "Open Account Settings"); const item = b.closest("[style*=grid]").getBoundingClientRect(); const r = b.getBoundingClientRect(); return r.bottom <= item.bottom + 1; })()`);
    assert(fits, "the open panel is tall enough for its content");
  },

  async "alert: opens on its trigger and Cancel closes it"(p) {
    await p.goto("/ui/alert");
    await p.waitText("Are you sure?", { gone: true });
    await p.clickText("Trigger Confirmation");
    await p.waitText("Are you sure?");
    await p.clickText("Cancel");
    await p.waitText("Are you sure?", { gone: true });
    // Continue closes it too.
    await p.clickText("Trigger Confirmation");
    await p.waitText("Are you sure?");
    await p.clickText("Continue");
    await p.waitText("Are you sure?", { gone: true });
  },

  async "switch: toggles its state and calls back"(p) {
    await p.goto("/ui/switch");
    assert(await p.ariaOf("test-switch", "role") === "switch", "the switch has role=switch");
    assert(await p.ariaOf("test-switch", "aria-checked") === "false", "it starts off");
    await p.clickLabel("test-switch");
    await p.waitDialog("Switch Toggled");
    await p.waitAria("test-switch", "aria-checked", "true");
    await p.clickLabel("test-switch");
    await p.waitDialog("Switch Toggled");
    await p.waitAria("test-switch", "aria-checked", "false");
  },

  async "checkbox: toggles its state and calls back"(p) {
    await p.goto("/ui/checkbox");
    assert(await p.ariaOf("test-checkbox", "role") === "checkbox", "the checkbox has role=checkbox");
    assert(await p.ariaOf("test-checkbox", "aria-checked") === "false", "it starts unchecked");
    await p.clickLabel("test-checkbox");
    await p.waitDialog("Checkbox Toggled");
    await p.waitAria("test-checkbox", "aria-checked", "true");
  },

  async "radio: one choice at a time, starting on the default"(p) {
    await p.goto("/ui/radio");
    const checked = async () => JSON.stringify(await p.evaluate(`(() => { ${finders} return [...document.querySelectorAll("[role=radio]")].filter((e) => __ui.visible(e) && e.getAttribute("aria-checked") === "true").map((e) => e.textContent.trim()); })()`));
    assert(await checked() === '["Default"]', `starts on Default (got ${await checked()})`);
    await p.waitText("Density: default");
    await p.clickText("Compact");
    await p.waitText("Density: compact");
    assert(await checked() === '["Compact"]', `only Compact is checked (got ${await checked()})`);
    await p.clickText("Comfortable");
    await p.waitText("Density: comfortable");
    assert(await checked() === '["Comfortable"]', `only Comfortable is checked (got ${await checked()})`);
    assert(await p.evaluate(`document.querySelectorAll('[role=radiogroup][aria-label="Density"]').length`) === 1, "the group is labelled");
  },

  async "dialog: opens, filters as you type, closes on Escape"(p) {
    await p.goto("/ui/dialog");
    const dialogOpen = `(() => { ${finders} return [...document.querySelectorAll("[role=dialog]")].some((e) => __ui.visible(e)); })()`;
    await p.waitFor(`!${dialogOpen}`, "no dialog at first");
    await p.clickLabel("open basic dialog");
    await p.waitFor(dialogOpen, "the dialog to open");
    for (const label of ["Pending", "Success", "Error"]) await p.waitText(label);
    // Focus lands in the search box, so typing filters straight away.
    await p.type("succ");
    await p.waitText("Pending", { gone: true });
    await p.waitText("Error", { gone: true });
    await p.waitText("Success");
    await p.press("Escape");
    await p.waitFor(`!${dialogOpen}`, "Escape to close the dialog");
  },

  async "dialog: a click outside closes it"(p) {
    await p.goto("/ui/dialog");
    const dialogOpen = `(() => { ${finders} return [...document.querySelectorAll("[role=dialog]")].some((e) => __ui.visible(e)); })()`;
    await p.clickLabel("open basic dialog");
    await p.waitFor(dialogOpen, "the dialog to open");
    await p.clickAway();
    await p.waitFor(`!${dialogOpen}`, "a click outside to close the dialog");
  },

  async "dialog: arrow keys move the highlight and Enter picks"(p) {
    await p.goto("/ui/dialog");
    // What a screen reader announces: the option the search box names as
    // its aria-activedescendant.
    const active = `(() => { const box = document.querySelector("[role=combobox][aria-activedescendant]"); const e = box && document.getElementById(box.getAttribute("aria-activedescendant")); return e ? e.textContent.trim() : null; })()`;
    const isActive = (label) => `${active} === ${JSON.stringify(label)}`;
    await p.clickLabel("open basic dialog");
    await p.waitText("Pending");
    // Like a command palette, the first option is highlighted on open.
    await p.waitFor(isActive("Pending"), "the first option to be highlighted on open");
    await p.press("ArrowDown");
    await p.waitFor(isActive("Success"), "ArrowDown to move to Success");
    await p.press("ArrowDown");
    await p.press("ArrowDown");
    await p.waitFor(isActive("Pending"), "ArrowDown to wrap to the top");
    await p.press("ArrowUp");
    await p.waitFor(isActive("Error"), "ArrowUp to wrap to the bottom");
    await p.press("Enter");
    await p.waitFor(`(() => { ${finders} return __ui.byText("Error").some((e) => e.closest("[role=option]")?.getAttribute("aria-selected") === "true"); })()`, "Enter to select Error");
  },

  async "drawer: opens from each side and closes on Escape"(p) {
    await p.goto("/ui/drawer");
    const sides = [
      ["Open Bottom", "Simple Drawer Content", (b) => b.bottom > b.vh * 0.5],
      ["Open Left", "Simple Drawer Content", (b) => b.right < b.vw * 0.5],
      ["Open Top", "Simple Drawer Content", (b) => b.top < b.vh * 0.5],
      ["Open Right (Details)", "Transaction Details", (b) => b.left > b.vw * 0.5],
    ];
    for (const [button, content, placed] of sides) {
      await p.waitText(content, { gone: true });
      await p.clickText(button);
      await p.waitText(content);
      await sleep(250); // the slide-in animation
      const box = await p.boxOf(content);
      assert(placed(box), `${button}: content is on its side (box ${JSON.stringify(box)})`);
      const dialog = await p.evaluate(`(() => { ${finders} return __ui.byText(${JSON.stringify(content)})[0]?.closest("[role=dialog]")?.getAttribute("aria-modal") ?? null; })()`);
      assert(dialog === "true", `${button}: the drawer is a modal dialog (aria-modal=${dialog})`);
      await p.press("Escape");
      await p.waitText(content, { gone: true });
    }
  },

  async "drawer: the backdrop and the close button close it"(p) {
    await p.goto("/ui/drawer");
    await p.clickText("Open Right (Details)");
    await p.waitText("Transaction Details");
    await p.clickLabel("Close details");
    await p.waitText("Transaction Details", { gone: true });
    await p.clickText("Open Right (Details)");
    await p.waitText("Transaction Details");
    await p.clickAway();
    await p.waitText("Transaction Details", { gone: true });
  },

  async "toast: shows in its corner, announced, and its close button dismisses it"(p) {
    await p.goto("/ui/toasts");
    await p.clickText("Save Successful");
    await p.waitText("Document Saved");
    const box = await p.boxOf("Document Saved");
    assert(box.left > box.vw / 2 && box.top < box.vh / 2, `the toast is top right (box ${JSON.stringify(box)})`);
    const role = await p.evaluate(`(() => { ${finders} return __ui.byText("Document Saved")[0]?.closest("[role=status],[role=alert]")?.getAttribute("role") ?? null; })()`);
    assert(role === "status", `a success toast is a status message (role=${role})`);
    await p.clickLabel("Dismiss notification");
    await p.waitText("Document Saved", { gone: true });
  },

  async "toast: closes on its own, and hovering the stack holds it"(p) {
    await p.goto("/ui/toasts");
    await p.clickText("Save Successful");
    await p.waitText("Document Saved");
    await p.waitText("Document Saved", { gone: true, timeout: 6000 });
    await p.clickText("Save Successful");
    await p.hoverText("Document Saved");
    await sleep(4000);
    assert(await p.count("Document Saved") === 1, "a hovered toast stays");
    await p.mouseTo(700, 880);
    await p.waitText("Document Saved", { gone: true, timeout: 6000 });
  },

  async "toast: dismissing one by keyboard leaves the others their full time"(p) {
    await p.goto("/ui/toasts");
    // A, then B (dismissed from the keyboard), then C. B's timer must not
    // take another toast with it.
    await p.clickText("Save Successful");
    await p.waitText("Document Saved");
    await sleep(1000);
    await p.clickText("Upload Complete");
    // "Upload Complete" is the button's text too; wait for the toast itself.
    await p.waitText("profile_photo.jpg has been uploaded.");
    const dismissB = `(() => { ${finders} return __ui.byText("profile_photo.jpg has been uploaded.")[0]?.closest("[role=status]")?.querySelector('[aria-label="Dismiss notification"]') ?? null; })()`;
    await p.waitFor(`!!${dismissB}`, "B's dismiss button");
    await p.evaluate(`${dismissB}.focus()`);
    await p.press("Enter");
    await p.waitText("profile_photo.jpg has been uploaded.", { gone: true });
    await sleep(1000);
    await p.clickText("Payment Processed");
    await p.waitText("Payment Received");
    await p.mouseTo(700, 880);
    // A goes after its duration; B was due a second later; C is due two
    // seconds after A.
    await p.waitText("Document Saved", { gone: true, timeout: 8000 });
    await sleep(1500);
    assert(await p.count("Payment Received") === 1, "C is still showing after B's timer would have fired");
    await p.waitText("Payment Received", { gone: true, timeout: 8000 });
  },

  async "tooltip: shows on hover and focus, hides on leave and Escape"(p) {
    await p.goto("/ui/tooltip");
    const tip = "This is a tooltip";
    await p.waitText(tip, { gone: true });
    await p.hoverText("Hover Me");
    await p.waitText(tip);
    const role = await p.evaluate(`(() => { ${finders} return __ui.byText(${JSON.stringify(tip)})[0]?.closest("[role=tooltip]") ? "tooltip" : null; })()`);
    assert(role === "tooltip", "the popup has role=tooltip");
    const below = await p.boxOf(tip), trigger = await p.boxOf("Hover Me");
    assert(below.bottom <= trigger.top + 1 || below.top >= trigger.bottom - 1 || below.left >= trigger.right - 1 || below.right <= trigger.left + 1, "the tooltip does not cover its trigger");
    await p.mouseTo(700, 880);
    await p.waitText(tip, { gone: true });
    // Escape dismisses it without moving the pointer (WCAG 1.4.13).
    await p.hoverText("Hover Me");
    await p.waitText(tip);
    await p.press("Escape");
    await p.waitText(tip, { gone: true });
    // Keyboard users get it by focusing the trigger.
    await p.mouseTo(700, 880);
    await p.evaluate(`(() => { ${finders} __ui.byText("Hover Me")[0].closest("[tabindex]").focus(); })()`);
    await p.waitText(tip);
    await p.evaluate(`document.activeElement.blur()`);
    await p.waitText(tip, { gone: true });
  },

  async "tooltip: custom triggers and custom content"(p) {
    await p.goto("/ui/tooltip");
    await p.hoverText("Custom Tooltip");
    await p.waitText("This is a custom trigger tooltip");
    await p.mouseTo(700, 880);
    await p.waitText("This is a custom trigger tooltip", { gone: true });
    await p.hoverText("Custom Tooltip with Custom Content");
    await p.waitFor(`(() => { ${finders} return __ui.byText("Due date").some((e) => e.closest("[role=tooltip]")); })()`, "the custom content in the tooltip");
  },

  async "select: pick an option with the pointer"(p) {
    await p.goto("/ui/select");
    // The first select on the page: Pending / Success / Error.
    const trigger = `[...document.querySelectorAll("[aria-haspopup=listbox]")].filter((e) => __ui.visible(e))[0]`;
    await p.waitText("Pending", { gone: true });
    await p.clickSelector("[aria-haspopup=listbox]", 0);
    for (const label of ["Pending", "Success", "Error"]) await p.waitText(label);
    await p.clickText("Success");
    await p.waitText("Pending", { gone: true });
    assert(await p.evaluate(`(() => { ${finders} return ${trigger}.textContent.trim(); })()`) === "Success", "the trigger reads Success");
    // A click outside closes an open select without choosing.
    await p.clickSelector("[aria-haspopup=listbox]", 0);
    await p.waitText("Error");
    await p.clickAway();
    await p.waitText("Error", { gone: true });
  },

  async "select: trigger and options expose their state; Escape closes"(p) {
    await p.goto("/ui/select");
    const trigger = `(() => { ${finders} return [...document.querySelectorAll("[aria-haspopup=listbox]")].filter((e) => __ui.visible(e))[0]; })()`;
    assert(await p.evaluate(`${trigger}?.getAttribute("aria-expanded")`) === "false", "the trigger reads collapsed");
    assert(await p.evaluate(`${trigger}?.textContent.trim()`) === "Select", "the trigger is named by its placeholder");
    await p.clickSelector("[aria-haspopup=listbox]", 0);
    await p.waitText("Pending");
    assert(await p.evaluate(`${trigger}?.getAttribute("aria-expanded")`) === "true", "the trigger reads expanded");
    const roles = await p.evaluate(`(() => { ${finders} return ["Pending", "Success", "Error"].map((t) => __ui.byText(t)[0]?.closest("[role=option]")?.getAttribute("aria-selected") ?? null); })()`);
    assert(JSON.stringify(roles) === '["false","false","false"]', `three unselected options (${JSON.stringify(roles)})`);
    assert(await p.evaluate(`(() => { ${finders} return !!__ui.byText("Pending")[0]?.closest("[role=listbox]"); })()`), "the options sit in a listbox");
    await p.press("Escape");
    await p.waitText("Pending", { gone: true });
    assert(await p.evaluate(`${trigger}?.getAttribute("aria-expanded")`) === "false", "collapsed again");
  },

  async "select: custom and detached triggers report the choice"(p) {
    await p.goto("/ui/select");
    // An icon-only trigger, named for screen readers.
    await p.clickLabel("More actions");
    await p.clickText("Item 3");
    await p.waitDialog("Selected: Item 3");
    await p.waitText("Item 3", { gone: true });
    // The detached select's list renders apart from its trigger.
    await p.clickText("Open Menu →");
    await p.clickText("Analytics");
    await p.waitDialog("Selected: Analytics");
  },

  async "command palette: Ctrl or Cmd + its key toggles it, Escape resets"(p) {
    await p.goto("/ui/commandpalette");
    // An open palette floats its label up out of the field.
    const raised = `(() => { ${finders} return (__ui.byText("Search...")[0]?.getAttribute("style") ?? "").includes("translateY(-70%)"); })()`;
    await p.waitFor(`!${raised}`, "the palette to start closed");
    await p.press("j", "KeyJ", 2); // Ctrl+J
    await p.waitFor(raised, "Ctrl+J to open it");
    await p.press("Escape");
    await p.waitFor(`!${raised}`, "Escape to close it");
    await p.press("j", "KeyJ", 4); // Cmd+J
    await p.waitFor(raised, "Cmd+J to open it");
    await p.clickText("Search...");
    await p.waitFor(`!${raised}`, "a click to toggle it closed");
  },

  async "command palette: revisiting the page leaves no listeners behind"(p) {
    await p.goto("/ui/commandpalette");
    const before = await p.listenerCount("keydown");
    for (let i = 0; i < 4; i++) {
      await p.clickText("Accordion");
      await p.waitText("Return Policy");
      await p.clickText("CommandPalette");
      await p.waitText("Open Dialog...");
    }
    const after = await p.listenerCount("keydown");
    assert(after === before, `keydown listeners went from ${before} to ${after} over 4 visits`);
  },

  async "combobox: several choices, search filters, Escape closes"(p) {
    await p.goto("/ui/combobox");
    const trigger = `(() => { ${finders} return [...document.querySelectorAll("[aria-haspopup=listbox]")].filter((e) => __ui.visible(e))[0]; })()`;
    const selected = `(() => { ${finders} return [...document.querySelectorAll("[role=option][aria-selected=true]")].filter((e) => __ui.visible(e)).map((e) => e.textContent.trim()); })()`;
    assert(await p.evaluate(`${trigger}?.getAttribute("aria-expanded")`) === "false", "starts collapsed");
    await p.clickSelector("[aria-haspopup=listbox]", 0);
    await p.waitText("Pending");
    assert(await p.evaluate(`!!document.querySelector('[role=listbox][aria-multiselectable="true"]')`), "the list allows several choices");
    await p.clickOption("Pending");
    await p.clickOption("Error");
    await p.waitFor(`JSON.stringify(${selected}) === '["Pending","Error"]'`, "Pending and Error both selected");
    await p.clickOption("Pending");
    await p.waitFor(`JSON.stringify(${selected}) === '["Error"]'`, "a second click to unselect Pending");
    // Focus is in the search box: typing filters.
    await p.type("succ");
    await p.waitText("Pending", { gone: true });
    await p.waitText("Success");
    await p.press("Escape");
    await p.waitText("Success", { gone: true });
    assert(await p.evaluate(`${trigger}?.getAttribute("aria-expanded")`) === "false", "collapsed again");
  },

  async "datepicker: days are named by date; picking, paging and changing year"(p) {
    await p.goto("/ui/datepicker");
    // The second picker starts on August 1991.
    const pressed = (label) => `(document.querySelector('[aria-label="${label}"]')?.getAttribute("aria-pressed") ?? null)`;
    await p.clickLabel("August 15, 1991");
    await p.waitFor(`${pressed("August 15, 1991")} === "true"`, "Aug 15 to read pressed");
    assert(p.dialogs.some((d) => d.startsWith("Date selected")), `on_date_select ran (dialogs ${JSON.stringify(p.dialogs)})`);
    await p.clickLabel("Next Month", 1);
    await p.waitFor(`!!document.querySelector('[aria-label="September 15, 1991"]')`, "September 1991");
    assert(await p.evaluate(pressed("September 15, 1991")) === "false", "the 15th of another month is not chosen");
    await p.clickLabel("Previous Month", 1);
    await p.waitFor(`${pressed("August 15, 1991")} === "true"`, "back to August, the 15th still chosen");
    // The same day in another year is not the chosen day.
    await p.clickText("1991");
    await p.clickOption("1992");
    await p.waitFor(`!!document.querySelector('[aria-label="August 15, 1992"]')`, "August 1992");
    assert(await p.evaluate(pressed("August 15, 1992")) === "false", "August 15, 1992 is not chosen");
  },

  async "slider: keys, a press on the track and a drag set the value"(p) {
    await p.goto("/ui/slider");
    const handle = `document.querySelector('[role=slider][aria-label="Volume"]')`;
    const now = (v) => `Number(${handle}?.getAttribute("aria-valuenow")) === ${v}`;
    await p.waitFor(now(40), "the slider to start at 40");
    await p.waitText("Volume: 40");
    await p.evaluate(`${handle}.focus()`);
    await p.press("ArrowRight");
    await p.waitFor(now(45), "ArrowRight to step to 45");
    await p.press("End");
    await p.waitFor(now(100), "End to go to 100");
    await p.press("Home");
    await p.waitFor(now(0), "Home to go to 0");
    await p.press("PageUp");
    await p.waitFor(now(50), "PageUp to jump ten steps");
    await p.waitText("Volume: 50");
    // The pointer: press at 80% of the track, then drag to 20%.
    const track = await p.evaluate(`(() => { const r = ${handle}.parentElement.getBoundingClientRect(); return { left: r.left, width: r.width, y: r.top + r.height / 2 }; })()`);
    await p.drag({ x: track.left + track.width * 0.8, y: track.y }, { x: track.left + track.width * 0.2, y: track.y });
    await p.waitFor(now(20), "the drag to end on 20");
    await p.waitText("Volume: 20");
    assert(await p.listenerCount("pointermove") === 0, "no pointermove listener left after the drag");
  },

  async "carousel: arrows, dots and a swipe change the slide"(p) {
    await p.goto("/ui/carousel");
    const titles = ["Slide One", "Slide Two", "Slide Three", "Slide Four", "Slide Five"];
    // The slide on show: the one whose title the viewport does not clip.
    const shown = `(() => { ${finders} return ${JSON.stringify(titles)}.filter((t) => __ui.byText(t).length > 0); })()`;
    const showing = (t) => p.waitFor(`JSON.stringify(${shown}) === ${JSON.stringify(JSON.stringify([t]))}`, `${t} alone on show`);
    await showing("Slide One");
    await p.clickLabel("Next slide");
    await showing("Slide Two");
    await p.clickLabel("Previous slide");
    await showing("Slide One");
    // Looping: back from the first goes to the last.
    await p.clickLabel("Previous slide");
    await showing("Slide Five");
    await p.clickLabel("Go to slide 3");
    await showing("Slide Three");
    assert(await p.evaluate(`document.querySelector('[aria-label="Go to slide 3"]').getAttribute("aria-pressed")`) === "true", "the third dot reads pressed");
    assert(await p.evaluate(`document.querySelector('[aria-label="Go to slide 1"]').getAttribute("aria-pressed")`) === "false", "the first dot does not");
    // A swipe to the left moves on one slide.
    const box = await p.boxOf("Slide Three");
    const y = (box.top + box.bottom) / 2, x = (box.left + box.right) / 2;
    await p.drag({ x: x + 120, y }, { x: x - 120, y });
    await showing("Slide Four");
  },

  async "sidebar: groups fold away, items mark the current one"(p) {
    await p.goto("/ui/sidebar");
    const group = (t) => `[...document.querySelectorAll("button[aria-expanded]")].find((e) => e.textContent.trim() === ${JSON.stringify(t)})`;
    const item = (t) => `[...document.querySelectorAll("button[aria-pressed]")].find((e) => e.textContent.trim() === ${JSON.stringify(t)})`;
    assert(await p.evaluate(`${group("Projects")}?.getAttribute("aria-expanded")`) === "true", "the Projects group starts open");
    await p.waitText("Treehouse");
    await p.evaluate(`${group("Projects")}.scrollIntoView({ block: "center" })`);
    const box = await p.evaluate(`(() => { const r = ${group("Projects")}.getBoundingClientRect(); return { x: r.left + r.width / 2, y: r.top + r.height / 2 }; })()`);
    await p.drag(box, box, 1); // a click on the group header
    await p.waitFor(`${group("Projects")}?.getAttribute("aria-expanded") === "false"`, "the group to read collapsed");
    await p.waitText("Treehouse", { gone: true });
    assert(await p.evaluate(`${item("Treehouse")}?.tabIndex`) === -1, "a folded item is out of the tab order");
    assert(await p.evaluate(`${item("Treehouse")}?.closest("[aria-hidden=true]") !== null`), "a folded group is hidden from screen readers");
    await p.drag(box, box, 1);
    await p.waitText("Treehouse");
    await p.clickText("Database");
    await p.waitFor(`${item("Database")}?.getAttribute("aria-pressed") === "true"`, "Database to read as current");
    assert(await p.evaluate(`${item("Treehouse")}?.getAttribute("aria-pressed")`) === "false", "the others do not");
    assert(await p.evaluate(`document.querySelector('[aria-label="Toggle menu"]')?.getAttribute("aria-expanded")`) === "true", "the menu toggle is named and reads open");
  },

  async "tabs: clicking and arrow keys switch the chart, focus follows"(p) {
    await p.goto("/ui/chart");
    const selected = `[...document.querySelectorAll("[role=tab][aria-selected=true]")].map((e) => e.textContent.trim())`;
    const isSelected = (t) => `JSON.stringify(${selected}) === ${JSON.stringify(JSON.stringify([t]))}`;
    await p.waitFor(isSelected("Line Charts"), "Line Charts selected at first");
    await p.clickText("Pie Charts");
    await p.waitFor(isSelected("Pie Charts"), "Pie Charts selected");
    await p.waitFor(`document.querySelectorAll('[id*="pie_slice"]').length >= 4`, "a pie chart in the Pie tab");
    await p.clickText("Bar Charts");
    await p.waitFor(isSelected("Bar Charts"), "Bar Charts selected");
    // Keyboard: only the selected tab takes Tab; arrows move the selection.
    assert(await p.evaluate(`[...document.querySelectorAll("[role=tab]")].filter((e) => e.tabIndex === 0).length`) === 1, "one tab in the tab order");
    await p.evaluate(`document.querySelector("[role=tab][aria-selected=true]").focus()`);
    await p.press("ArrowRight");
    await p.waitFor(isSelected("Pie Charts"), "ArrowRight to select Pie Charts");
    await p.waitFor(`document.activeElement?.textContent.trim() === "Pie Charts"`, "focus to follow to Pie Charts");
    await p.press("End");
    await p.waitFor(isSelected("Area Charts"), "End to select the last tab");
    await p.press("ArrowRight");
    await p.waitFor(isSelected("Line Charts"), "ArrowRight to wrap to the first");
    await p.waitFor(`document.activeElement?.textContent.trim() === "Line Charts"`, "focus on Line Charts");
  },

  async "table: sort both ways, select rows, page through"(p) {
    await p.goto("/ui/table");
    // The sortable table: the one with a sort button on Amount.
    const sortBtn = `[...document.querySelectorAll("[aria-label^='Sort by Amount']")][0]`;
    const grid = `${sortBtn}.closest("[role=grid]")`;
    const amounts = `[...${grid}.querySelectorAll("[role=rowgroup]:last-of-type [role=row]")].map((r) => r.textContent.match(/(\\d+)$/)?.[1]).filter(Boolean).map(Number)`;
    await p.evaluate(`${sortBtn}.scrollIntoView({ block: "center" })`);
    assert((await p.evaluate(`${sortBtn}.getAttribute("aria-label")`)) === "Sort by Amount, not sorted", "unsorted at first");
    await p.clickSelector("[aria-label^='Sort by Amount']");
    await p.waitFor(`${sortBtn}.getAttribute("aria-label") === "Sort by Amount, descending"`, "the first click to sort descending");
    let a = await p.evaluate(amounts);
    assert(a.length > 1 && a.every((v, i) => i === 0 || a[i - 1] >= v), `amounts descending (${a})`);
    await p.clickSelector("[aria-label^='Sort by Amount']");
    await p.waitFor(`${sortBtn}.getAttribute("aria-label") === "Sort by Amount, ascending"`, "the second click to flip it");
    a = await p.evaluate(amounts);
    assert(a.every((v, i) => i === 0 || a[i - 1] <= v), `amounts ascending (${a})`);
    // Selecting rows.
    const boxes = `[...${grid}.querySelectorAll('[role=checkbox][aria-label="Select row"]')]`;
    await p.evaluate(`${boxes}[0].scrollIntoView({ block: "center" })`);
    const first = await p.evaluate(`(() => { const r = ${boxes}[0].getBoundingClientRect(); return { x: r.left + r.width / 2, y: r.top + r.height / 2 }; })()`);
    await p.drag(first, first, 1);
    await p.waitFor(`${boxes}[0].getAttribute("aria-checked") === "true"`, "the first row to read selected");
    assert(await p.evaluate(`${boxes}.filter((b) => b.getAttribute("aria-checked") === "true").length`) === 1, "only that row");
    const all = await p.evaluate(`(() => { const b = ${grid}.querySelector('[role=checkbox][aria-label="Select all"]'); const r = b.getBoundingClientRect(); return { x: r.left + r.width / 2, y: r.top + r.height / 2 }; })()`);
    await p.drag(all, all, 1);
    await p.waitFor(`${boxes}.every((b) => b.getAttribute("aria-checked") === "true")`, "Select all to select every row");
    // Paging, on the table with two pages.
    await p.waitText("Page 1 of 2");
    await p.clickLabel("Go to next page");
    await p.waitText("Page 2 of 2");
  },

  async "table: searching a column filters the rows"(p) {
    await p.goto("/ui/table");
    const btn = `document.querySelector("[aria-label^='Search by Email']")`;
    const grid = `${btn}.closest("[role=grid]")`;
    const emails = `[...${grid}.querySelectorAll("[role=row]")].map((r) => r.textContent.match(/[a-z]+@example\\.com/)?.[0]).filter(Boolean)`;
    await p.evaluate(`${btn}.scrollIntoView({ block: "center" })`);
    const before = await p.evaluate(emails);
    assert(before.length >= 5, `rows before searching (${before})`);
    await p.clickSelector("[aria-label^='Search by Email']");
    await p.waitFor(`document.activeElement?.tagName === "INPUT"`, "the search box to take focus");
    await p.type("alice");
    // Row text runs the cells together ("erralice@example.com300").
    await p.waitFor(`${emails}.length > 0 && ${emails}.every((e) => e.includes("alice@"))`, "only alice's rows");
  },

  async "text field: labels lead to their inputs, passwords are hidden"(p) {
    await p.goto("/ui/textfield");
    const inputFor = (label) => `(() => { ${finders} const l = __ui.byText(${JSON.stringify(label)}).find((e) => e.tagName === "LABEL"); return l && document.getElementById(l.htmlFor); })()`;
    assert(await p.evaluate(`${inputFor("Password")}?.type`) === "password", "the password field hides what is typed");
    assert(await p.evaluate(`${inputFor("Email")}?.type`) === "email", "the email field is an email input");
    // A click where the (floating) label sits focuses the field; what you
    // type stays in it.
    const at = async (label) => {
      await p.evaluate(`(() => { ${finders} __ui.byText(${JSON.stringify(label)})[0].scrollIntoView({ block: "center" }); })()`);
      const b = await p.boxOf(label);
      const c = { x: (b.left + b.right) / 2, y: (b.top + b.bottom) / 2 };
      await p.drag(c, c, 1);
    };
    await at("Email");
    await p.waitFor(`document.activeElement === ${inputFor("Email")}`, "a click on the Email label to focus its input");
    await p.type("ada@example.com");
    await sleep(200);
    assert(await p.evaluate(`${inputFor("Email")}.value`) === "ada@example.com", "the email field keeps the text");
    await at("Password");
    await p.waitFor(`document.activeElement === ${inputFor("Password")}`, "a click on the Password label to focus its input");
  },

  async "progress: the bar runs to 100% and replays; the circle toggles"(p) {
    await p.goto("/ui/progress");
    // The progressbar beside each control.
    const barOf = (label) => `(() => { ${finders} let n = __ui.byText(${JSON.stringify(label)})[0]; while (n && !n.querySelector("[role=progressbar]")) n = n.parentElement; return Number(n?.querySelector("[role=progressbar]")?.getAttribute("aria-valuenow")); })()`;
    const startAt = await p.evaluate(barOf("Start Animation"));
    await p.clickText("Start Animation");
    await p.waitFor(`${barOf("Start Animation")} > ${startAt}`, "the bar to move");
    await p.waitFor(`${barOf("Start Animation")} === 100`, "the bar to reach 100%", 12000);
    await p.clickText("Start Animation");
    await p.waitFor(`${barOf("Start Animation")} < 50`, "a second start to run it again from the beginning");
    const circle = await p.evaluate(barOf("Toggle Progress"));
    await p.clickText("Toggle Progress");
    await p.waitFor(`${barOf("Toggle Progress")} !== ${circle}`, "the circle to change");
    const next = await p.evaluate(barOf("Toggle Progress"));
    assert([30, 80].includes(next), `the circle reads 30 or 80 (${next})`);
  },

  async "marquee: scrolls, and pauses while the pointer is over it"(p) {
    await p.goto("/ui/marquee");
    const group = `[...document.querySelectorAll(".marquee-group")].find((g) => g.getBoundingClientRect().height > 0)`;
    await p.evaluate(`${group}.scrollIntoView({ block: "center" })`);
    await sleep(200);
    const state = `getComputedStyle(${group}).animationPlayState`;
    assert(await p.evaluate(state) === "running", "a marquee runs on its own");
    const x1 = await p.evaluate(`${group}.getBoundingClientRect().left`);
    await sleep(300);
    const x2 = await p.evaluate(`${group}.getBoundingClientRect().left`);
    assert(x1 !== x2, `it moves (${x1} -> ${x2})`);
    const box = await p.evaluate(`(() => { const r = ${group}.parentElement.getBoundingClientRect(); return { x: r.left + r.width / 2, y: r.top + r.height / 2 }; })()`);
    await p.mouseTo(box.x, box.y);
    await p.waitFor(`${state} === "paused"`, "hovering to pause it");
    await p.mouseTo(5, 890);
    await p.waitFor(`${state} === "running"`, "leaving to resume it");
  },

  async "button: every button has a name; a loading one says it is busy"(p) {
    await p.goto("/ui/button");
    const unnamed = await p.evaluate(`(() => { ${finders} return [...document.querySelectorAll("button")].filter((b) => __ui.visible(b) && !b.getAttribute("aria-label") && !b.textContent.trim()).length; })()`);
    assert(unnamed === 0, `${unnamed} visible buttons with no name`);
    await p.clickLabel("Next");
    const busy = await p.evaluate(`(() => { ${finders} const b = __ui.byText("Please wait")[0]?.closest("button"); return b && [b.getAttribute("aria-busy"), b.getAttribute("aria-disabled")]; })()`);
    assert(JSON.stringify(busy) === '["true","true"]', `the loading button reads busy and disabled (${JSON.stringify(busy)})`);
  },

  async "every page: each control has a name"(p) {
    const pages = ["/", "/ui/accordion", "/ui/alert", "/ui/button", "/ui/carousel", "/ui/chart", "/ui/checkbox", "/ui/combobox", "/ui/commandpalette", "/ui/components", "/ui/datepicker", "/ui/dialog", "/ui/drawer", "/ui/marquee", "/ui/progress", "/ui/radio", "/ui/select", "/ui/sidebar", "/ui/slider", "/ui/switch", "/ui/table", "/ui/templates", "/ui/textfield", "/ui/toasts", "/ui/tooltip"];
    const problems = [];
    for (const path of pages) {
      await p.goto(path);
      // Its label, text, associated <label>, placeholder or title.
      const unnamed = await p.evaluate(unnamedControls);
      for (const u of unnamed) problems.push(`${path}: ${u}`);
    }
    assert(problems.length === 0, `controls with no name:\n        ${problems.join("\n        ")}`);
  },

  async "table: a row's action menu runs the action on that row"(p) {
    await p.goto("/ui/table");
    // The first action menu on the page belongs to the With Actions table.
    const menu = `[...document.querySelectorAll("[role=gridcell] [aria-haspopup=listbox]")][0]`;
    await p.evaluate(`${menu}.scrollIntoView({ block: "center" })`);
    const email = await p.evaluate(`${menu}.closest("[role=row]").textContent.match(/[a-z]+@example\\.com/)[0].replace(/^(pending|paid|declined)/, "")`);
    const at = await p.evaluate(`(() => { const r = ${menu}.getBoundingClientRect(); return { x: r.left + r.width / 2, y: r.top + r.height / 2 }; })()`);
    await p.drag(at, at, 1);
    await p.clickOption("View");
    await p.waitDialog(`Viewing: ${email}`);
  },

  async "carousel: a bounded one disables the arrow at each end"(p) {
    await p.goto("/ui/carousel");
    // Carousels in page order: basic, compact, bounded.
    const prev = `document.querySelectorAll('[aria-label="Previous slide"]')[2]`;
    const next = `document.querySelectorAll('[aria-label="Next slide"]')[2]`;
    await p.evaluate(`${prev}.scrollIntoView({ block: "center" })`);
    assert(await p.evaluate(`${prev}.getAttribute("aria-disabled")`) === "true", "previous is disabled on the first slide");
    assert(await p.evaluate(`${next}.getAttribute("aria-disabled")`) !== "true", "next is not");
    for (let i = 0; i < 3; i++) await p.clickSelector('[aria-label="Next slide"]', 2);
    await p.waitFor(`${next}.getAttribute("aria-disabled") === "true"`, "next to disable on the last slide");
    assert(await p.evaluate(`${prev}.getAttribute("aria-disabled")`) !== "true", "previous works again");
  },

  async "kanban: buttons move and delete a card"(p) {
    await p.goto("/ui/templates");
    await p.evaluate(`(() => { ${finders} __ui.byText("Performance audit")[0].scrollIntoView({ block: "center" }); })()`);
    assert(await p.evaluate(kanbanColumnOf("Performance audit")) === "Backlog", "starts in Backlog");
    await p.evaluate(`${kanbanCardButton("Performance audit", "Move task right")}.scrollIntoView({ block: "center" })`);
    const right = await p.evaluate(`(() => { const r = ${kanbanCardButton("Performance audit", "Move task right")}.getBoundingClientRect(); return { x: r.left + r.width / 2, y: r.top + r.height / 2 }; })()`);
    await p.drag(right, right, 1);
    await p.waitFor(`${kanbanColumnOf("Performance audit")} === "To Do"`, "the card to move to To Do");
    await p.waitFor(`!!${kanbanCardButton("Performance audit", "Delete task")}`, "the card's delete button");
    const del = await p.evaluate(`(() => { const b = ${kanbanCardButton("Performance audit", "Delete task")}; b.scrollIntoView({ block: "center" }); const r = b.getBoundingClientRect(); return { x: r.left + r.width / 2, y: r.top + r.height / 2 }; })()`);
    await p.drag(del, del, 1);
    await p.waitText("Performance audit", { gone: true });
  },

  async "kanban: a card dragged to another column lands there"(p) {
    await p.goto("/ui/templates");
    await p.evaluate(`(() => { ${finders} __ui.byText("Database schema review")[0].scrollIntoView({ block: "center" }); })()`);
    await sleep(300);
    assert(await p.evaluate(kanbanColumnOf("Database schema review")) === "Backlog", "starts in Backlog");
    const from = await p.evaluate(`(() => { ${finders} const r = __ui.byText("Database schema review")[0].getBoundingClientRect(); return { x: r.left + r.width / 2, y: r.top + r.height / 2 }; })()`);
    const to = await p.evaluate(`(() => { ${finders} const r = __ui.byText("User authentication flow")[0].getBoundingClientRect(); return { x: r.left + r.width / 2, y: r.bottom + 40 }; })()`);
    await p.drag(from, to, 20);
    await p.waitFor(`${kanbanColumnOf("Database schema review")} === "In Progress"`, "the card to land in In Progress");
  },

  async "chat: sending with no server connected says so"(p) {
    await p.goto("/ui/templates");
    // The chat sends over a WebSocket; this static site has no server.
    await p.evaluate(`document.querySelector('textarea[aria-label="Type a message..."]').scrollIntoView({ block: "center" })`);
    await p.evaluate(`document.querySelector('textarea[aria-label="Type a message..."]').focus()`);
    await p.type("Hello there");
    await p.clickLabel("Send message");
    await p.waitText("Not Connected");
    await p.waitText("Waiting for connection...");
  },

  async "landing: every tab shows its content"(p) {
    await p.goto("/");
    // A tab's own text, to know it rendered.
    const expect = {
      Components: "Components",
      Templates: "Revenue",
      Kanban: "Backlog",
      Authentication: "Login into Acorn",
      Payments: "Ryven Pricing",
      Chat: "Type a message...",
    };
    for (const [tab, text] of Object.entries(expect)) {
      await p.clickSelector(`[role=tab][id$="-${tab.toLowerCase()}"]`);
      await p.waitFor(`document.querySelector('[role=tab][aria-selected=true]')?.textContent.trim() === ${JSON.stringify(tab)}`, `the ${tab} tab to be selected`);
      await sleep(400);
      const shown = await p.evaluate(`(() => { ${finders} return __ui.byText(${JSON.stringify(text)}).length > 0 || !!document.querySelector('[placeholder=${JSON.stringify(text)}]'); })()`);
      assert(shown, `the ${tab} tab shows ${JSON.stringify(text)}`);
      const unnamed = await p.evaluate(unnamedControls);
      assert(unnamed.length === 0, `controls with no name on the ${tab} tab:\n        ${unnamed.join("\n        ")}`);
    }
  },

  async "drawer: opening and closing leaves no listeners behind"(p) {
    await p.goto("/ui/drawer");
    const before = await p.listenerCount("keydown");
    for (let i = 0; i < 5; i++) {
      await p.clickText("Open Bottom");
      await p.waitText("Simple Drawer Content");
      await p.press("Escape");
      await p.waitText("Simple Drawer Content", { gone: true });
    }
    const after = await p.listenerCount("keydown");
    assert(after === before, `keydown listeners went from ${before} to ${after} over 5 open/close cycles`);
  },
};

// ── main ────────────────────────────────────────────────────────────────────

if (!existsSync(join(siteDir, "zig-out/bin/vapor.wasm")) || !existsSync(join(siteDir, "zig-out/bin/bundle.min.js"))) {
  console.error("missing zig-out/bin/vapor.wasm or bundle.min.js; run `zig build` (or `zig build test-ui`)");
  process.exit(2);
}

const server = createServer(serve);
await new Promise((r) => server.listen(flags.has("--serve") ? 8091 : 0, "127.0.0.1", r));
const origin = `http://127.0.0.1:${server.address().port}`;
if (flags.has("--serve")) {
  console.log(`serving ${siteDir} at ${origin}`);
  await new Promise(() => {});
}

const cdp = await launch();
const page = makePage(cdp, origin);

if (flags.has("--dump")) {
  // Every visible thing a test could press or read, for writing tests.
  for (const path of positional) {
    await page.goto(path);
    await sleep(500);
    const items = await page.evaluate(`(() => {
      ${finders}
      return [...document.querySelectorAll("button, a, input, textarea, select, [role], [aria-label], [tabindex]")]
        .filter((e) => __ui.visible(e))
        .map((e) => [e.tagName.toLowerCase(), e.getAttribute("role") ?? "", e.getAttribute("aria-label") ?? "", e.textContent.trim().replace(/\\s+/g, " ").slice(0, 60)].join(" | "));
    })()`);
    console.log(`── ${path}\n  ${items.join("\n  ")}`);
  }
  cdp.close();
  server.close();
  process.exit(0);
}

const only = positional[0];
const selected = Object.entries(tests).filter(([name]) => !only || name.toLowerCase().includes(only.toLowerCase()));
if (selected.length === 0) {
  console.error(`no test name contains "${only}"`);
  process.exit(2);
}

let failed = 0;
for (const [name, fn] of selected) {
  cdp.problems.length = 0;
  cdp.dialogs.length = 0;
  try {
    await fn(page);
    await sleep(100);
    if (cdp.problems.length) throw new Error(cdp.problems.join("\n      "));
    console.log(`ok   ${name}`);
  } catch (err) {
    failed++;
    console.log(`FAIL ${name}\n      ${err.message}`);
    if (cdp.problems.length) console.log(`      page errors:\n      ${[...new Set(cdp.problems)].join("\n      ")}`);
  }
}

cdp.close();
server.close();
console.log(failed ? `\n${failed} failed` : `\nall ${selected.length} passed`);
process.exit(failed ? 1 : 0);
