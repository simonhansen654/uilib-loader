-- UILib v1 X11 Part 1/10
-- @nulare Discord
-- Matcha-compatible Drawing UI Library

UILib = {}
UILib.__index = UILib

ESP_FONTSIZE = 7
BLACK = Color3.new(0,0,0)

local Players = game:GetService('Players')
local myPlayer = Players.LocalPlayer
local myMouse = myPlayer:GetMouse()

local function clamp(x, a, b)
    if x > b then return b end
    if x < a then return a end
    return x
end

local function color3fromHSV(h,s,v)
    local i = math.floor(h*6)
    local f = h*6 - i
    local p = v*(1-s)
    local q = v*(1-f*s)
    local t = v*(1-(1-f)*s)
    i = i%6
    local r,g,b
    if i==0 then r,g,b=v,t,p
    elseif i==1 then r,g,b=q,v,p
    elseif i==2 then r,g,b=p,v,t
    elseif i==3 then r,g,b=p,q,v
    elseif i==4 then r,g,b=t,p,v
    else r,g,b=v,p,q end
    return {r*255,g*255,b*255}
end

local function getMousePos()
    return Vector2.new(myMouse.X,myMouse.Y)
end

local function lerp(a,b,t)
    return a+(b-a)*t
end

local function undrawAll(drawingsTable)
    for _,d in pairs(drawingsTable) do d.Visible = false end
end

local function destroyAllDrawings(drawingsTable)
    for _,d in ipairs(drawingsTable) do
        pcall(function() d:Remove() end)
    end
end

