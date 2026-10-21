
--[[ Core/Loading.lua : OceanUI loading overlay and social links. ]]

local OceanUI, Util = ...
if not Util then
    local shared = (type(getgenv) == "function" and getgenv() or _G).OceanUIShared
    OceanUI, Util = shared.OceanUI, shared.Util
end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local new = Util.new
local addCorner = Util.addCorner
local tween = Util.tween
local fetchIcon = Util.fetchIcon

local YOUTUBE_URL = "https://www.youtube.com/@YetYoursTruly"
local YOUTUBE_RED = Color3.fromRGB(255, 90, 90)
local DEFAULT_HINT = "Click to copy any of my social links"

local PHRASES = {
    "Sailing an ocean",
    "Crying an ocean",
    "Teaching fish to swim",
    "Bribing a seagull",
    "Asking a crab for directions",
    "Untangling a kraken",
    "Polishing the waves",
    "Counting every drop",
    "Looking for a lost fish",
    "Wringing out the sea",
    "Waiting for the tide",
    "Gently drowning",
}

local Loading = {}
OceanUI.Loading = Loading

local gui
local session
local shownAt = 0

local function minTime()
    local value = Util.env.OceanUIMinLoadTime
    return type(value) == "number" and value or 1.5
end

local function pickPhrase(last)
    local choice = PHRASES[math.random(#PHRASES)]
    while choice == last and #PHRASES > 1 do
        choice = PHRASES[math.random(#PHRASES)]
    end
    return choice
end

local function copyToClipboard(text)
    local env = Util.env
    local fn = env.setclipboard or env.toclipboard

    if not fn and type(env.Clipboard) == "table" then
        fn = env.Clipboard.set
    end

    if type(fn) ~= "function" then
        return false
    end

    local ok, result = pcall(fn, text)
    return ok and result ~= false
end

function Loading.Show()
    if gui then
        return
    end

    local theme = OceanUI.Theme

    pcall(function()
        local old = Util.getGuiParent():FindFirstChild("OceanUILoading")
        if old then
            old:Destroy()
        end
    end)

    local newGui = new("ScreenGui", {
        Name = "OceanUILoading",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 999,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })

    gui = newGui
    shownAt = os.clock()

    local dim = new("Frame", {
        Name = "Dim",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Active = true,
    }, newGui)

    local center = new("CanvasGroup", {
        Name = "Center",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(340, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        GroupTransparency = 1,
    }, newGui)

    new("UIListLayout", {
        Padding = UDim.new(0, 0),
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
    }, center)

    -- Same accent dot used in every OceanUI window title bar.
    local dot = new("Frame", {
        Name = "LoadingDot",
        Size = UDim2.fromOffset(8, 8),
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        LayoutOrder = 1,
    }, center)

    addCorner(dot, 4)

    local phraseLabel = new("TextLabel", {
        Name = "Phrase",
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1,
        Text = "",
        RichText = true,
        TextColor3 = theme.Text,
        TextSize = 20,
        Font = Enum.Font.GothamBold,
        LayoutOrder = 2,
    }, center)

    -- Extra space separates the loading message from social links.
    new("Frame", {
        Name = "SocialSpacing",
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundTransparency = 1,
        LayoutOrder = 3,
    }, center)

    -- Transparent clickable area; no visible button frame.
    local button = new("TextButton", {
        Name = "YouTube",
        Size = UDim2.fromOffset(40, 32),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        LayoutOrder = 4,
    }, center)

    local fallback = new("TextLabel", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "▶",
        TextColor3 = YOUTUBE_RED,
        TextSize = 25,
        Font = Enum.Font.GothamBold,
    }, button)

    local icon = new("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(30, 30),
        BackgroundTransparency = 1,
        ImageColor3 = YOUTUBE_RED,
        ScaleType = Enum.ScaleType.Fit,
        Visible = false,
    }, button)

    local hint = new("TextLabel", {
        Name = "Hint",
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundTransparency = 1,
        Text = DEFAULT_HINT,
        TextColor3 = theme.Muted,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        TextWrapped = true,
        LayoutOrder = 5,
    }, center)

    local hintToken

    button.Activated:Connect(function()
        if copyToClipboard(YOUTUBE_URL) then
            hint.TextColor3 = theme.Success
            hint.Text = "Copied to clipboard!\n" .. YOUTUBE_URL
        else
            hint.TextColor3 = theme.Danger
            hint.Text = "Copy this link:\n" .. YOUTUBE_URL
        end

        local token = {}
        hintToken = token

        task.delay(5, function()
            if hintToken == token and hint.Parent then
                hint.TextColor3 = theme.Muted
                hint.Text = DEFAULT_HINT
            end
        end)
    end)

    local mounted = pcall(function()
        newGui.Parent = Util.getGuiParent()
    end)

    if not mounted or not newGui.Parent then
        newGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    local mySession = {
        alive = true,
        dim = dim,
        center = center,
    }
    session = mySession

    tween(dim, { BackgroundTransparency = 0.3 }, 0.3)
    tween(center, { GroupTransparency = 0 }, 0.3)

    task.spawn(function()
        local phrase = pickPhrase(nil)
        local dots = 0
        local ticks = 0

        while mySession.alive and phraseLabel.Parent do
            phraseLabel.Text = string.format(
                '%s%s<font transparency="1">%s</font>',
                phrase,
                string.rep(".", dots),
                string.rep(".", 3 - dots)
            )

            task.wait(0.4)

            dots = (dots + 1) % 4
            ticks += 1

            if ticks % 6 == 0 then
                phrase = pickPhrase(phrase)
            end
        end
    end)

    task.spawn(function()
        local startedAt = os.clock()

        while type(Util.env.FetchImage) ~= "function"
            and os.clock() - startedAt < 15 do
            task.wait(0.1)
        end

        local asset = fetchIcon("youtube")
        if asset and icon.Parent then
            icon.Image = asset
            icon.Visible = true
            fallback.Visible = false
        end
    end)
end

function Loading.Hide(immediate)
    local g, s = gui, session
    if not g or not s then
        return
    end

    gui, session = nil, nil

    if immediate then
        s.alive = false
        g:Destroy()
        return
    end

    task.spawn(function()
        local remaining = minTime() - (os.clock() - shownAt)
        if remaining > 0 then
            task.wait(remaining)
        end

        s.alive = false

        tween(s.dim, { BackgroundTransparency = 1 }, 0.3)
        tween(s.center, { GroupTransparency = 1 }, 0.3)
        task.wait(0.35)

        g:Destroy()
    end)
end
