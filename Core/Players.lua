--[[ Core/Players.lua : player helpers, handy as dropdown Options. ]]

local OceanUI = ...

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Pass this function as `Options` and the list refreshes every time the dropdown opens.
function OceanUI.PlayerList()
    local names = {}

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(names, player.Name)
        end
    end

    table.sort(names)
    return names
end

function OceanUI.GetPlayer(name)
    if type(name) ~= "string" then
        return nil
    end
    return Players:FindFirstChild(name)
end