function UILib.new(name,size,watermarkActivity)
    repeat wait(1/9999) until isrbxactive()
    local self = setmetatable({},UILib)

    self._inputs = {
        ['m1']={id=0x01,held=false,click=false},
        ['m2']={id=0x02,held=false,click=false},
        ['mb']={id=0x04,held=false,click=false},
        ['tab']={id=0x09,held=false,click=false},
        ['enter']={id=0x0D,held=false,click=false},
        ['shift']={id=0x10,held=false,click=false},
        ['ctrl']={id=0x11,held=false,click=false},
        ['alt']={id=0x12,held=false,click=false},
        ['space']={id=0x20,held=false,click=false},
        ['left']={id=0x25,held=false,click=false},
        ['up']={id=0x26,held=false,click=false},
        ['right']={id=0x27,held=false,click=false},
        ['down']={id=0x28,held=false,click=false},
        ['f1']={id=0x70,held=false,click=false},
        ['f2']={id=0x71,held=false,click=false},
        ['f3']={id=0x72,held=false,click=false},
        ['f4']={id=0x73,held=false,click=false},
        ['f5']={id=0x74,held=false,click=false},
        ['f6']={id=0x75,held=false,click=false},
        ['f7']={id=0x76,held=false,click=false},
        ['f8']={id=0x77,held=false,click=false},
        ['f9']={id=0x78,held=false,click=false},
        ['f10']={id=0x79,held=false,click=false},
        ['f11']={id=0x7A,held=false,click=false},
        ['f12']={id=0x7B,held=false,click=false},
        ['a']={id=0x41,held=false,click=false},
        ['b']={id=0x42,held=false,click=false},
        ['c']={id=0x43,held=false,click=false},
        ['d']={id=0x44,held=false,click=false},
        ['e']={id=0x45,held=false,click=false},
        ['f']={id=0x46,held=false,click=false},
        ['g']={id=0x47,held=false,click=false},
        ['h']={id=0x48,held=false,click=false},
        ['i']={id=0x49,held=false,click=false},
        ['j']={id=0x4A,held=false,click=false},
        ['k']={id=0x4B,held=false,click=false},
        ['l']={id=0x4C,held=false,click=false},
        ['m']={id=0x4D,held=false,click=false},
        ['n']={id=0x4E,held=false,click=false},
        ['o']={id=0x4F,held=false,click=false},
        ['p']={id=0x50,held=false,click=false},
        ['q']={id=0x51,held=false,click=false},
        ['r']={id=0x52,held=false,click=false},
        ['s']={id=0x53,held=false,click=false},
        ['t']={id=0x54,held=false,click=false},
        ['u']={id=0x55,held=false,click=false},
        ['v']={id=0x56,held=false,click=false},
        ['w']={id=0x57,held=false,click=false},
        ['x']={id=0x58,held=false,click=false},
        ['y']={id=0x59,held=false,click=false},
        ['z']={id=0x5A,held=false,click=false}
    }

    self._active_tab = nil
    self._open = true
    self._watermark = true
    self._base_opacity = 0
    self._dragging = false
    self._drag_offset = Vector2.new(0,0)
    self._active_dropdown = nil
    self._active_colorpicker = nil
    self._clipboard_color = nil
    self._tick = os.clock()

    self.identity = name
    self._watermark_activity = watermarkActivity
    self.x = 20
    self.y = 60
    self.w = size and size.x or 300
    self.h = size and size.y or 400

    -- theme
    self._color_accent = Color3.fromRGB(255,127,0)
    self._color_text = Color3.fromRGB(255,255,255)
    self._color_crust = Color3.fromRGB(0,0,0)
    self._color_border = Color3.fromRGB(25,25,25)
    self._color_surface = Color3.fromRGB(38,38,38)
    self._color_overlay = Color3.fromRGB(76,76,76)

    self._title_h = 25
    self._tab_h = 20
    self._padding = 6
    self._gradient_detail = 80

    -- menu base
    local base = Drawing.new('Square')
    base.Filled = true
    base.Color = self._color_surface

    local crust = Drawing.new('Square')
    crust.Filled = false
    crust.Thickness = 1
    crust.Color = self._color_crust

    local border = Drawing.new('Square')
    border.Filled = false
    border.Thickness = 1
    border.Color = self._color_border

    local navbar = Drawing.new('Square')
    navbar.Filled = true
    navbar.Color = self._color_border

    local title = Drawing.new('Text')
    title.Text = self.identity
    title.Outline = true
    title.Color = self._color_text

    -- watermark
    local watermarkBase = Drawing.new('Square')
    watermarkBase.Filled = true
    watermarkBase.Color = self._color_surface

    local watermarkCursor = Drawing.new('Square')
    watermarkCursor.Filled = true
    watermarkCursor.Color = self._color_accent

    local watermarkCrust = Drawing.new('Square')
    watermarkCrust.Filled = false
    watermarkCrust.Thickness = 1
    watermarkCrust.Color = self._color_crust

    local watermarkBorder = Drawing.new('Square')
    watermarkBorder.Filled = false
    watermarkBorder.Thickness = 1
    watermarkBorder.Color = self._color_border

    local watermarkText = Drawing.new('Text')
    watermarkText.Text = name
    watermarkText.Outline = true
    watermarkText.Color = self._color_text

    self._tree = {
        ['_tabs'] = {},
        ['_drawings'] = {crust,border,base,navbar,title,watermarkBase,watermarkCursor,watermarkCrust,watermarkBorder,watermarkText}
    }

    return self
end

-- UILib Part 2/10

function UILib._GetTextBounds(str)
    return #str * ESP_FONTSIZE, ESP_FONTSIZE
end

function UILib._IsMouseWithinBounds(origin, size)
    local mousePos = getMousePos()
    return mousePos.x >= origin.x and mousePos.x <= origin.x + size.x
       and mousePos.y >= origin.y and mousePos.y <= origin.y + size.y
end

function UILib:_RemoveDropdown()
    if self._active_dropdown then
        destroyAllDrawings(self._active_dropdown['_drawings'])
        self._active_dropdown = nil
    end
end

function UILib:_RemoveColorpicker()
    if self._active_colorpicker then
        destroyAllDrawings(self._active_colorpicker['_drawings'])
        self._active_colorpicker = nil
    end
end

