const Toast = @import("opaque-ui").Toast;

// Toasts follow your theme's background, text and border colours. Set any
// of these once, before showing a toast, to change them.
pub fn style() void {
    // Every toast
    Toast.border_radius = .all(8);
    Toast.border_color = .palette(.tint);

    // One type: a see-through red error that blurs the page behind it
    Toast.err_background = .transparentize(.hex("#ef4444"), 0.8);
    Toast.err_text_color = .white;
    Toast.err_blur = 12;

    // The icon colour that tells the types apart
    Toast.success_icon_color = .hex("#10b981");
}
