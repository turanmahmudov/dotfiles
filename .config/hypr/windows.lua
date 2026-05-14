--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

------------------------------
---- WORKSPACE -> MONITOR ----
------------------------------

for _, ws in ipairs({ 1, 2 }) do
    hl.workspace_rule({ workspace = tostring(ws), monitor = "eDP-1" })
end
for _, ws in ipairs({ 3, 4, 5, 6, 7, 8, 9, 10 }) do
    hl.workspace_rule({ workspace = tostring(ws), monitor = "HDMI-A-1" })
end

----------------------
---- WINDOW RULES ----
----------------------

-- Ignore maximize requests from all apps and slightly dim everything
hl.window_rule({
    name = "suppress-maximize",
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- Fix some dragging issues with XWayland
hl.window_rule({
    name = "fix-xwayland-drags",
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false,
    },
    no_focus = true,
})

-- Per-app workspace pinning
hl.window_rule({ match = { class = "^(Spotify|spotify)$" }, workspace = "2" })
hl.window_rule({ match = { class = "^(Slack)$" }, workspace = "3" })
hl.window_rule({ match = { class = "^(obsidian)$" }, workspace = "4" })

-- Make specific applications floating
hl.window_rule({ match = { class = "^(org.gnome.Calculator)$" }, float = true })

-- Touchpad scroll tuning per terminal
hl.window_rule({ match = { class = "(Alacritty|kitty)" }, scroll_touchpad = 1.5 })
hl.window_rule({ match = { class = "com.mitchellh.ghostty" }, scroll_touchpad = 0.2 })

-- File dialogs: tag as floating-window so they float + center
hl.window_rule({
    match = {
        class = "(xdg-desktop-portal-gtk|sublime_text|DesktopEditors|org.gnome.Nautilus)",
        title = "^(Open.*Files?|Open [F|f]older.*|Save.*Files?|Save.*As|Save|All Files|.*wants to [open|save].*|[C|c]hoose.*)",
    },
    tag = "+floating-window",
})

-- Bitwarden: do not share its screen content
hl.window_rule({ match = { class = "^(Bitwarden)$" }, no_screen_share = true })

-- Generic floating-window behavior
hl.window_rule({ match = { tag = "floating-window" }, float = true, center = true })

-- Popped window rounding
hl.window_rule({ match = { tag = "pop" }, rounding = 8 })

-------------------------------
---- PICTURE-IN-PICTURE    ----
-------------------------------

hl.window_rule({ match = { title = "(Picture.?in.?[Pp]icture)" }, tag = "+pip" })
hl.window_rule({
    match = { tag = "pip" },
    float = true,
    pin = true,
    size = "600 338",
    keep_aspect_ratio = true,
    border_size = 0,
    opacity = "1 1",
    move = "((monitor_w*1)-window_w-40) ((monitor_h*0.04))",
})

---------------------
---- LAYER RULES ----
---------------------

hl.layer_rule({ match = { namespace = "swaync-control-center" }, blur = true, ignore_alpha = 0 })
hl.layer_rule({ match = { namespace = "swaync-notification-window" }, blur = true, ignore_alpha = 0 })
hl.layer_rule({ match = { namespace = "vicinae" }, blur = true, ignore_alpha = 0, no_anim = true })
