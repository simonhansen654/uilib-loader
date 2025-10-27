-- Part 1/4: UILib base, setup, and utility functions
--[[ 
  Detailed Lua UI Library for Matcha External
  Features: Tabs, Checkboxes, Sliders, Buttons, Dragging, Hover
  Aurora-style ready
--]]

local UILib = {}
UILib.__index = UILib

-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Utility functions
local function getMousePos()
    return Vector2.new(Mouse.X, Mouse.Y)
end

local function undrawAll(drawings)
    for _, d in pairs(drawings) do
        d.Visible = false
    end
end

-- Constructor
function UILib.new(title)
    local self = setmetatable({}, UILib)

    self._clickFrame = false
    self._mouseHeld = false
    self._dragging = false
    self._dragOffset = Vector2.new(0, 0)

    self.x = 200
    self.y = 200
    self.width = 400
    self.height = 300

    -- Style settings
    self._padding = 4
    self._titleHeight = 20
    self._tabHeight = 18
    self._itemHeight = 26

    -- Base drawings
    local base = Drawing.new("Square")
    base.Filled = true

    local titleText = Drawing.new("Text")
    titleText.Text = title

    self._tree = {
        _drawings = {base, titleText},
        _tabs = {}
    }

    return self
end

-- Check if mouse is inside a rectangle
function UILib._IsMouseInside(origin, size)
    local mp = getMousePos()
    return mp.x >= origin.x and mp.x <= origin.x + size.x and mp.y >= origin.y and mp.y <= origin.y + size.y
end

-- Part 2/4: Tabs, Checkboxes, and Buttons

-- Create a new tab
function UILib:Tab(name)
    local tabBackdrop = Drawing.new("Square")
    tabBackdrop.Filled = true

    local tabText = Drawing.new("Text")
    tabText.Text = name

    table.insert(self._tree._tabs, {
        name = name,
        _items = {},
        _collapsed = true,
        _drawings = {tabBackdrop, tabText}
    })

    return name
end

-- Internal function to add items to tabs
function UILib:_AddToTab(tabName, itemType, value, callback, drawings, meta)
    for _, tab in pairs(self._tree._tabs) do
        if tab.name == tabName then
            local item = {
                type = itemType,
                value = value,
                callback = callback,
                _drawings = drawings
            }
            if meta then
                for k,v in pairs(meta) do
                    item[k] = v
                end
            end
            table.insert(tab._items, item)
            break
        end
    end
end

-- Add a checkbox
function UILib:Checkbox(tabName, label, defaultValue, callback)
    local outline = Drawing.new("Square")
    outline.Thickness = 2
    outline.Filled = false

    local fill = Drawing.new("Square")
    fill.Filled = true

    local text = Drawing.new("Text")
    text.Text = label

    self:_AddToTab(tabName, "checkbox", defaultValue, callback, {outline, fill, text})
end

-- Add a button
function UILib:Button(tabName, label, callback)
    local text = Drawing.new("Text")
    text.Text = ":: "..label.." ::"

    self:_AddToTab(tabName, "button", nil, callback, {text})
end

-- Part 3/4: Sliders, Choices, and Step input handling

-- Add a slider
function UILib:Slider(tabName, label, defaultValue, step, min, max, unit, callback)
    local outline = Drawing.new("Square")
    outline.Thickness = 2
    outline.Filled = false

    local fill = Drawing.new("Square")
    fill.Filled = true

    local text = Drawing.new("Text")
    text.Text = label

    self:_AddToTab(tabName, "slider", defaultValue, callback, {outline, fill, text}, {
        step = step,
        min = min,
        max = max,
        unit = unit,
        _label = label
    })
end

-- Add a choice dropdown
function UILib:Choice(tabName, label, defaultValue, choices, callback)
    local text = Drawing.new("Text")
    text.Text = label

    self:_AddToTab(tabName, "choice", defaultValue, callback, {text}, {
        choices = choices,
        _label = label
    })
end

-- Main loop: Step function
function UILib:Step()
    local mousePos = getMousePos()

    -- Mouse input
    if iskeypressed(0x01) then
        if not self._m1_held then
            self._click_frame = true
        end
        self._m1_held = true
    else
        self._m1_held = false
    end

    -- Draw base
    local base = self._tree._drawings[1]
    local title = self._tree._drawings[2]
    base.Position = Vector2.new(self.x, self.y)
    base.Size = Vector2.new(self.w, self.h)
    base.Color = Color3.fromRGB(24, 24, 24)
    base.Visible = true

    title.Position = Vector2.new(self.x + self._padding, self.y + self._padding)
    title.Color = Color3.fromRGB(255, 0, 255)
    title.Visible = true

    -- Drag handling
    local titleRect = {pos = Vector2.new(self.x, self.y), size = Vector2.new(self.w, self._title_h)}
    if self._IsMouseWithinBounds(titleRect.pos, titleRect.size) and self._click_frame then
        self._dragging = true
        self._drag_offset = getMousePos() - titleRect.pos
    end

    if self._dragging then
        if self._m1_held then
            local mp = getMousePos()
            self.x = mp.x - self._drag_offset.x
            self.y = mp.y - self._drag_offset.y
        else
            self._dragging = false
        end
    end
