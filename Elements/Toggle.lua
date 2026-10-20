--[[ Elements/Toggle.lua : on/off switch with OnEnable / OnDisable / Loop hooks. ]]

local OceanUI, Util = ...
if not Util then
    -- Some executors don't pass extra arguments to loadstring chunks; read the shared tables instead.
    local shared = (type(getgenv) == "function" and getgenv() or _G).OceanUIShared
    OceanUI, Util = shared.OceanUI, shared.Util
end

local Window = OceanUI.Window

local new = Util.new
local addCorner = Util.addCorner
local makeLabel = Util.makeLabel
local tween = Util.tween
local fire = Util.fire

function Window:AddToggle(options)
    options = options or {}
    local theme = OceanUI.Theme

    local t = self:_register("Toggle", options, options.Default == true)
    t._loops = {}
    t._onEnable = {}
    t._onDisable = {}
    t._gen = 0
    t._ready = false

    local row = self:_row(34)
    t.Row = row

    makeLabel({
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -62, 1, 0),
        Text = t.Name,
    }, row)

    local track = new("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.fromOffset(40, 20),
        BackgroundColor3 = theme.Button,
        BorderSizePixel = 0,
    }, row)

    addCorner(track, 10)

    local knob = new("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 2, 0.5, 0),
        Size = UDim2.fromOffset(16, 16),
        BackgroundColor3 = theme.Muted,
        BorderSizePixel = 0,
    }, track)

    addCorner(knob, 8)

    local hit = new("TextButton", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "",
    }, row)

    local function render(duration)
        local on = t.Value
        tween(track, { BackgroundColor3 = on and theme.Accent or theme.Button }, duration)
        tween(knob, {
            Position = on and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
            BackgroundColor3 = on and theme.Background or theme.Muted,
        }, duration)
    end

    local function runLoop(loop, gen)
        task.spawn(function()
            local dt = 0
            while t.Value and not t.Destroyed and t._gen == gen do
                local ok, err = pcall(loop.fn, dt)
                if not ok then
                    warn("[OceanUI] Loop error in '" .. t.Name .. "': " .. tostring(err))
                end
                dt = task.wait(loop.interval)
            end
        end)
    end

    local function startLoops()
        t._gen += 1
        for _, loop in ipairs(t._loops) do
            runLoop(loop, t._gen)
        end
    end

    local function runHandlers(list)
        for _, fn in ipairs(list) do
            task.spawn(fn)
        end
    end

    function t:Set(state, silent)
        state = state == true
        if self.Value == state then
            return
        end

        self.Value = state
        OceanUI.Flags[self.Flag] = state
        render(0.15)

        if not self._ready then
            return -- the deferred start below handles it
        end

        if state then
            startLoops()
        else
            self._gen += 1
        end

        if not silent then
            runHandlers(state and self._onEnable or self._onDisable)
            fire(self, state)
        end
    end

    function t:Toggle()
        self:Set(not self.Value)
    end

    function t:OnEnabled(fn)
        table.insert(self._onEnable, fn)
        return self
    end

    function t:OnDisabled(fn)
        table.insert(self._onDisable, fn)
        return self
    end

    function t:Loop(fn, interval)
        local loop = { fn = fn, interval = interval or 0 }
        table.insert(self._loops, loop)
        if self._ready and self.Value then
            runLoop(loop, self._gen)
        end
        return self
    end

    -- Runs when the toggle/window is destroyed while ON, so OnDisable can restore things.
    function t:_cleanup()
        if self.Value and not self._cleaned then
            self._cleaned = true
            self.Value = false
            self._gen += 1
            for _, fn in ipairs(self._onDisable) do
                pcall(fn)
            end
        end
    end

    if options.OnEnable then
        t:OnEnabled(options.OnEnable)
    end
    if options.OnDisable then
        t:OnDisabled(options.OnDisable)
    end
    if options.Loop then
        t:Loop(options.Loop, options.Interval)
    end

    hit.Activated:Connect(function()
        t:Toggle()
    end)

    render(0)

    -- Deferred so you can attach more hooks right after creating the toggle.
    -- A toggle created with Default = true fires its enable hooks once here.
    task.defer(function()
        t._ready = true
        if t.Value and not t.Destroyed then
            startLoops()
            runHandlers(t._onEnable)
            fire(t, true)
        end
    end)

    return t
end