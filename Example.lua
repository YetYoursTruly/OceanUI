--[[
    OceanUI example / template sheet.
    Copy any block, rename it, and put your code where the comments say.
]]

-- Load the library. The Loader fetches every module in the OceanUI folder for you.

-- Option A: from GitHub (upload the whole OceanUI folder, then use your raw links)
getgenv().OceanUIBase = "https://raw.githubusercontent.com/YetYoursTruly/OceanUI/main/"
local OceanUI = loadstring(game:HttpGet(getgenv().OceanUIBase .. "Loader.lua"))()

-- Option B: from your executor's workspace folder (put the OceanUI folder inside it)
-- getgenv().OceanUILocal = "OceanUI"
-- local OceanUI = loadstring(readfile("OceanUI/Loader.lua"))()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function getHumanoid()
    local character = LocalPlayer.Character
    return character and character:FindFirstChildOfClass("Humanoid")
end

--==================================================
-- CUSTOM NUMBER TYPES
--==================================================
-- Shows "Moving 1 stud", "Moving 12 studs"
OceanUI.RegisterUnit("Moving", {
    Prefix = "Moving ",
    Singular = "stud",
    Plural = "studs",
})

-- Full control with a function (here: studs/s shown as mph)
OceanUI.RegisterUnit("SpeedMPH", {
    Format = function(value)
        return string.format("%.1f mph", value * 0.682)
    end,
})

--==================================================
-- WINDOW
--==================================================
local Window = OceanUI:CreateWindow({
    Title = "OceanUI Example",
    Size = Vector2.new(320, 480),
    ToggleKey = Enum.KeyCode.RightShift, -- optional show/hide key
})

--==================================================
-- TOGGLES
--==================================================
Window:AddSection("Movement")

-- "When enabled do speed 250, when disabled put it back"
Window:AddToggle({
    Name = "Speed 250",
    Flag = "Speed",
    Default = false,

    OnEnable = function()
        local humanoid = getHumanoid()
        if humanoid then
            humanoid.WalkSpeed = 250
        end
    end,

    OnDisable = function()
        local humanoid = getHumanoid()
        if humanoid then
            humanoid.WalkSpeed = 16
        end
    end,
})

-- "While enabled keep doing something" (runs every 0.1s while ON)
Window:AddToggle({
    Name = "Keep Jump Power",
    Flag = "KeepJump",

    Interval = 0.1,
    Loop = function(dt)
        local humanoid = getHumanoid()
        if humanoid then
            humanoid.UseJumpPower = true
            humanoid.JumpPower = 100
        end
    end,

    OnDisable = function()
        local humanoid = getHumanoid()
        if humanoid then
            humanoid.JumpPower = 50
        end
    end,
})

-- Same thing, but attached AFTER creation
local noclip = Window:AddToggle({ Name = "Noclip" })

noclip:Loop(function()
    local character = LocalPlayer.Character
    if not character then
        return
    end
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end)

--==================================================
-- SLIDER
--==================================================
Window:AddSlider({
    Name = "WalkSpeed",
    Min = 16,
    Max = 250,
    Default = 16,
    Step = 1,
    Unit = "SpeedMPH", -- uses the custom unit registered above

    Callback = function(value)
        local humanoid = getHumanoid()
        if humanoid then
            humanoid.WalkSpeed = value
        end
    end,
})

--==================================================
-- NUMBER
--==================================================
Window:AddNumber({
    Name = "Distance",
    Min = 0,
    Max = 500,
    Default = 1,
    Step = 1,
    Unit = "Moving", -- "Moving 1 stud" / "Moving 25 studs"

    Callback = function(value)
        print("Distance set to", value)
    end,
})

--==================================================
-- STRING
--==================================================
Window:AddSection("Misc")

Window:AddString({
    Name = "Chat Message",
    Placeholder = "Say something...",
    -- Live = true,  -- fire on every keystroke instead of on Enter / unfocus

    Callback = function(text)
        print("Message:", text)
    end,
})

--==================================================
-- DROPDOWNS
--==================================================
-- Auto-updating player list (re-reads every time it opens)
local targetDropdown = Window:AddDropdown({
    Name = "Target",
    Flag = "Target",
    Options = OceanUI.PlayerList,
    Placeholder = "Select a player...",

    Callback = function(playerName)
        local target = OceanUI.GetPlayer(playerName) -- Player instance, or nil
        print("Target:", target)
    end,
})

-- Static options, multi-select
Window:AddDropdown({
    Name = "Features",
    Options = { "ESP", "Aimbot", "Fly" },
    Multi = true,
    Default = { "ESP" },

    Callback = function(selectedList)
        print("Selected:", table.concat(selectedList, ", "))
    end,
})

--==================================================
-- BUTTON
--==================================================
Window:AddButton({
    Name = "Do Something",

    Callback = function()
        local target = OceanUI.GetPlayer(OceanUI.Flags.Target)
        if not target then
            warn("No target selected")
            return
        end

        print("Running on", target.Name)
        -- your code here
    end,
})

--==================================================
-- READING VALUES ANYWHERE
--==================================================
-- OceanUI.Flags.Speed        --> true / false
-- OceanUI.Flags.Target       --> selected player name (or nil)
-- toggle:Get()  toggle:Set(true)  toggle:OnChanged(function(v) end)