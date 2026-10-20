--[[ Elements/Slider.lua : draggable slider with Min / Max / Step / Unit. ]]

local OceanUI, Util = ...

local Window = OceanUI.Window

local new = Util.new
local addCorner = Util.addCorner
local makeLabel = Util.makeLabel
local isPointerStart = Util.isPointerStart
local makeSnapper = Util.makeSnapper
local fire = Util.fire

function Window:AddSlider(options)
    options = options or {}
    local theme = OceanUI.Theme

    local min = options.Min or 0
    local max = options.Max or 100
    local step = options.Step or 1
    local snap = makeSnapper(min, max, step)

    local s = self:_register("Slider", options, snap(options.Default or min))
    s.Min, s.Max, s.Step, s.Unit = min, max, step, options.Unit

    local row = self:_row(50)
    s.Row = row

    makeLabel({
        Position = UDim2.new(0, 10, 0, 7),
        Size = UDim2.new(0.5, -10, 0, 16),
        Text = s.Name,
    }, row)

    local valueLabel = makeLabel({
        Position = UDim2.new(0.5, 0, 0, 7),
        Size = UDim2.new(0.5, -10, 0, 16),
        TextColor3 = theme.Accent,
        TextXAlignment = Enum.TextXAlignment.Right,
    }, row)

    local track = new("Frame", {
        Position = UDim2.new(0, 10, 0, 34),
        Size = UDim2.new(1, -20, 0, 6),
        BackgroundColor3 = theme.Button,
        BorderSizePixel = 0,
    }, row)

    addCorner(track, 3)

    local fill = new("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
    }, track)

    addCorner(fill, 3)

    local knob = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(14, 14),
        BackgroundColor3 = theme.Text,
        BorderSizePixel = 0,
    }, track)

    addCorner(knob, 7)

    local hit = new("TextButton", {
        Position = UDim2.new(0, 0, 0, 22),
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1,
        Text = "",
    }, row)

    local function render()
        local alpha = max > min and (s.Value - min) / (max - min) or 0
        fill.Size = UDim2.new(alpha, 0, 1, 0)
        knob.Position = UDim2.new(alpha, 0, 0.5, 0)
        valueLabel.Text = OceanUI.FormatValue(s.Unit, s.Value)
    end

    function s:Set(value, silent)
        value = tonumber(value)
        if not value then
            return
        end

        value = snap(value)
        if value == self.Value then
            return
        end

        self.Value = value
        OceanUI.Flags[self.Flag] = value
        render()

        if not silent then
            fire(self, value)
        end
    end

    local function setFromX(x)
        local width = track.AbsoluteSize.X
        local alpha = width > 0 and math.clamp((x - track.AbsolutePosition.X) / width, 0, 1) or 0
        s:Set(min + alpha * (max - min))
    end

    hit.InputBegan:Connect(function(input)
        if not isPointerStart(input) then
            return
        end

        self.Body.ScrollingEnabled = false
        setFromX(input.Position.X)

        self:_beginDrag(input, function(pos)
            setFromX(pos.X)
        end, function()
            self.Body.ScrollingEnabled = true
        end)
    end)

    render()

    return s
end
