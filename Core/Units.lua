--[[ Core/Units.lua : custom number types (units) for sliders and number inputs. ]]

local OceanUI, Util = ...
if not Util then
    -- Some executors don't pass extra arguments to loadstring chunks; read the shared tables instead.
    local shared = (type(getgenv) == "function" and getgenv() or _G).OceanUIShared
    OceanUI, Util = shared.OceanUI, shared.Util
end

local formatNumber = Util.formatNumber

function OceanUI.RegisterUnit(name, definition)
    OceanUI.Units[name] = definition
    return definition
end

-- Built-in units. Add your own with OceanUI.RegisterUnit.
OceanUI.RegisterUnit("MPH", { Suffix = " mph" })
OceanUI.RegisterUnit("Studs", { Singular = "stud", Plural = "studs" })
OceanUI.RegisterUnit("Moving", { Prefix = "Moving ", Singular = "stud", Plural = "studs" })
OceanUI.RegisterUnit("StudsPerSecond", { Suffix = " studs/s" })
OceanUI.RegisterUnit("Seconds", { Singular = "second", Plural = "seconds" })
OceanUI.RegisterUnit("Percent", { Suffix = "%" })
OceanUI.RegisterUnit("Degrees", { Suffix = "°" })

local function resolveUnit(unit)
    if unit == nil then
        return nil
    end

    if type(unit) == "string" then
        local lowered = string.lower(unit)
        for name, definition in pairs(OceanUI.Units) do
            if string.lower(name) == lowered then
                return definition
            end
        end
        return { Suffix = " " .. unit }
    end

    if type(unit) == "function" then
        return { Format = unit }
    end

    if type(unit) == "table" then
        return unit
    end

    return nil
end

function OceanUI.FormatValue(unit, value)
    local definition = resolveUnit(unit)

    if not definition then
        return formatNumber(value, 2)
    end

    if type(definition.Format) == "function" then
        local ok, result = pcall(definition.Format, value)
        if ok and result ~= nil then
            return tostring(result)
        end
    end

    local text = formatNumber(value, definition.Decimals or 2)
    local word = ""

    if definition.Singular or definition.Plural then
        local single = math.abs(value) == 1
        local chosen = single and (definition.Singular or definition.Plural)
            or (definition.Plural or definition.Singular)
        word = " " .. chosen
    end

    return (definition.Prefix or "") .. text .. word .. (definition.Suffix or "")
end