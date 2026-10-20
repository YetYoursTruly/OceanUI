--[[ Elements/Number.lua : number input with +/- buttons, typed entry, Min / Max / Step / Unit. ]]

local OceanUI, Util = ...

local Window = OceanUI.Window

local new = Util.new
local addCorner = Util.addCorner
local makeLabel = Util.makeLabel
local makeSnapper = Util.makeSnapper
local formatNumber = Util.formatNumber
local fire = Util.fire

function Window:AddNumber(options)
    options = options or {}
    local theme = OceanUI.Theme

    local min = options.Min or -math.huge
    local max = options.Max or math.huge
    local step = options.Step or 1
    local snap = makeSnapper(min, max, step)

    local fallback = min ~= -math.huge and min or 0
    local n = self:_register("Number", options, snap(options.Default or fallback))
    n.Min, n.Max, n.Step, n.Unit = min, max, step, options.Unit

    local row = self:_row(34)
    n.Row = row

    local boxWidth = options.Unit and 120 or 70

    makeLabel({
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -(boxWidth + 74), 1, 0),
        Text = n.Name,
    }, row)

    local function stepButton(text, rightOffset)
        local button = new("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -rightOffset, 0.5, 0),
            Size = UDim2.fromOffset(24, 24),
            BackgroundColor3 = theme.Button,
            BackgroundTransparency = 0.2,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = text,
            TextColor3 = theme.Text,
            TextSize = 16,
            Font = Enum.Font.GothamBold,
        }, row)

        addCorner(button, 6)
        return button
    end

    local plus = stepButton("+", 8)

    local box = new("TextBox", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -36, 0.5, 0),
        Size = UDim2.fromOffset(boxWidth, 24),
        BackgroundColor3 = theme.Background,
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        Text = "",
        TextColor3 = theme.Text,
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ClearTextOnFocus = false,
    }, row)

    addCorner(box, 6)

    local minus = stepButton("-", 36 + boxWidth + 4)

    local function show()
        box.Text = OceanUI.FormatValue(n.Unit, n.Value)
    end

    function n:Set(value, silent)
        value = tonumber(value)
        if not value then
            show()
            return
        end

        value = snap(value)
        if value == self.Value then
            show()
            return
        end

        self.Value = value
        OceanUI.Flags[self.Flag] = value
        show()

        if not silent then
            fire(self, value)
        end
    end

    local increment = step > 0 and step or 1

    plus.Activated:Connect(function()
        n:Set(n.Value + increment)
    end)

    minus.Activated:Connect(function()
        n:Set(n.Value - increment)
    end)

    box.Focused:Connect(function()
        box.Text = formatNumber(n.Value, 4)
    end)

    box.FocusLost:Connect(function()
        local typed = tonumber(box.Text) or tonumber(string.match(box.Text, "-?%d+%.?%d*"))
        if typed then
            n:Set(typed)
        end
        show()
    end)

    show()

    return n
end