function UILib:_SpawnDropdown(default, choices, multi, callback, position, width)
    if self._active_dropdown then
        self:_RemoveDropdown()
    end

    local base = Drawing.new('Square')
    base.Filled = true
    base.Color = self._color_surface

    local crust = Drawing.new('Square')
    crust.Filled = false
    crust.Thickness = 1
    crust.Color = self._color_crust

    local border = Drawing.new('Square')
    border.Filled = false
    border.Thickness = 1
    border.Color = self._color_border

    local drawings = {base, crust, border}
    for _, choice in ipairs(choices) do
        local entry = Drawing.new('Text')
        entry.Outline = true
        entry.Color = self._color_text
        entry.Text = choice
        table.insert(drawings, entry)
    end

    local choiceHash = {}
    for _, choice in ipairs(choices) do choiceHash[choice] = false end
    for _, def in ipairs(default) do choiceHash[def] = true end

    self._active_dropdown = {
        ['choices'] = choiceHash,
        ['multi'] = multi,
        ['callback'] = callback,
        ['position'] = position,
        ['w'] = width,
        ['_drawings'] = drawings
    }
end

function UILib:_SpawnColorpicker(default, colorLabel, callback)
    if self._active_colorpicker then
        self:_RemoveColorpicker()
    end

    local base = Drawing.new('Square')
    base.Filled = true
    base.Color = self._color_surface

    local crust = Drawing.new('Square')
    crust.Filled = false
    crust.Thickness = 1
    crust.Color = self._color_crust

    local border = Drawing.new('Square')
    border.Filled = false
    border.Thickness = 1
    border.Color = self._color_border

    local titleBar = Drawing.new('Square')
    titleBar.Filled = true
    titleBar.Color = self._color_border

    local label = Drawing.new('Text')
    label.Outline = true
    label.Color = self._color_text
    label.Text = colorLabel

    local preview = Drawing.new('Square')
    preview.Filled = true
    preview.Color = self._color_surface

    local drawings = {base, crust, border, titleBar, label, preview}

    for _ = 1, self._gradient_detail*3 do
        table.insert(drawings, Drawing.new('Square'))
    end

    local cursorCrustPrimary = Drawing.new('Circle')
    cursorCrustPrimary.Filled = false
    cursorCrustPrimary.Thickness = 3
    cursorCrustPrimary.Radius = 6
    cursorCrustPrimary.NumSides = 20
    cursorCrustPrimary.Color = self._color_crust

    local cursorBasePrimary = Drawing.new('Circle')
    cursorBasePrimary.Filled = false
    cursorBasePrimary.Thickness = 1
    cursorBasePrimary.Radius = 6
    cursorBasePrimary.NumSides = 20
    cursorBasePrimary.Color = self._color_border

    local cursorBaseSecondary = Drawing.new('Square')
    cursorBaseSecondary.Filled = true
    cursorBaseSecondary.Color = self._color_border

    local cursorBorderSecondary = Drawing.new('Square')
    cursorBorderSecondary.Filled = false
    cursorBorderSecondary.Thickness = 1
    cursorBorderSecondary.Color = self._color_surface

    local cursorCrustSecondary = Drawing.new('Square')
    cursorCrustSecondary.Filled = false
    cursorCrustSecondary.Thickness = 1
    cursorCrustSecondary.Color = self._color_crust

    for _, cursor in ipairs{cursorBasePrimary, cursorCrustPrimary, cursorBaseSecondary, cursorCrustSecondary, cursorBorderSecondary} do
        table.insert(drawings, cursor)
    end

    self._active_colorpicker = {
        ['callback'] = callback,
        ['_pallete_pos'] = nil,
        ['_slider_y'] = 0,
        ['_drawings'] = drawings
    }
end

function UILib:ToggleWatermark(state)
    self._watermark = state
end

function UILib:ToggleMenu(state)
    self._open = state
end

function UILib:IsMenuOpen()
    return self._open
end

function UILib:Tab(name)
    local backdrop = Drawing.new('Square')
    backdrop.Color = self._color_border
    backdrop.Filled = true

    local shadow = Drawing.new('Square')
    shadow.Color = BLACK
    shadow.Filled = true

    local cursor = Drawing.new('Square')
    cursor.Color = self._color_accent
    cursor.Filled = true

    local text = Drawing.new('Text')
    text.Color = self._color_text
    text.Outline = true
    text.Text = name

    table.insert(self._tree['_tabs'], {
        ['name'] = name,
        ['_sections'] = {},
        ['_drawings'] = {backdrop, shadow, cursor, text}
    })

    if not self._active_tab then self._active_tab = name end

    return name
end

