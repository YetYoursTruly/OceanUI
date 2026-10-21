--[[ Core/Window.lua : window creation, dragging, resizing, minimize, layout rows. ]]

local OceanUI, Util = ...
if not Util then
    -- Some executors don't pass extra arguments to loadstring chunks; read the shared tables instead.
    local shared = (type(getgenv) == "function" and getgenv() or _G).OceanUIShared
    OceanUI, Util = shared.OceanUI, shared.Util
end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

local new = Util.new
local addCorner = Util.addCorner
local addStroke = Util.addStroke
local addPadding = Util.addPadding
local tween = Util.tween
local isPointerStart = Util.isPointerStart
local makeLabel = Util.makeLabel
local newSignal = Util.newSignal
local getGuiParent = Util.getGuiParent

local Element = OceanUI.Element

local Window = {}
Window.__index = Window

OceanUI.Window = Window

--==================================================
-- CREATE WINDOW
--==================================================

function OceanUI:CreateWindow(options)
    options = options or {}

    local theme = OceanUI.Theme
    local self = setmetatable({}, Window)

    self.Elements = {}
    self.Destroyed = false
    self._conns = {}
    self._order = 0
    self._drag = nil

    local HEADER_H = 40
    local minW, minH = 450, 300 -- Raised minimum dimensions to prevent collapsing on resize
    local maxW = options.MaxSize and options.MaxSize.X or 900 -- Extended bounds for 1440p+ setups
    local maxH = options.MaxSize and options.MaxSize.Y or 800
    local size = options.Size or Vector2.new(580, 460) -- Changed default footprint from vertical phone style to a wider desktop dashboard

    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(800, 600)

    local gui = new("ScreenGui", {
        Name = "OceanUI",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 998,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })

    self.Gui = gui

    local window = new("Frame", {
        Name = "Window",
        Size = UDim2.fromOffset(size.X, size.Y),
        Position = UDim2.fromOffset(
            math.max(0, math.floor((viewport.X - size.X) / 2)),
            math.max(0, math.floor(viewport.Y * 0.15))
        ),
        BackgroundColor3 = theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Active = true,
    }, gui)

    addCorner(window, 12)
    addStroke(window)

    local header = new("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, HEADER_H),
        BackgroundColor3 = theme.Header,
        BorderSizePixel = 0,
        Active = true,
        ZIndex = 2,
    }, window)

    addCorner(header, 12)

    local headerFill = new("Frame", {
        Name = "HeaderFill",
        Position = UDim2.new(0, 0, 1, -12),
        Size = UDim2.new(1, 0, 0, 12),
        BackgroundColor3 = theme.Header,
        BorderSizePixel = 0,
        ZIndex = 2,
    }, header)

    local headerLine = new("Frame", {
        Name = "HeaderLine",
        Position = UDim2.new(0, 0, 1, -1),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = theme.Border,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        ZIndex = 3,
    }, header)

    local dot = new("Frame", {
        Name = "Dot",
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 13, 0.5, 0),
        Size = UDim2.fromOffset(8, 8),
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        ZIndex = 3,
    }, header)

    addCorner(dot, 4)

    local titleLabel = makeLabel({
        Name = "Title",
        Position = UDim2.new(0, 28, 0, 0),
        Size = UDim2.new(1, -108, 1, 0),
        Text = options.Title or "OceanUI",
        TextSize = 15,
        Font = Enum.Font.GothamBold,
        ZIndex = 3,
    }, header)

    local function headerButton(name, text, rightOffset, color)
        local button = new("TextButton", {
            Name = name,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -rightOffset, 0.5, 0),
            Size = UDim2.fromOffset(28, 28),
            BackgroundColor3 = color,
            BackgroundTransparency = 0.35,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = text,
            TextColor3 = theme.Text,
            TextSize = 18,
            Font = Enum.Font.Gotham,
            ZIndex = 4,
        }, header)

        addCorner(button, 8)

        button.MouseEnter:Connect(function()
            tween(button, { BackgroundTransparency = 0 }, 0.12)
        end)
        button.MouseLeave:Connect(function()
            tween(button, { BackgroundTransparency = 0.35 }, 0.15)
        end)

        return button
    end

    local closeButton = headerButton("Close", "×", 8, theme.CloseButton)
    closeButton.TextSize = 22
    local minimizeButton = headerButton("Minimize", "–", 42, theme.Button)

    local body = new("ScrollingFrame", {
        Name = "Body",
        Position = UDim2.new(0, 0, 0, HEADER_H),
        Size = UDim2.new(1, 0, 1, -HEADER_H),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = theme.Border,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
    }, window)

    new("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, body)

    addPadding(body, 10, 10, 10, 28)

    self.Body = body
    self.Window = window

    local resizeHandle = new("TextButton", {
        Name = "ResizeHandle",
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -4, 1, -4),
        Size = UDim2.fromOffset(22, 22),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Text = "◢",
        TextColor3 = theme.Muted,
        TextSize = 16,
        Font = Enum.Font.Gotham,
        ZIndex = 10,
    }, window)

    --------------------------------------------------
    -- Shared drag handling (window move, resize, sliders)
    --------------------------------------------------

    function self:_connect(signal, fn)
        local connection = signal:Connect(fn)
        table.insert(self._conns, connection)
        return connection
    end

    function self:_beginDrag(input, onMove, onEnd)
        self._drag = {
            input = input.UserInputType == Enum.UserInputType.Touch and input or nil,
            onMove = onMove,
            onEnd = onEnd,
        }
    end

    self:_connect(UserInputService.InputChanged, function(input)
        local drag = self._drag
        if not drag then
            return
        end

        local isMouse = input.UserInputType == Enum.UserInputType.MouseMovement
        if isMouse or (drag.input ~= nil and input == drag.input) then
            drag.onMove(Vector2.new(input.Position.X, input.Position.Y))
        end
    end)

    self:_connect(UserInputService.InputEnded, function(input)
        local drag = self._drag
        if not drag then
            return
        end

        local mouseUp = input.UserInputType == Enum.UserInputType.MouseButton1
        if mouseUp or (drag.input ~= nil and input == drag.input) then
            self._drag = nil
            if drag.onEnd then
                drag.onEnd()
            end
        end
    end)

    -- Move window
    self:_connect(header.InputBegan, function(input)
        if not isPointerStart(input) then
            return
        end

        local start = Vector2.new(input.Position.X, input.Position.Y)
        local origin = window.AbsolutePosition

        self:_beginDrag(input, function(pos)
            local screen = gui.AbsoluteSize
            local x = math.clamp(origin.X + pos.X - start.X, 0, math.max(0, screen.X - window.AbsoluteSize.X))
            local y = math.clamp(origin.Y + pos.Y - start.Y, 0, math.max(0, screen.Y - HEADER_H))
            window.Position = UDim2.fromOffset(x, y)
        end)
    end)

    -- Resize window
    self:_connect(resizeHandle.InputBegan, function(input)
        if not isPointerStart(input) then
            return
        end

        local start = Vector2.new(input.Position.X, input.Position.Y)
        local origin = window.AbsoluteSize

        self:_beginDrag(input, function(pos)
            local screen = gui.AbsoluteSize
            local winPos = window.AbsolutePosition

            local width = math.clamp(
                origin.X + pos.X - start.X,
                minW,
                math.max(minW, math.min(maxW, screen.X - winPos.X))
            )
            local height = math.clamp(
                origin.Y + pos.Y - start.Y,
                minH,
                math.max(minH, math.min(maxH, screen.Y - winPos.Y))
            )

            window.Size = UDim2.fromOffset(width, height)
        end)
    end)

    -- Optional show/hide key
    if options.ToggleKey then
        self:_connect(UserInputService.InputBegan, function(input, processed)
            if not processed and input.KeyCode == options.ToggleKey then
                gui.Enabled = not gui.Enabled
            end
        end)
    end

    --------------------------------------------------
    -- Minimize / close
    --------------------------------------------------

    local minimized = false
    local expandedSize = window.Size

    function self:SetMinimized(state)
        if minimized == state then
            return
        end

        minimized = state

        if state then
            expandedSize = window.Size
            body.Visible = false
            resizeHandle.Visible = false
            headerFill.Visible = false
            headerLine.Visible = false
            minimizeButton.Text = "□"
            minimizeButton.TextSize = 15
            tween(window, {
                Size = UDim2.fromOffset(window.AbsoluteSize.X, HEADER_H),
                BackgroundColor3 = theme.Header,
            }, 0.2)
        else
            body.Visible = true
            resizeHandle.Visible = true
            headerFill.Visible = true
            headerLine.Visible = true
            minimizeButton.Text = "–"
            minimizeButton.TextSize = 18
            tween(window, {
                Size = expandedSize,
                BackgroundColor3 = theme.Background,
            }, 0.2)
        end
    end

    function self:SetTitle(text)
        titleLabel.Text = tostring(text)
    end

    function self:Show()
        gui.Enabled = true
    end

    function self:Hide()
        gui.Enabled = false
    end

    self:_connect(minimizeButton.Activated, function()
        self:SetMinimized(not minimized)
    end)

    self:_connect(closeButton.Activated, function()
        if type(options.OnClose) == "function" then
            task.spawn(options.OnClose)
        end
        self:Destroy()
    end)

    --------------------------------------------------
    -- Mount
    --------------------------------------------------

    local mounted = pcall(function()
        gui.Parent = getGuiParent()
    end)

    if not mounted or not gui.Parent then
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    table.insert(OceanUI._windows, self)

    return self
