dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

require("default.hypr.omarchy")

hl.monitor({ output = "", mode = "highrr", position = "auto", scale = 1 })

require("settings")
require("monitors")
require("bindings")
require("rules")

local state = (os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")) .. "/dotfiles"
pcall(dofile, state .. "/monitors.lua")
pcall(dofile, state .. "/workspaces.lua")

require("default.hypr.toggles")
