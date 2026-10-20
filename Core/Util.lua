--[[ Core/Util.lua : instance helpers, signals, number formatting and snapping. Shared by every module. ]]

local OceanUI, Util = ...

local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

function Util.new(className, props, parent)
    local instance = Instance.new(className)
    for key, value in pairs(props) do
        instance[key] = value
    end
    instance.Parent = parent
    return instance
end

local new = Util.new

function Util.addCorner(instance, radius)
    return new("UICorner", { CornerRadius = UDim.new(0, radius) }, instance)
end

function Util.addStroke(instance, color, transparency)
    return new("UIStroke", {
        Color = color or OceanUI.Theme.Border,
        Thickness = 1,
        Transparency = transparency or 0.2,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, instance)
end

function Util.addPadding(instance, left, right, top, bottom)
    return new("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or 0),
        PaddingTop = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
    }, instance)
end

function Util.tween(instance, props, duration)
    TweenService:Create(
        instance,
        TweenInfo.new(duration or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        props
    ):Play()
end

function Util.isPointerStart(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
end

function Util.makeLabel(props, parent)
    props.BackgroundTransparency = 1
    props.Font = props.Font or Enum.Font.GothamMedium
    props.TextSize = props.TextSize or 13
    props.TextColor3 = props.TextColor3 or OceanUI.Theme.Text
    props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
    props.TextTruncate = Enum.TextTruncate.AtEnd
    return new("TextLabel", props, parent)
end

function Util.newSignal()
    local handlers = {}
    local signal = {}

    function signal:Connect(fn)
        local handler = { fn = fn }
        table.insert(handlers, handler)
        return {
            Disconnect = function()
                local index = table.find(handlers, handler)
                if index then
                    table.remove(handlers, index)
                end
            end,
        }
    end

    function signal:Fire(...)
        for _, handler in ipairs(table.clone(handlers)) do
            task.spawn(handler.fn, ...)
        end
    end

    return signal
end

function Util.getGuiParent()
    if type(gethui) == "function" then
        local ok, result = pcall(gethui)
        if ok and typeof(result) == "Instance" then
            return result
        end
    end
    return CoreGui
end

-- Fires an element's Changed signal and its Callback.
function Util.fire(element, ...)
    if element.Destroyed then
        return
    end

    element.Changed:Fire(...)

    if type(element.Callback) == "function" then
        task.spawn(element.Callback, ...)
    end
end

function Util.formatNumber(value, decimals)
    decimals = decimals or 2
    local text = string.format("%." .. decimals .. "f", value)

    if decimals > 0 then
        text = string.gsub(text, "0+$", "")
        text = string.gsub(text, "%.$", "")
    end

    return text
end

function Util.makeSnapper(min, max, step)
    return function(value)
        value = math.clamp(value, min, max)

        if step and step > 0 then
            local base = (min == -math.huge) and 0 or min
            value = base + math.floor((value - base) / step + 0.5) * step
            value = math.clamp(value, min, max)
        end

        return math.floor(value * 1e6 + 0.5) / 1e6
    end
end