function UILib:Section(tabName,name)
    for _,tab in ipairs(self._tree['_tabs']) do
        if tab['name']==tabName then
            local base = Drawing.new('Square')
            base.Filled = true
            base.Color = self._color_surface

            local crust = Drawing.new('Square')
            crust.Filled = false
            crust.Thickness = 1
            crust.Color = self._color_crust

            local border = Drawing.new('Square')
            border.Filled = false
            border.Thickness = 1
            border.Color = self._color_overlay

            local title = Drawing.new('Text')
            title.Text = name
            title.Outline = true
            title.Color = self._color_text

            local section = {
                ['name'] = name,
                ['_items'] = {},
                ['_drawings'] = {base,crust,border,title}
            }

            table.insert(tab._sections,section)
            return name
        end
    end
end

-- UILib Part 3/10

function UILib:_AddToSection(tabName, sectionName, itemType, value, callback, drawings, meta)
    for _, tab in pairs(self._tree._tabs) do
        if tab.name == tabName then
            for _, section in pairs(tab._sections) do
                if section.name == sectionName then
                    local item = {
                        ['type'] = itemType,
                        ['value'] = value,
                        ['callback'] = callback,
                        ['_drawings'] = drawings
                    }

                    if meta then
                        for key, val in pairs(meta) do
                            item[key] = val
                        end
                    end

                    table.insert(section._items, item)
                    return
                end
            end
        end
    end
end

function UILib:Checkbox(tabName, sectionName, label, defaultValue, callback)
    local outline = Drawing.new('Square')
    outline.Color = self._color_crust
    outline.Thickness = 1
    outline.Filled = false

    local check = Drawing.new('Square')
    check.Color = self._color_accent
    check.Filled = true

    local checkShadow = Drawing.new('Square')
    checkShadow.Color = BLACK
    checkShadow.Filled = true

    local text = Drawing.new('Text')
    text.Color = self._color_text
    text.Outline = true
    text.Text = label

    self:_AddToSection(tabName, sectionName, 'checkbox', defaultValue, callback, {
        outline,
        check,
        checkShadow,
        text
    })
end

function UILib:Slider(tabName, sectionName, label, defaultValue, callback, min, max, step, appendix)
    local outline = Drawing.new('Square')
    outline.Color = self._color_crust
    outline.Filled = true

    local fill = Drawing.new('Square')
    fill.Color = self._color_accent
    fill.Filled = true

    local fillShadow = Drawing.new('Square')
    fillShadow.Color = BLACK
    fillShadow.Filled = true

    local value = Drawing.new('Text')
    value.Color = self._color_text
    value.Outline = true
    value.Text = label

    local text = Drawing.new('Text')
    text.Color = self._color_text
    text.Outline = true
    text.Text = label

    self:_AddToSection(tabName, sectionName, 'slider', defaultValue, callback, {
        outline,
        fill,
        fillShadow,
        value,
        text
    }, {
        ['min'] = min,
        ['max'] = max,
        ['step'] = step,
        ['appendix'] = appendix
    })
end

function UILib:Choice(tabName, sectionName, label, defaultValue, callback, choices, multi)
    local outline = Drawing.new('Square')
    outline.Color = self._color_crust
    outline.Thickness = 1
    outline.Filled = false

    local fill = Drawing.new('Square')
    fill.Color = self._color_crust
    fill.Filled = true

    local values = Drawing.new('Text')
    values.Color = self._color_text
    values.Outline = true
    values.Text = label

    local expand = Drawing.new('Text')
    expand.Color = self._color_text
    expand.Outline = true
    expand.Text = label

    local text = Drawing.new('Text')
    text.Color = self._color_text
    text.Outline = true
    text.Text = label

    self:_AddToSection(tabName, sectionName, 'choice', defaultValue, callback, {
        outline,
        fill,
        values,
        expand,
        text
    }, {
        ['choices'] = choices,
        ['multi'] = multi
    })
end

-- UILib Part 4/10

