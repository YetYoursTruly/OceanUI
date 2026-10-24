getgenv().OceanUIBase = "https://raw.githubusercontent.com/YetYoursTruly/OceanUI/main/"
local OceanUI = loadstring(game:HttpGet(getgenv().OceanUIBase .. "Loader.lua"))()

local Window = OceanUI:CreateWindow({
    Title = "OceanUI Example",
    Size = Vector2.new(320, 460),
})

-- Toggle test
Window:AddToggle({
    Name = "Toggle Test",
    OnEnable = function()
        print("Toggle enabled")
    end,
    OnDisable = function()
        print("Toggle disabled")
    end,
})

-- Slider test
Window:AddSlider({
    Name = "Slider Test",
    Min = 0,
    Max = 100,
    Default = 50,
    Callback = function(value)
        print("Slider:", value)
    end,
})

-- Unit test (shows "Moving 1 stud", "Moving 12 studs")
OceanUI.RegisterUnit("Moving", {
    Prefix = "Moving ",
    Singular = "stud",
    Plural = "studs",
})

Window:AddNumber({
    Name = "Unit Test",
    Min = 0,
    Max = 500,
    Default = 1,
    Unit = "Moving",
    Callback = function(value)
        print("Distance:", value)
    end,
})

-- Text test
Window:AddString({
    Name = "Text Test",
    Placeholder = "Type here...",
    Callback = function(text)
        print("Text:", text)
    end,
})

-- Dropdown test
Window:AddDropdown({
    Name = "Dropdown Test",
    Options = { "One", "Two", "Three" },
    Callback = function(choice)
        print("Dropdown:", choice)
    end,
})

-- Separator tests
Window:AddSeparator()
Window:AddSeparator("Actions")

-- Button tests
Window:AddButton({
    Name = "Button Test",
    Callback = function()
        print("Button clicked")
    end,
})

Window:AddButton({
    Name = "Secondary Button",
    Style = "Secondary",
    Callback = function()
        print("Secondary clicked")
    end,
})

Window:AddButton({
    Name = "Danger Button",
    Style = "Danger",
    Callback = function()
        print("Danger clicked")
    end,
})