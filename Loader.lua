--[[
    OceanUI Loader
    Fetches every module in order and hands them the shared OceanUI / Util tables.

    Remote (default):
        loadstring(game:HttpGet("https://raw.githubusercontent.com/YOU/REPO/main/OceanUI/Loader.lua"))()

    Custom base URL (set BEFORE loading, must end with "/"):
        getgenv().OceanUIBase = "https://raw.githubusercontent.com/YOU/REPO/main/OceanUI/"

    Local (files saved in your executor's workspace folder, e.g. workspace/OceanUI/...):
        getgenv().OceanUILocal = "OceanUI"
        loadstring(readfile("OceanUI/Loader.lua"))()

    Module layout:
        Core/Theme.lua      colors
        Core/Util.lua       instance helpers, signals, snapping
        Core/Units.lua      custom number types
        Core/Players.lua    player list helpers
        Core/Element.lua    base element methods
        Core/Window.lua     window, dragging, resizing, layout
        Elements/*.lua      one file per element type
]]

local env = _G
if type(getgenv) == "function" then
    local ok, result = pcall(getgenv)
    if ok and type(result) == "table" then
        env = result
    end
end

-- Remove a previous copy if the script is executed twice.
if type(env.OceanUI) == "table" and type(env.OceanUI.Destroy) == "function" then
    pcall(env.OceanUI.Destroy, env.OceanUI)
end

local BASE_URL = env.OceanUIBase or "https://raw.githubusercontent.com/YOU/REPO/main/OceanUI/"
local LOCAL_FOLDER = env.OceanUILocal

-- Order matters: later files use what earlier files define.
local MODULES = {
    "Core/Theme.lua",
    "Core/Util.lua",
    "Core/Loading.lua"
    "Core/Units.lua",
    "Core/Players.lua",
    "Core/Element.lua",
    "Core/Window.lua",

    "Elements/Toggle.lua",
    "Elements/Slider.lua",
    "Elements/Number.lua",
    "Elements/String.lua",
    "Elements/Dropdown.lua",
    "Elements/Button.lua", -- Button, Label, Section
}

local function readSource(path)
    if LOCAL_FOLDER then
        return readfile(LOCAL_FOLDER .. "/" .. path)
    end
    return game:HttpGet(BASE_URL .. path)
end

local OceanUI = {
    Version = "2.0",
    Flags = {},
    Units = {},
    _windows = {},
}

local Util = {
    env = env,
}

-- Fallback channel for executors that don't forward extra arguments to loadstring chunks.
env.OceanUIShared = { OceanUI = OceanUI, Util = Util }

for _, path in ipairs(MODULES) do
    local okRead, source = pcall(readSource, path)
    if not okRead then
        error(string.format("[OceanUI] Could not read %s: %s", path, tostring(source)), 0)
    end

    local chunk, compileError = loadstring(source, "=OceanUI/" .. path)
    if not chunk then
        error(string.format("[OceanUI] Syntax error in %s: %s", path, tostring(compileError)), 0)
    end

    local okRun, runError = pcall(chunk, OceanUI, Util)
    if not okRun then
        error(string.format("[OceanUI] Error while running %s: %s", path, tostring(runError)), 0)
    end

    if path == "Core/Loading.lua" then
        OceanUI.Loading.Show()
        task.wait()
    end
end

if OceanUI.Loading then
    OceanUI.Loading.Hide()
end

env.OceanUIShared = nil
env.OceanUI = OceanUI

return OceanUI