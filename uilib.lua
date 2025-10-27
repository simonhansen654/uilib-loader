-- Simple Roblox UI Library (LuaU / Matcha compatible)
UILib = {}
UILib.__index = UILib

-- Constants
ESP_FONTSIZE = 7
BLACK = Color3.new(0, 0, 0)

-- Player references
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Helpers
local function clamp(value, minValue, maxValue)
    return math.max(minValue, math.min(value, maxValue))
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

-- Create UILib
function UILib.new(title, watermark, watermarkActivity)
    repeat wait() until isrbxactive()

    local self = setmetatable({}, UILib)

    -- Input tracking
    self._inputs = {
        m1 = {id = 1, held = false, click = false},
        m2 = {id = 2, held = false, click = false},
        f1 = {id = 112, held = false, click = false},
    }

    -- Menu settings
    self._open = true
    self._watermark = true
    self._dragging = false
    self._drag_offset = Vector2.new(0, 0)
    self._active_tab = nil
    self._active_dropdown = nil
    self._active_colorpicker = nil
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

    -- Tree
    self._tree = {
        _tabs = {},
        _drawings = {}
    }

    -- Main update loop (polling inputs)
    spawn(function()
        while true do
            wait(0.03)
            self:_updateInputs()
            self:_updateUI()
        end
    end)

    return self
end

-- Input polling
function UILib:_updateInputs()
    for _, input in pairs(self._inputs) do
        input.held = Mouse:IsButtonPressed(input.id)
    end
end

-- UI update placeholder
function UILib:_updateUI()
    -- redraw all elements: sliders, buttons, colorpickers, etc.
end

-- Bounds check
function UILib._IsMouseWithinBounds(pos, size)
    local mouse = getMousePos()
    return mouse.x >= pos.x and mouse.x <= pos.x + size.x
       and mouse.y >= pos.y and mouse.y <= pos.y + size.y
end

-- Toggle menu
function UILib:ToggleMenu(open)
    self._open = open
end

-- Toggle watermark
function UILib:ToggleWatermark(enable)
    self._watermark = enable
end

-- Tabs & Sections
function UILib:Tab(name)
    local tab = { name = name, _sections = {}, _drawings = {} }
    table.insert(self._tree._tabs, tab)
    if not self._active_tab then self._active_tab = name end
    return name
end

function UILib:Section(tabName, sectionName)
    for _, tab in ipairs(self._tree._tabs) do
        if tab.name == tabName then
            local section = { name = sectionName, _items = {}, _drawings = {} }
            table.insert(tab._sections, section)
            return sectionName
        end
    end
end

-- Controls
function UILib:Checkbox(tabName, sectionName, label, defaultValue, callback)
    local section = self:_findSection(tabName, sectionName)
    if not section then return end
    table.insert(section._items, { type="checkbox", label=label, value=defaultValue, callback=callback })
end

function UILib:Button(tabName, sectionName, label, callback)
    local section = self:_findSection(tabName, sectionName)
    if not section then return end
    table.insert(section._items, { type="button", label=label, callback=callback })
end

function UILib:Slider(tabName, sectionName, label, min, max, defaultValue, callback)
    local section = self:_findSection(tabName, sectionName)
    if not section then return end
    table.insert(section._items, { type="slider", label=label, min=min, max=max, value=defaultValue, callback=callback })
end

function UILib:Choice(tabName, sectionName, label, options, defaultIndex, callback)
    local section = self:_findSection(tabName, sectionName)
    if not section then return end
    table.insert(section._items, { type="choice", label=label, options=options, index=defaultIndex, callback=callback })
end

function UILib:ColorPicker(tabName, sectionName, label, defaultColor, callback)
    local section = self:_findSection(tabName, sectionName)
    if not section then return end
    table.insert(section._items, { type="colorpicker", label=label, color=defaultColor, callback=callback })
end

function UILib:Keybind(tabName, sectionName, label, defaultKey, callback)
    local section = self:_findSection(tabName, sectionName)
    if not section then return end
    table.insert(section._items, { type="keybind", label=label, key=defaultKey, callback=callback })
end

-- Helper to find section
function UILib:_findSection(tabName, sectionName)
    for _, tab in ipairs(self._tree._tabs) do
        if tab.name == tabName then
            for _, s in ipairs(tab._sections) do
                if s.name == sectionName then return s end
            end
        end
    end
end

-- Example: Settings Tab
function UILib:CreateSettingsTab()
    local tab = self:Tab("Menu")
    local section = self:Section("Menu", "Settings")
    self:Keybind("Menu","Settings","Open Menu","F1",function()
        self:ToggleMenu(not self._open)
    end)
    self:Checkbox("Menu","Settings","Watermark",true,function(val)
        self:ToggleWatermark(val)
    end)
end
