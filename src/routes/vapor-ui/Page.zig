// routes/vapor-ui/Page.zig
const std = @import("std");
const Vapor = @import("vapor");
const View = @import("../../components/View.zig").View;
const Opaque = @import("opaque-ui");
const Templates = @import("../../components/templates/Dashboard.zig");
const Kanban_old = @import("../../components/templates/Kanban.zig");
const KanbanShared = @import("../../components/templates/Kanban_1.zig").Kanban;
const ApiClient = @import("../../components/templates/ApiClient.zig");
const Tabs = Opaque.Tabs;
const Text = Vapor.Text;
const Row = Vapor.Row;
const Center = Vapor.Center;
const Stack = Vapor.Stack;
const Login = @import("../../components/templates/Login.zig");
const KeyStone = @import("keystone");
const Payment = @import("../../components/templates/Payment.zig");
const Stripe = @import("../../components/templates/Stripe.zig");
const Todolist = @import("Todolist.zig").TodoList;

// Nav Components
const Footer = @import("Footer.zig");
const VaporUINav = @import("VaporUINav.zig");

// Pages
const ChartPage = @import("../../routes/ui/components/chart/ChartPage.zig");
const ButtonPage = @import("../../routes/ui/components/button/ButtonPage.zig");
const CommandPalettePage = @import("../../routes/ui/components/commandpalette/CommandPalettePage.zig");
const ComboBoxPage = @import("../../routes/ui/components/combobox/ComboboxPage.zig");
const AccordionPage = @import("../../routes/ui/components/accordion/AccordionPage.zig");
const SelectPage = @import("../../routes/ui/components/select/SelectPage.zig");
const TablePage = @import("../../routes/ui/components/table/TablePage.zig");
const DialogPage = @import("../../routes/ui/components/dialog/DialogPage.zig");
const AlertPage = @import("../../routes/ui/components/alert/AlertPage.zig");
const DatePickerPage = @import("../../routes/ui/components/datepicker/DatePickerPage.zig");
const DrawerPage = @import("../../routes/ui/components/drawer/DrawerPage.zig");
const ToastPage = @import("../../routes/ui/components/toasts/ToastPage.zig");
const TextFieldPage = @import("../../routes/ui/components/textfield/TextFieldPage.zig");
const ToolTipPage = @import("../../routes/ui/components/tooltip/ToolTipPage.zig");
const SwitchPage = @import("../../routes/ui/components/switch/SwitchPage.zig");
const ProgressPage = @import("../../routes/ui/components/progress/ProgressPage.zig");
const SideBarPage = @import("../../routes/ui/components/sidebar/SideBarPage.zig");
const SliderPage = @import("../../routes/ui/components/slider/SliderPage.zig");
const ComponentsPage = @import("../../routes/ui/components/ComponentsPage.zig");
const ComponentsNav = @import("../../routes/ui/components/ComponentsNav.zig");
const TemplatesPage = @import("../../routes/ui/templates/TemplatesPage.zig");
const CarouselPage = @import("../../routes/ui/components/carousel/CarouselPage.zig");
const MarqueePage = @import("../../routes/ui/components/marquee/MarqueePage.zig");
const CheckBoxPage = @import("../../routes/ui/components/checkbox/CheckBoxPage.zig");
const RadioPage = @import("../../routes/ui/components/radio/RadioPage.zig");
const TabsPage = @import("../../routes/ui/components/tabs/TabsPage.zig");
const AuthPage = @import("../../routes/ui/auth/AuthPage.zig");
const PaymentPage = @import("../../routes/ui/payment/PaymentPage.zig");

const Toast = Opaque.Toast;
const Chat = @import("../../components//templates/Chat.zig");
const Ecommerce = @import("../../components/templates/Ecommerce.zig");

pub var login: Login = .{
    .login_title = "Login into Acorn",
    .login_subtitle = "Login into your Acorn account.",
    .create_account_title = "Create Acorn Account",
    .create_account_subtitle = "Create an Acorn account to login",
};

var stripe: Stripe = .{
    .title = "Payment",
    .subtitle = "Payment to your account",
};

var todolist: Todolist = undefined;
pub fn vaporUILayout(page: *const fn () void) void {
    VaporUINav.render();
    Vapor.Spacer(60).end();
    page();
    VaporUINav.combobox_dialog.render();
    Toast.renderStack();
    Opaque.TooltipLayer();
}