function UILib:Colorpicker(tabName, sectionName, label, defaultValue, callback)
    local base = Drawing.new('Square')
    base.Filled = true
    base.Color = self._color_surface

    local outline = Drawing.new('Square')
    outline.Filled = false
    outline.Thickness = 1
    outline.Color = self._color_crust

    local border = Drawing.new('Square')
    border.Filled = false
    border.Thickness = 1
    border.Color = self._color_border

    local title = Drawing.new('Text')
    title.Text = label
    title.Outline = true
    title.Color = self._color_text

    local preview = Drawing.new('Square')
    preview.Filled = true
    preview.Color = Color3.fromRGB(defaultValue[1], defaultValue[2], defaultValue[3])

    self:_AddToSection(tabName, sectionName, 'colorpicker', defaultValue, callback, {
        base,
        outline,
        border,
        title,
        preview
    })
end

function UILib:Keybind(tabName, sectionName, label, defaultKey, callback, mode)
    local outline = Drawing.new('Square')
    outline.Filled = false
    outline.Thickness = 1
    outline.Color = self._color_crust

    local keyText = Drawing.new('Text')
    keyText.Text = defaultKey
    keyText.Outline = true
    keyText.Color = self._color_text

    local labelText = Drawing.new('Text')
    labelText.Text = label
    labelText.Outline = true
    labelText.Color = self._color_text

    self:_AddToSection(tabName, sectionName, 'keybind', defaultKey, callback, {
        outline,
        keyText,
        labelText
    }, {
        ['mode'] = mode or 'Toggle'
    })
end

-- UILib Part 5/10

function UILib:ToggleMenu(state)
    self._open = state
end

function UILib:ToggleWatermark(state)
    self._watermark = state
end

function UILib:IsMenuOpen()
    return self._open
end

function UILib:Step()
    local mousePos = getMousePos()
    local clickFrame = myMouse:IsButtonPressed(Enum.UserInputType.MouseButton1)
    local ctxFrame = myMouse:IsButtonPressed(Enum.UserInputType.MouseButton2)
    local baseOpacity = self._base_opacity

    -- handle dragging
    if self._dragging then
        self.x = mousePos.x - self._drag_offset.x
        self.y = mousePos.y - self._drag_offset.y
    end

    -- menu core
    local coreDrawings = self._tree._drawings
    local bg = coreDrawings[3]
    local crust = coreDrawings[1]
    local border = coreDrawings[2]
    local navbar = coreDrawings[4]
    local title = coreDrawings[5]
    
    bg.Position = Vector2.new(self.x, self.y)
    bg.Size = Vector2.new(self.w, self.h)
    bg.Transparency = baseOpacity
    bg.Visible = self._open

    crust.Position = Vector2.new(self.x, self.y)
    crust.Size = Vector2.new(self.w, self.h)
    crust.Transparency = baseOpacity
    crust.Visible = self._open

    border.Position = Vector2.new(self.x, self.y)
    border.Size = Vector2.new(self.w, self.h)
    border.Transparency = baseOpacity
    border.Visible = self._open

    navbar.Position = Vector2.new(self.x, self.y)
    navbar.Size = Vector2.new(self.w, self._tab_h)
    navbar.Transparency = baseOpacity
    navbar.Visible = self._open

    title.Position = Vector2.new(self.x + 6, self.y + self._tab_h/2 - 4)
    title.Transparency = baseOpacity
    title.Visible = self._open
end

-- UILib Part 6/10

function UILib:Tab(name)
    local backdrop = Drawing.new('Square')
    backdrop.Filled = true
    backdrop.Color = self._color_border

    local shadow = Drawing.new('Square')
    shadow.Filled = true
    shadow.Color = BLACK

    local cursor = Drawing.new('Square')
    cursor.Filled = true
    cursor.Color = self._color_accent

    local text = Drawing.new('Text')
    text.Color = self._color_text
    text.Outline = true
    text.Text = name

    local tab = {
        name = name,
        _sections = {},
        _drawings = { backdrop, shadow, cursor, text }
    }

    table.insert(self._tree._tabs, tab)

    -- activate first tab if none active
    if not self._active_tab then
        self._active_tab = name
    end

    return name
end

