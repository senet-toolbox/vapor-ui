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
//   node tests/run.mjs --shot / /ui/x  (whole-page screenshots at 1440, 1024,
//                                       768 and 390px into $SHOT_DIR)
//   node tests/run.mjs --release       (against release/, as a static host
//                                       serves it; `zig build test-release`)
//
// No npm dependencies: Node >= 22 provides fetch and WebSocket. Chrome is found
// via $CHROME, then the usual install locations.

import { spawn } from "node:child_process";
import { createServer } from "node:http";
import { existsSync, mkdtempSync, readFileSync, rmSync, statSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, extname, join, normalize, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const projectDir = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const args = process.argv.slice(2);
const flags = new Set(args.filter((a) => a.startsWith("--")));
const positional = args.filter((a) => !a.startsWith("--"));
const release = flags.has("--release");
const siteDir = release ? join(projectDir, "release") : projectDir;

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

// release/ as a static host serves it: the file, else the directory's
// index.html, else the fallback for paths no file covers: app.html when the
// pages are prerendered, index.html when the site is client-rendered.
function serveRelease(req, res) {
  const path = decodeURIComponent(new URL(req.url, "http://x").pathname);
  const file = normalize(join(siteDir, path));
  if (!file.startsWith(siteDir)) return res.writeHead(400).end();
  const found = [file, join(file, "index.html"), join(siteDir, "app.html"), join(siteDir, "index.html")].find((f) => existsSync(f) && statSync(f).isFile());
  res.writeHead(200, { "content-type": mime[extname(found)] ?? "application/octet-stream" });
  res.end(readFileSync(found));
}

function serve(req, res) {
  if (release) return serveRelease(req, res);
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
  res.end(readFileSync(join(projectDir, "template.html")));
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
    // Resizes the page; the app reads its width when it loads, so goto after.
    async viewport(width, height, mobile = false) {
      await cdp.send("Emulation.setDeviceMetricsOverride", { width, height, deviceScaleFactor: 1, mobile });
    },
    // The colour scheme the system prefers, "light" or "dark"; none for
    // Chrome's own. The app reads it when it loads, so goto after.
    async colorScheme(scheme) {
      const features = scheme ? [{ name: "prefers-color-scheme", value: scheme }] : [];
      await cdp.send("Emulation.setEmulatedMedia", { features });
    },
    // Whether the system asks for less motion, "reduce" or "no-preference";
    // none for Chrome's own (headless Chrome reduces). Goto after.
    async reducedMotion(value) {
      const features = value ? [{ name: "prefers-reduced-motion", value }] : [];
      await cdp.send("Emulation.setEmulatedMedia", { features });
    },
    // How fast CSS animations play: 0.1 is ten times slower, 1 normal.
    async animationSpeed(rate) {
      await cdp.send("Animation.enable");
      await cdp.send("Animation.setPlaybackRate", { playbackRate: rate });
    },
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
    // A real click at a point of the page.
    async clickAt(x, y) {
      await mouse("mouseMoved", x, y, { button: "none", clickCount: 0 });
      await mouse("mousePressed", x, y);
      await mouse("mouseReleased", x, y);
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
    async dblclick(at) {
      await mouse("mouseMoved", at.x, at.y, { button: "none", clickCount: 0 });
      for (const clickCount of [1, 2]) {
        await mouse("mousePressed", at.x, at.y, { clickCount });
        await mouse("mouseReleased", at.x, at.y, { clickCount });
      }
      await sleep(60);
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
    // A finger drag, through the browser's touch pipeline: it scrolls,
    // cancels pointers and fires touch events as a phone would.
    async tap(at) {
      await cdp.send("Emulation.setTouchEmulationEnabled", { enabled: true, maxTouchPoints: 1 });
      await cdp.send("Input.dispatchTouchEvent", { type: "touchStart", touchPoints: [at] });
      await sleep(40);
      await cdp.send("Input.dispatchTouchEvent", { type: "touchEnd", touchPoints: [] });
      await sleep(100);
      await cdp.send("Emulation.setTouchEmulationEnabled", { enabled: false });
    },
    // `then`: points the finger moves on to after the dwell, before lifting.
    async touchDrag(from, to, { steps = 12, holdMs = 0, dwellMs = 0, then = [] } = {}) {
      await cdp.send("Emulation.setTouchEmulationEnabled", { enabled: true, maxTouchPoints: 1 });
      const touch = (type, x, y) => cdp.send("Input.dispatchTouchEvent", { type, touchPoints: type === "touchEnd" ? [] : [{ x, y }] });
      await touch("touchStart", from.x, from.y);
      if (holdMs) await sleep(holdMs);
      for (let i = 1; i <= steps; i++) {
        await touch("touchMove", from.x + ((to.x - from.x) * i) / steps, from.y + ((to.y - from.y) * i) / steps);
        await sleep(16);
      }
      if (dwellMs) await sleep(dwellMs);
      for (const at of then) {
        await touch("touchMove", at.x, at.y);
        await sleep(50);
      }
      await touch("touchEnd", to.x, to.y);
      await sleep(100);
      await cdp.send("Emulation.setTouchEmulationEnabled", { enabled: false });
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
    // Types `text` one key at a time, keydown to keyup, as a keyboard does,
    // so a keydown handler that cancels keys stops them. "\n" is Shift+Enter.
    async typeKeys(text) {
      for (const ch of text) {
        const enter = ch === "\n";
        const key = enter ? "Enter" : ch;
        const typed = enter ? "\r" : ch;
        const keyCode = enter ? 13 : ch.toUpperCase().charCodeAt(0);
        const modifiers = enter ? 8 : 0;
        await cdp.send("Input.dispatchKeyEvent", { type: "keyDown", key, modifiers, windowsVirtualKeyCode: keyCode, text: typed, unmodifiedText: typed });
        await cdp.send("Input.dispatchKeyEvent", { type: "keyUp", key, modifiers, windowsVirtualKeyCode: keyCode });
        await sleep(20);
      }
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

// Where to pick up the card titled `title`, and a point in `column` to drop
// it at, after scrolling the card into view.
async function kanbanDragPoints(p, title, column) {
  return p.evaluate(`(() => {
    ${finders}
    const t = __ui.byText(${JSON.stringify(title)})[0];
    t.scrollIntoView({ block: "center", inline: "nearest" });
    const r = t.getBoundingClientRect();
    const backlog = __ui.byText("Backlog")[0].getBoundingClientRect();
    const head = __ui.byText(${JSON.stringify(column)}).map((e) => e.getBoundingClientRect()).find((h) => Math.abs(h.top - backlog.top) < 4);
    return { from: { x: r.left + 20, y: r.top + r.height / 2 }, to: { x: Math.min(head.left + 40, innerWidth - 10), y: r.top + r.height / 2 + 40 } };
  })()`);
}

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

const COMPONENT_PAGES = ["accordion", "alert", "avatar", "badge", "button", "carousel", "chart", "checkbox", "combobox", "commandpalette", "datepicker", "dialog", "drawer", "marquee", "menu", "progress", "radio", "select", "sidebar", "slider", "switch", "table", "tabs", "textfield", "toasts", "tooltip"].map((n) => `/ui/components/${n}`);

const tests = {
  async "focus: Tab shows the one ring on every component, a click shows none"(p) {
    const ringOf = (find) => `(() => { const e = ${find}; const s = getComputedStyle(e); return [s.outlineStyle, s.outlineWidth, s.outlineOffset, s.outlineColor].join(" "); })()`;
    const button = (text) => `[...document.querySelectorAll("button")].find((b) => b.textContent.trim() === ${JSON.stringify(text)})`;
    // A ring outside the control, or just inside one that fills a list.
    const controls = [
      ["accordion", `[...document.querySelectorAll("button")].find((b) => b.textContent.includes("Product Information"))`, "2px"],
      ["tabs", `document.querySelector("[role=tab]")`, "-2px"],
      ["checkbox", `document.querySelector("[role=checkbox]")`, "2px"],
      ["menu", button("Actions"), "2px"],
      ["sidebar", button("Dashboard"), "-2px"],
      // The site's own, from the template's rule.
      ["button", button("Secondary"), "2px"],
    ];
    // The theme's text colour, without the body's colour transition.
    const textColor = `(() => { const e = document.createElement("i"); e.style.color = "rgb(var(--text_color))"; document.body.append(e); const c = getComputedStyle(e).color; e.remove(); return c; })()`;
    for (const scheme of ["light", "dark"]) {
      await p.colorScheme(scheme);
      for (const [page, find, offset] of controls) {
        await p.goto("/ui/components/" + page);
        await p.press("Shift", "ShiftLeft");
        await p.evaluate(`(${find}).focus()`);
        const want = `solid 2px ${offset} ${await p.evaluate(textColor)}`;
        // Past the outline's transition, where a control has one.
        await p.waitFor(`${ringOf(find)} === ${JSON.stringify(want)}`, `${scheme} ${page}: the ring "${want}" (is "${await p.evaluate(ringOf(find))}")`);
      }
    }
    await p.colorScheme("light");
    await p.goto("/ui/components/accordion");
    await p.clickText("Product Information");
    const trigger = controls[0][1];
    await p.waitFor(`document.activeElement === (${trigger})`, "the click to focus the trigger");
    await sleep(200);
    const ring = await p.evaluate(ringOf(trigger));
    assert(!ring.startsWith("solid"), `a click left a ring on the trigger (${ring})`);
  },

  async "accordion: a header opens its panel and closes it again"(p) {
    await p.goto("/ui/components/accordion");
    const body = "We stand behind our products with a 30-day return policy. If you're not satisfied, simply return the item in its original condition for a full refund.";
    await p.waitText(body, { gone: true });
    await p.clickText("Return Policy");
    await p.waitText(body);
    await p.clickText("Return Policy");
    await p.waitText(body, { gone: true });
  },

  async "accordion: a custom panel's own buttons work"(p) {
    await p.goto("/ui/components/accordion");
    await p.waitText("Open Account Settings", { gone: true });
    await p.clickText("Security Settings");
    await p.waitText("Open Account Settings");
  },

  async "accordion: triggers report open/closed, items never overlap, closed panels leave the tab order"(p) {
    await p.goto("/ui/components/accordion");
    const trigger = (t) => `(() => { ${finders} return __ui.byText(${JSON.stringify(t)})[0]?.closest("button[aria-expanded]"); })()`;
    assert(await p.evaluate(`${trigger("Security Settings")}?.getAttribute("aria-expanded")`) === "false", "starts collapsed");
    // A closed panel's buttons cannot take focus (visibility: hidden).
    assert(await p.evaluate(`(() => { const b = [...document.querySelectorAll("button")].find((e) => e.textContent.trim() === "Open Account Settings"); return getComputedStyle(b).visibility; })()`) === "hidden", "a closed panel's button is hidden");
    await p.clickText("Security Settings");
    await p.waitFor(`${trigger("Security Settings")}?.getAttribute("aria-expanded") === "true"`, "the trigger to read expanded");
    await p.waitText("Open Account Settings");
    await sleep(300); // the open animation
    // No item (a trigger and its panel) overlaps the next, open or closed.
    const overlaps = await p.evaluate(`(() => { const bs = [...document.querySelectorAll("button[aria-expanded]")].map((b) => b.parentElement.getBoundingClientRect()); let n = 0; for (let i = 1; i < bs.length; i++) if (bs[i].top < bs[i - 1].bottom - 1 && bs[i].left < bs[i - 1].right) n++; return n; })()`);
    assert(overlaps === 0, `${overlaps} accordion items overlap the one before`);
    // The open panel shows all of its content.
    const fits = await p.evaluate(`(() => { const b = [...document.querySelectorAll("button")].find((e) => e.textContent.trim() === "Open Account Settings"); const item = b.closest("[style*=grid]").parentElement.getBoundingClientRect(); const r = b.getBoundingClientRect(); return r.bottom <= item.bottom + 1; })()`);
    assert(fits, "the open panel is tall enough for its content");
  },

  async "accordion: the API reference shows init, render and every item field, framed like the examples"(p) {
    for (const [w, h] of [[1440, 900], [390, 844]]) {
      await p.viewport(w, h);
      await p.goto("/ui/components/accordion");
      const text = await p.evaluate(`document.body.textContent`);
      for (const want of ["pub fn init(items: []AccordionItem) Accordion", "pub fn render(accordion: *Accordion) void", "is_open", "?*const fn (*AccordionItem) void"])
        assert(text.includes(want), `at ${w}px the API reference doesn't show ${JSON.stringify(want)}`);
      // The ApiBox: the frame (with a CodeBox's 18px corners) around the tab
      // reading "AccordionItem"; each field's name is in the code font.
      const got = await p.evaluate(`(() => {
        const tab = [...document.querySelectorAll("p, span")].find((e) => e.textContent === "AccordionItem" && getComputedStyle(e).fontStyle === "italic");
        let box = tab;
        while (box && getComputedStyle(box).borderTopLeftRadius !== "18px") box = box.parentElement;
        if (!box) return null;
        const names = [...box.querySelectorAll("p, span")].filter((e) => getComputedStyle(e).fontFamily.includes("DM Mono") && getComputedStyle(e).fontWeight === "500");
        const rows = names.map((e) => e.parentElement.parentElement);
        return {
          names: names.map((e) => e.textContent),
          radius: getComputedStyle(box).borderTopLeftRadius,
          fits: box.getBoundingClientRect().right <= innerWidth && rows.every((e) => e.scrollWidth <= e.clientWidth + 1),
        };
      })()`);
      assert(got, `at ${w}px there is no AccordionItem API box`);
      assert(JSON.stringify(got.names) === JSON.stringify(["title", "description", "is_open", "trigger", "content"]), `at ${w}px the fields are ${got.names}`);
      assert(got.radius === "18px", `at ${w}px the API box's corners are ${got.radius}, not the code boxes' 18px`);
      assert(got.fits, `at ${w}px a field row is wider than the page or its box`);
    }
    await p.viewport(1440, 900);
  },

  async "docs: every component's API reference uses the shared boxes"(p) {
    // Each page, the API box it has first, and that box's first entry.
    const pages = {
      accordion: ["AccordionItem", "title"], alert: ["Alert", "content"], button: ["Defaults", "background"],
      carousel: ["Options", "id"], chart: ["Config", "height"], checkbox: ["Parameters", "aria_label"], commandpalette: ["CommandPalette", "text"],
      datepicker: ["DatePicker", "start_date"], dialog: ["Item(T)", "value"], progress: ["ProgressBar.Config", "id"],
      radio: ["Group", "name"], select: ["Item", "value"], sidebar: ["SideBar", "groups"], slider: ["Slider", "min"],
      switch: ["Parameters", "aria_label"], table: ["Column(T)", "title"], tabs: ["Tabs", "tag"], tooltip: ["Options", "content"],
      combobox: ["Item", "value"], avatar: ["Options", "name"], badge: ["Options", "text"], drawer: ["Sheet", "content"], marquee: ["Options", "direction"], menu: ["Item", "label"], textfield: ["Field", "label"], toasts: ["Options", "title"],
    };
    for (const [page, [tab, first]] of Object.entries(pages)) {
      await p.goto(`/ui/components/${page}`);
      const got = await p.evaluate(`(() => {
        // An API box: the 18px frame around an italic tab; its entries' names
        // are DM Mono at weight 500.
        const names = (b) => b ? [...b.querySelectorAll("p, span")].filter((e) => getComputedStyle(e).fontFamily.includes("DM Mono") && getComputedStyle(e).fontWeight === "500").map((e) => e.textContent) : [];
        const frame = (tab) => { let b = tab; while (b && getComputedStyle(b).borderTopLeftRadius !== "18px") b = b.parentElement; return b; };
        // A code box can share the title; the API box is the one with entries.
        const box = (title) => [...document.querySelectorAll("p, span")]
          .filter((e) => e.textContent === title && getComputedStyle(e).fontStyle === "italic")
          .map(frame).find((b) => names(b).length > 0);
        return {
          title: document.body.textContent.includes("API Reference"),
          first: names(box(${JSON.stringify(tab)}))[0] ?? null,
          behaviours: names(box("Behaviour")).length,
          // The old flat boxes were #1a1a1a.
          flat: [...document.querySelectorAll("div")].filter((e) => getComputedStyle(e).backgroundColor === "rgb(26, 26, 26)").length,
          bogus: document.body.textContent.includes("vapor add"),
        };
      })()`);
      assert(got.title, `${page} has no API Reference`);
      assert(got.first === first, `${page}'s ${tab} box starts with ${got.first}, not ${first}`);
      assert(got.behaviours >= 2, `${page} has no Behaviour box`);
      assert(got.flat === 0, `${page} still has ${got.flat} old flat code boxes`);
      assert(!got.bogus, `${page} tells you to run vapor add, which doesn't exist`);
    }
  },

  async "command palette: its shortcut opens your own dialog, and a pick closes both"(p) {
    await p.goto("/ui/components/commandpalette");
    const raised = `(() => { ${finders} return (__ui.byText("Open Dialog...")[0]?.getAttribute("style") ?? "").includes("translateY(-70%)"); })()`;
    await p.waitText("Opened: nothing yet");
    await p.press("i", "KeyI", 2); // Ctrl+I
    await p.waitFor(raised, "Ctrl+I to open the palette");
    await p.clickOption("Settings");
    await p.waitText("Opened: Settings");
    await p.waitFor(`!${raised}`, "the palette to rest once the dialog closes");
  },

  async "alert: opens on its trigger and Cancel closes it"(p) {
    await p.goto("/ui/components/alert");
    await p.waitText("Delete your account?", { gone: true });
    await p.clickText("Trigger Confirmation");
    await p.waitText("Delete your account?");
    await p.clickText("Cancel");
    await p.waitText("Delete your account?", { gone: true });
    // The action closes it too.
    await p.clickText("Trigger Confirmation");
    await p.waitText("Delete your account?");
    await p.clickText("Delete account");
    await p.waitText("Delete your account?", { gone: true });
  },

  async "alert: a labelled modal dialog that takes the focus and gives it back"(p) {
    await p.goto("/ui/components/alert");
    const dialog = `[...document.querySelectorAll("[role=alertdialog]")].find((e) => e.getBoundingClientRect().width > 0)`;
    // Opened from the keyboard.
    await p.evaluate(`document.querySelector('[aria-label="open alert"]').focus()`);
    await p.press("Enter");
    await p.waitText("Delete your account?");
    await p.waitFor(`!!${dialog} && ${dialog}.contains(document.activeElement)`, "the focus to move into the alert").catch(() => {});
    const got = await p.evaluate(`(() => {
      const d = ${dialog};
      return {
        dialog: !!d, modal: d?.getAttribute("aria-modal"), label: d?.getAttribute("aria-label"),
        focusInside: !!d && d.contains(document.activeElement),
        // Buttons a keyboard can reach that say nothing: the click-catcher behind it.
        mute: [...document.querySelectorAll("button")].filter((b) => b.tabIndex >= 0 && b.getBoundingClientRect().width > 0 && !b.textContent.trim() && !b.getAttribute("aria-label")).length,
      };
    })()`);
    assert(got.dialog && got.modal === "true" && got.label, `the alert is not a labelled modal alertdialog: ${JSON.stringify(got)}`);
    assert(got.focusInside, "focus stays behind the alert when it opens");
    assert(got.mute === 0, `${got.mute} unnamed buttons can be tabbed to`);
    await p.press("Escape");
    await p.waitText("Delete your account?", { gone: true });
    await p.waitFor(`document.activeElement?.getAttribute("aria-label") === "open alert"`, "focus to return to the button that opened it");
    await p.waitText("Answer: dismissed");
    // A click outside dismisses it too, and says so. (Each time, the alert
    // finishes leaving before the next click.)
    await sleep(300);
    await p.clickText("Trigger Confirmation");
    await p.waitText("Delete your account?");
    await p.clickText("Delete account");
    await p.waitText("Answer: continued");
    await p.waitText("Delete your account?", { gone: true });
    await sleep(300);
    await p.clickText("Trigger Confirmation");
    await p.waitText("Delete your account?");
    await p.waitFor(`!!${dialog}`, "the alert to open");
    // Beside the panel, on the backdrop.
    const out = await p.evaluate(`(() => { const r = ${dialog}.getBoundingClientRect(); return { x: Math.max(5, r.left - 40), y: r.top + r.height / 2 }; })()`);
    await p.clickAt(out.x, out.y);
    await p.waitFor(`!${dialog}`, "a click outside to close the alert");
    await p.waitText("Answer: dismissed");
  },

  async "alert: its border follows the theme"(p) {
    await p.colorScheme("dark");
    await p.goto("/ui/components/alert");
    await p.clickText("Trigger Confirmation");
    await p.waitText("Delete your account?");
    const border = await p.evaluate(`(() => { let e = [...document.querySelectorAll("*")].find((x) => x.textContent === "Delete your account?" && !x.children.length); while (e && getComputedStyle(e).borderTopWidth === "0px") e = e.parentElement; return e ? getComputedStyle(e).borderTopColor : null; })()`);
    await p.colorScheme(null);
    assert(border && border !== "rgb(228, 228, 228)", `in dark mode the alert keeps its light border (${border})`);
  },

  async "alert: its panel has room round its content, and fits a phone"(p) {
    const panel = `document.querySelector("[role=alertdialog]")`;
    const measure = `(() => { const e = ${panel}, cs = getComputedStyle(e), r = e.getBoundingClientRect(); return { padding: parseFloat(cs.paddingLeft), left: r.left, right: innerWidth - r.right, width: r.width }; })()`;
    await p.goto("/ui/components/alert");
    await p.clickText("Trigger Confirmation");
    await p.waitFor(`!!${panel}`, "the alert to open");
    const wide = await p.evaluate(measure);
    assert(wide.padding >= 16, `the alert's content touches its edge (padding ${wide.padding}px)`);
    assert(wide.width <= 440, `the alert is ${wide.width}px wide; it stops at 440`);
    await p.press("Escape");
    await p.viewport(375, 740, true);
    try {
      await p.goto("/ui/components/alert");
      await p.clickText("Trigger Confirmation");
      await p.waitFor(`!!${panel}`, "the alert to open on a phone");
      const phone = await p.evaluate(measure);
      assert(phone.left >= 15 && phone.right >= 15, `on a phone the alert runs off the screen (${JSON.stringify(phone)})`);
    } finally {
      await p.viewport(1440, 900);
    }
  },

  async "components: the sidebar marks the page, with a trailing slash too"(p) {
    const marked = `[...document.querySelectorAll("#components-sidebar li")].filter((li) => getComputedStyle(li).borderRightColor !== "rgba(0, 0, 0, 0)").map((li) => li.textContent.trim())`;
    for (const path of ["/ui/components/menu", "/ui/components/menu/"]) {
      await p.goto(path);
      await p.waitFor(`!!document.getElementById("components-sidebar")`, "the sidebar");
      { const got = await p.evaluate(marked); assert(JSON.stringify(got) === JSON.stringify(["Menu"]), `the sidebar's marked entry at ${path}` + ": " + JSON.stringify(got)); }
    }
  },

  async "components: previous and next links go through the pages, each from its top"(p) {
    const links = `[...document.querySelectorAll("[role=navigation][aria-label='Previous and next component'] a")].map((a) => a.getAttribute("aria-label"))`;
    await p.goto("/ui/components/accordion");
    { const got = await p.evaluate(links); assert(JSON.stringify(got) === JSON.stringify(["Next: Alert"]), "the first page's links" + ": " + JSON.stringify(got)); }
    await p.goto("/ui/components/progress");
    { const got = await p.evaluate(links); assert(JSON.stringify(got) === JSON.stringify(["Previous: Tooltip"]), "the last page's links" + ": " + JSON.stringify(got)); }
    await p.goto("/ui/components/alert");
    { const got = await p.evaluate(links); assert(JSON.stringify(got) === JSON.stringify(["Previous: Accordion", "Next: Avatar"]), "the alert page's links" + ": " + JSON.stringify(got)); }
    await p.evaluate(`window.scrollTo(0, document.documentElement.scrollHeight)`);
    await p.waitFor(`window.scrollY > 300`, "the page scrolled to its foot");
    await p.evaluate(`document.querySelector("a[aria-label='Next: Avatar']").click()`);
    await p.waitFor(`location.pathname === "/ui/components/avatar" && document.body.textContent.includes("avatar-ui")`, "the avatar page");
    await sleep(150);
    { const got = await p.evaluate(`window.scrollY`); assert(JSON.stringify(got) === JSON.stringify(0), "the next page's scroll position" + ": " + JSON.stringify(got)); }
    { const got = await p.evaluate(links); assert(JSON.stringify(got) === JSON.stringify(["Previous: Alert", "Next: Badge"]), "the avatar page's links" + ": " + JSON.stringify(got)); }
  },

  async "menu: opens on its first item; keys move, skip, jump and pick; focus comes back"(p) {
    await p.goto("/ui/components/menu");
    const trigger = `[...document.querySelectorAll('button[aria-haspopup=menu]')].find((b) => b.textContent.trim() === "Actions")`;
    const menu = `document.querySelector('[role=menu][aria-label="Actions"]')`;
    // An item's name: its text but the shortcut, which is hidden from readers.
    const focused = `(document.activeElement?.getAttribute("role") === "menuitem" ? [...document.activeElement.children].filter((c) => !c.hasAttribute("aria-hidden")).map((c) => c.textContent).join("").trim() : null)`;
    assert(await p.evaluate(`${trigger}.getAttribute("aria-expanded")`) === "false", "the menu starts closed");
    await p.evaluate(`${trigger}.focus()`);
    await p.press("Enter");
    await p.waitFor(`!!${menu}`, "Enter to open the menu");
    assert(await p.evaluate(`${trigger}.getAttribute("aria-expanded")`) === "true", "the button doesn't say it's open");
    await p.waitFor(`${focused} === "Edit"`, "the focus on the first item");
    const move = async (key, expect, why) => { await p.press(key); await p.waitFor(`${focused} === ${JSON.stringify(expect)}`, why); };
    await move("ArrowDown", "Duplicate", "Down to the next item");
    await move("ArrowDown", "Delete", "Down to skip the disabled Archive");
    await move("ArrowDown", "Edit", "Down to wrap round");
    await move("End", "Delete", "End to the last item");
    await move("Home", "Edit", "Home to the first");
    await move("d", "Duplicate", "a letter to the next item starting with it");
    assert(await p.evaluate(`[...${menu}.querySelectorAll("[role=menuitem]")].find((e) => e.textContent.trim() === "Archive").getAttribute("aria-disabled")`) === "true", "Archive isn't marked disabled");
    assert(await p.evaluate(`[...${menu}.querySelectorAll("[role=menuitem]")].find((e) => e.textContent.startsWith("Edit")).getAttribute("aria-keyshortcuts")`) === "E", "Edit's shortcut isn't given as aria-keyshortcuts");
    await p.press("Enter");
    await p.waitText("Picked: Duplicate");
    await p.waitFor(`!${menu}`, "a pick to close the menu");
    await p.waitFor(`document.activeElement === ${trigger}`, "the focus back on the button");
    // Up opens at the last item; Escape closes.
    await p.press("ArrowUp");
    await p.waitFor(`${focused} === "Delete"`, "Up to open the menu at its last item");
    await p.press("Escape");
    await p.waitFor(`!${menu}`, "Escape to close the menu");
    await p.waitFor(`document.activeElement === ${trigger}`, "the focus back on the button after Escape");
    // A disabled item can't be picked; a click outside closes.
    await p.evaluate(`${trigger}.click()`);
    await p.waitFor(`!!${menu}`, "a click to open it");
    await p.clickText("Archive");
    await sleep(150);
    assert(await p.evaluate(`!!${menu}`) && await p.evaluate(`document.body.textContent.includes("Picked: Duplicate")`), "clicking the disabled Archive picked it");
    const out = await p.evaluate(`(() => { const r = ${menu}.getBoundingClientRect(); return { x: Math.max(5, r.left - 60), y: r.top + 10 }; })()`);
    await p.clickAt(out.x, out.y);
    await p.waitFor(`!${menu}`, "a click outside to close it");
  },

  async "menu: the text beside the button stays beside it, shut and open"(p) {
    await p.goto("/ui/components/menu");
    const trigger = `[...document.querySelectorAll('button[aria-haspopup=menu]')].find((b) => b.textContent.trim() === "Actions")`;
    const picked = `[...document.querySelectorAll("p")].find((e) => e.textContent.startsWith("Picked:"))`;
    // The text after the button: before it, the page moved when the menu opened.
    const after = `!!(${trigger}.compareDocumentPosition(${picked}) & Node.DOCUMENT_POSITION_FOLLOWING)`;
    await p.waitFor(`!!${trigger} && !!${picked}`, "the basic menu");
    assert(await p.evaluate(after), "the text comes before the button while the menu is shut");
    // Near the bottom of the window, with no room below, it opens above
    // rather than over its button.
    await p.evaluate(`window.scrollTo(0, 0); ${trigger}.scrollIntoView({ block: "end" })`);
    await p.evaluate(`${trigger}.click()`);
    await p.waitFor(`!!document.querySelector('[role=menu][aria-label="Actions"]')`, "the menu to open");
    await sleep(150);
    const clear = await p.evaluate(`(() => { const b = ${trigger}.getBoundingClientRect(), m = document.querySelector('[role=menu]').getBoundingClientRect(); return m.bottom <= b.top + 1 || m.top >= b.bottom - 1; })()`);
    assert(clear, "with no room below, the menu covers its button");
    await p.press("Escape");
    await p.waitFor(`!document.querySelector('[role=menu][aria-label="Actions"]')`, "the menu to close");
    // With room below it, as when someone has scrolled to it.
    await p.evaluate(`${trigger}.scrollIntoView({ block: "center" })`);
    const before = await p.evaluate(`JSON.stringify(${trigger}.getBoundingClientRect())`);
    await p.evaluate(`${trigger}.click()`);
    await p.waitFor(`!!document.querySelector('[role=menu][aria-label="Actions"]')`, "the menu to open");
    assert(await p.evaluate(after), "the text comes before the button while the menu is open");
    assert(await p.evaluate(`JSON.stringify(${trigger}.getBoundingClientRect())`) === before, "the button moved when the menu opened");
    // The menu opens below the row, not over the text.
    const r = await p.evaluate(`(() => { const t = ${picked}.getBoundingClientRect(), m = document.querySelector('[role=menu]').getBoundingClientRect(); return m.top >= t.bottom || m.right <= t.left || m.left >= t.right; })()`);
    assert(r, "the open menu covers the text beside the button");
    await p.press("Escape");
  },

  async "menu: an icon-only button is named, and the pointer moves the highlight"(p) {
    await p.goto("/ui/components/menu");
    const trigger = `document.querySelector('button[aria-haspopup=menu][aria-label="Account menu"]')`;
    assert(await p.evaluate(`!!${trigger}`), "the icon button isn't named Account menu");
    await p.evaluate(`${trigger}.click()`);
    const menu = `document.querySelector('[role=menu][aria-label="Account menu"]')`;
    await p.waitFor(`!!${menu}`, "the account menu to open");
    await p.hoverText("Settings");
    await p.waitFor(`document.activeElement?.textContent.trim() === "Settings"`, "hovering Settings to highlight it");
    await p.press("ArrowDown");
    await p.waitFor(`document.activeElement?.textContent.trim() === "Sign out"`, "the keys to carry on from where the pointer was");
  },

  async "avatar: named, with initials when the photo is missing, and a group that counts the rest"(p) {
    await p.goto("/ui/components/avatar");
    await sleep(300);
    const got = await p.evaluate(`(() => {
      const imgs = [...document.querySelectorAll("[role=img][aria-label]")];
      const byName = (n) => imgs.find((e) => e.getAttribute("aria-label") === n);
      const shown = (e) => e && [...e.querySelectorAll("*")].filter((c) => !c.children.length && c.textContent.trim()).map((c) => c.textContent.trim()).join("");
      const g = document.querySelector('[role=group][aria-label="6 people"]');
      return {
        names: imgs.map((e) => e.getAttribute("aria-label")),
        sarah: shown(byName("Sarah Chen")),
        mike: shown(byName("Mike Johnson")),
        // Over the missing photo's layer, the initials still have colour behind them.
        mikeBg: byName("Mike Johnson") && getComputedStyle(byName("Mike Johnson").firstElementChild).backgroundColor,
        photo: !!byName("John Lennon")?.querySelector('[style*="lenon.webp"]'),
        group: g ? [...g.querySelectorAll("[role=img]")].map((e) => e.getAttribute("aria-label")) : null,
      };
    })()`);
    for (const n of ["John Lennon", "Sarah Chen", "Mike Johnson", "Emily Davis (online)", "Alex Kim (busy)"])
      assert(got.names.includes(n), `no avatar named ${JSON.stringify(n)} (have ${JSON.stringify(got.names)})`);
    assert(got.sarah === "SC", `Sarah Chen's initials read ${JSON.stringify(got.sarah)}`);
    assert(got.mike === "MJ" && got.mikeBg !== "rgba(0, 0, 0, 0)", `with its photo missing, Mike's avatar shows ${JSON.stringify(got.mike)} on ${got.mikeBg}`);
    assert(got.photo, "John Lennon's avatar has no photo");
    assert(got.group && got.group.length === 5 && got.group[4] === "2 more", `the group reads ${JSON.stringify(got.group)}`);
  },

  async "badge: counts are named in full and cut to 99+; tones read in both themes"(p) {
    const lum = (rgb) => {
      const [r, g, b] = rgb.match(/[\d.]+/g).slice(0, 3).map(Number).map((v) => { v /= 255; return v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4; });
      return 0.2126 * r + 0.7152 * g + 0.0722 * b;
    };
    const contrast = (a, b) => { const [x, y] = [lum(a), lum(b)].sort((m, n) => n - m); return (x + 0.05) / (y + 0.05); };
    await p.goto("/ui/components/badge");
    const counts = await p.evaluate(`[...document.querySelectorAll("[role=status][aria-label]")].map((e) => [e.getAttribute("aria-label"), e.textContent.trim()])`);
    assert(JSON.stringify(counts) === '[["3 unread messages","3"],["150 alerts","99+"]]', `the counts read ${JSON.stringify(counts)}`);
    // The theme's page colours, as the chart's contrast test has them.
    for (const [scheme, page] of [["light", "rgb(255, 255, 255)"], ["dark", "rgb(17, 17, 17)"]]) {
      await p.colorScheme(scheme);
      await p.goto("/ui/components/badge");
      const texts = await p.evaluate(`["Draft", "New", "Active", "Pending", "Failed", "v3.8.0"].map((t) => { const e = [...document.querySelectorAll("*")].find((x) => x.textContent === t && !x.children.length); return [t, e ? getComputedStyle(e).color : null]; })`);
      for (const [t, c] of texts) {
        assert(c, `no badge reads ${t}`);
        assert(contrast(c, page) >= 3, `in ${scheme} mode the ${t} badge's text (${c}) barely shows on ${page} (contrast ${contrast(c, page).toFixed(2)})`);
      }
    }
    await p.colorScheme(null);
  },

  async "switch: toggles its state and calls back"(p) {
    await p.goto("/ui/components/switch");
    assert(await p.ariaOf("Airplane mode", "role") === "switch", "the switch has role=switch");
    assert(await p.ariaOf("Airplane mode", "aria-checked") === "false", "it starts off");
    await p.clickLabel("Airplane mode");
    await p.waitText("Airplane mode: on");
    await p.waitAria("Airplane mode", "aria-checked", "true");
    await p.clickLabel("Airplane mode");
    await p.waitText("Airplane mode: off");
    await p.waitAria("Airplane mode", "aria-checked", "false");
  },

  async "checkbox: toggles its state and calls back"(p) {
    await p.goto("/ui/components/checkbox");
    assert(await p.ariaOf("Email me updates", "role") === "checkbox", "the checkbox has role=checkbox");
    assert(await p.ariaOf("Email me updates", "aria-checked") === "false", "it starts unchecked");
    await p.clickLabel("Email me updates");
    await p.waitText("Emails: on");
    await p.waitAria("Email me updates", "aria-checked", "true");
    // The custom one's callback gets the new state.
    await p.clickLabel("Sound");
    await p.waitAria("Sound", "aria-checked", "true");
  },

  async "radio: one choice at a time, starting on the default"(p) {
    await p.goto("/ui/components/radio");
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

  async "radio: arrow keys move the choice and the focus; one tab stop"(p) {
    await p.goto("/ui/components/radio");
    const radio = (name) => `[...document.querySelectorAll("[role=radio]")].find((e) => e.textContent.trim() === ${JSON.stringify(name)})`;
    const stops = await p.evaluate(`[...document.querySelectorAll("[role=radio]")].filter((e) => e.tabIndex >= 0).map((e) => e.textContent.trim())`);
    assert(JSON.stringify(stops) === '["Default"]', `the group's tab stops are ${JSON.stringify(stops)}, not just the chosen one`);
    await p.evaluate(`${radio("Default")}.focus()`);
    await p.press("ArrowDown");
    await p.waitText("Density: comfortable");
    await p.waitFor(`document.activeElement === ${radio("Comfortable")}`, "focus to follow the choice");
    await p.press("ArrowRight");
    await p.waitText("Density: compact");
    await p.press("ArrowDown");
    await p.waitText("Density: default");
    await p.press("ArrowUp");
    await p.waitText("Density: compact");
    await p.waitFor(`document.activeElement === ${radio("Compact")}`, "focus to wrap round with the choice");
  },

  async "dialog: opens, filters as you type, closes on Escape"(p) {
    await p.goto("/ui/components/dialog");
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

  async "dialog: is labelled, and Escape closes it once"(p) {
    await p.goto("/ui/components/dialog");
    await p.waitText("Closed 0 times");
    await p.clickLabel("open basic dialog");
    await p.waitFor(`!!document.querySelector('[role=dialog][aria-label="Pick a status"]')`, "the dialog, labelled by its example");
    await p.press("Escape");
    await p.waitText("Closed 1 time");
    await sleep(200);
    assert(!(await p.evaluate(`document.body.textContent.includes("Closed 2 times")`)), "Escape called on_close twice");
    assert(!(await p.evaluate(`!!document.querySelector('[aria-label="Command Palette"]')`)), "a dialog still calls itself Command Palette");
  },

  async "dialog: a click outside closes it"(p) {
    await p.goto("/ui/components/dialog");
    const dialogOpen = `(() => { ${finders} return [...document.querySelectorAll("[role=dialog]")].some((e) => __ui.visible(e)); })()`;
    await p.clickLabel("open basic dialog");
    await p.waitFor(dialogOpen, "the dialog to open");
    await p.clickAway();
    await p.waitFor(`!${dialogOpen}`, "a click outside to close the dialog");
  },

  async "dialog: arrow keys move the highlight and Enter picks"(p) {
    await p.goto("/ui/components/dialog");
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
    await p.goto("/ui/components/drawer");
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

  async "drawer: takes the focus when it opens and gives it back"(p) {
    await p.goto("/ui/components/drawer");
    const opener = `[...document.querySelectorAll("button")].find((b) => b.textContent.trim() === "Open Bottom")`;
    const panel = `[...document.querySelectorAll("[role=dialog]")].find((e) => e.getBoundingClientRect().width > 0)`;
    await p.evaluate(`${opener}.focus()`);
    await p.press("Enter");
    await p.waitText("Simple Drawer Content");
    await p.waitFor(`!!${panel} && ${panel}.contains(document.activeElement)`, "the focus to move into the drawer");
    await p.press("Escape");
    await p.waitText("Simple Drawer Content", { gone: true });
    await p.waitFor(`document.activeElement === ${opener}`, "the focus to go back to the button that opened it");
  },

  async "drawer: the backdrop and the close button close it"(p) {
    await p.goto("/ui/components/drawer");
    await p.clickText("Open Right (Details)");
    await p.waitText("Transaction Details");
    await p.clickLabel("Close details");
    await p.waitText("Transaction Details", { gone: true });
    await p.clickText("Open Right (Details)");
    await p.waitText("Transaction Details");
    await p.clickAway();
    await p.waitText("Transaction Details", { gone: true });
  },

  async "toast: the corner buttons move the stack there"(p) {
    await p.goto("/ui/components/toasts");
    const corners = [
      // Each toast's description; its title is also a label on the page.
      ["Show Bottom Left", "Toasts stack upward from bottom left.", false, false],
      ["Show Top Left", "Toasts stack from the top left.", false, true],
      ["Show Bottom Right", "Toasts rise from the bottom right.", true, false],
      ["Show Top Right", "Toasts appear in the top right corner.", true, true],
    ];
    for (const [button, title, right, top] of corners) {
      await p.clickText(button);
      await p.waitText(title);
      await sleep(400);
      const box = await p.boxOf(title);
      const x = (box.left + box.right) / 2, y = (box.top + box.bottom) / 2;
      assert((x > box.vw / 2) === right && (y < box.vh / 2) === top, `"${button}" shows its toast at ${Math.round(x)},${Math.round(y)}`);
    }
  },

  async "toast: its colours follow the theme"(p) {
    // The toast's own box, and the colours of its background and title.
    const look = `(() => { ${finders} const t = __ui.byText("Document Saved")[0]; const box = t.closest('[id^="opaque-toast-"]'); return { bg: getComputedStyle(box).backgroundColor, text: getComputedStyle(t).color }; })()`;
    const want = {
      light: { bg: "rgb(255, 255, 255)", text: "rgb(0, 0, 0)" },
      dark: { bg: "rgb(17, 17, 17)", text: "rgb(234, 234, 234)" },
    };
    try {
      for (const scheme of ["light", "dark"]) {
        await p.colorScheme(scheme);
        await p.goto("/ui/components/toasts");
        await p.clickText("Save Successful");
        await p.waitText("Document Saved");
        const got = await p.evaluate(look);
        assert(got.text === want[scheme].text, `in ${scheme}, a toast's text is ${got.text}`);
        assert(got.bg === want[scheme].bg, `in ${scheme}, a toast's background is ${got.bg}`);
      }
    } finally {
      await p.colorScheme(null);
    }
  },

  async "toast: closing slides it away whole, without fading"(p) {
    await p.goto("/ui/components/toasts");
    await p.clickText("Save Successful");
    await p.waitText("Document Saved");
    await sleep(500);
    const toast = `__ui.byText("Document Saved")[0]?.closest('[id^="opaque-toast-"]')`;
    const before = await p.evaluate(`(() => { ${finders} return ${toast}.getBoundingClientRect().left; })()`);
    try {
      // Ten times slower, so the check lands inside the 200ms exit (vapor
      // removes an exiting element after a second whatever the speed).
      await p.animationSpeed(0.1);
      await p.clickLabel("Dismiss notification");
      await sleep(500);
      const mid = await p.evaluate(`(() => {
        const box = document.querySelector('[id^="opaque-toast-"][data-removing="true"]');
        if (!box) return null;
        let o = 1;
        for (let e = box.querySelector("*"); e; e = e.parentElement) o *= +getComputedStyle(e).opacity;
        return { left: box.getBoundingClientRect().left, opacity: o };
      })()`);
      assert(mid, "the toast was gone before its exit was half way");
      // A fading toast loses its backdrop blur at once and leaves its text
      // fading on its own.
      assert(mid.opacity === 1, `the closing toast fades (opacity ${mid.opacity})`);
      assert(mid.left > before + 20, `the closing toast does not slide away (left ${before} then ${mid.left})`);
    } finally {
      await p.animationSpeed(1);
    }
    await p.waitText("Document Saved", { gone: true });
  },

  async "toast: only the front toast shows its content until the stack is hovered"(p) {
    await p.goto("/ui/components/toasts");
    await p.clickText("Connection Failed");
    await p.waitText("Connection Error");
    await p.clickText("Save Successful");
    await p.waitText("Document Saved");
    await sleep(400);
    // Two stacks share an id, and hovering then reaches the wrong one.
    const stacks = await p.evaluate(`document.querySelectorAll("#opaque-toast-stack").length`);
    assert(stacks === 1, `the page has ${stacks} toast stacks`);
    // Found by its text alone: the finders skip a toast hidden behind another.
    const opacity = (text) => `(() => { const t = [...document.querySelectorAll("body *")].find((e) => e.childElementCount === 0 && e.textContent === ${JSON.stringify(text)}); if (!t) return "missing"; let o = 1; for (let e = t; e; e = e.parentElement) o *= +getComputedStyle(e).opacity; return o; })()`;
    assert(await p.evaluate(opacity("Document Saved")) === 1, "the front toast's text is hidden");
    assert(await p.evaluate(opacity("Connection Error")) === 0, "the text of the toast behind shows past the front one");
    await p.hoverText("Document Saved");
    await p.waitFor(`${opacity("Connection Error")} === 1`, "the toast behind to show its text on hover");
    await p.mouseTo(700, 880);
    await p.waitFor(`${opacity("Connection Error")} === 0`, "the toast behind to hide its text again");
  },

  async "toast: shows in its corner, announced, and its close button dismisses it"(p) {
    await p.goto("/ui/components/toasts");
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
    await p.goto("/ui/components/toasts");
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
    await p.goto("/ui/components/toasts");
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
    await p.goto("/ui/components/tooltip");
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

  async "tooltip: a custom trigger can be reached and opened from the keyboard"(p) {
    await p.goto("/ui/components/tooltip");
    const tip = "This is a custom trigger tooltip";
    const focused = await p.evaluate(`(() => {
      let e = [...document.querySelectorAll("*")].find((x) => x.textContent === "Custom Tooltip" && !x.children.length);
      while (e && e.tabIndex < 0) e = e.parentElement;
      if (!e || e === document.body) return false;
      e.focus();
      return document.activeElement === e;
    })()`);
    assert(focused, "nothing around the custom trigger takes the focus");
    await p.waitText(tip);
  },

  async "tooltip: custom triggers and custom content"(p) {
    await p.goto("/ui/components/tooltip");
    await p.hoverText("Custom Tooltip");
    await p.waitText("This is a custom trigger tooltip");
    await p.mouseTo(700, 880);
    await p.waitText("This is a custom trigger tooltip", { gone: true });
    await p.hoverText("Custom Tooltip with Custom Content");
    await p.waitFor(`(() => { ${finders} return __ui.byText("Due date").some((e) => e.closest("[role=tooltip]")); })()`, "the custom content in the tooltip");
  },

  async "select: pick an option with the pointer"(p) {
    await p.goto("/ui/components/select");
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
    await p.goto("/ui/components/select");
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
    await p.goto("/ui/components/select");
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
    await p.goto("/ui/components/commandpalette");
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
    await p.goto("/ui/components/commandpalette");
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
    await p.goto("/ui/components/combobox");
    const trigger = `(() => { ${finders} return [...document.querySelectorAll("[aria-haspopup=listbox]")].filter((e) => __ui.visible(e))[0]; })()`;
    const selected = `(() => { ${finders} return [...document.querySelectorAll("[role=option][aria-selected=true]")].filter((e) => __ui.visible(e)).map((e) => e.textContent.trim()); })()`;
    assert(await p.evaluate(`${trigger}?.getAttribute("aria-expanded")`) === "false", "starts collapsed");
    await p.clickSelector("[aria-haspopup=listbox]", 0);
    await p.waitText("Pending");
    assert(await p.evaluate(`!!document.querySelector('[role=listbox][aria-multiselectable="true"]')`), "the list allows several choices");
    // The example starts with Pending ticked, by default().
    assert(JSON.stringify(await p.evaluate(selected)) === '["Pending"]', `starts with ${JSON.stringify(await p.evaluate(selected))} ticked, not Pending`);
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
    await p.goto("/ui/components/datepicker");
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

  async "datepicker: the chosen day is filled, in its own text colour"(p) {
    await p.goto("/ui/components/datepicker");
    await p.clickLabel("August 15, 1991");
    await p.waitFor(`document.querySelector('[aria-label="August 15, 1991"]').getAttribute("aria-pressed") === "true"`, "Aug 15 chosen");
    await sleep(300);
    const got = await p.evaluate(`(() => {
      const day = (l) => document.querySelector('[aria-label="' + l + '"]');
      const look = (e) => ({ bg: getComputedStyle(e).backgroundColor, text: getComputedStyle(e.querySelector("*") || e).color });
      return { chosen: look(day("August 15, 1991")), other: look(day("August 16, 1991")) };
    })()`);
    assert(got.chosen.bg !== got.other.bg, `the chosen day has the same background as the rest (${got.chosen.bg})`);
    assert(got.chosen.text === "rgb(255, 255, 255)", `the chosen day's number is ${got.chosen.text}, not selected_text_color`);
  },

  async "tabs: tab lists are named for what they hold"(p) {
    await p.goto("/ui/components/tabs");
    assert(await p.evaluate(`!!document.querySelector('[role=tablist][aria-label="Account settings"]')`), "the basic tabs aren't labelled Account settings");
    await p.goto("/ui/components/chart");
    assert(await p.evaluate(`!!document.querySelector('[role=tablist][aria-label="Chart types"]')`), "the chart's tabs aren't labelled Chart types");
    assert(!(await p.evaluate(`!!document.querySelector('[aria-label="Main navigation tabs"]')`)), "a tab list is still called Main navigation tabs");
  },

  async "slider: keys, a press on the track and a drag set the value"(p) {
    await p.goto("/ui/components/slider");
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
    await p.goto("/ui/components/carousel");
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
    await p.goto("/ui/components/sidebar");
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

  async "chart: zooming in keeps the lines inside the axes"(p) {
    await p.goto("/ui/components/chart");
    const svg = `document.querySelector("svg:has(.series-line)")`;
    await p.waitFor(`!!${svg}`, "a line chart");
    await p.evaluate(`${svg}.scrollIntoView({ block: "center" })`);
    await sleep(200);
    // The plot area is the box the two axes draw.
    const plot = () => p.evaluate(`(() => {
      const s = ${svg}, x = s.querySelector("#chart-axis-x").getBoundingClientRect(), y = s.querySelector("#chart-axis-y").getBoundingClientRect();
      return { left: y.left, right: x.right, top: y.top, bottom: x.bottom };
    })()`);
    const box = await plot();
    const w = box.right - box.left, h = box.bottom - box.top;
    await p.drag({ x: box.left + w * 0.35, y: box.top + h * 0.3 }, { x: box.left + w * 0.6, y: box.top + h * 0.7 });
    await p.waitFor(`${svg}.querySelector(".series-line").getBoundingClientRect().width > ${w * 1.5}`, "the chart to zoom in");
    const after = await plot();
    // The line now runs past the axes; it has to be clipped to them.
    const loose = await p.evaluate(`(() => {
      const s = ${svg}, a = ${JSON.stringify(after)}, out = [];
      for (const e of s.querySelectorAll(".series-line, .series-area, .series-dot, .series-bar")) {
        const g = e.closest("[clip-path]");
        const id = g?.getAttribute("clip-path").slice("url(#".length, -1);
        const r = id && document.getElementById(id)?.querySelector("rect");
        if (!r) { out.push(e.getAttribute("class") + " is not clipped"); continue; }
        const m = r.getScreenCTM(), b = r.getBBox();
        const l = m.e + b.x * m.a, t = m.f + b.y * m.d, rr = l + b.width * m.a, bb = t + b.height * m.d;
        if (Math.abs(l - a.left) > 1.5 || Math.abs(rr - a.right) > 1.5 || Math.abs(t - a.top) > 1.5 || Math.abs(bb - a.bottom) > 1.5)
          out.push(e.getAttribute("class") + " is clipped to " + [l, t, rr, bb].map(Math.round) + ", not the axes " + [a.left, a.top, a.right, a.bottom].map(Math.round));
      }
      return [...new Set(out)];
    })()`);
    assert(loose.length === 0, loose.join("\n        "));
  },

  async "chart: a zoomed chart zooms back out, by button or double-click"(p) {
    await p.goto("/ui/components/chart");
    const svg = `document.querySelector("svg:has(.series-line)")`;
    await p.waitFor(`!!${svg}`, "a line chart");
    await p.evaluate(`${svg}.scrollIntoView({ block: "center" })`);
    await sleep(200);
    // Measured again before each use: clicking the button scrolls the page.
    const plot = async () => {
      const b = await p.evaluate(`(() => {
        const s = ${svg}, x = s.querySelector("#chart-axis-x").getBoundingClientRect(), y = s.querySelector("#chart-axis-y").getBoundingClientRect();
        return { left: y.left, right: x.right, top: y.top, bottom: x.bottom };
      })()`);
      return { ...b, w: b.right - b.left, h: b.bottom - b.top };
    };
    const lineWidth = () => p.evaluate(`Math.round(${svg}.querySelector(".series-line").getBoundingClientRect().width)`);
    const full = await lineWidth();
    const reset = `document.querySelector('button[aria-label="Reset zoom"]')`;
    assert(!(await p.evaluate(`!!${reset}`)), "a chart that isn't zoomed offers to reset its zoom");
    const zoom = async () => {
      const b = await plot();
      await p.drag({ x: b.left + b.w * 0.35, y: b.top + b.h * 0.3 }, { x: b.left + b.w * 0.6, y: b.top + b.h * 0.7 });
      await p.waitFor(`${svg}.querySelector(".series-line").getBoundingClientRect().width > ${full * 1.5}`, "the chart to zoom in");
    };
    await zoom();
    await p.waitFor(`!!${reset}`, "a Reset zoom button");
    await p.clickSelector('button[aria-label="Reset zoom"]');
    await p.waitFor(`Math.abs(${svg}.querySelector(".series-line").getBoundingClientRect().width - ${full}) < 2`, "the button to zoom the chart back out");
    await p.waitFor(`!${reset}`, "the Reset zoom button to go");
    await zoom();
    const b = await plot();
    await p.dblclick({ x: b.left + b.w / 2, y: b.top + b.h / 2 });
    await p.waitFor(`Math.abs(${svg}.querySelector(".series-line").getBoundingClientRect().width - ${full}) < 2`, "a double-click to zoom the chart back out");
  },

  async "chart: pointing at Reset zoom hides the tooltip and nothing covers the button"(p) {
    await p.goto("/ui/components/chart");
    const svg = `document.querySelector("svg:has(.series-line)")`;
    await p.waitFor(`!!${svg}`, "a line chart");
    await p.evaluate(`${svg}.scrollIntoView({ block: "center" })`);
    await sleep(200);
    const plot = await p.evaluate(`(() => {
      const s = ${svg}, x = s.querySelector("#chart-axis-x").getBoundingClientRect(), y = s.querySelector("#chart-axis-y").getBoundingClientRect();
      return { left: y.left, right: x.right, top: y.top, bottom: x.bottom };
    })()`);
    const w = plot.right - plot.left, h = plot.bottom - plot.top;
    await p.drag({ x: plot.left + w * 0.35, y: plot.top + h * 0.3 }, { x: plot.left + w * 0.6, y: plot.top + h * 0.7 });
    const reset = `document.querySelector('button[aria-label="Reset zoom"]')`;
    await p.waitFor(`!!${reset}`, "a Reset zoom button");
    const tipShown = `(() => {
      const t = [...${svg}.parentElement.parentElement.querySelectorAll("div")].filter((e) => /^Month \\d/.test(e.textContent) && e.textContent.includes("Sales")).pop();
      return !!t && getComputedStyle(t).visibility === "visible";
    })()`;
    assert(await p.evaluate(tipShown), "no tooltip in the plot after zooming");
    // Slide over from the plot to the button, as a hand would.
    const btn = await p.evaluate(`(() => { const r = ${reset}.getBoundingClientRect(); return { x: r.left + r.width / 2, y: r.top + r.height / 2 }; })()`);
    const from = { x: plot.left + w * 0.6, y: plot.top + h * 0.7 };
    for (let i = 1; i <= 6; i++) {
      await p.mouseTo(from.x + ((btn.x - from.x) * i) / 6, from.y + ((btn.y - from.y) * i) / 6);
    }
    await sleep(100);
    await p.waitFor(`!${tipShown}`, "the tooltip to go while the pointer is on Reset zoom");
    assert(await p.evaluate(`${reset}.contains(document.elementFromPoint(${btn.x}, ${btn.y}))`), "something covers the Reset zoom button");
    const zoomed = await p.evaluate(`Math.round(${svg}.querySelector(".series-line").getBoundingClientRect().width)`);
    await p.clickSelector('button[aria-label="Reset zoom"]');
    await p.waitFor(`!${reset}`, "the button to zoom the chart back out");
    assert(await p.evaluate(`${svg}.querySelector(".series-line").getBoundingClientRect().width < ${zoomed}`), "the chart is still zoomed in");
  },

  async "chart: the tooltip shows only over the plot, and names the point it is at"(p) {
    await p.goto("/ui/components/chart");
    const svg = `document.querySelector("svg:has(.series-line)")`;
    await p.waitFor(`!!${svg}`, "a line chart");
    await p.evaluate(`${svg}.scrollIntoView({ block: "center" })`);
    await sleep(200);
    const plot = await p.evaluate(`(() => {
      const s = ${svg}, x = s.querySelector("#chart-axis-x").getBoundingClientRect(), y = s.querySelector("#chart-axis-y").getBoundingClientRect();
      return { left: y.left, right: x.right, top: y.top, bottom: x.bottom };
    })()`);
    const tip = `(() => {
      const t = [...${svg}.parentElement.querySelectorAll("div")].filter((e) => /^Month \\d/.test(e.textContent) && getComputedStyle(e).pointerEvents === "none").pop();
      return t && getComputedStyle(t).visibility === "visible" ? t.textContent : null;
    })()`;
    await p.mouseTo((plot.left + plot.right) / 2, (plot.top + plot.bottom) / 2);
    await sleep(150);
    const text = await p.evaluate(tip);
    assert(text !== null, "no tooltip over the plot");
    assert(/^Month \d+Sales\d+$/.test(text), `the tooltip reads ${JSON.stringify(text)}: not the point's x, its value, and no Total for one series`);
    // Over the y axis's labels, outside the plot.
    await p.mouseTo(plot.left - 20, (plot.top + plot.bottom) / 2);
    await sleep(150);
    await p.waitFor(`${tip} === null`, "the tooltip to go over the axis labels");
  },

  async "chart: a drag zooms into an x range, and the y axis fits what is in it"(p) {
    await p.goto("/ui/components/chart");
    const svg = `document.querySelector("svg:has(.series-line)")`;
    await p.waitFor(`!!${svg}`, "a line chart");
    await p.evaluate(`${svg}.scrollIntoView({ block: "center" })`);
    await sleep(200);
    const ticks = (axis) => p.evaluate(`[...${svg}.querySelectorAll('[id^="chart-axis-${axis}-"][id$="-text-label"]')].map((e) => Number(e.textContent))`);
    const plot = await p.evaluate(`(() => {
      const s = ${svg}, x = s.querySelector("#chart-axis-x").getBoundingClientRect(), y = s.querySelector("#chart-axis-y").getBoundingClientRect();
      return { left: y.left, right: x.right, top: y.top, bottom: x.bottom };
    })()`);
    const w = plot.right - plot.left, h = plot.bottom - plot.top;
    const yBefore = await ticks("y");
    // A flat drag: an x zoom needs no height.
    await p.drag({ x: plot.left + w * 0.3, y: plot.top + h * 0.5 }, { x: plot.left + w * 0.5, y: plot.top + h * 0.5 });
    await p.waitFor(`!!document.querySelector('button[aria-label="Reset zoom"]')`, "a flat drag to zoom");
    await sleep(200);
    const xAfter = await ticks("x"), yAfter = await ticks("y");
    assert(Math.max(...xAfter) - Math.min(...xAfter) < 10, `the x axis runs ${xAfter.join(", ")}: not the dragged range`);
    assert(Math.max(...yAfter) < Math.max(...yBefore), `the y axis still runs to ${Math.max(...yAfter)}: it doesn't fit the zoomed points`);
  },

  async "chart: the legend shows and hides a series, and pointing at one fades the rest"(p) {
    await p.goto("/ui/components/chart");
    await p.clickText("Bar Charts");
    const svg = `document.querySelector("svg:has(.stacked-bar)")`;
    await p.waitFor(`!!${svg}`, "the bar chart");
    const item = (name) => `[...document.querySelectorAll("button[aria-pressed]")].find((b) => b.textContent === ${JSON.stringify(name)})`;
    const count = () => p.evaluate(`${svg}.querySelectorAll(".stacked-bar.item-2").length`);
    assert((await count()) > 0, "no 4XX segments to begin with");
    await p.clickText("4XX");
    await p.waitFor(`${item("4XX")}.getAttribute("aria-pressed") === "false"`, "4XX to read as off");
    assert((await count()) === 0, "the 4XX segments are still drawn");
    await p.clickText("4XX");
    await p.waitFor(`${svg}.querySelectorAll(".stacked-bar.item-2").length > 0`, "4XX to come back");
    await p.hoverText("5XX");
    await sleep(250);
    const faded = await p.evaluate(`(() => {
      const s = ${svg};
      return { other: getComputedStyle(s.querySelector(".stacked-bar.item-0")).opacity, own: getComputedStyle(s.querySelector(".stacked-bar.item-3")).opacity };
    })()`);
    assert(Number(faded.other) < 0.5 && faded.own === "1", `pointing at 5XX leaves the others at ${faded.other} and 5XX at ${faded.own}`);
  },

  async "chart: pointing at a pie's slice shows its value and share"(p) {
    await p.goto("/ui/components/chart");
    await p.clickText("Pie Charts");
    const svg = `document.querySelector("svg:has(.pie-slice)")`;
    await p.waitFor(`!!${svg}`, "the pie chart");
    await sleep(600);
    // The middle of the Search slice (40 of 100), measured along its arc.
    const at = await p.evaluate(`(() => {
      const s = [...${svg}.querySelectorAll(".pie-slice")][1], b = s.getBoundingClientRect();
      const g = ${svg}.querySelector(".pie-slice").closest("g[transform]").getBoundingClientRect();
      const cx = (g.left + g.right) / 2, cy = (g.top + g.bottom) / 2, r = (g.right - g.left) / 2 * 0.6;
      const mid = -Math.PI / 2 + 2 * Math.PI * (0.35 + 0.2);
      return { x: cx + r * Math.cos(mid), y: cy + r * Math.sin(mid) };
    })()`);
    await p.mouseTo(at.x, at.y);
    await sleep(200);
    const text = await p.evaluate(`(() => {
      const t = [...document.querySelectorAll("div")].filter((e) => /^Traffic/.test(e.textContent) && getComputedStyle(e).pointerEvents === "none").pop();
      return t && getComputedStyle(t).visibility === "visible" ? t.textContent : null;
    })()`);
    assert(text === "TrafficSearch40 (40%)", `over the Search slice the tooltip reads ${JSON.stringify(text)}`);
  },

  async "chart: a chart fades in when it first shows, and not again"(p) {
    const svg = `document.querySelector("svg:has(.series-line)")`;
    const anim = () => p.evaluate(`getComputedStyle(${svg}.querySelector("g.chart")).animationName`);
    // Not for anyone who asks for less motion.
    await p.reducedMotion("reduce");
    await p.goto("/ui/components/chart");
    await p.waitFor(`!!${svg}`, "a line chart");
    assert((await anim()) === "none", `with less motion asked for, the chart still animates (${await anim()})`);
    await p.reducedMotion("no-preference");
    await p.goto("/ui/components/chart");
    await p.waitFor(`!!${svg}`, "a line chart");
    assert((await anim()) === "chart-fade", `the chart's first animation is ${await anim()}`);
    // A fade, so nothing in it moves.
    const moving = await p.evaluate(`[...${svg}.querySelectorAll("*")].filter((e) => getComputedStyle(e).animationName !== "none" && !e.matches("g.chart")).length`);
    assert(moving === 0, `${moving} of the chart's parts animate on their own`);
    await p.evaluate(`${svg}.scrollIntoView({ block: "center" })`);
    await sleep(200);
    const plot = await p.evaluate(`(() => {
      const s = ${svg}, x = s.querySelector("#chart-axis-x").getBoundingClientRect(), y = s.querySelector("#chart-axis-y").getBoundingClientRect();
      return { left: y.left, right: x.right, top: y.top, bottom: x.bottom };
    })()`);
    const w = plot.right - plot.left, h = plot.bottom - plot.top;
    await p.drag({ x: plot.left + w * 0.3, y: plot.top + h * 0.5 }, { x: plot.left + w * 0.6, y: plot.top + h * 0.5 });
    await p.waitFor(`!!document.querySelector('button[aria-label="Reset zoom"]')`, "the chart to zoom");
    assert((await anim()) === "none", `after a zoom the chart fades in again (${await anim()})`);
    await p.reducedMotion(null);
  },

  async "chart: the tooltip fades in where it belongs, and slides only between points"(p) {
    await p.goto("/ui/components/chart");
    const svg = `document.querySelector("svg:has(.series-line)")`;
    await p.waitFor(`!!${svg}`, "a line chart");
    await p.evaluate(`${svg}.scrollIntoView({ block: "center" })`);
    await sleep(500);
    const plot = await p.evaluate(`(() => {
      const s = ${svg}, x = s.querySelector("#chart-axis-x").getBoundingClientRect(), y = s.querySelector("#chart-axis-y").getBoundingClientRect();
      return { left: y.left, right: x.right, top: y.top, bottom: x.bottom };
    })()`);
    const w = plot.right - plot.left, h = plot.bottom - plot.top;
    // Where the tooltip box is, each frame for a while, at a twentieth of the speed.
    const track = `new Promise((done) => {
      const t = [...${svg}.parentElement.querySelectorAll("div")].filter((e) => getComputedStyle(e).pointerEvents === "none" && e.style.transform).find((e) => /Sales/.test(e.textContent));
      const frames = [], start = performance.now();
      const tick = () => {
        const r = t.getBoundingClientRect();
        frames.push({ x: Math.round(r.left), y: Math.round(r.top), o: Number(getComputedStyle(t).opacity) });
        if (performance.now() - start < 600) requestAnimationFrame(tick); else done(frames);
      };
      tick();
    })`;
    await p.animationSpeed(0.05);
    // Shown once and hidden, so it has somewhere else to have been.
    await p.mouseTo(plot.left + w * 0.2, plot.top + h * 0.5);
    await sleep(100);
    await p.mouseTo(plot.left - 30, plot.top + h * 0.5);
    await sleep(100);
    await p.animationSpeed(0.05);
    await p.mouseTo(plot.left + w * 0.7, plot.top + h * 0.5);
    const frames = await p.evaluate(track);
    await p.animationSpeed(1);
    const seen = frames.filter((f) => f.o > 0.02);
    assert(seen.length > 0, "the tooltip never showed");
    const xs = new Set(seen.map((f) => f.x)), ys = new Set(seen.map((f) => f.y));
    assert(xs.size === 1 && ys.size === 1, `the tooltip moved while it faded in: x ${[...xs].join(", ")}, y ${[...ys].join(", ")}`);
    assert(seen[0].o < 0.9, `the tooltip came in at opacity ${seen[0].o}, not fading`);
  },

  async "chart: the area chart marks its target, and shows dollars"(p) {
    await p.goto("/ui/components/chart");
    await p.clickText("Area Charts");
    const svg = `document.querySelector("svg:has(.series-area)")`;
    await p.waitFor(`!!${svg}`, "the area chart");
    const got = await p.evaluate(`(() => {
      const s = ${svg};
      return {
        line: !!s.querySelector(".ref-line"),
        label: s.querySelector(".ref-label")?.textContent,
        ticks: [...s.querySelectorAll('[id^="chart-axis-y-"][id$="-text-label"]')].map((e) => e.textContent),
      };
    })()`);
    assert(got.line && got.label === "Target", `the target line: ${JSON.stringify(got)}`);
    assert(got.ticks.length > 0 && got.ticks.every((t) => t.startsWith("$")), `the y ticks read ${got.ticks.join(", ")}`);
  },

  async "chart: a chart follows its parent's width as the page resizes"(p) {
    await p.goto("/ui/components/chart");
    const svg = `document.querySelector("svg:has(.series-line)")`;
    await p.waitFor(`!!${svg}`, "a line chart");
    // The drawing's own width, against the box it fills.
    const fit = `(() => { const s = ${svg}; return Math.abs(s.viewBox.baseVal.width - s.parentElement.getBoundingClientRect().width) <= 1; })()`;
    assert(await p.evaluate(fit), "the chart is not as wide as its box");
    const before = await p.evaluate(`${svg}.viewBox.baseVal.width`);
    await p.viewport(1100, 900);
    await p.waitFor(`${svg}.viewBox.baseVal.width < ${before} - 50 && ${fit}`, "the chart to narrow with the page");
    await p.viewport(1440, 900);
    await p.waitFor(`${svg}.viewBox.baseVal.width > ${before} - 2 && ${fit}`, "the chart to widen again");
  },

  async "chart: after zooming, the tooltip shows the values under the pointer"(p) {
    await p.goto("/ui/components/chart");
    const svg = `document.querySelector("svg:has(.series-line)")`;
    await p.waitFor(`!!${svg}`, "a line chart");
    await p.evaluate(`${svg}.scrollIntoView({ block: "center" })`);
    await sleep(200);
    const plot = await p.evaluate(`(() => {
      const s = ${svg}, x = s.querySelector("#chart-axis-x").getBoundingClientRect(), y = s.querySelector("#chart-axis-y").getBoundingClientRect();
      return { left: y.left, right: x.right, top: y.top, bottom: x.bottom };
    })()`);
    const w = plot.right - plot.left, h = plot.bottom - plot.top;
    await p.drag({ x: plot.left + w * 0.35, y: plot.top + h * 0.3 }, { x: plot.left + w * 0.6, y: plot.top + h * 0.7 });
    await sleep(300);
    // The tooltip: the box that names the point, then each series' value.
    const tip = await p.evaluate(`(() => {
      const c = ${svg}.parentElement;
      const t = [...c.querySelectorAll("div")].filter((e) => /^Month \\d/.test(e.textContent) && e.textContent.includes("Sales")).pop();
      return t ? t.textContent : null;
    })()`);
    assert(tip !== null, "no tooltip after zooming");
    assert(/^Month \d+Sales\d+$/.test(tip), `after zooming the tooltip reads ${JSON.stringify(tip)}`);
  },

  async "chart: its labels and grid follow the theme"(p) {
    for (const [scheme, text, page] of [["light", "rgb(0, 0, 0)", "rgb(255, 255, 255)"], ["dark", "rgb(234, 234, 234)", "rgb(17, 17, 17)"]]) {
      await p.colorScheme(scheme);
      await p.goto("/ui/components/chart");
      const svg = `document.querySelector("svg:has(.series-line)")`;
      await p.waitFor(`!!${svg}`, "a line chart");
      const got = await p.evaluate(`(() => {
        const s = ${svg}, fill = (q) => getComputedStyle(s.querySelector(q)).fill;
        const legend = [...document.querySelectorAll("button[aria-pressed]")].find((b) => b.textContent === "Sales");
        return { axis: fill(".axis-label"), tick: fill(".tick-label"), legend: getComputedStyle(legend.lastElementChild).color };
      })()`);
      for (const [what, color] of Object.entries(got))
        assert(color === text, `in ${scheme} mode the chart's ${what} text is ${color}, not ${text}`);
      // A dot's ring is cut from the background, not drawn in white.
      const ring = await p.evaluate(`getComputedStyle(${svg}.querySelector(".series-dot")).stroke`);
      assert(ring === page, `in ${scheme} mode a dot's ring is ${ring}, on a ${page} page`);
    }
    await p.colorScheme(null);
  },

  async "chart: a pie's legend names each slice, in its colour"(p) {
    await p.goto("/ui/components/chart");
    await p.clickText("Pie Charts");
    const svg = `document.querySelector("svg:has(.pie-slice)")`;
    await p.waitFor(`!!${svg}`, "the pie chart");
    const got = await p.evaluate(`(() => {
      const s = ${svg}, items = [...document.querySelectorAll("button[aria-pressed]")];
      return {
        names: items.map((e) => e.textContent),
        swatches: items.map((e) => getComputedStyle(e.firstElementChild).backgroundColor),
        slices: [...s.querySelectorAll(".pie-slice")].map((e) => getComputedStyle(e).fill),
      };
    })()`);
    assert(JSON.stringify(got.names) === JSON.stringify(["Direct", "Search", "Social", "Email"]), `the pie's legend reads ${JSON.stringify(got.names)}`);
    assert(JSON.stringify(got.swatches) === JSON.stringify(got.slices), `the legend's colours ${JSON.stringify(got.swatches)} aren't the slices' ${JSON.stringify(got.slices)}`);
  },

  async "chart: an area chart's fill is see-through"(p) {
    await p.goto("/ui/components/chart");
    await p.clickText("Area Charts");
    await p.waitFor(`!!document.querySelector(".series-area")`, "the area chart");
    const opacity = await p.evaluate(`getComputedStyle(document.querySelector(".series-area")).fillOpacity`);
    assert(opacity === "0.3", `the area's fill-opacity is ${opacity}`);
  },

  async "chart: the bar chart's colours stand apart, and from the page, in both themes"(p) {
    const lum = (rgb) => {
      const [r, g, b] = rgb.match(/\d+/g).map(Number).map((v) => { v /= 255; return v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4; });
      return 0.2126 * r + 0.7152 * g + 0.0722 * b;
    };
    const contrast = (a, b) => { const [x, y] = [lum(a), lum(b)].sort((m, n) => n - m); return (x + 0.05) / (y + 0.05); };
    for (const [scheme, page] of [["light", "rgb(255, 255, 255)"], ["dark", "rgb(17, 17, 17)"]]) {
      await p.colorScheme(scheme);
      await p.goto("/ui/components/chart");
      await p.clickText("Bar Charts");
      const svg = `document.querySelector("svg:has(.stacked-bar)")`;
      await p.waitFor(`!!${svg}`, "the bar chart");
      const swatches = await p.evaluate(`[...document.querySelectorAll("button[aria-pressed]")].map((e) => getComputedStyle(e.firstElementChild).backgroundColor)`);
      assert(new Set(swatches).size === swatches.length, `in ${scheme} mode the legend repeats a colour: ${swatches.join(", ")}`);
      for (const c of swatches) assert(contrast(c, page) >= 2, `in ${scheme} mode ${c} barely shows on ${page} (contrast ${contrast(c, page).toFixed(2)})`);
    }
    await p.colorScheme(null);
  },

  async "chart: the page shows how to use charts, zoom them and style them"(p) {
    await p.goto("/ui/components/chart");
    for (const title of ["Usage", "Pie and Donut Charts", "Zooming", "Styling"])
      assert(await p.evaluate(`(() => { ${finders} return __ui.byText(${JSON.stringify(title)}).some((e) => e.getAttribute("role") !== "tab"); })()`), `no ${JSON.stringify(title)} section`);
    const text = await p.evaluate(`document.body.textContent`);
    for (const code of ["chart.addSeries(.line_smooth", ".label = \"Direct\"", "chart.onendselection = onZoom", "chart.resetZoom()", ".fill_opacity = 0.15"])
      assert(text.includes(code), `the page's examples don't show ${code}`);
  },

  async "code: examples line up, scroll to their last and longest line, and only where needed"(p) {
    // A page per code box style there was, and the chart's long lines.
    const pages = [["/ui/components/chart", "chart.addSeries(.line_smooth"], ["/ui/components/dialog", "@import"], ["/ui/components/toasts", "Toast.err_blur"]];
    for (const [w, h] of [[1440, 900], [390, 844]]) {
      await p.viewport(w, h);
      for (const [path, needle] of pages) {
        await p.goto(path);
        const got = await p.evaluate(`(() => {
          const lines = [...document.querySelectorAll("div")].filter((d) => d.children.length === 2 && /^\\d+$/.test(d.children[0].textContent.trim()));
          const box = lines.find((d) => d.textContent.includes(${JSON.stringify(needle)}))?.parentElement;
          if (!box) return { error: "no code box" };
          const rows = lines.filter((d) => d.parentElement === box);
          const starts = new Set(rows.map((d) => Math.round(d.children[1].getBoundingClientRect().left)));
          // The boxes between the code and its frame that clip or scroll it.
          const clips = [];
          for (let a = box.parentElement, n = 0; a && n < 6; a = a.parentElement, n++) {
            const s = getComputedStyle(a);
            if (s.overflowX !== "visible" || s.overflowY !== "visible") clips.push({ a, x: s.overflowX, y: s.overflowY });
          }
          const scroller = clips[0]?.a;
          const last = rows[rows.length - 1].children[1];
          const longest = rows.map((d) => d.children[1]).sort((a, b) => b.scrollWidth - a.scrollWidth)[0];
          if (scroller) { scroller.scrollTop = 1e6; scroller.scrollLeft = 1e6; }
          // Scrolled to the end both ways: the last line's bottom and the
          // longest line's end are within the box.
          const box_ = (a) => a.getBoundingClientRect();
          return {
            starts: [...starts],
            clips: clips.map((c) => c.x + "/" + c.y),
            lastShows: !!scroller && last.getBoundingClientRect().bottom <= box_(scroller).bottom + 1,
            longestShows: !!scroller && longest.getBoundingClientRect().right <= box_(scroller).right + 1,
            numbersSelect: getComputedStyle(rows[0].children[0]).userSelect,
            codeHeight: Math.round(box.getBoundingClientRect().height),
            boxHeight: scroller ? Math.round(box_(scroller).height) : 0,
            copy: [...document.querySelectorAll("button")].some((b) => b.getAttribute("aria-label") === "Copy code"),
          };
        })()`);
        const at = `at ${w}px on ${path}`;
        assert(!got.error, `${at}: ${got.error}`);
        assert(got.starts.length === 1, `${at} the lines start at ${got.starts.join(", ")}px, not one edge`);
        assert(got.clips.length === 1 && got.clips[0] === "auto/auto", `${at} the code sits in ${got.clips.length} clipping or scrolling boxes (${got.clips.join(", ")}), not one that scrolls only when needed`);
        assert(got.lastShows, `${at} the example's last line can't be scrolled into view`);
        assert(got.boxHeight <= got.codeHeight + 80, `${at} the code box is ${got.boxHeight}px tall for ${got.codeHeight}px of code`);
        assert(got.longestShows, `${at} the example's longest line can't be scrolled into view`);
        assert(got.numbersSelect === "none", `${at} selecting code also selects its line numbers`);
        assert(got.copy, `${at} no button is named "Copy code"`);
      }
    }
    await p.viewport(1440, 900);
  },

  async "accordion: opening and closing moves only the panel, smoothly"(p) {
    await p.goto("/ui/components/accordion");
    const trig = `[...document.querySelectorAll("button[aria-expanded]")].find((b) => b.textContent.includes("Product Information"))`;
    await p.evaluate(`${trig}.scrollIntoView({ block: "center" })`);
    await sleep(300);
    // Every frame of one toggle: the trigger's top and height, and the panel's height.
    const toggle = () => p.evaluate(`new Promise((done) => {
      const b = ${trig};
      const content = [...b.parentElement.parentElement.querySelectorAll("p")].find((e) => e.textContent.startsWith("Our flagship"));
      const frames = [], start = performance.now();
      const tick = () => {
        const r = b.getBoundingClientRect();
        frames.push({ top: r.top, height: r.height, gap: content.getBoundingClientRect().top - r.bottom, shown: content.parentElement.parentElement.getBoundingClientRect().height });
        if (performance.now() - start < 500) requestAnimationFrame(tick); else done(frames);
      };
      requestAnimationFrame(tick);
      setTimeout(() => b.click(), 20);
    })`);
    for (const [what, grows] of [["opening", true], ["closing", false]]) {
      const frames = await toggle();
      const tops = new Set(frames.map((f) => f.top.toFixed(1))), heights = new Set(frames.map((f) => f.height.toFixed(1)));
      assert(tops.size === 1 && heights.size === 1, `${what}, the trigger moves: tops ${[...tops].join(", ")}, heights ${[...heights].join(", ")}`);
      const shown = frames.map((f) => f.shown);
      const steps = shown.slice(1).map((v, i) => v - shown[i]);
      assert(steps.every((d) => (grows ? d >= -0.01 : d <= 0.01)), `${what}, the panel's height goes back and forth: ${shown.map((v) => v.toFixed(1)).join(", ")}`);
      assert(new Set(shown.map((v) => v.toFixed(0))).size > 3, `${what}, the panel jumps instead of animating: ${shown.map((v) => v.toFixed(1)).join(", ")}`);
      await sleep(200);
    }
  },

  async "tabs: clicking and arrow keys switch the chart, focus follows"(p) {
    await p.goto("/ui/components/chart");
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
    await p.goto("/ui/components/table");
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
    await p.goto("/ui/components/table");
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
    await p.goto("/ui/components/textfield");
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
    await p.goto("/ui/components/progress");
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

  async "marquee: stays still for less motion, and pauses while it has focus"(p) {
    const group = `[...document.querySelectorAll(".marquee-group")].find((g) => g.getBoundingClientRect().height > 0)`;
    const state = `getComputedStyle(${group}).animationPlayState`;
    await p.reducedMotion("reduce");
    await p.goto("/ui/components/marquee");
    assert(await p.evaluate(state) === "paused", "a marquee moves for someone who asked for less motion");
    await p.reducedMotion("no-preference");
    await p.goto("/ui/components/marquee");
    assert(await p.evaluate(state) === "running", "a marquee doesn't run on its own");
    // A keyboard reaches it, named, and focus holds it still.
    const region = `${group}.closest("[tabindex]")`;
    const got = await p.evaluate(`(() => { const r = ${region}; return r ? { tab: r.tabIndex, role: r.getAttribute("role"), label: r.getAttribute("aria-label") } : null; })()`);
    assert(got && got.tab === 0 && got.role === "region" && got.label, `the marquee isn't a named tab stop: ${JSON.stringify(got)}`);
    await p.evaluate(`${region}.focus()`);
    await p.waitFor(`${state} === "paused"`, "focus to pause it");
    await p.evaluate(`${region}.blur()`);
    await p.waitFor(`${state} === "running"`, "it to carry on when focus leaves");
    await p.reducedMotion(null);
  },

  async "marquee: scrolls, and pauses while the pointer is over it"(p) {
    await p.reducedMotion("no-preference");
    await p.goto("/ui/components/marquee");
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
    await p.reducedMotion(null);
  },

  async "button: every button has a name; a loading one says it is busy"(p) {
    await p.goto("/ui/components/button");
    const unnamed = await p.evaluate(`(() => { ${finders} return [...document.querySelectorAll("button")].filter((b) => __ui.visible(b) && !b.getAttribute("aria-label") && !b.textContent.trim()).length; })()`);
    assert(unnamed === 0, `${unnamed} visible buttons with no name`);
    await p.clickLabel("Next");
    const busy = await p.evaluate(`(() => { ${finders} const b = __ui.byText("Please wait")[0]?.closest("button"); return b && [b.getAttribute("aria-busy"), b.getAttribute("aria-disabled")]; })()`);
    assert(JSON.stringify(busy) === '["true","true"]', `the loading button reads busy and disabled (${JSON.stringify(busy)})`);
  },

  async "components: the sidebar is on component pages only"(p) {
    const sidebar = `!!document.querySelector('[aria-label="navigate to /ui/components/accordion"]')`;
    await p.goto("/ui/components/tabs");
    assert(await p.evaluate(sidebar), "a component page has the sidebar");
    for (const path of ["/", "/ui/components", "/ui/templates", "/ui/auth", "/ui/payment"]) {
      await p.goto(path);
      assert(!(await p.evaluate(sidebar)), `${path} has no sidebar`);
    }
  },

  async "phone: every page fits a 390px screen without sideways scrolling"(p) {
    const pages = ["/", "/ui/components", "/ui/templates", "/ui/auth", "/ui/payment", ...COMPONENT_PAGES];
    const tooWide = `(() => {
      if (document.documentElement.scrollWidth <= innerWidth + 1 && innerWidth <= 391) return null;
      // What sticks out: elements past the screen's edge with no child that
      // does, and no ancestor that clips or scrolls them, or pins them (a
      // fixed bar only stretches with the page).
      const contained = (e) => {
        for (let a = e; a && a.id !== "contents"; a = a.parentElement) {
          const cs = getComputedStyle(a);
          if (cs.position === "fixed") return true;
          if (a !== e && cs.overflowX !== "visible") return true;
        }
        return false;
      };
      const out = [];
      for (const e of document.querySelectorAll("#contents *")) {
        const r = e.getBoundingClientRect();
        if (r.right <= 392 || r.width === 0 || contained(e)) continue;
        if ([...e.children].some((c) => c.getBoundingClientRect().right > 392 && !contained(c))) continue;
        out.push(e.tagName.toLowerCase() + "#" + e.id + " " + Math.round(r.right) + "px " + JSON.stringify((e.textContent || "").trim().slice(0, 24)));
      }
      return "page is " + document.documentElement.scrollWidth + "px: " + out.slice(0, 4).join(", ");
    })()`;
    const problems = [];
    await p.viewport(390, 844, true);
    try {
      for (const path of pages) {
        await p.goto(path);
        const wide = await p.evaluate(tooWide);
        if (wide) problems.push(`${path}: ${wide}`);
      }
    } finally {
      await p.viewport(1440, 900);
    }
    assert(problems.length === 0, `pages wider than a phone:\n        ${problems.join("\n        ")}`);
  },

  async "home: switching tabs shows the new tab at its size, not animating to it"(p) {
    // The Chat tab's elements were reused for the pricing cards, whose
    // transition then animated them from the chat's sizes.
    await p.goto("/");
    await p.clickText("Chat");
    await p.waitText("Messages");
    const sample = p.evaluate(`new Promise((done) => {
      const out = []; const t0 = performance.now();
      const tick = () => {
        const card = [...document.querySelectorAll("p")].find((e) => e.textContent.trim() === "Premium")?.parentElement;
        if (card) out.push(Math.round(card.getBoundingClientRect().width));
        if (performance.now() - t0 < 400) requestAnimationFrame(tick); else done(out);
      };
      requestAnimationFrame(tick);
    })`);
    await p.clickText("Payments");
    const widths = await sample;
    // Its hover rounds the corners, which should animate too.
    const animates = await p.evaluate(`(() => {
      let e = [...document.querySelectorAll("p")].find((e) => e.textContent.trim() === "Premium");
      while (e && getComputedStyle(e).transitionDuration === "0s") e = e.parentElement;
      return e ? getComputedStyle(e).transitionProperty : "";
    })()`);
    // The tab is remembered; leave the one the other tests expect.
    await p.clickText("Components");
    assert(widths.length > 0, "the pricing cards never showed");
    assert(new Set(widths).size === 1, `a pricing card's width changed as it appeared: ${widths.join(" ")}`);
    const names = animates.split(", ");
    assert(names.includes("border-radius") && !names.includes("width"), `a pricing card animates: ${animates}`);
  },

  async "prerendered tabs and progress keep their ids when the app takes over"(p) {
    // Their ids were memory addresses, which differ between the generator
    // and the browser, so every such element was rebuilt. A client-rendered
    // build has no prerendered ids, and nothing to compare.
    // The home page remembers its tab; it is prerendered on the first.
    await p.goto("/");
    await p.clickText("Components");
    for (const path of ["/", "/ui/components/progress", "/ui/components/tabs"]) {
      await p.goto(path);
      const missing = await p.evaluate(`(async () => {
        const pick = (root) => [...root.querySelectorAll("[id^=tab-],[id^=bar-],[id^=progress-]")].map((e) => e.id);
        const html = await (await fetch(location.href)).text();
        const live = new Set(pick(document));
        return pick(new DOMParser().parseFromString(html, "text/html")).filter((id) => !live.has(id)).join(", ");
      })()`);
      assert(missing === "", `${path}: prerendered ids gone after takeover: ${missing}`);
    }
  },

  async "phone: a tab opened by a click gets its phone layout"(p) {
    // The phone rules of what a click brings in lost to its base rules:
    // the dashboard kept its side nav and was wider than the screen.
    await p.viewport(390, 844, true);
    try {
      await p.goto("/");
      await p.clickText("Components");
      await p.clickText("Templates");
      await p.waitText("Recent Transactions");
      await sleep(300);
      const width = await p.evaluate(`document.documentElement.scrollWidth`);
      assert(width <= 390, `the page is ${width}px wide`);
      await p.waitText("Analytics", { gone: true });
    } finally {
      await p.viewport(1440, 900);
    }
  },

  async "phone: the dashboard chart survives a narrow screen"(p) {
    // Its width minus its margins underflowed and the app panicked.
    await p.viewport(390, 844, true);
    try {
      // A panic would fail the test as a page error.
      await p.goto("/ui/templates");
      await p.waitText("templates-ui");
      await sleep(500);
    } finally {
      await p.viewport(1440, 900);
    }
  },

  async "phone: the menu lists every page and closes on a choice, search opens"(p) {
    await p.viewport(390, 844, true);
    try {
      await p.goto("/");
      await p.waitText("Tabs", { gone: true });
      await p.clickLabel("open menu");
      for (const text of ["Components", "Templates", "Authentication", "Payments", "Accordion", "Tabs", "Progress Bar/Circle"]) await p.waitText(text);
      // The section links read their names, inside the menu.
      const menu = await p.evaluate(`[...document.querySelectorAll("#mobile-menu a")].slice(0, 4).map((a) => a.textContent.trim()).join(",")`);
      assert(menu === "Components,Templates,Authentication,Payments", `menu sections read ${menu}`);
      await p.clickText("Tabs");
      await p.waitFor(`location.pathname === "/ui/components/tabs"`, "the tabs page");
      await p.waitFor(`!document.getElementById("mobile-menu")`, "the menu to close");
      await p.waitText("Change your name, email and avatar.");
      await p.clickLabel("search components");
      await p.waitFor(`!!document.querySelector('[role=dialog], dialog[open]')`, "the search dialog");
    } finally {
      await p.viewport(1440, 900);
    }
  },

  async "auth: the demo forms say they have no backend"(p) {
    await p.goto("/ui/auth");
    // The first "Login" is the tab; the second is the form's button.
    await p.clickText("Login", 1);
    await p.waitText("This login form is not connected to a backend.");
  },

  async "nav: every link in the nav and sidebar leads to a page"(p) {
    await p.goto("/ui/components/accordion");
    const links = await p.evaluate(`[...new Set([...document.querySelectorAll("a[href^='/']")].map((a) => new URL(a.href).pathname))]`);
    assert(links.length > 10, `found only ${links.length} links`);
    const missing = [];
    for (const path of links) {
      await p.goto(path);
      if (await p.evaluate(`!!document.getElementById("vapor-not-found")`)) missing.push(path);
    }
    assert(missing.length === 0, `links with no page: ${missing.join(", ")}`);
  },

  async "tabs: each example switches its panel, and arrow keys move the selection"(p) {
    await p.goto("/ui/components/tabs");
    await p.waitText("Change your name, email and avatar.");
    await p.clickText("Password");
    await p.waitText("Update your password. You will be signed out of other devices.");
    await p.press("ArrowRight");
    await p.waitText("Choose which emails and push notifications you receive.");
    await p.waitFor(`document.activeElement?.textContent.trim() === "Notifications"`, "focus to follow the selected tab");

    await p.waitText("Selected: Activity");
    await p.clickText("Settings");
    await p.waitText("Selected: Settings");

    await p.waitText("128 visits today");
    await p.clickText("Weekly");
    await p.waitText("904 visits this week");
  },

  async "auth: the login card switches to account creation"(p) {
    await p.goto("/ui/auth");
    await p.waitText("Login into Acorn");
    await p.clickText("Create Account");
    await p.waitText("Create Acorn Account");
  },

  async "payment: the pricing cards show every plan"(p) {
    await p.goto("/ui/payment");
    for (const text of ["Ryven Pricing", "$0", "$29", "$79"]) await p.waitText(text);
  },

  async "payment: the highlighted plan's text is white in light and dark"(p) {
    const color = (text) =>
      `getComputedStyle([...document.querySelectorAll("*")].find((e) => e.childElementCount === 0 && e.textContent === ${JSON.stringify(text)})).color`;
    try {
      for (const scheme of ["light", "dark"]) {
        await p.colorScheme(scheme);
        await p.goto("/ui/payment");
        await p.waitText("$29");
        for (const text of ["Pro", "$29", "Priority support", "Start Free Trial"]) {
          const c = await p.evaluate(color(text));
          assert(c === "rgb(255, 255, 255)", `in ${scheme}, the Pro card's "${text}" is ${c}`);
        }
        // The other cards keep the theme's text colour.
        const free = await p.evaluate(color("$0"));
        const want = scheme === "light" ? "rgb(0, 0, 0)" : "rgb(234, 234, 234)";
        assert(free === want, `in ${scheme}, the Free card's "$0" is ${free}`);
      }
    } finally {
      await p.colorScheme(null);
    }
  },

  async "every page: each control has a name"(p) {
    const pages = ["/", "/ui/components/accordion", "/ui/components/alert", "/ui/components/button", "/ui/components/carousel", "/ui/components/chart", "/ui/components/checkbox", "/ui/components/combobox", "/ui/components/commandpalette", "/ui/components", "/ui/components/datepicker", "/ui/components/dialog", "/ui/components/drawer", "/ui/components/marquee", "/ui/components/progress", "/ui/components/radio", "/ui/components/select", "/ui/components/sidebar", "/ui/components/slider", "/ui/components/switch", "/ui/components/table", "/ui/components/tabs", "/ui/templates", "/ui/components/textfield", "/ui/components/toasts", "/ui/components/tooltip", "/ui/auth", "/ui/payment"];
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
    await p.goto("/ui/components/table");
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
    await p.goto("/ui/components/carousel");
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

  async "kanban: a card dropped below a short column's last card joins it"(p) {
    // Only the list's own box took drops, which ends at its last card.
    await p.goto("/ui/templates");
    const { from } = await kanbanDragPoints(p, "Performance audit", "Done");
    const to = await p.evaluate(`(() => {
      ${finders}
      const backlog = __ui.byText("Backlog")[0].getBoundingClientRect();
      const done = __ui.byText("Done").map((e) => e.getBoundingClientRect()).find((h) => Math.abs(h.top - backlog.top) < 4);
      // Lower than any card in Done: it holds the fewest.
      const lowest = Math.max(...[...document.querySelectorAll("[id^=ST-Item]")].map((e) => e.getBoundingClientRect()).filter((r) => r.right > done.left && r.left < done.left + 60).map((r) => r.bottom));
      return { x: done.left + 40, y: Math.min(lowest + 60, innerHeight - 10) };
    })()`);
    await p.drag(from, to, 16);
    await p.waitFor(`${kanbanColumnOf("Performance audit")} === "Done"`, "the card to land in Done");
  },

  async "phone: a card held then dragged by touch moves to another column"(p) {
    // A finger moving at once is a scroll, which the browser takes over
    // (pointercancel); resting on the card first picks it up.
    await p.viewport(390, 844, true);
    try {
      await p.goto("/ui/templates");
      const { from, to } = await kanbanDragPoints(p, "Performance audit", "To Do");
      await p.touchDrag(from, to, { holdMs: 300 });
      await p.waitFor(`${kanbanColumnOf("Performance audit")} === "To Do"`, "the card to land in To Do");
    } finally {
      await p.viewport(1440, 900);
    }
  },

  async "phone: swiping across a card scrolls the board and leaves the card"(p) {
    await p.viewport(390, 844, true);
    try {
      await p.goto("/ui/templates");
      const { from } = await kanbanDragPoints(p, "Performance audit", "To Do");
      const board = `(() => { ${finders} let e = __ui.byText("Backlog")[0]; while (e && getComputedStyle(e).overflowX !== "auto" && getComputedStyle(e).overflowX !== "scroll") e = e.parentElement; return e; })()`;
      const before = await p.evaluate(`${board}.scrollLeft`);
      await p.touchDrag(from, { x: from.x - 150, y: from.y });
      await p.waitFor(`${board}.scrollLeft > ${before + 50}`, "the board to scroll");
      assert(await p.evaluate(kanbanColumnOf("Performance audit")) === "Backlog", "the card moved");
    } finally {
      await p.viewport(1440, 900);
    }
  },

  async "phone: a held card dragged to the board's edge reaches the columns off screen"(p) {
    await p.viewport(390, 844, true);
    try {
      await p.goto("/ui/templates");
      const { from } = await kanbanDragPoints(p, "Performance audit", "To Do");
      // Rest at the right edge while the board scrolls to its end, then
      // drop into the last column.
      const y = from.y + 40;
      await p.touchDrag(from, { x: 385, y }, { holdMs: 300, dwellMs: 2500, then: [{ x: 340, y }, { x: 300, y }] });
      const where = await p.evaluate(kanbanColumnOf("Performance audit"));
      assert(where === "Done", `the card landed in ${where}`);
    } finally {
      await p.viewport(1440, 900);
    }
  },

  async "phone: tapping a card's button still works"(p) {
    await p.viewport(390, 844, true);
    try {
      await p.goto("/ui/templates");
      await p.evaluate(`${kanbanCardButton("Performance audit", "Move task right")}.scrollIntoView({ block: "center", inline: "nearest" })`);
      const at = await p.evaluate(`(() => { const r = ${kanbanCardButton("Performance audit", "Move task right")}.getBoundingClientRect(); return { x: r.left + r.width / 2, y: r.top + r.height / 2 }; })()`);
      await p.tap(at);
      await p.waitFor(`${kanbanColumnOf("Performance audit")} === "To Do"`, "the card to move to To Do");
    } finally {
      await p.viewport(1440, 900);
    }
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

  async "chat: with no server connected, a sent message joins the thread"(p) {
    await p.goto("/ui/templates");
    // The chat sends over a WebSocket; this static site has no server.
    const box = `document.querySelector('textarea[aria-label="Type a message..."]')`;
    await p.evaluate(`${box}.scrollIntoView({ block: "center" })`);
    await p.evaluate(`${box}.focus()`);
    await p.type("Hello there");
    await p.clickLabel("Send message");
    await p.waitText("Hello there");
    await p.waitFor(`${box}.value === ""`, "the message box to empty");
    assert(!(await p.evaluate(`(() => { ${finders} return __ui.byText("Not Connected").length > 0; })()`)), "it said Not Connected");
  },

  async "chat: the message box takes typing; Shift+Enter is a new line, Enter sends"(p) {
    await p.goto("/ui/templates");
    const box = `document.querySelector('textarea[aria-label="Type a message..."]')`;
    await p.evaluate(`${box}.scrollIntoView({ block: "center" })`);
    await p.evaluate(`${box}.focus()`);
    await p.typeKeys("Hi there\nsecond line");
    const typed = await p.evaluate(`${box}.value`);
    assert(typed === "Hi there\nsecond line", `the message box reads ${JSON.stringify(typed)}`);
    await p.press("Enter");
    await p.waitText("Hi there\nsecond line");
    await p.waitFor(`${box}.value === ""`, "the message box to empty");
  },

  async "chat: the message box grows with its lines, then scrolls"(p) {
    await p.goto("/ui/templates");
    const box = `document.querySelector('textarea[aria-label="Type a message..."]')`;
    await p.evaluate(`${box}.scrollIntoView({ block: "center" })`);
    await p.evaluate(`${box}.focus()`);
    const height = () => p.evaluate(`${box}.getBoundingClientRect().height`);
    const empty = await height();
    await p.typeKeys("one\ntwo\nthree");
    await sleep(100);
    const three = await height();
    assert(three > empty, `three lines leave the box at ${three}px, as tall as empty (${empty}px)`);
    await p.typeKeys("\nline".repeat(30));
    await sleep(100);
    const many = await p.evaluate(`(() => { const t = ${box}; const s = getComputedStyle(t); return { h: t.getBoundingClientRect().height, scroll: t.scrollHeight, overflow: s.overflowY, max: s.maxHeight }; })()`);
    assert(many.h <= 256, `thirty lines stretch the box to ${many.h}px (max-height ${many.max})`);
    assert(many.scroll > many.h, `the box holds every line without scrolling (${JSON.stringify(many)})`);
    assert(many.overflow !== "hidden" && many.overflow !== "visible", `the box can't scroll (overflow-y ${many.overflow})`);
    // The bar under the messages grows to hold the box, rather than the box
    // spilling up over the messages.
    const spill = await p.evaluate(`(() => {
      const t = ${box}.getBoundingClientRect();
      let bar = ${box}.parentElement;
      while (bar && !bar.querySelector('[aria-label="Send message"]')) bar = bar.parentElement;
      const b = bar.getBoundingClientRect();
      return t.top < b.top - 0.5 || t.bottom > b.bottom + 0.5 ? { box: [t.top, t.bottom], bar: [b.top, b.bottom] } : null;
    })()`);
    assert(spill === null, `the box spills out of the bar that holds it: ${JSON.stringify(spill)}`);
  },

  async "chat: long and many messages stay inside the window, and the thread scrolls"(p) {
    for (const [vw, vh, mobile] of [[1440, 900, false], [1440, 1600, false], [390, 844, true]]) {
      const at = `at ${vw}x${vh}`;
      await p.viewport(vw, vh, mobile);
      await p.goto("/ui/templates");
      const box = `document.querySelector('textarea[aria-label="Type a message..."]')`;
      await p.evaluate(`${box}.scrollIntoView({ block: "center" })`);
      // The window: the box holding the conversation list and the message box.
      const win = `(() => { let w = ${box}; while (w && !w.querySelector('[aria-label="New chat"]')) w = w.parentElement; return w; })()`;
      // The thread: the scrolling box the messages sit in.
      const thread = `[...${win}.querySelectorAll("div")].find((d) => /auto|scroll/.test(getComputedStyle(d).overflowY) && d.textContent.includes("project going"))`;
      const size = () => p.evaluate(`(() => { const r = ${win}.getBoundingClientRect(); return { w: Math.round(r.width), h: Math.round(r.height) }; })()`);
      const before = await size();
      const send = async (text) => {
        await p.evaluate(`${box}.focus()`);
        await p.typeKeys(text);
        await p.press("Enter");
        await p.waitFor(`${box}.value === ""`, "the message box to empty");
      };
      await send("a long message that keeps going ".repeat(12) + "x".repeat(160));
      for (let i = 1; i <= 12; i++) await send(`Hello number ${i}`);
      await sleep(600);
      const after = await size();
      assert(Math.abs(after.w - before.w) <= 1 && Math.abs(after.h - before.h) <= 1, `${at} the window went from ${before.w}x${before.h} to ${after.w}x${after.h}`);
      const got = await p.evaluate(`(() => {
        const t = ${thread}, w = ${win}.getBoundingClientRect();
        if (!t) return { error: "no scrolling thread" };
        const r = t.getBoundingClientRect();
        const bubble = [...t.querySelectorAll("*")].filter((d) => d.textContent.startsWith("a long message") && d.textContent.endsWith("x")).pop().getBoundingClientRect();
        return {
          overflowing: t.scrollHeight > t.clientHeight + 1,
          atEnd: t.scrollTop + t.clientHeight >= t.scrollHeight - 2,
          threadIn: r.left >= w.left - 1 && r.right <= w.right + 1 && r.bottom <= w.bottom + 1,
          bubbleIn: bubble.left >= r.left - 1 && bubble.right <= r.right + 1,
          pageWide: document.documentElement.scrollWidth > innerWidth,
        };
      })()`);
      assert(!got.error, `${at}: ${got.error}`);
      assert(got.threadIn, `${at} the thread spills out of the window (${JSON.stringify(got)})`);
      assert(got.overflowing, `${at} thirteen messages fit without the thread scrolling: it grew instead`);
      assert(got.atEnd, `${at} the thread isn't scrolled to the newest message`);
      assert(got.bubbleIn && !got.pageWide, `${at} the long message runs out sideways (${JSON.stringify(got)})`);
    }
    await p.viewport(1440, 900);
  },

  async "chat: only the newest messages render; scrolling up loads older ones in place"(p) {
    await p.goto("/ui/templates");
    const box = `document.querySelector('textarea[aria-label="Type a message..."]')`;
    await p.evaluate(`${box}.scrollIntoView({ block: "center" })`);
    const thread = `(() => { let w = ${box}; while (w && !w.querySelector('[aria-label="New chat"]')) w = w.parentElement; return [...w.querySelectorAll("div")].find((d) => /auto|scroll/.test(getComputedStyle(d).overflowY) && d.textContent.includes("project going")); })()`;
    await sleep(300);
    const count = () => p.evaluate(`${thread}.children.length`);
    assert((await count()) === 50, `the thread renders ${await count()} messages, not the newest 50 of 120`);
    assert(await p.evaluate(`${thread}.scrollTop + ${thread}.clientHeight >= ${thread}.scrollHeight - 2`), "the thread doesn't open at its newest message");
    // Scroll to the top of what is there: the next page goes in above, and
    // the message that was first stays where it was on screen, the same
    // element, without animating in again.
    const loadOlder = async (expect) => {
      const top = await p.evaluate(`(() => { const t = ${thread}; t.scrollTop = 0; window.__first = t.children[0]; return window.__first.getBoundingClientRect().top; })()`);
      await p.waitFor(`${thread}.children.length === ${expect}`, `${expect} messages after scrolling up`);
      await sleep(100);
      const now = await p.evaluate(`(() => { const e = window.__first; return { kept: e.isConnected, top: e.getBoundingClientRect().top, anim: e.getAnimations().length }; })()`);
      assert(now.kept, "the message that was on screen was replaced by a new element");
      assert(Math.abs(now.top - top) <= 1, `loading older messages moved the reader's place from ${top} to ${now.top}`);
      assert(now.anim === 0, "the message on screen animated in again");
    };
    await loadOlder(100);
    await loadOlder(120);
    await p.evaluate(`${thread}.scrollTop = 0`);
    await sleep(300);
    assert((await count()) === 120, `with nothing older left the thread has ${await count()} messages`);
    assert(await p.evaluate(`${thread}.textContent.includes("Morning! Did you see the latest build?")`), "the oldest message never showed");
  },

  async "chat: a reply while scrolled up keeps your place, and a button takes you to it"(p) {
    await p.goto("/ui/templates");
    const box = `document.querySelector('textarea[aria-label="Type a message..."]')`;
    await p.evaluate(`${box}.scrollIntoView({ block: "center" })`);
    const thread = `(() => { let w = ${box}; while (w && !w.querySelector('[aria-label="New chat"]')) w = w.parentElement; return [...w.querySelectorAll("div")].find((d) => /auto|scroll/.test(getComputedStyle(d).overflowY) && d.textContent.includes("project going")); })()`;
    await p.evaluate(`${box}.focus()`);
    await p.typeKeys("Are you around later?");
    await p.press("Enter");
    await p.waitFor(`${box}.value === ""`, "the message to send");
    await sleep(500);
    // Up a screen or so, to read back, before the demo's reply comes.
    const before = await p.evaluate(`(() => { const t = ${thread}; t.scrollTop = t.scrollTop - 600; return t.scrollTop; })()`);
    const button = `document.querySelector('[aria-label="Jump to new messages"]')`;
    await p.waitFor(`!!${button}`, "a Jump to new messages button when the reply comes", 6000);
    const after = await p.evaluate(`${thread}.scrollTop`);
    assert(Math.abs(after - before) <= 2, `the reply moved the thread from ${before} to ${after}`);
    const label = await p.evaluate(`${button}.textContent`);
    assert(label === "\u2193 1 new message", `the button reads ${JSON.stringify(label)}`);
    await p.clickSelector('[aria-label="Jump to new messages"]');
    await p.waitFor(`${thread}.scrollTop + ${thread}.clientHeight >= ${thread}.scrollHeight - 2`, "the button to take the thread to the newest message");
    await p.waitFor(`!${button}`, "the button to go");
  },

  async "chat: the message box's text follows the theme"(p) {
    const box = `document.querySelector('textarea[aria-label="Type a message..."]')`;
    for (const [scheme, text] of [["light", "rgb(0, 0, 0)"], ["dark", "rgb(234, 234, 234)"]]) {
      await p.colorScheme(scheme);
      await p.goto("/ui/templates");
      await p.waitFor(`!!${box}`, "the message box");
      const color = await p.evaluate(`getComputedStyle(${box}).color`);
      assert(color === text, `in ${scheme} mode the message box's text is ${color}, not ${text}`);
    }
    await p.colorScheme(null);
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
    await p.goto("/ui/components/drawer");
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

if (release) {
  if (!existsSync(join(siteDir, "index.html"))) {
    console.error("missing release/index.html; run `zig build release` (or `zig build test-release`)");
    process.exit(2);
  }
} else if (!existsSync(join(siteDir, "zig-out/bin/vapor.wasm")) || !existsSync(join(siteDir, "zig-out/bin/bundle.min.js"))) {
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

if (flags.has("--shot")) {
  // Whole-page screenshots of each path at each width, for checking layout.
  const out = process.env.SHOT_DIR ?? tmpdir();
  const widths = (process.env.SHOT_WIDTHS ?? "1440,1024,768,390").split(",").map(Number);
  // SHOT_SCHEME=light|dark: the colour scheme the page sees the system prefer.
  if (process.env.SHOT_SCHEME) await page.colorScheme(process.env.SHOT_SCHEME);
  for (const path of positional) {
    for (const width of widths) {
      await page.viewport(width, 900, width < 768);
      await page.goto(path);
      // SHOT_CLICK="Templates": click the element reading that first.
      if (process.env.SHOT_CLICK) await page.clickText(process.env.SHOT_CLICK);
      await sleep(600);
      // SHOT_EVAL="js expression": print what it returns, for measuring.
      if (process.env.SHOT_EVAL) console.log(await page.evaluate(process.env.SHOT_EVAL));
      const { cssContentSize } = await cdp.send("Page.getLayoutMetrics");
      // SHOT_VIEWPORT=1: only what is on screen, as a visitor sees it.
      const shot = await cdp.send(
        "Page.captureScreenshot",
        process.env.SHOT_VIEWPORT
          ? { format: "png" }
          : {
              format: "png",
              captureBeyondViewport: true,
              clip: { x: 0, y: 0, width: Math.max(width, cssContentSize.width), height: cssContentSize.height, scale: 1 },
            },
      );
      const file = join(out, `${(path + (process.env.SHOT_CLICK ?? "")).replace(/\W+/g, "_") || "_"}-${width}.png`);
      writeFileSync(file, Buffer.from(shot.data, "base64"));
      console.log(`${file}  page ${Math.round(cssContentSize.width)}x${Math.round(cssContentSize.height)}`);
    }
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
