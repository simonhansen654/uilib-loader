-- Simple Roblox UI Library (LuaU / Matcha compatible)
UILib = {}
UILib.__index = UILib

-- Constants
ESP_FONTSIZE = 7
BLACK = Color3.new(0, 0, 0)

-- Player references
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
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
        toggleUI = {id = Enum.KeyCode.RightShift, held = false, click = false}, -- Toggle UI
    }

    -- Menu settings
    self._open = true
    self._ui_visible = true
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

    -- Notifications
    self._notifications = {}

    -- Input blocking and keybinds
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if self._ui_visible then
            if input.UserInputType == Enum.UserInputType.MouseButton1 or
               input.UserInputType == Enum.UserInputType.MouseButton2 then
                gameProcessed = true
            end
            if input.KeyCode == Enum.KeyCode.RightShift then
                self._ui_visible = not self._ui_visible
            end
            for _, tab in ipairs(self._tree._tabs) do
                for _, section in ipairs(tab._sections) do
                    for _, item in ipairs(section._items) do
                        if item.type == "keybind" and input.KeyCode.Name == item.key then
                            if item.callback then
                                item.callback()
                            end
                        end
                    end
                end
            end
        end
    end)

    -- Mouse drag & dropdown/colorpicker handling
    Mouse.Button1Down:Connect(function()
        local mousePos = getMousePos()
        if self:_IsMouseWithinBounds(Vector2.new(self.x, self.y), Vector2.new(self.w, self._title_h)) then
            self._dragging = true
            self._drag_offset = Vector2.new(mousePos.X - self.x, mousePos.Y - self.y)
        end

        -- Dropdown clicks
        for _, tab in ipairs(self._tree._tabs) do
            for _, section in ipairs(tab._sections) do
                for _, item in ipairs(section._items) do
                    if item.type == "dropdown" then
                        local pos = Vector2.new(self.x + 10, self.y + 100)
                        local size = Vector2.new(150, 16)
                        if self:_IsMouseWithinBounds(pos, size) then
                            item.open = not item.open
                        end
                        if item.open then
                            for i, opt in ipairs(item.options) do
                                local optPos = Vector2.new(pos.X, pos.Y + i * 16)
                                local optSize = Vector2.new(150, 16)
                                if self:_IsMouseWithinBounds(optPos, optSize) then
                                    item.index = i
                                    if item.callback then item.callback(opt) end
                                    self:Notify(item.label.." set to "..opt) -- Notification example
                                end
                            end
                        end
                    end
                end
            end
        end
    end)

    Mouse.Button1Up:Connect(function()
        self._dragging = false
    end)

    -- Main update loop
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