end

-- Part 4/4: Item rendering, interaction, and cleanup

-- Draw tabs and items
function UILib:_DrawItems()
    local uiY = self._title_h + self._padding

    for _, tab in pairs(self._tree._tabs) do
        local tabDraws = tab._drawings
        local collapsed = tab._collapsed

        -- Tab background
        local tabPos = Vector2.new(self.x + self._padding, self.y + uiY)
        local tabSize = Vector2.new(self.w - self._padding*2, self._tab_h)
        tabDraws[1].Position = tabPos
        tabDraws[1].Size = tabSize
        tabDraws[1].Visible = true

        tabDraws[2].Position = Vector2.new(tabPos.x + 4, tabPos.y + 4)
        tabDraws[2].Text = tab.name .. (collapsed and " [+]" or " [-]")
        tabDraws[2].Color = Color3.fromRGB(255,255,255)
        tabDraws[2].Visible = true

        -- Toggle collapse on click
        if self._IsMouseWithinBounds(tabPos, tabSize) and self._click_frame then
            tab._collapsed = not tab._collapsed
        end

        uiY = uiY + self._tab_h

        -- Items
        for _, item in pairs(tab._items) do
            local type_ = item.type
            local value = item.value
            local draws = item._drawings

            if not collapsed then
                local ix = self.x + self._padding + 10
                local iy = self.y + uiY
                local iw = self.w - self._padding*2 - 15

                if type_ == "checkbox" then
                    local outline, fill, text = draws[1], draws[2], draws[3]
                    outline.Position = Vector2.new(ix + iw - 18, iy + self._item_h/2 - 7)
                    outline.Size = Vector2.new(14,14)
                    outline.Filled = false
                    outline.Thickness = 1
                    outline.Color = Color3.fromRGB(255,255,255)
                    outline.Visible = true

                    fill.Position = Vector2.new(ix + iw - 16, iy + self._item_h/2 - 5)
                    fill.Size = Vector2.new(10,10)
                    fill.Filled = true
                    fill.Color = value and Color3.fromRGB(80,200,120) or Color3.fromRGB(120,120,120)
                    fill.Visible = true

                    text.Position = Vector2.new(ix+4, iy + self._item_h/2 - 4)
                    text.Color = Color3.fromRGB(255,255,255)
                    text.Visible = true

                    if self._IsMouseWithinBounds(Vector2.new(ix + iw - 18, iy + self._item_h/2 - 7), Vector2.new(14,14)) and self._click_frame then
                        item.value = not item.value
                        if item.callback then item.callback(item.value) end
                    end
                elseif type_ == "button" then
                    local btnText = draws[1]
                    btnText.Position = Vector2.new(ix, iy + self._item_h/2 - 4)
                    btnText.Color = Color3.fromRGB(80,200,250)
                    btnText.Visible = true

                    if self._IsMouseWithinBounds(Vector2.new(ix, iy), Vector2.new(iw, self._item_h)) and self._click_frame then
                        if item.callback then item.callback() end
                    end
                elseif type_ == "slider" then
                    local outline, fill, text = draws[1], draws[2], draws[3]
                    local sw, sh = 140, 8
                    local sx, sy = ix + iw - sw - 4, iy + self._item_h/2 - sh/2

                    outline.Position = Vector2.new(sx, sy)
                    outline.Size = Vector2.new(sw, sh)
                    outline.Filled = false
                    outline.Thickness = 2
                    outline.Color = Color3.fromRGB(255,255,255)
                    outline.Visible = true

                    local ratio = (value - item.min)/(item.max - item.min)
                    fill.Position = Vector2.new(sx+2, sy+2)
                    fill.Size = Vector2.new((sw-4)*ratio, sh-4)
                    fill.Filled = true
                    fill.Color = Color3.fromRGB(80,200,250)
                    fill.Visible = true

                    text.Position = Vector2.new(ix+4, iy+self._item_h/2 -4)
                    text.Text = item._label.." :: "..tostring(value)..(item.unit or "")
                    text.Color = Color3.fromRGB(255,255,255)
                    text.Visible = true

                    if self._IsMouseWithinBounds(Vector2.new(sx, sy), Vector2.new(sw, sh)) and self._m1_held then
                        local newValue = item.min + ((mouse.X - sx)/sw)*(item.max - item.min)
                        newValue = math.max(item.min, math.min(newValue, item.max))
                        newValue = math.ceil(newValue/item.step)*item.step
                        item.value = newValue
                        if item.callback then item.callback(newValue) end
                    end
                end
                uiY = uiY + self._item_h
            else
                undrawAll(draws)
            end
        end

        uiY = uiY + self._padding
    end

    self._click_frame = false
end

-- Destroy all drawings
function UILib:Destroy()
    for _, drawing in pairs(self._tree._drawings) do drawing:Remove() end
    for _, tab in pairs(self._tree._tabs) do
        for _, item in pairs(tab._items) do
            for _, draw in pairs(item._drawings) do draw:Remove() end
        end
        for _, draw in pairs(tab._drawings) do draw:Remove() end
    end
    self._tree = nil
end

return UILib
