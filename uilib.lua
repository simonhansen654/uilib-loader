-- Full Roblox UI Library
UILib = {}
UILib.__index = UILib

-- Constants
ESP_FONTSIZE = 7
BLACK = Color3.new(0, 0, 0)

-- Player references
local LocalPlayer = game:GetService("Players").LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Helper functions
local function clamp(value, minValue, maxValue)
    if value > maxValue then
        return maxValue
    elseif value < minValue then
        return minValue
    else
        return value
    end
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function getMousePos()
    return Vector2.new(Mouse.X, Mouse.Y)
end

local function hideDrawings(drawings)
    for _, d in pairs(drawings) do
        d.Visible = false
    end
end

local function removeDrawings(drawings)
    for _, d in ipairs(drawings) do
        d:Remove()
    end
end

-- Create a new UILib object
function UILib.new(title, watermark, watermarkActivity)
    repeat wait(0.0001) until isrbxactive()

    local self = setmetatable({}, UILib)

    -- Input tracking
    self._inputs = {f1 = {id = 112, held = false, click = false}}

    -- Menu settings
    self._open = true
    self._watermark = true
    self._base_opacity = 0
    self._dragging = false
    self._drag_offset = Vector2.new(0, 0)
    self._active_tab = nil
    self._active_dropdown = nil
    self._active_colorpicker = nil
    self._tick = os.clock()
    self.identity = title
    self._watermark_activity = watermarkActivity

    -- Position & size
    self.x = 20
    self.y = 60
    self.w = 300
    self.h = 400

    -- Colors
    self._color_accent = Color3.fromRGB(255, 127, 0)
    self._color_text = Color3.fromRGB(255, 255, 255)
    self._color_crust = Color3.fromRGB(0, 0, 0)
    self._color_border = Color3.fromRGB(25, 25, 25)
    self._color_surface = Color3.fromRGB(38, 38, 38)
    self._color_overlay = Color3.fromRGB(76, 76, 76)

    -- Layout
    self._title_h = 25
    self._tab_h = 20
    self._padding = 6
    self._gradient_detail = 80

    -- Tree for drawing objects
    self._tree = {_tabs = {}, _drawings = {}}

    return self
end

-- Helper: Mouse bounds check
function UILib._IsMouseWithinBounds(pos, size)
    local mouse = getMousePos()
    return mouse.x >= pos.x and mouse.x <= pos.x + size.x
       and mouse.y >= pos.y and mouse.y <= pos.y + size.y
end

-- Toggle menu
function UILib.ToggleMenu(self, open)
    self._open = open
end

-- Toggle watermark
function UILib.ToggleWatermark(self, enable)
    self._watermark = enable
end

-- Create tab
function UILib.Tab(self, tabName)
    local tab = {name = tabName, _sections = {}, _drawings = {}}
    table.insert(self._tree._tabs, tab)
    if not self._active_tab then
        self._active_tab = tabName
    end
    return tabName
end

-- Create section
function UILib.Section(self, tabName, sectionName)
    for _, tab in ipairs(self._tree._tabs) do
        if tab.name == tabName then
            local section = {name = sectionName, _items = {}, _drawings = {}}
            table.insert(tab._sections, section)
            return sectionName
        end
    end
end

-- Add Checkbox
function UILib.Checkbox(self, tabName, sectionName, label, defaultValue, callback)
    local tab, section
    for _, t in ipairs(self._tree._tabs) do
        if t.name == tabName then tab = t end
    end
    if tab then
        for _, s in ipairs(tab._sections) do
            if s.name == sectionName then section = s end
        end
    end
    if not section then return end

    local checkbox = {label = label, value = defaultValue, callback = callback}
    table.insert(section._items, checkbox)
end

-- Add Slider
function UILib.Slider(self, tabName, sectionName, label, minValue, maxValue, defaultValue, callback)
    local tab, section
    for _, t in ipairs(self._tree._tabs) do if t.name==tabName then tab=t end end
    if tab then for _, s in ipairs(tab._sections) do if s.name==sectionName then section=s end end end
    if not section then return end

    local slider = {
        label = label,
        min = minValue,
        max = maxValue,
        value = clamp(defaultValue, minValue, maxValue),
        callback = callback
    }
    table.insert(section._items, slider)
end

-- Add Choice (Dropdown)
function UILib.Choice(self, tabName, sectionName, label, options, defaultValue, callback)
    local tab, section
    for _, t in ipairs(self._tree._tabs) do if t.name==tabName then tab=t end end
    if tab then for _, s in ipairs(tab._sections) do if s.name==sectionName then section=s end end end
    if not section then return end

    local choice = {
        label = label,
        options = options,
        value = defaultValue or options[1],
        callback = callback
    }
    table.insert(section._items, choice)
end

-- Add Colorpicker
function UILib.Colorpicker(self, tabName, sectionName, label, defaultValue, callback)
    local tab, section
    for _, t in ipairs(self._tree._tabs) do if t.name==tabName then tab=t end end
    if tab then for _, s in ipairs(tab._sections) do if s.name==sectionName then section=s end end end
    if not section then return end

    local colorpicker = {
        label = label,
        value = defaultValue or Color3.new(1,1,1),
        callback = callback
    }
    table.insert(section._items, colorpicker)
end

-- Add Button
function UILib.Button(self, tabName, sectionName, label, callback)
    local tab, section
    for _, t in ipairs(self._tree._tabs) do if t.name==tabName then tab=t end end
    if tab then for _, s in ipairs(tab._sections) do if s.name==sectionName then section=s end end end
    if not section then return end

    local button = {label=label, callback=callback}
    table.insert(section._items, button)
end

-- Add Keybind
function UILib.Keybind(self, tabName, sectionName, label, defaultKey, callback)
    local tab, section
    for _, t in ipairs(self._tree._tabs) do if t.name==tabName then tab=t end end
    if tab then for _, s in ipairs(tab._sections) do if s.name==sectionName then section=s end end end
    if not section then return end

    local keybind = {label=label, key=defaultKey, callback=callback}
    table.insert(section._items, keybind)
end

-- Add Step/Loop toggle
function UILib.StepLoop(self, tabName, sectionName, label, defaultValue, callback)
    local tab, section
    for _, t in ipairs(self._tree._tabs) do if t.name==tabName then tab=t end end
    if tab then for _, s in ipairs(tab._sections) do if s.name==sectionName then section=s end end end
    if not section then return end

    local loopToggle = {label=label, value=defaultValue, callback=callback}
    table.insert(section._items, loopToggle)
end

-- Example: Create settings tab with all
function UILib.CreateSettingsTab(self)
    local tab = self:Tab("Menu")
    local section = self:Section(tab, "Settings")

    self:Keybind(tab, section, "Open Menu", "F1", function()
        self:ToggleMenu(not self._open)
    end)

    self:Checkbox(tab, section, "Watermark", true, function(v)
        self:ToggleWatermark(v)
    end)

    self:Slider(tab, section, "Example Slider", 0, 100, 50, function(v) print("Slider", v) end)
    self:Choice(tab, section, "Example Choice", {"Option1","Option2","Option3"}, "Option1", function(v) print("Choice", v) end)
    self:Colorpicker(tab, section, "Example Color", Color3.fromRGB(255,0,0), function(v) print("Color", v) end)
    self:Button(tab, section, "Example Button", function() print("Button Pressed") end)
    self:StepLoop(tab, section, "Loop Toggle", false, function(v) print("Loop:", v) end)
end

return UILib