function UILib:_DrawTabs()
    local tabY = self.y + self._tab_h
    local tabX = self.x
    local spacing = 6

    for _, tab in ipairs(self._tree._tabs) do
        local backdrop, shadow, cursor, text = table.unpack(tab._drawings)
        local tabW = #tab.name * ESP_FONTSIZE + 12

        backdrop.Position = Vector2.new(tabX, self.y)
        backdrop.Size = Vector2.new(tabW, self._tab_h)
        backdrop.Visible = self._open
        backdrop.Transparency = self._base_opacity

        shadow.Position = Vector2.new(tabX + 2, self.y + 2)
        shadow.Size = Vector2.new(tabW, self._tab_h)
        shadow.Visible = self._open
        shadow.Transparency = self._base_opacity

        cursor.Position = Vector2.new(tabX, self.y)
        cursor.Size = Vector2.new(tabW, self._tab_h)
        cursor.Visible = (self._active_tab == tab.name) and self._open or false
        cursor.Transparency = self._base_opacity

        text.Position = Vector2.new(tabX + 6, self.y + self._tab_h / 2 - 4)
        text.Visible = self._open
        text.Transparency = self._base_opacity

        -- handle input
        if self._IsMouseWithinBounds(Vector2.new(tabX, self.y), Vector2.new(tabW, self._tab_h)) and myMouse:IsButtonPressed(Enum.UserInputType.MouseButton1) then
            self._active_tab = tab.name
        end

        tabX = tabX + tabW + spacing
    end
end

-- UILib Part 7/10

function UILib:Section(tabName, name)
    for _, tab in ipairs(self._tree._tabs) do
        if tab.name == tabName then
            local base = Drawing.new('Square')
            base.Filled = true
            base.Color = self._color_surface

            local crust = Drawing.new('Square')
            crust.Filled = false
            crust.Thickness = 1
            crust.Color = self._color_crust

            local border = Drawing.new('Square')
            border.Filled = false
            border.Thickness = 1
            border.Color = self._color_overlay

            local title = Drawing.new('Text')
            title.Outline = true
            title.Color = self._color_text
            title.Text = name

            local section = {
                name = name,
                _items = {},
                _drawings = { base, crust, border, title }
            }

            table.insert(tab._sections, section)
            return name
        end
    end
end

function UILib:_DrawSections()
    for _, tab in ipairs(self._tree._tabs) do
        local tabActive = (self._active_tab == tab.name)
        for _, section in ipairs(tab._sections) do
            local base, crust, border, title = table.unpack(section._drawings)

            base.Position = Vector2.new(self.x + 10, self.y + self._title_h + 30)
            base.Size = Vector2.new(self.w - 20, 100) -- placeholder height
            base.Visible = self._open and tabActive

            crust.Position = base.Position
            crust.Size = base.Size
            crust.Visible = self._open and tabActive

            border.Position = base.Position + Vector2.new(1,1)
            border.Size = base.Size - Vector2.new(2,2)
            border.Visible = self._open and tabActive

            title.Position = base.Position + Vector2.new(6, -8)
            title.Visible = self._open and tabActive

            -- draw items
            local itemY = base.Position.y + 10
            for _, item in ipairs(section._items) do
                local draws = item._drawings
                for _, d in ipairs(draws) do
                    d.Position = Vector2.new(base.Position.x + 10, itemY)
                    d.Visible = self._open and tabActive
                end
                itemY = itemY + 22
            end
        end
    end
end

-- UILib Part 8/10

