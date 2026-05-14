-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/
--
-- Wrap in hl.on("hyprland.start", ...) so commands fire once at session start
-- and not on every config reload.

hl.on("hyprland.start", function()
    -- Propagate session env to dbus / systemd user services
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")

    -- Plugins
    hl.exec_cmd("hyprpm reload -n")

    -- Polkit agent
    hl.exec_cmd("/usr/libexec/hyprpolkitagent")

    -- Desktop components
    hl.exec_cmd("~/.local/bin/hypr-run hyprpaper") -- wallpaper
    hl.exec_cmd("~/.local/bin/hypr-run hypridle") -- idle management
    hl.exec_cmd("~/.local/bin/hypr-run swaync") -- notifications
    hl.exec_cmd("~/.local/bin/hypr-run waybar") -- top bar

    -- Clipboard history
    hl.exec_cmd("wl-paste --type text --watch cliphist store")

    -- User apps
    hl.exec_cmd("bitwarden") -- password manager
    hl.exec_cmd("syncthing --no-browser") -- sync obsidian

    -- Launcher
    hl.exec_cmd("systemctl --user restart vicinae.service")

    -- On-screen-display
    hl.exec_cmd("systemctl --user restart swayosd-server.service")
end)