-- Notifications
function UILib:Notify(text, duration)
    duration = duration or 2
    local notif = {text = text, time = 0, duration = duration}
    notif._label = Drawing.new("Text")
    notif._label.Size = 16
    notif._label.Color = self._color_accent
    notif._label.Position = Vector2.new(self.x + 10, self.y + self.h + 10 + (#self._notifications * 20))
    notif._label.Font = 2
    notif._label.Text = text
    notif._label.Visible = true
    table.insert(self._notifications, notif)
end

-- UI update
function UILib:_updateUI()
    if not self._ui_visible then
        hideDrawings({self._watermark_label})
        return
    end

    -- Smooth drag
    if self._dragging then
        local mousePos = getMousePos()
        self.x = lerp(self.x, mousePos.x - self._drag_offset.X, 0.3)
        self.y = lerp(self.y, mousePos.y - self._drag_offset.Y, 0.3)
    end

    -- Watermark
    if self._watermark then
        if not self._watermark_label then
            self._watermark_label = Drawing.new("Text")
            self._watermark_label.Size = 16
            self._watermark_label.Color = self._color_accent
            self._watermark_label.Position = Vector2.new(10, 10)
            self._watermark_label.Font = 2
            self._watermark_label.Text = self.identity
            self._watermark_label.Visible = true
        else
            self._watermark_label.Text = self.identity
            self._watermark_label.Visible = true
        end
    elseif self._watermark_label then
        self._watermark_label.Visible = false
    end

    -- Sliders, ColorPickers, Dropdowns
    for _, tab in ipairs(self._tree._tabs) do
        for _, section in ipairs(tab._sections) do
            for _, item in ipairs(section._items) do
                -- Slider
                if item.type == "slider" then
                    if not item._label then
                        item._label = Drawing.new("Text")
                        item._label.Size = 14
                        item._label.Color = self._color_text
                        item._label.Position = Vector2.new(self.x + 10, self.y + 60)
                        item._label.Font = 2
                        item._label.Text = item.label..": "..tostring(item.value)
                        item._label.Visible = true
                    else
                        if Mouse:IsButtonPressed(1) and self:_IsMouseWithinBounds(Vector2.new(self.x + 10, self.y + 60), Vector2.new(150, 16)) then
                            local mouseX = getMousePos().X
                            local relX = clamp(mouseX - (self.x + 10), 0, 150)
                            local percent = relX / 150
                            item.value = math.floor(item.min + (item.max - item.min) * percent)
                            if item.callback then item.callback(item.value) end
                        end
                        item._label.Text = item.label..": "..tostring(item.value)
                    end
                end

                -- ColorPicker
                if item.type == "colorpicker" then
                    if not item._preview then
                        item._preview = Drawing.new("Square")
                        item._preview.Size = Vector2.new(20, 20)
                        item._preview.Position = Vector2.new(self.x + 10, self.y + 80)
                        item._preview.Color = item.color
                        item._preview.Filled = true
                        item._preview.Visible = true
                    else
                        if Mouse:IsButtonPressed(1) and self:_IsMouseWithinBounds(item._preview.Position, item._preview.Size) then
                            local mouseX = getMousePos().X
                            local mouseY = getMousePos().Y
                            local r = clamp((mouseX - self.x)/self.w,0,1)
                            local g = clamp((mouseY - self.y)/self.h,0,1)
                            local b = item.color.B
                            item.color = Color3.new(r,g,b)
                            if item.callback then item.callback(item.color) end
                        end
                        item._preview.Color = item.color
                    end
                end

                -- Dropdown
                if item.type == "dropdown" then
                    if not item._label then
                        item._label = Drawing.new("Text")
                        item._label.Size = 14
                        item._label.Color = self._color_text
                        item._label.Position = Vector2.new(self.x + 10, self.y + 100)
                        item._label.Font = 2
                        item._label.Text = item.label..": "..item.options[item.index]
                        item._label.Visible = true
                    else
                        item._label.Text = item.label..": "..item.options[item.index]
                    end
                end
            end
        end
    end

    -- Update notifications
    for i = #self._notifications,1,-1 do
        local notif = self._notifications[i]
        notif.time = notif.time + 0.03
        if notif.time > notif.duration then
            notif._label.Visible = false
            notif._label:Remove()
            table.remove(self._notifications,i)
        else
            notif._label.Position = Vector2.new(self.x + 10, self.y + self.h + 10 - (notif.time * 10))
        end
    end
end

-- Bounds check
function UILib:_IsMouseWithinBounds(pos, size)
    local mouse = getMousePos()
    return mouse.x >= pos.x and mouse.x <= pos.x + size.x
       and mouse.y >= pos.y and mouse.y <= pos.y + size.y
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
            local section = { name = sectionName, _items = {}, _drawings = {}, _subsections = {} }
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

function UILib:Slider(tabName, sectionName, label, min, max, defaultValue, callback)
    local section = self:_findSection(tabName, sectionName)
    if not section then return end
    table.insert(section._items, { type="slider", label=label, min=min, max=max, value=defaultValue, callback=callback })
end

function UILib:Choice(tabName, sectionName, label, options, defaultIndex, callback)
    local section = self:_findSection(tabName, sectionName)
    if not section then return end
    table.insert(section._items, { type="dropdown", label=label, options=options, index=defaultIndex, callback=callback, open=false })
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
