--[[ Elements/Separator.lua : AddSeparator - a thin divider line, optionally with centered text. ]]

local OceanUI, Util = ...
if not Util then
    -- Some executors don't pass extra arguments to loadstring chunks; read the shared tables instead.
    local shared = (type(getgenv) == "function" and getgenv() or _G).OceanUIShared
    OceanUI, Util = shared.OceanUI, shared.Util
end

local Window = OceanUI.Window

local new = Util.new

--[[
    Window:AddSeparator(options)

    options can be:
        nil / {}              plain line
        "Some text"           line with centered text
        {
            Text = "Title",   optional centered text
            Height = 14,      total row height (default 14, or 18 with text)
            Color = Color3,   line color (default Theme.Border)
            Transparency = 0, line transparency (default 0.2)
        }

    Returns an object with :SetText(text), :SetVisible(bool) and :Destroy().
]]
function Window:AddSeparator(options)
    if type(options) == "string" then
        options = { Text = options }
    end
    options = options or {}

    local theme = OceanUI.Theme
    local lineColor = options.Color or theme.Border
    local lineTransparency = options.Transparency or 0.2

    self._order += 1

    local hasText = options.Text ~= nil and options.Text ~= ""

    local row = new("Frame", {
        Name = "Separator",
        Size = UDim2.new(1, 0, 0, options.Height or (hasText and 18 or 14)),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        LayoutOrder = self._order,
    }, self.Body)

    local function makeLine(name)
        return new("Frame", {
            Name = name,
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = lineColor,
            BackgroundTransparency = lineTransparency,
            BorderSizePixel = 0,
        }, row)
    end

    local single = makeLine("Line")
    local left = makeLine("LineLeft")
    local right = makeLine("LineRight")

    local label = new("TextLabel", {
        Name = "Text",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromOffset(0, 14),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = theme.Muted,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
    }, row)

    local PAD = 8 -- gap between the text and each line

    local function layout()
        local show = hasText
        single.Visible = not show
        left.Visible = show
        right.Visible = show
        label.Visible = show

        single.Position = UDim2.new(0, 0, 0.5, 0)
        single.Size = UDim2.new(1, 0, 0, 1)

        if show then
            -- Lines stretch from each edge up to the text (plus padding).
            local half = label.AbsoluteSize.X / 2 + PAD
            left.Position = UDim2.new(0, 0, 0.5, 0)
            left.Size = UDim2.new(0.5, -half, 0, 1)
            right.AnchorPoint = Vector2.new(1, 0.5)
            right.Position = UDim2.new(1, 0, 0.5, 0)
            right.Size = UDim2.new(0.5, -half, 0, 1)
        end
    end

    label:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)

    local function setText(text)
        hasText = text ~= nil and text ~= ""
        label.Text = hasText and string.upper(tostring(text)) or ""
        layout()
    end

    setText(options.Text)

    return {
        Row = row,
        SetText = function(_, text)
            setText(text)
        end,
        SetVisible = function(_, visible)
            row.Visible = visible
        end,
        Destroy = function()
            row:Destroy()
        end,
    }
end