end

--==================================================
-- DESTROY
--==================================================

function Window:Destroy()
    if self.Destroyed then
        return
    end

    -- Let toggles clean up (e.g. restore WalkSpeed) before everything stops.
    for _, element in ipairs(table.clone(self.Elements)) do
        if element._cleanup then
            pcall(element._cleanup)
        end
        element.Destroyed = true
        OceanUI.Flags[element.Flag] = nil
    end

    self.Destroyed = true

    for _, connection in ipairs(self._conns) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    local index = table.find(OceanUI._windows, self)
    if index then
        table.remove(OceanUI._windows, index)
    end

    if self.Gui then
        self.Gui:Destroy()
    end
end

function OceanUI:Destroy()
    for _, window in ipairs(table.clone(self._windows)) do
        window:Destroy()
    end

    if Util.env.OceanUI == self then
        Util.env.OceanUI = nil
    end
end

--==================================================
-- INTERNAL HELPERS USED BY ELEMENT FILES
--==================================================

function Window:_row(height)
    self._order += 1

    local row = new("Frame", {
        Name = "Row",
        Size = UDim2.new(1, 0, 0, height),
        BackgroundColor3 = OceanUI.Theme.Surface,
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        LayoutOrder = self._order,
    }, self.Body)

    addCorner(row, 8)
    addStroke(row)

    return row
end

function Window:_register(kind, options, value)
    local name = options.Name or kind

    local element = setmetatable({
        Kind = kind,
        Name = name,
        Flag = options.Flag or name,
        Callback = options.Callback,
        Value = value,
        Changed = newSignal(),
        Destroyed = false,
        Window = self,
    }, Element)

    table.insert(self.Elements, element)
    OceanUI.Flags[element.Flag] = value

    return element
end