/// So the issue is we reuse the node, and so transistion on a node is going to transition the widths and such
/// the ndoes can be identical, and so we
var board_a: KanbanShared = undefined;
// var board_b: KanbanShared = undefined;
pub fn init() void {
    Vapor.Page(.{ .route = "/" }, render, null);
    VaporUINav.init();
    Vapor.lib.registerLayout("/", vaporUILayout, .{}) catch unreachable;
    TemplatesPage.init();

    CheckBoxPage.init();
    RadioPage.init();
    Chat.init();

    Vapor.Animation.init("enter")
        .prop(.translateY, -20, 0)
        .prop(.opacity, 0, 1)
        .duration(300)
        .easing(.easeOut)
        .fill(.forwards).build();

    Vapor.Animation.init("exit")
        .prop(.opacity, 1, 0)
        .prop(.scale, 1, 0.95)
        .duration(200)
        .easing(.easeIn)
        .fill(.forwards).build();

    KanbanShared.initShared(); // call once
    board_a.init();

    CarouselPage.init();
    MarqueePage.init();
    Ecommerce.init();
    Templates.init();

    Payment.init();
    ApiClient.init();
    AccordionPage.init();
    AlertPage.init();
    ChartPage.init();
    ComboBoxPage.init();
    SelectPage.init();
    DatePickerPage.init();
    DrawerPage.init();
    DialogPage.init();
    TablePage.init();
    ButtonPage.init();
    CommandPalettePage.init();
    TextFieldPage.init();
    ToolTipPage.init();
    SwitchPage.init();
    ProgressPage.init();
    ToastPage.init();
    SideBarPage.init();
    SliderPage.init();
    ComponentsPage.init();
    ComponentsNav.init();
    TabsPage.init();
    AuthPage.init();
    PaymentPage.init();
}

fn layout(page: *const fn () void) void {
    const current_path = Vapor.currentPath();
    VaporUINav.render();
    Vapor.Spacer(60).end();
    page();
    if (!std.mem.eql(u8, current_path, "/ui/components")) {
        Row()
            .width(.percent(100))
            .layout(.top_center)
            .padding(.{ .bottom = 32 })
            .children({
            Row()
                .width(.percent(50))
                .children({
                Footer.render();
            });
        });
    }
}

fn setTab(tabs: *Tabs) void {
    Vapor.lib.store("active_tab", tabs.active_tab orelse "");
}

var toggled: bool = false;
fn toggle() void {
    toggled = !toggled;
}

fn log(index: usize, _: *Vapor.Event) void {
    std.log.info("Btn-{d}", .{index});
}

var input_1: []const u8 = "";
var input_2: []const u8 = "";
var input_3: []const u8 = "";

const items: [3]*[]const u8 = .{ &input_1, &input_2, &input_3 };

pub fn render() void {
    // var r = Row();
    // r.children({
    //     Text("Hello").bold().end();
    // });
    // r.clone();
    const stored_tab = Vapor.lib.getStore([]const u8, "active_tab");
    Vapor.Stack()
        .width(.percent(100))
        .layout(.top_center)
        .children({
        Vapor.Stack()
            .layout(.center)
            .height(.px(256))
            .width(.percent(100))
            .children({
            Text("vapor-ui ⇒").style(&.{
                .visual = .font(12, 500, .hex("#6f6f6f")),
                .font_family = "IBM Plex Mono,monospace",
            }).end();

            Text("vapor-ui")
                .font(72, 700, .palette(.text_color))
                .end();
            Text("Vapor UI is a collection of well crafted UI components for Vapor. It comes with default animations, and a rich set of components.")
                .font(16, 300, .palette(.text_color))
                .end();
            Text("Vapor allows you to build complex UIs, and Animations, with no dependencies.")
                .font(14, 300, .palette(.text_color))
                .fontFamily("Montserrat")
                .end();
        });

        Stack()
            .spacing(24)
            .width(.percent(90))
            .children({
            const index = Tabs.create("vapor-ui", &.{ "Components", "Templates", "Kanban", "Authentication", "Payments", "Chat" })
                .default(stored_tab)
                .onClick(setTab)
                .render();
            switch (index) {
                0 => {
                    Row()
                        .a11y(.tabPanel("Components")) // Add this - references the tab button
                        .id("tabpanel-Components")
                        .size(.full)
                        .children({
                        View();
                    });
                },
                1 => {
                    Templates.render();
                },
                2 => {
                    board_a.render();
                },
                3 => {
                    Row()
                        .width(.percent(100))
                        .layout(.center)
                        .children({
                        Row()
                            .direction(.column)
                            .width(.percent(50))
                            .children({
                            login.render();
                        });
                    });
                },
                4 => {
                    Payment.render();
                },
                5 => {
                    Chat.render();
                },

                else => {},
            }
        });
    });
}
