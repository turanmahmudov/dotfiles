---------------------
---- KEYBINDINGS ----
---------------------

-- See https://wiki.hypr.land/Configuring/Basics/Binds/ for more

---------------------
---- MY PROGRAMS ----
---------------------

local terminal_app = "kitty --single-instance"
local terminal = "kitty --single-instance " .. (os.getenv("SHELL") or "/bin/sh") .. " -i"
local fileManager = "nautilus"
local menu = "vicinae toggle"
local mod = "SUPER" -- Sets "Windows" key as main modifier

local function exec(cmd)
    return hl.dsp.exec_cmd(cmd)
end

-----------------------------------
---- LAYOUT / WINDOW STATE     ----
-----------------------------------

hl.bind(mod .. " + P", hl.dsp.window.pseudo())
hl.bind(mod .. " + J", hl.dsp.layout("togglesplit")) -- dwindle only
hl.bind(mod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + CTRL + V", hl.dsp.exec_raw("workspaceopt allfloat"))
hl.bind(mod .. " + F", hl.dsp.window.fullscreen({ mode = 0 })) -- Full screen
hl.bind(mod .. " + CTRL + F", hl.dsp.window.fullscreen_state({ internal = 0, client = 2 })) -- Full screen inside tiled
hl.bind(mod .. " + ALT + F", hl.dsp.window.fullscreen({ mode = 1 })) -- Full width / maximize
-- Toggle the active workspace between dwindle and scrolling layouts.
hl.bind(mod .. " + L", function()
    local ws = hl.get_active_workspace()
    if not ws then
        return
    end
    local new_layout = ws.tiled_layout == "dwindle" and "scrolling" or "dwindle"
    hl.workspace_rule({ workspace = tostring(ws.id), layout = new_layout })
end)

-- Scrolling layout column moves
hl.bind(mod .. " + period", hl.dsp.layout("move +col"))
hl.bind(mod .. " + comma", hl.dsp.layout("move -col"))
hl.bind(mod .. " + SHIFT + period", hl.dsp.layout("swapcol r"))
hl.bind(mod .. " + SHIFT + comma", hl.dsp.layout("swapcol l"))

------------------------------
---- SESSION / LAUNCHERS  ----
------------------------------

hl.bind(mod .. " + Escape", hl.dsp.exit())
hl.bind(mod .. " + C", hl.dsp.window.close())
hl.bind(mod .. " + Return", exec(terminal_app))
hl.bind(mod .. " + T", exec(terminal .. " -c tmux"))
hl.bind(mod .. " + Space", exec(menu))
hl.bind(mod .. " + D", exec("vicinae toggle"))
hl.bind(mod .. " + E", exec(fileManager))
hl.bind(mod .. " + SHIFT + V", exec("~/.local/bin/clipboard-history"))
hl.bind(mod .. " + SHIFT + C", exec("~/.local/bin/hypr-run quickshell")) -- restart the shell

------------------------------
---- FOCUS / MOVE WINDOWS ----
------------------------------

-- Move focus / windows with mod + arrows
for _, dir in ipairs({ "left", "right", "up", "down" }) do
    hl.bind(mod .. " + " .. dir, hl.dsp.focus({ direction = dir }))
    hl.bind(mod .. " + SHIFT + " .. dir, hl.dsp.window.move({ direction = dir }))
end

----------------------
---- WORKSPACES   ----
----------------------

-- Numpad codes (when NumLock is ON)
local numpad = {
    KP_End = 1,
    KP_Down = 2,
    KP_Next = 3,
    KP_Left = 4,
    KP_Begin = 5,
    KP_Right = 6,
    KP_Home = 7,
    KP_Up = 8,
    KP_Prior = 9,
    KP_Insert = 10,
}

-- Switch workspaces with mod + [0-9]
-- Move active window to a workspace with mod + SHIFT + [0-9]
for n = 0, 9 do
    local ws = (n == 0) and 10 or n
    hl.bind(mod .. " + " .. tostring(n), hl.dsp.focus({ workspace = ws }))
    hl.bind(mod .. " + SHIFT + " .. tostring(n), hl.dsp.window.move({ workspace = ws }))
end
for key, ws in pairs(numpad) do
    hl.bind(mod .. " + " .. key, hl.dsp.focus({ workspace = ws }))
    hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = ws }))
end

-- Navigate workspaces on the current monitor
hl.bind(mod .. " + CTRL + right", hl.dsp.focus({ workspace = "+1" }))
hl.bind(mod .. " + CTRL + left", hl.dsp.focus({ workspace = "-1" }))
hl.bind(mod .. " + SHIFT + CTRL + right", hl.dsp.window.move({ workspace = "+1" }))
hl.bind(mod .. " + SHIFT + CTRL + left", hl.dsp.window.move({ workspace = "-1" }))

-- Jump back to the last workspace; repeats bounce between the two when
-- binds:allow_workspace_cycles is on.
hl.bind(mod .. " + grave", hl.dsp.focus({ workspace = "previous" }))

-- Special workspace (scratchpad)
hl.bind(mod .. " + minus", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mod .. " + SHIFT + minus", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mod + scroll
hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

----------------------------
---- MOUSE: MOVE/RESIZE ----
----------------------------

hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

--------------------------
---- MULTIMEDIA KEYS  ----
--------------------------

-- Volume & brightness (locked + repeating); the shell renders the OSD
hl.bind("XF86AudioRaiseVolume", exec("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", exec("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", exec("brightnessctl set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", exec("brightnessctl set 5%-"), { locked = true, repeating = true })

-- Media (requires playerctl)
hl.bind("XF86AudioNext", exec("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", exec("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", exec("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", exec("playerctl previous"), { locked = true })

------------------------
---- RESIZE SUBMAP  ----
------------------------

hl.bind(mod .. " + R", hl.dsp.submap("resize"))
hl.define_submap("resize", function()
    hl.bind("right", hl.dsp.window.resize({ x = 20, y = 0 }), { repeating = true })
    hl.bind("left", hl.dsp.window.resize({ x = -20, y = 0 }), { repeating = true })
    hl.bind("up", hl.dsp.window.resize({ x = 0, y = -20 }), { repeating = true })
    hl.bind("down", hl.dsp.window.resize({ x = 0, y = 20 }), { repeating = true })
    hl.bind("escape", hl.dsp.submap("reset"))
end)

---------------------
---- SCREENSHOT  ----
---------------------

hl.bind("Print", exec("qs ipc call screenshot open region"))
hl.bind("SHIFT + Print", exec("qs ipc call screenshot grabScreen"))

-- Screen recording; CTRL + Print also stops an in-progress recording
hl.bind("CTRL + Print", exec("qs ipc call recorder toggle"))
hl.bind("CTRL + SHIFT + Print", exec("qs ipc call recorder startFocused"))

--------------------------
---- WINDOW GROUPING  ----
--------------------------

hl.bind(mod .. " + G", hl.dsp.group.toggle()) -- Create or disband a group
hl.bind(mod .. " + Tab", hl.dsp.group.next()) -- Cycle forward through group members

-----------------
---- MISC    ----
-----------------

hl.bind("ALT + Tab", hl.dsp.window.cycle_next()) -- focus another window
hl.bind("CTRL + ALT + Delete", exec(terminal .. " -c btop"))
hl.bind(mod .. " + I", exec('XDG_CURRENT_DESKTOP="gnome" gnome-control-center'))
hl.bind(mod .. " + A", exec(terminal .. " -c opencode"))