function UILib:_UpdateItems()
    for _, tab in ipairs(self._tree._tabs) do
        local tabActive = (self._active_tab == tab.name)
        for _, section in ipairs(tab._sections) do
            local itemY = section._drawings[1].Position.y + 10
            for _, item in ipairs(section._items) do
                local t = item.type
                local draws = item._drawings

                if t == 'checkbox' then
                    local outline, check, shadow, text = table.unpack(draws)
                    outline.Position = Vector2.new(self.x + 20, itemY)
                    check.Position = outline.Position + Vector2.new(2,2)
                    shadow.Position = check.Position + Vector2.new(1,1)
                    text.Position = outline.Position + Vector2.new(20,0)

                    check.Visible = item.value and self._open and tabActive
                    outline.Visible = self._open and tabActive
                    shadow.Visible = self._open and tabActive
                    text.Visible = self._open and tabActive

                    if self:_IsMouseWithinBounds(outline.Position, Vector2.new(16,16)) and self._open then
                        if self._inputs['m1'].click then
                            item.value = not item.value
                            if item.callback then
                                item.callback(item.value)
                            end
                        end
                    end

                elseif t == 'slider' then
                    local outline, fill, fillShadow, valueText, labelText = table.unpack(draws)
                    outline.Position = Vector2.new(self.x + 20, itemY)
                    outline.Size = Vector2.new(self.w - 60, 8)
                    fill.Position = outline.Position
                    fill.Size = Vector2.new(((item.value - item.min)/(item.max-item.min)) * outline.Size.x, 8)
                    fillShadow.Position = fill.Position + Vector2.new(1,1)
                    valueText.Position = outline.Position + Vector2.new(outline.Size.x + 6, -2)
                    labelText.Position = outline.Position + Vector2.new(0, -10)

                    outline.Visible = self._open and tabActive
                    fill.Visible = self._open and tabActive
                    fillShadow.Visible = self._open and tabActive
                    valueText.Visible = self._open and tabActive
                    labelText.Visible = self._open and tabActive

                    if self:_IsMouseWithinBounds(outline.Position, outline.Size) and self._inputs['m1'].held then
                        local rel = getMousePos().x - outline.Position.x
                        local pct = math.clamp(rel/outline.Size.x,0,1)
                        local val = item.min + (item.max-item.min) * pct
                        val = math.floor(val/item.step + 0.5) * item.step
                        item.value = val
                        if item.callback then item.callback(val) end
                    end

                elseif t == 'choice' then
                    local outline, fill, valueText, expandText, labelText = table.unpack(draws)
                    outline.Position = Vector2.new(self.x + 20, itemY)
                    valueText.Position = outline.Position + Vector2.new(4,0)
                    expandText.Position = outline.Position + Vector2.new(outline.Size.x - 12,0)
                    labelText.Position = outline.Position + Vector2.new(0,-10)

                    outline.Visible = self._open and tabActive
                    valueText.Visible = self._open and tabActive
                    expandText.Visible = self._open and tabActive
                    labelText.Visible = self._open and tabActive

                    if self:_IsMouseWithinBounds(outline.Position, Vector2.new(80,16)) and self._inputs['m1'].click then
                        self:_SpawnDropdown(item.value or {}, item.choices, item.multi, function(newVals)
                            item.value = newVals
                            if item.callback then item.callback(newVals) end
                        end, outline.Position, 80)
                    end

                elseif t == 'colorpicker' then
                    local base, crust, border, titleText, preview = table.unpack(draws)
                    base.Position = Vector2.new(self.x + 20, itemY)
                    preview.Position = base.Position + Vector2.new(90,0)

                    base.Visible = self._open and tabActive
                    crust.Visible = self._open and tabActive
                    border.Visible = self._open and tabActive
                    titleText.Visible = self._open and tabActive
                    preview.Visible = self._open and tabActive

                    if self:_IsMouseWithinBounds(preview.Position, Vector2.new(16,16)) and self._inputs['m1'].click then
                        self:_SpawnColorpicker(item.value, item.label, function(newColor)
                            item.value = newColor
                            if item.callback then item.callback(newColor) end
                        end)
                    end

                elseif t == 'key' then
                    local keyText = draws[4]
                    keyText.Text = item.value or 'None'
                    keyText.Position = Vector2.new(self.x + 20, itemY)
                    keyText.Visible = self._open and tabActive
                end

                itemY = itemY + 22
            end
        end
    end
end

-- UILib Part 9/10

