--[[ Elements/Dropdown.lua : single or multi select dropdown with an inline list. ]]

local OceanUI, Util = ...

local Window = OceanUI.Window

local new = Util.new
local addCorner = Util.addCorner
local addPadding = Util.addPadding
local makeLabel = Util.makeLabel
local fire = Util.fire

function Window:AddDropdown(options)
    options = options or {}
    local theme = OceanUI.Theme

    local multi = options.Multi == true
    local maxListHeight = options.MaxHeight or 150

    local d = self:_register("Dropdown", options, multi and {} or nil)
    d.Multi = multi

    local optionSource = options.Options or {}
    local optionList = {}
    local selected = {}
    local buttons = {}
    local open = false

    local row = self:_row(34)
    d.Row = row
    row.AutomaticSize = Enum.AutomaticSize.Y

    new("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, row)

    local head = new("TextButton", {
        Name = "Head",
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundTransparency = 1,
        Text = "",
        LayoutOrder = 1,
    }, row)

    makeLabel({
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(0.4, -10, 1, 0),
        Text = d.Name,
    }, head)

    local valueLabel = makeLabel({
        Position = UDim2.new(0.4, 0, 0, 0),
        Size = UDim2.new(0.6, -30, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Right,
        TextSize = 12,
    }, head)

    local chevron = new("TextLabel", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.fromOffset(16, 16),
        BackgroundTransparency = 1,
        Text = "▾",
        TextColor3 = theme.Muted,
        TextSize = 14,
        Font = Enum.Font.Gotham,
    }, head)

    local holder = new("ScrollingFrame", {
        Name = "Options",
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = theme.Border,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Visible = false,
        LayoutOrder = 2,
    }, row)

    new("UIListLayout", {
        Padding = UDim.new(0, 2),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, holder)

    addPadding(holder, 6, 6, 2, 6)

    local function syncMultiValue()
        local list, seen = {}, {}

        for _, option in ipairs(optionList) do
            if selected[option] then
                table.insert(list, option)
                seen[option] = true
            end
        end

        for option in pairs(selected) do
            if not seen[option] then
                table.insert(list, option)
            end
        end

        d.Value = list
    end

    local function updateText()
        local hasValue

        if multi then
            local parts = {}
            for _, value in ipairs(d.Value) do
                table.insert(parts, tostring(value))
            end
            hasValue = #parts > 0
            valueLabel.Text = hasValue and table.concat(parts, ", ") or "None"
        else
            hasValue = d.Value ~= nil
            valueLabel.Text = hasValue and tostring(d.Value) or (options.Placeholder or "Select...")
        end

        valueLabel.TextColor3 = hasValue and theme.Text or theme.Muted
    end

    local function paintOptions()
        for option, button in pairs(buttons) do
            local on
            if multi then
                on = selected[option] == true
            else
                on = d.Value == option
            end

            button.BackgroundColor3 = on and theme.Accent or theme.Button
            button.BackgroundTransparency = on and 0 or 0.35
            button.TextColor3 = on and theme.Background or theme.Text
        end
    end

    local function sizeHolder()
        local count = math.max(1, #optionList)
        holder.Size = UDim2.new(1, 0, 0, math.min(count * 28 + 8, maxListHeight))
    end

    local function rebuild()
        local source = optionSource

        if type(source) == "function" then
            local ok, result = pcall(source)
            source = (ok and type(result) == "table") and result or {}
        end

        optionList = table.clone(source)

        for _, child in ipairs(holder:GetChildren()) do
            if child:IsA("GuiObject") then
                child:Destroy()
            end
        end

        buttons = {}

        if #optionList == 0 then
            makeLabel({
                Size = UDim2.new(1, 0, 0, 26),
                Text = "No options",
                TextColor3 = theme.Muted,
                TextSize = 12,
            }, holder)
        end

        for index, option in ipairs(optionList) do
            local button = new("TextButton", {
                Name = tostring(option),
                Size = UDim2.new(1, 0, 0, 26),
                BackgroundColor3 = theme.Button,
                BackgroundTransparency = 0.35,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Text = tostring(option),
                TextColor3 = theme.Text,
                TextSize = 12,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                LayoutOrder = index,
            }, holder)

            addCorner(button, 6)
            addPadding(button, 10, 10, 0, 0)

            buttons[option] = button

            button.Activated:Connect(function()
                if multi then
                    local nextList = {}
                    local found = false

                    for _, value in ipairs(d.Value) do
                        if value == option then
                            found = true
                        else
                            table.insert(nextList, value)
                        end
                    end

                    if not found then
                        table.insert(nextList, option)
                    end

                    d:Set(nextList)
                else
                    d:Set(option)
                    d:Close()
                end
            end)
        end

        sizeHolder()
        paintOptions()
    end

    function d:Set(value, silent)
        if multi then
            local newSelected = {}
            if type(value) == "table" then
                for _, item in ipairs(value) do
                    newSelected[item] = true
                end
            elseif value ~= nil then
                newSelected[value] = true
            end
            selected = newSelected
            syncMultiValue()
        else
            if self.Value == value then
                return
            end
            self.Value = value
        end

        OceanUI.Flags[self.Flag] = self.Value
        updateText()
        paintOptions()

        if not silent then
            fire(self, multi and table.clone(self.Value) or self.Value)
        end
    end

    local function validate()
        local inList = {}
        for _, option in ipairs(optionList) do
            inList[option] = true
        end

        if multi then
            local keep, changed = {}, false
            for _, value in ipairs(d.Value) do
                if inList[value] then
                    table.insert(keep, value)
                else
                    changed = true
                end
            end
            if changed then
                d:Set(keep)
            end
        elseif d.Value ~= nil and not inList[d.Value] then
            d:Set(nil)
        end
    end

    -- Re-reads the options (calls the Options function if you passed one).
    function d:Refresh()
        rebuild()
        validate()
    end

    function d:SetOptions(list)
        optionSource = list or {}
        self:Refresh()
    end

    function d:Open()
        if open then
            return
        end

        if type(optionSource) == "function" then
            self:Refresh()
        end

        open = true
        holder.Visible = true
        sizeHolder()
        chevron.Text = "▴"
    end

    function d:Close()
        open = false
        holder.Visible = false
        chevron.Text = "▾"
    end

    head.Activated:Connect(function()
        if open then
            d:Close()
        else
            d:Open()
        end
    end)

    rebuild()
    d:Set(options.Default, true)
    updateText()
    paintOptions()

    return d
end
