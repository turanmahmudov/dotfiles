------------------
---- MONITORS ----
------------------

-- The display layout differs per machine, so the quickshell display panel
-- generates it into monitors_generated.lua, which git does not track.
-- See https://wiki.hypr.land/Configuring/Basics/Monitors/

if not pcall(require, "monitors_generated") then
    hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })
end