function UILib:_UpdateDropdown()
    if not self._active_dropdown then return end
    local dd = self._active_dropdown
    local base, crust, border = dd._drawings[1], dd._drawings[2], dd._drawings[3]

    base.Position = dd.position
    base.Size = Vector2.new(dd.w, #dd.choices * 16)
    crust.Position = base.Position
    crust.Size = base.Size
    border.Position = base.Position
    border.Size = base.Size

    base.Visible = self._open
    crust.Visible = self._open
    border.Visible = self._open

    local idx = 0
    for choice, selected in pairs(dd.choices) do
        local textDraw = dd._drawings[3 + idx]
        textDraw.Position = base.Position + Vector2.new(4, idx * 16)
        textDraw.Visible = self._open
        if self:_IsMouseWithinBounds(textDraw.Position, Vector2.new(dd.w - 8, 16)) and self._inputs['m1'].click then
            if dd.multi then
                dd.choices[choice] = not dd.choices[choice]
            else
                for k in pairs(dd.choices) do dd.choices[k] = false end
                dd.choices[choice] = true
            end
            if dd.callback then dd.callback(dd.choices) end
        end
        idx = idx + 1
    end
end

function UILib:_UpdateColorpicker()
    if not self._active_colorpicker then return end
    local cp = self._active_colorpicker
    local base, crust, border, title, preview = cp._drawings[1], cp._drawings[2], cp._drawings[3], cp._drawings[4], cp._drawings[5]

    base.Position = Vector2.new(self.x + 120, self.y + 60)
    crust.Position = base.Position
    crust.Size = Vector2.new(150,150)
    border.Position = base.Position
    border.Size = crust.Size
    title.Position = base.Position + Vector2.new(0,-10)
    preview.Position = base.Position + Vector2.new(160,0)

    for i=6,#cp._drawings do
        cp._drawings[i].Visible = self._open
    end

    base.Visible = self._open
    crust.Visible = self._open
    border.Visible = self._open
    title.Visible = self._open
    preview.Visible = self._open
end

function UILib:Step()
    -- update mouse clicks
    for _, key in pairs(self._inputs) do
        key.click = false
    end

    -- input polling for mouse/keyboard happens externally or via wrapper
    -- update UI elements
    self:_UpdateItems()
    self:_UpdateDropdown()
    self:_UpdateColorpicker()
end

function UILib:Destroy()
    for _, drawing in ipairs(self._tree._drawings) do
        drawing:Remove()
    end
    self._tree._drawings = {}
    self._tree._tabs = {}
    self._active_dropdown = nil
    self._active_colorpicker = nil
end

-- UILib Part 10/10

function UILib:Keybind(tabName, sectionName, label, defaultKey, callback, mode)
    local text = Drawing.new('Text')
    text.Color = self._color_text
    text.Outline = true
    text.Text = label .. ": " .. defaultKey

    self:_AddToSection(tabName, sectionName, 'keybind', defaultKey, callback, { text }, { ['mode'] = mode })
end

function UILib:_UpdateItems()
    for _, tab in pairs(self._tree._tabs) do
        for _, section in pairs(tab._sections) do
            for _, item in pairs(section._items) do
                if item.type == 'checkbox' then
                    item._drawings[2].Visible = item.value
                elseif item.type == 'slider' then
                    local fill = item._drawings[2]
                    local min, max = item.min, item.max
                    local percent = (item.value - min) / (max - min)
                    fill.Size = Vector2.new(percent * 100, 4)
                    fill.Visible = self._open
                elseif item.type == 'choice' then
                    item._drawings[2].Visible = self._open
                elseif item.type == 'keybind' then
                    item._drawings[1].Text = item.value
                    item._drawings[1].Visible = self._open
                end
            end
        end
    end
end

function UILib:ToggleMenu(state)
    self._open = state
    if not state then
        self:_RemoveDropdown()
        self:_RemoveColorpicker()
    end
end

function UILib:ToggleWatermark(state)
    self._watermark = state
end

function UILib:_RenderWatermark()
    if not self._watermark then return end
    local wm = self._tree._drawings
    wm[6].Position = Vector2.new(10, 10) -- watermarkBase
    wm[6].Size = Vector2.new(100, 20)
    wm[6].Visible = true
    wm[9].Position = Vector2.new(15, 12) -- watermarkText
    wm[9].Visible = true
end

-- Utilities
function UILib:StepAll()
    self:Step()
    self:_RenderWatermark()
end

function UILib:_Clamp(x, a, b)
    if x < a then return a end
    if x > b then return b end
    return x
end

function UILib:Lerp(a, b, t)
    return a + (b - a) * t
end

function UILib:ColorFromHSV(h, s, v)
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    i = i % 6
    local r,g,b
    if i==0 then r,g,b=v,t,p
    elseif i==1 then r,g,b=q,v,p
    elseif i==2 then r,g,b=p,v,t
    elseif i==3 then r,g,b=p,q,v
    elseif i==4 then r,g,b=t,p,v
    else r,g,b=v,p,q end
    return {r*255,g*255,b*255}
end

return UILib
