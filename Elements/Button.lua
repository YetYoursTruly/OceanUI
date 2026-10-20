--[[ Elements/Button.lua : AddButton, AddLabel, AddSection. ]]

local OceanUI, Util = ...

local Window = OceanUI.Window

local new = Util.new
local makeLabel = Util.makeLabel
local tween = Util.tween
local fire = Util.fire

function Window:AddSection(text)
    self._order += 1

    local label = makeLabel({
        Name = "Section",
        Size = UDim2.new(1, 0, 0, 20),
        Text = string.upper(tostring(text)),
        TextColor3 = OceanUI.Theme.Muted,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        LayoutOrder = self._order,
    }, self.Body)

    return {
        SetText = function(_, newText)
            label.Text = string.upper(tostring(newText))
        end,
        Destroy = function()
            label:Destroy()
        end,
    }
end

function Window:AddLabel(text)
    self._order += 1

    local label = new("TextLabel", {
        Name = "Label",
        Size = UDim2.new(1, 0, 0, 18),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Text = tostring(text),
        TextColor3 = OceanUI.Theme.Muted,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        LayoutOrder = self._order,
    }, self.Body)

    return {
        SetText = function(_, newText)
            label.Text = tostring(newText)
        end,
        Destroy = function()
            label:Destroy()
        end,
    }
end

function Window:AddButton(options)
    options = options or {}
    local theme = OceanUI.Theme

    local b = self:_register("Button", options, nil)
    local row = self:_row(34)
    b.Row = row

    row.BackgroundColor3 = theme.Accent
    row.BackgroundTransparency = 0

    local button = new("TextButton", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = options.Name or "Button",
        TextColor3 = theme.Background,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
    }, row)

    button.MouseEnter:Connect(function()
        tween(row, { BackgroundColor3 = Color3.fromRGB(122, 210, 250) }, 0.12)
    end)
    button.MouseLeave:Connect(function()
        tween(row, { BackgroundColor3 = theme.Accent }, 0.15)
    end)

    function b:Click()
        fire(self)
    end

    button.Activated:Connect(function()
        b:Click()
    end)

    return b
end
