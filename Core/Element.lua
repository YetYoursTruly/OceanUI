--[[ Core/Element.lua : methods every element shares (Get, OnChanged, SetVisible, Destroy). ]]

local OceanUI = ...

local Element = {}
Element.__index = Element

OceanUI.Element = Element

function Element:Get()
    if type(self.Value) == "table" then
        return table.clone(self.Value)
    end
    return self.Value
end

function Element:OnChanged(fn)
    return self.Changed:Connect(fn)
end

function Element:SetVisible(visible)
    if self.Row then
        self.Row.Visible = visible
    end
end

function Element:Destroy()
    if self.Destroyed then
        return
    end

    if self._cleanup then
        pcall(self._cleanup)
    end

    self.Destroyed = true
    OceanUI.Flags[self.Flag] = nil

    if self.Row then
        self.Row:Destroy()
    end

    local list = self.Window and self.Window.Elements
    local index = list and table.find(list, self)
    if index then
        table.remove(list, index)
    end
end
