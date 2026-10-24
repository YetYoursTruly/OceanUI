--[[ Elements/Button.lua : AddButton, AddLabel, AddSection. ]]

local OceanUI, Util = ...
if not Util then
    -- Some executors don't pass extra arguments to loadstring chunks; read the shared tables instead.
    local shared = (type(getgenv) == "function" and getgenv() or _G).OceanUIShared
    OceanUI, Util = shared.OceanUI, shared.Util
end

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

--[[
    Window:AddButton(options)
        Name     = "Text on the button"
        Callback = function() end
        Style    = "Accent" (default) | "Secondary" | "Danger"
        Disabled = false

    Returns an element with :Click(), :SetText(text), :SetDisabled(bool).
]]
function Window:AddButton(options)
    options = options or {}
    local theme = OceanUI.Theme

    local b = self:_register("Button", options, nil)
    local row = self:_row(34)
    b.Row = row

    local styles = {
        Accent = { Fill = theme.Accent, Hover = Color3.fromRGB(122, 210, 250), Text = theme.Background },
        Secondary = { Fill = theme.Button, Hover = Color3.fromRGB(54, 84, 106), Text = theme.Text },
        Danger = { Fill = theme.Danger, Hover = Color3.fromRGB(250, 165, 165), Text = theme.Background },
    }
    local style = styles[options.Style] or styles.Accent

    row.BackgroundColor3 = style.Fill
    row.BackgroundTransparency = 0

    local button = new("TextButton", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Text = options.Name or "Button",
        TextColor3 = style.Text,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
    }, row)

    b.Disabled = options.Disabled == true

    local function render()
        button.TextTransparency = b.Disabled and 0.5 or 0
        row.BackgroundTransparency = b.Disabled and 0.5 or 0
    end
    render()

    button.MouseEnter:Connect(function()
        if not b.Disabled then
            tween(row, { BackgroundColor3 = style.Hover }, 0.12)
        end
    end)
    button.MouseLeave:Connect(function()
        tween(row, { BackgroundColor3 = style.Fill }, 0.15)
    end)
    button.MouseButton1Down:Connect(function()
        if not b.Disabled then
            tween(row, { BackgroundColor3 = style.Fill }, 0.05)
        end
    end)

    function b:Click()
        if self.Disabled then
            return
        end
        fire(self)
    end

    function b:SetText(text)
        self.Name = tostring(text)
        button.Text = self.Name
    end

    function b:SetDisabled(state)
        self.Disabled = state == true
        render()
    end

    button.Activated:Connect(function()
        b:Click()
    end)

    return b
end