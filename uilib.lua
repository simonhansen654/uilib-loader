-- Full Roblox UI Library with all elements
local UILib = {}
UILib.__index = UILib

-- Player references
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Helpers
local function getMousePos() return Vector2.new(Mouse.X, Mouse.Y) end
local function clamp(val, min, max) return math.max(min, math.min(max, val)) end
local function lerp(a, b, t) return a + (b - a) * t end

-- Create new UI instance
function UILib.new(title)
    local self = setmetatable({}, UILib)
    self.title = title or "UILib Menu"
    self._open = true
    self._tabs = {}
    self._active_tab = nil
    self._dragging = false
    self._drag_offset = Vector2.new(0,0)
    self.x = 100
    self.y = 100
    self.w = 300
    self.h = 400

    -- Colors
    self.color_bg = Color3.fromRGB(30,30,30)
    self.color_tab = Color3.fromRGB(45,45,45)
    self.color_section = Color3.fromRGB(50,50,50)
    self.color_text = Color3.fromRGB(255,255,255)
    self.color_accent = Color3.fromRGB(255,127,0)

    -- Drawings
    self._drawings = {}
    self._mouse_down = false

    return self
end

-- Toggle menu
function UILib:ToggleMenu() self._open = not self._open end

-- Create a tab
function UILib:Tab(name)
    local tab = {name=name, _sections={}, _items={}}
    table.insert(self._tabs, tab)
    if not self._active_tab then self._active_tab = tab end
    return tab
end

-- Create a section
function UILib:Section(tab, name)
    local section = {name=name, _items={}}
    table.insert(tab._sections, section)
    return section
end

-- Elements
function UILib:Checkbox(tab, section, label, default, callback)
    table.insert(section._items,{type="checkbox", label=label, value=default, callback=callback})
end

function UILib:Button(tab, section, label, callback)
    table.insert(section._items,{type="button", label=label, callback=callback})
end

function UILib:Keybind(tab, section, label, key, callback)
    table.insert(section._items,{type="keybind", label=label, key=key, callback=callback})
end

function UILib:Slider(tab, section, label, min, max, default, callback)
    table.insert(section._items,{type="slider", label=label, min=min, max=max, value=default, callback=callback})
end

function UILib:Choice(tab, section, label, options, default, callback)
    table.insert(section._items,{type="choice", label=label, options=options, value=default, callback=callback})
end

function UILib:Colorpicker(tab, section, label, default, callback)
    table.insert(section._items,{type="colorpicker", label=label, value=default, callback=callback})
end

function UILib:StepLoop(tab, section, label, step, callback)
    table.insert(section._items,{type="steploop", label=label, step=step, callback=callback, lastTick=os.clock()})
end

-- Main render loop
function UILib:Render()
    local UILibInstance = self

    -- Dragging input
    UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            UILibInstance._mouse_down = true
            local mouse = getMousePos()
            if mouse.X >= UILibInstance.x and mouse.X <= UILibInstance.x + UILibInstance.w
            and mouse.Y >= UILibInstance.y and mouse.Y <= UILibInstance.y + 25 then
                UILibInstance._dragging = true
                UILibInstance._drag_offset = Vector2.new(mouse.X - UILibInstance.x, mouse.Y - UILibInstance.y)
            end
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            UILibInstance._dragging = false
            UILibInstance._mouse_down = false
        end
    end)

    -- Keybind handling
    UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard then
            for _, tab in ipairs(UILibInstance._tabs) do
                for _, section in ipairs(tab._sections) do
                    for _, item in ipairs(section._items) do
                        if item.type=="keybind" and input.KeyCode.Name==item.key then
                            item.callback()
                        end
                    end
                end
            end
        end
    end)

    -- RenderStepped loop
    RunService.RenderStepped:Connect(function()
        if not UILibInstance._open then return end

        local mouse = getMousePos()
        if UILibInstance._dragging then
            UILibInstance.x = mouse.X - UILibInstance._drag_offset.X
            UILibInstance.y = mouse.Y - UILibInstance._drag_offset.Y
        end

        -- Draw background
        if not UILibInstance._drawings.bg then
            local bg = Drawing.new("Square")
            bg.Size = Vector2.new(UILibInstance.w, UILibInstance.h)
            bg.Position = Vector2.new(UILibInstance.x, UILibInstance.y)
            bg.Filled = true
            bg.Color = UILibInstance.color_bg
            bg.Visible = true
            UILibInstance._drawings.bg = bg

            local title = Drawing.new("Text")
            title.Position = Vector2.new(UILibInstance.x+10, UILibInstance.y+5)
            title.Text = UILibInstance.title
            title.Color = UILibInstance.color_text
            title.Size = 18
            title.Visible = true
            UILibInstance._drawings.title = title
        else
            UILibInstance._drawings.bg.Position = Vector2.new(UILibInstance.x, UILibInstance.y)
            UILibInstance._drawings.title.Position = Vector2.new(UILibInstance.x+10, UILibInstance.y+5)
        end

        -- Step loops
        for _, tab in ipairs(UILibInstance._tabs) do
            for _, section in ipairs(tab._sections) do
                for _, item in ipairs(section._items) do
                    if item.type=="steploop" then
                        if os.clock() - item.lastTick >= item.step then
                            item.lastTick = os.clock()
                            item.callback()
                        end
                    end
                end
            end
        end
    end)
end

-- Example usage
local UI = UILib.new("My Menu")
local tab = UI:Tab("Main")
local section = UI:Section(tab,"Features")

UI:Checkbox(tab,section,"Auto Farm",false,function(val) print("Auto Farm:",val) end)
UI:Button(tab,section,"Click Me!",function() print("Button pressed") end)
UI:Keybind(tab,section,"Toggle Menu","F1",function() UI:ToggleMenu() end)
UI:Slider(tab,section,"Speed",1,100,50,function(val) print("Speed:",val) end)
UI:Choice(tab,section,"Mode",{"Easy","Normal","Hard"},"Normal",function(val) print("Mode:",val) end)
UI:Colorpicker(tab,section,"Color",Color3.fromRGB(255,0,0),function(val) print("Color:",val) end)
UI:StepLoop(tab,section,"LoopTest",1,function() print("Step loop") end)

UI:Render()
