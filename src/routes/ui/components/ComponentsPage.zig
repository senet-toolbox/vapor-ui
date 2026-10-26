const std = @import("std");
const Vapor = @import("vapor");
const Row = Vapor.Row;
const Text = Vapor.Text;
const Button = Vapor.Button;
const Label = Vapor.Label;
const TextFmt = Vapor.TextFmt;
const TextField = Vapor.TextField;
const TextArea = Vapor.TextArea;
const Link = Vapor.Link;
const Image = Vapor.Image;
const List = Vapor.List;
const ListItem = Vapor.ListItem;
const CtxButton = Vapor.Button;
const RedirectLink = Vapor.RedirectLink;
const ButtonCtx = Vapor.Button;
const ComponentsNav = @import("ComponentsNav.zig");

pub fn init() void {
    Vapor.Page(.{ .src = @src() }, render, null);
}

pub fn render() void {
    // const { Row, Stack, List } = Vapor;
    Row()
        .width(.percent(100))
        .layout(.center)
        .direction(.column)
        .spacing(16)
        .children({
        // Vapor.Graphic(.{ .src = "/assets/futuristic.svg" })
        //     .pos(.tl(.px(60), .percent(0), .absolute))
        //     // .transform(.rotateXYZ(0, 0, 90))
        //     .size(.hw(.fit, .percent(20)))
        //     // .fill(.palette(.text_color))
        //     // .stroke(.palette(.text_color))
        //     .end();
        // Vapor.Graphic(.{ .src = "/assets/futuristic2.svg" })
        //     .pos(.tr(.px(60), .percent(0), .absolute))
        //     // .transform(.rotateXYZ(0, 180, 0))
        //     .size(.hw(.fit, .percent(20)))
        //     // .fill(.palette(.text_color))
        //     // .stroke(.palette(.text_color))
        //     .end();
        Row()
            .width(.percent(100))
            .height(.px(256))
            .layout(.center)
            .direction(.column)
            .spacing(16)
            .children({
            Text("Components")
                .font(72, 700, .palette(.text_color))
                .end();
            Text("Components are the building blocks of your application. They are reusable, composable, and customizable.")
                .font(16, 300, .palette(.text_color))
                .end();
        });
        List()
            .layout(.flex)
            .direction(.column)
            .height(.px(720))
            .spacing(64)
            .wrap(.wrap)
            .listStyle(.none)
            .children({
            for (ComponentsNav.items) |item| {
                ListItem()
                    .duration(100)
                    .pointer()
                    .height(.px(18))
                    .children({
                    if (item.link) |link| {
                        Vapor.Link(.{ .url = link, .aria_label = Vapor.fmtln("navigate to {s}", .{item.label}) })
                            .textDecoration(.none)
                            .hoverText(.palette(.tint))
                            .textColor(.palette(.text_color))
                            .children({
                            Text(item.label)
                                .fontSize(18)
                                .fontFamily("IBM Plex Mono,monospace")
                                .end();
                        });
                    }
                });
            }
        });
    });
}
