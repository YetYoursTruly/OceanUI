--[[ Elements/String.lua : text input. Fires on Enter/unfocus, or every keystroke with Live = true. ]]

local OceanUI, Util = ...
if not Util then
    -- Some executors don't pass extra arguments to loadstring chunks; read the shared tables instead.
    local shared = (type(getgenv) == "function" and getgenv() or _G).OceanUIShared
    OceanUI, Util = shared.OceanUI, shared.Util
end

local Window = OceanUI.Window

local new = Util.new
local addCorner = Util.addCorner
local addPadding = Util.addPadding
local makeLabel = Util.makeLabel
local fire = Util.fire

function Window:AddString(options)
    options = options or {}
    local theme = OceanUI.Theme

    local str = self:_register("String", options, options.Default or "")
    local row = self:_row(34)
    str.Row = row

    makeLabel({
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(0.45, -10, 1, 0),
        Text = str.Name,
    }, row)

    local box = new("TextBox", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.new(0.55, -8, 0, 24),
        BackgroundColor3 = theme.Background,
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        Text = str.Value,
        PlaceholderText = options.Placeholder or "Type here...",
        PlaceholderColor3 = theme.Muted,
        TextColor3 = theme.Text,
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ClearTextOnFocus = options.ClearOnFocus == true,
    }, row)

    addCorner(box, 6)
    addPadding(box, 8, 8, 0, 0)

    function str:Set(value, silent)
        value = tostring(value or "")
        if value == self.Value then
            return
        end

        self.Value = value
        box.Text = value
        OceanUI.Flags[self.Flag] = value

        if not silent then
            fire(self, value)
        end
    end

    local function commit()
        if box.Text ~= str.Value then
            str.Value = box.Text
            OceanUI.Flags[str.Flag] = box.Text
            fire(str, box.Text)
        end
    end

    if options.Live then
        box:GetPropertyChangedSignal("Text"):Connect(commit)
    else
        box.FocusLost:Connect(commit)
    end

    return str
end