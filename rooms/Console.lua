Console = Object:extend()

function Console:new()
    self.timer = Tim()
    self.area = Area(self)

    self.main_canvas = love.graphics.newCanvas(gw, gh)
    self.final_canvas = love.graphics.newCanvas(gw, gh)
    self.temp_canvas = love.graphics.newCanvas(gw, gh)
    self.glitch_canvas = love.graphics.newCanvas(gw, gh)
    self.rgb_shift_mag = 0
    self.font = fonts.Anonymous_8
    self.arch = fonts.Arch_8

    self.lines = {}
    self.line_y = 8
    camera:lookAt(gw/2, gh/2)
    camera.scale = 1
    self.modules = {}

    self.glitches = {}

    command_history_index = #command_history

    if first_run_ever then self:bytepathIntro()
    else self:bytepathMain() end

    input:unbindAll()
    input:bind('left', 'left')
    input:bind('right', 'right')
    input:bind('up', 'up')
    input:bind('down', 'down')
    input:bind('mouse1', 'left_click')
    input:bind('return', 'return')
    input:bind('backspace', 'backspace')
    input:bind('escape', 'escape')
    input:bind('dpleft', 'left')
    input:bind('dpright', 'right')
    input:bind('dpup', 'up')
    input:bind('dpdown', 'down')
    input:bind('fright', 'escape')
    input:bind('fdown', 'return')
    input:bind('fleft', 'return')
    input:bind('select', 'escape')
    input:bind('start', 'start')
    input:bind('tab', 'tab')

    save()
    fadeVolume('music', 1, 0.05)
    fadeVolume('game', 1, 0.0)

    self.timer:every(0.05, function()
        local r = 127 + love.math.random(-8, 8)
        table.insert(self.glitches, GlitchDisplacementC(love.math.random(0, gw), love.math.random(0, gh), love.math.random(16, 48), love.math.random(8, 16), {r, r, r}))
    end)

    self.timer:every({0.1, 0.2}, function() self.area:addGameObject('GlitchDisplacement') end)
end

function Console:update(dt)
    self.timer:update(dt)
    self.area:update(dt)

    for _, line in ipairs(self.lines) do line:update(dt) end
    for _, module in ipairs(self.modules) do module:update(dt) end
    for i = #self.glitches, 1, -1 do
        self.glitches[i]:update(dt)
        if self.glitches[i].dead then table.remove(self.glitches, i) end
    end

    -- GUI main-menu input. Keyboard-only: arrows move the selection, Enter
    -- activates, 1-8 jump to that row. (Mouse support was removed because
    -- the window→viewport coordinate mapping made hover detection unreliable
    -- in this room's shader pipeline.)
    if self.main_menu and self.main_menu.visible then
        local m = self.main_menu
        local n = #m.titles

        if input:pressed('up') then
            m.selection_index = m.selection_index - 1
            if m.selection_index < 1 then m.selection_index = n end
            playMenuSwitch()
        end
        if input:pressed('down') then
            m.selection_index = m.selection_index + 1
            if m.selection_index > n then m.selection_index = 1 end
            playMenuSwitch()
        end

        -- Numeric hotkeys (1..8): jump to that index and execute.
        if input:pressed('1') then self:_runMainMenu(1) end
        if input:pressed('2') then self:_runMainMenu(2) end
        if input:pressed('3') then self:_runMainMenu(3) end
        if input:pressed('4') then self:_runMainMenu(4) end
        if input:pressed('5') then self:_runMainMenu(5) end
        if input:pressed('6') then self:_runMainMenu(6) end
        if input:pressed('7') then self:_runMainMenu(7) end
        if input:pressed('8') then self:_runMainMenu(8) end

        -- Return/enter triggers the current selection.
        if input:pressed('return') then
            self:_runMainMenu(m.selection_index)
        end
    end
end

function Console:draw()
    love.graphics.setCanvas(self.glitch_canvas)
    love.graphics.clear()
        love.graphics.setColor(127/255, 127/255, 127/255)
        love.graphics.rectangle('fill', 0, 0, gw, gh)
        love.graphics.setColor(1, 1, 1)
        self.area:drawOnly({'glitch'})
    love.graphics.setCanvas()

    love.graphics.setCanvas(self.main_canvas)
    love.graphics.clear()
        camera:attach(0, 0, gw, gh)
        for _, line in ipairs(self.lines) do line:draw() end
        for _, module in ipairs(self.modules) do
            -- Skip modules that aren't currently active. Many modules (Device,
            -- Escape, Help, Shutdown) keep themselves in self.modules so a future
            -- call can reactivate them, but their draw() shouldn't paint anything
            -- while they're dormant. Without this guard the polygons and large
            -- filled text from the most recent module leak through over whatever
            -- the next room is supposed to show.
            if module.active then module:draw() end
        end

        camera:detach()
    love.graphics.setCanvas()

    love.graphics.setCanvas(self.temp_canvas)
    love.graphics.clear()
        if scanlines_enabled and not disable_expensive_shaders then
            -- glitch shader pass: displaces pixels according to glitch_canvas
            love.graphics.setColor(1, 1, 1)
            love.graphics.setBlendMode("alpha", "premultiplied")
            love.graphics.setShader(shaders.glitch)
            shaders.glitch:send('glitch_map', self.glitch_canvas)
            love.graphics.draw(self.main_canvas, 0, 0, 0, 1, 1)
            love.graphics.setShader()
            love.graphics.setBlendMode("alpha")
        else
            -- Effects off: blit main_canvas straight into temp_canvas.
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(self.main_canvas, 0, 0, 0, 1, 1)
        end
    love.graphics.setCanvas()

    love.graphics.setCanvas(self.final_canvas)
    love.graphics.clear()
        if scanlines_enabled and not disable_expensive_shaders then
            -- rgb_shift shader pass: per-channel line offset
            love.graphics.setColor(1, 1, 1)
            love.graphics.setBlendMode("alpha", "premultiplied")
            love.graphics.setShader(shaders.rgb_shift)
            shaders.rgb_shift:send('amount', {random(-self.rgb_shift_mag, self.rgb_shift_mag)/gw, random(-self.rgb_shift_mag, self.rgb_shift_mag)/gh})
            love.graphics.draw(self.temp_canvas, 0, 0, 0, 1, 1)
            love.graphics.setShader()
            love.graphics.setBlendMode("alpha")
        else
            -- Effects off: blit temp_canvas into final_canvas without
            -- any per-channel separation.
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(self.temp_canvas, 0, 0, 0, 1, 1)
        end
    love.graphics.setCanvas()

    if scanlines_enabled and not disable_expensive_shaders then
        -- distort shader pass: scanlines + horizontal fuzz + rgb offset
        love.graphics.setShader(shaders.distort)
        shaders.distort:send('time', time)
        shaders.distort:send('horizontal_fuzz', 0.2*(distortion/10))
        shaders.distort:send('rgb_offset', 0.2*(distortion/10))
        shaders.distort:send('scanlines', scanlines_enabled and 1 or 0)
    end
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setBlendMode('alpha', 'premultiplied')
    drawGameCanvas(self.final_canvas)

    -- GUI main menu: drawn AFTER the shader pipeline so the rectangle isn't
    -- smeared by glitch/rgb_shift/distort. We render in viewport coords
    -- (gw × 270) and rely on drawGameCanvas having already painted; the
    -- drawGameCanvas call above sets setCanvas() to default (the back buffer),
    -- so we paint directly into the window here.
    self:_drawMainMenu()

    love.graphics.setBlendMode('alpha')
    love.graphics.setShader()
end

function Console:destroy()
    -- Hide the main menu first so its GUI cell doesn't ghost under whatever
    -- next room replaces this one.
    self:_hideMainMenu()
    self.main_menu = nil

    -- Tear down every active module (EscapeModule / HelpModule /
    -- DeviceModule / ShutdownModule / ClearModule) so its update/draw
    -- callbacks stop running.
    if self.modules then
        for _, mod in ipairs(self.modules) do
            if mod.destroy then mod:destroy() end
        end
        self.modules = {}
    end

    -- Wipe pending timer callbacks (DeviceModule schedules several
    -- self.timer:after(...) lines for its body text). If we don't clear
    -- them, they keep firing on the *next* Console instance and dump
    -- their text into self.lines as ghost content.
    if self.timer and self.timer.clear then self.timer:clear() end

    -- Reset camera state so the next room's camera:lookAt() is the only
    -- thing modifying it.
    if camera and camera.lookAt then camera:lookAt(gw/2, gh/2) end
    if Camera.smooth and Camera.smooth.damped and camera.smoother then
        camera.smoother = Camera.smooth.none and Camera.smooth.none() or nil
    end
    if camera then camera.scale = 1 end

    -- Drop any in-flight module lines that landed in self.lines.
    self.lines = {}
    self.line_y = 0
    self.input_line = nil
    self.scrolling_y = nil
end

function Console:addLine(after, text, duration, swaps)
    self.timer:after(after, function()
        if text ~= '' then playComputerLine() end
        if self.bytepath_main then
            if text == '~ type @help# for help' then
                self.bytepath_main_y = self.line_y
            end
        end
        table.insert(self.lines, ConsoleLine(8, self.line_y, {text = text, duration = duration, swaps = swaps}))
        self.line_y = self.line_y + 12
        if self.line_y > gh then camera:lookAt(camera.x, camera.y + 12) end
    end)
end

-- Shared buffer for capturing the ConsoleLine inserted by the next addLine call.
-- This must be set just before the addLine that we want to grab. Then on the
-- NEXT frame the timer fires, insert happens, and we hook into the result by
-- peeking at self.lines[#self.lines]. The hook below sets a field while the
-- timer is pending.
function Console:_captureNextLine(key)
    -- Use a poll-and-cache: when draw runs (after timer fires), the line is
    -- already in self.lines, so we resolve by recency.
    local last_count = #self.lines
    self.timer:after(0.001, function()
        if #self.lines > last_count and not self.bytepath_main_menu_lines[key] then
            self.bytepath_main_menu_lines[key] = self.lines[#self.lines]
        end
    end)
end

function Console:addInputLine(delay, text)
    self.timer:after(delay, function()
        self.input_line = ConsoleInputLine(8, self.line_y, {text = text, console = self})
        table.insert(self.lines, self.input_line)
        self.line_y = self.line_y + 12
        if self.line_y > gh then camera:lookAt(camera.x, camera.y + 12) end 
    end)
end

function Console:getRandomArchWord()
    local word = ''
    local random_letters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWYXZ'
    for i = 1, love.math.random(1, 5) do 
        local r = love.math.random(1, #random_letters)
        word = word .. random_letters:utf8sub(r, r) 
    end
    return word
end

function Console:keypressed(key)
    if self.input_line and self:isConsoleCharacter(key) then 
        self.bytepath_main = false
        self.input_line:keypressed(key) 
    end
end

function Console:addToCommandHistory(command)
    table.insert(command_history, command)
    command_history_index = #command_history
end

function Console:isConsoleCharacter(key)
    local keys = {'space', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', '1', '2', '3', '4', '5', '6', '7', '8', '9', '0'}
    if fn.any(keys, key) then return true end
end

function Console:bytepathMain(delay)
    local delay = delay or 0
    self:_hideMainMenu()
    self:_showMainMenu({
        x = 12, y = 84,
        w = gw - 96, h = 22,
        spacing = 4,
        titles = {
            {key = 'start',     label = 'start',     desc = 'to start the simulation'},
            {key = 'classes',   label = 'classes',   desc = 'to view the class window'},
            {key = 'device',    label = 'device',    desc = 'to select a new device'},
            {key = 'passives',  label = 'passives',  desc = 'to view the passive skill tree'},
            {key = 'terminal',  label = 'terminal',  desc = 'to escape this terminal'},
            {key = 'options',   label = 'options',   desc = 'to view display / window options'},
            {key = 'help',      label = 'help',      desc = 'to view all builtin commands'},
            {key = 'shutdown',  label = 'shutdown',  desc = 'to quit the game'},
        },
        delay = delay,
    })
end

function Console:bytepathMain2()
    local delay = delay or 0
    self:_hideMainMenu()
    self:_showMainMenu({
        x = 12, y = 72,
        w = gw - 96, h = 22,
        spacing = 4,
        titles = {
            {key = 'start',     label = 'start',     desc = 'to start the simulation'},
            {key = 'classes',   label = 'classes',   desc = 'to view the class window'},
            {key = 'device',    label = 'device',    desc = 'to select a new device'},
            {key = 'passives',  label = 'passives',  desc = 'to view the passive skill tree'},
            {key = 'terminal',  label = 'terminal',  desc = 'to escape this terminal'},
            {key = 'options',   label = 'options',   desc = 'to view display / window options'},
            {key = 'help',      label = 'help',      desc = 'to view all builtin commands'},
            {key = 'shutdown',  label = 'shutdown',  desc = 'to quit the game'},
        },
        delay = delay,
    })
end

-- Show a single-column GUI menu in the viewport. Both keyboard (up/down/return
-- + hotkey 1–8) and mouse (hover/click) work. The active menu state is held in
-- self.main_menu so a single draw() can render it on the same canvas as the
-- console text.
function Console:_showMainMenu(opts)
    -- Wipe any module text that was pushed into self.lines by previous
    -- menu sessions (DeviceModule, HelpModule, EscapeModule, etc.). These
    -- would otherwise ghost behind the new menu because they're already in
    -- self.lines and we don't tear down the menu on every redraw.
    self.lines = {}
    self.line_y = 0
    self.input_line = nil
    self.scrolling_y = nil
    self.glitches = {}

    self.main_menu = {
        x = opts.x, y = opts.y,
        w = opts.w, h = opts.h,
        spacing = opts.spacing or 4,
        titles = opts.titles,
        selection_index = 1,
        hovered_index = nil,
        visible = true,
    }
    self.main_menu_texts = {}
    for i, t in ipairs(opts.titles) do
        self.main_menu_texts[i] = t.key
    end
    -- Action map: the function that runs when a specific entry is triggered.
    self.main_menu_actions = {
        terminal = function() local m = EscapeModule(self, self.line_y); table.insert(self.modules, m); playMenuSelect() end,
        start    = function() gotoRoom('Stage'); playMenuSelect() end,
        help     = function() self:help(); playMenuSelect() end,
        classes  = function() gotoRoom('Classes'); playMenuSelect() end,
        device   = function() table.insert(self.modules, DeviceModule(self, self.line_y)); playMenuSelect() end,
        passives = function() gotoRoom('SkillTree'); playMenuSelect() end,
        shutdown = function() table.insert(self.modules, ShutdownModule(self, self.line_y)); playMenuSelect() end,
        options  = function() gotoRoom('Options'); playMenuSelect() end,
    }
    if opts.delay and opts.delay > 0 then
        self.timer:after(opts.delay, function() self.main_menu.visible = true end)
        self.main_menu.visible = false
    end
end

function Console:_hideMainMenu()
    self.main_menu = nil
    self.main_menu_texts = nil
    self.main_menu_actions = nil
    self.bytepath_main = false
end

-- Bounding-box origin (in viewport coords) of the i-th menu cell.
function Console:_mainMenuCell(i)
    local m = self.main_menu
    return m.x, m.y + (i - 1) * (m.h + m.spacing)
end

-- Execute the action at index i and close the menu.
function Console:_runMainMenu(i)
    local m = self.main_menu
    if not m then return end
    local key = m.titles[i].key
    local act = self.main_menu_actions and self.main_menu_actions[key]
    self:rgbShift()
    -- Hide first so the action that opens e.g. Options doesn't paint the menu
    -- over the new screen for one frame.
    self:_hideMainMenu()
    if act then act() end
end

-- Draw the GUI main menu on top of the shader-painted canvas. All cells are
-- drawn in viewport coordinates (gw × gh); the existing drawGameCanvas()
-- pipeline in Console:draw handles the window letterbox scaling.
--
-- Column layout per row (within the cell, x progresses left → right):
--   • 3 px accent bar (selected only) — drawn just outside the cell, left
--   • INDEX "01".."08" — column 0..16
--   • vertical separator at x=16
--   • LABEL — column 20..100 (fixed so long labels can't bleed into desc)
--   • DESCRIPTION — column 104..(W-28)
--   • HOTKEY "[1]"..["8"] — column (W-22)..(W-6)
--   • chevron — only on selected row, drawn just outside the cell, right
function Console:_drawMainMenu()
    local m = self.main_menu
    if not m or not m.visible then return end
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setBlendMode('alpha')
    love.graphics.setShader()

    local n = #m.titles
    local accent_w = 3
    local index_w = 16
    local label_w = 80
    local hotkey_w = 22
    local row_h = m.h

    -- Background plate so the menu is readable above glitch/noise.
    local total_h = n * (row_h + m.spacing) - m.spacing + 8
    love.graphics.setColor(0, 0, 0, 0.78)
    love.graphics.rectangle('fill', m.x - 6, m.y - 6, m.w + 12, total_h)
    love.graphics.setColor(80/255, 80/255, 80/255, 1)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle('line', m.x - 6, m.y - 6, m.w + 12, total_h)
    love.graphics.setLineWidth(1)

    -- Geometry inside each cell.
    local idx_col  = m.x + 4
    local sep_x    = m.x + index_w
    local label_x  = m.x + index_w + 6
    local desc_x   = label_x + label_w + 12
    local desc_max_w = (m.w - (desc_x - m.x)) - hotkey_w - 8
    local hk_x     = m.x + m.w - hotkey_w - 4

    for i, title in ipairs(m.titles) do
        local cell_x, cell_y = self:_mainMenuCell(i)
        local is_selected = i == m.selection_index
        local is_hovered  = i == m.hovered_index

        -- Cell fill.
        local cell_fill
        if is_selected then
            cell_fill = {skill_point_color[1]/255, skill_point_color[2]/255, skill_point_color[3]/255, 0.30}
        elseif is_hovered then
            cell_fill = {70/255, 70/255, 80/255, 1}
        else
            cell_fill = {22/255, 22/255, 28/255, 1}
        end
        love.graphics.setColor(cell_fill[1], cell_fill[2], cell_fill[3], cell_fill[4])
        love.graphics.rectangle('fill', cell_x, cell_y, m.w, row_h)

        -- Left accent bar (vertical stripe, selected only).
        if is_selected then
            love.graphics.setColor(skill_point_color[1]/255, skill_point_color[2]/255, skill_point_color[3]/255, 1)
            love.graphics.rectangle('fill', cell_x - accent_w, cell_y, accent_w, row_h)
        end

        -- Vertical separator between the index badge and the label.
        love.graphics.setColor(50/255, 50/255, 50/255, 1)
        love.graphics.rectangle('line', sep_x, cell_y, 0, row_h)

        local text_y = cell_y + math.floor((row_h - self.font:getHeight())/2)

        -- Index badge "01".."08".
        local label_r, label_g, label_b, label_a
        if is_selected then
            label_r, label_g, label_b = skill_point_color[1]/255, skill_point_color[2]/255, skill_point_color[3]/255
            label_a = 1
        elseif is_hovered then
            label_r, label_g, label_b = 222/255, 222/255, 222/255
            label_a = 1
        else
            label_r, label_g, label_b = default_color[1]/255, default_color[2]/255, default_color[3]/255
            label_a = 1
        end

        love.graphics.setColor(label_r, label_g, label_b, label_a)
        local idx_str = string.format('%02d', i)
        local idx_w = self.font:getWidth(idx_str)
        love.graphics.print(idx_str, sep_x - idx_w - 4, text_y)

        -- LABEL — clamped to label_w so it can't bleed into the desc column.
        love.graphics.setColor(label_r, label_g, label_b, label_a)
        local label = title.label
        -- Truncate if necessary (defensive; current labels fit).
        if self.font:getWidth(label) > label_w - 8 then
            while self.font:getWidth(label .. '..') > label_w - 8 and #label > 1 do
                label = label:sub(1, -2)
            end
            label = label .. '..'
        end
        love.graphics.print(label, label_x, text_y)
        if is_selected then
            love.graphics.setColor(label_r, label_g, label_b, 0.55)
            love.graphics.print(label, label_x + 1, text_y)
        end

        -- DESCRIPTION (in its own column, capped width).
        if title.desc then
            local desc = title.desc
            local desc_alpha
            if is_selected then desc_alpha = 0.95
            elseif is_hovered then desc_alpha = 0.7
            else desc_alpha = 0.45 end
            love.graphics.setColor(label_r, label_g, label_b, desc_alpha)
            -- truncate if too wide
            if self.font:getWidth(desc) > desc_max_w then
                while self.font:getWidth(desc .. '..') > desc_max_w and #desc > 1 do
                    desc = desc:sub(1, -2)
                end
                desc = desc .. '..'
            end
            love.graphics.print(desc, desc_x, text_y)
        end

        -- HOTKEY hint "[N]" pinned to the right edge *inside* the cell.
        local hk = '[' .. i .. ']'
        local hk_alpha
        if is_selected then hk_alpha = 1
        elseif is_hovered then hk_alpha = 0.85
        else hk_alpha = 0.55 end
        love.graphics.setColor(label_r, label_g, label_b, hk_alpha)
        love.graphics.print(hk, hk_x, text_y)

        -- Right-side chevron just *outside* the cell (selected only).
        if is_selected then
            love.graphics.setColor(skill_point_color[1]/255, skill_point_color[2]/255, skill_point_color[3]/255, 1)
            love.graphics.print('›', cell_x + m.w + 4, text_y)
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function Console:help()
    self.main_menu = nil
    self.input_line = nil
    table.insert(self.modules, HelpModule(self, self.line_y))
end

function Console:bytepathIntro()
    first_run_ever = false

    local delay = 7.50
    self:addLine(2.0, '...')
    self:addLine(3.0, '...')
    self:addLine(4.0, '...')
    self:addLine(5.0, '...')
    self:addLine(5.52, '')
    self:addLine(delay + 0.0, ':: running genesis hook [stre]')
    self:addLine(delay + 0.02, ':: running hook [stre]')
    self:addLine(delay + 0.1, '.. triggering genesis events...')
    self:addLine(delay + 0.3, ':: running hook [' .. self:getRandomArchWord() .. ']')
    self:addLine(delay + 0.3, ':: running hook [' .. self:getRandomArchWord() .. ']')
    self:addLine(delay + 0.3, ':: running hook [' .. self:getRandomArchWord() .. ']')
    self:addLine(delay + 0.5, ':: running hook [' .. self:getRandomArchWord() .. ']')
    self:addLine(delay + 0.5, ':: running hook [' .. self:getRandomArchWord() .. ']')
    self:addLine(delay + 0.5, ':: running hook [' .. self:getRandomArchWord() .. ']')
    self:addLine(delay + 0.5, ':: running hook [' .. self:getRandomArchWord() .. ']')
    self:addLine(delay + 0.5, ':: running hook [' .. self:getRandomArchWord() .. ']')
    self:addLine(delay + 0.6, ':: running hook [' .. self:getRandomArchWord() .. ']')
    self:addLine(delay + 0.60, ":: mounting '/dev/ARCH-282809' to '/run/archtype/bootmnt'")
    self:addLine(delay + 0.61, ":: device '/dev/ARCH-282809' mounted successfully")
    self:addLine(delay + 0.62, ":: mounting '/run/archtype/ethspace' (tmpfs) filesystem, size=75%...")
    self:addLine(delay + 0.8, ":: mounting '/dev/loop0' to '/run/archtype/rootfs'")
    self:addLine(delay + 1.6, ":: device '/dev/loop0' mounted successfully'")
    self:addLine(delay + 1.70, ":: creating '/run/archtype/ethspace/persistent-ARCH-3017/rootfs.eth' as non-persistent")
    self:addLine(delay + 1.71, ":: mounting '/dev/mapper/arch-rootfs' to /new-root/")
    self:addLine(delay + 1.80, ":: device '/dev/mapper/arch-rootfs' mounted successfully'")
    self:addLine(delay + 1.81, ':: running late hook [' .. self:getRandomArchWord() .. ']')
    self:addLine(delay + 1.82, ':: running cleanup hook [' .. self:getRandomArchWord() .. ']')
    self:addLine(delay + 1.83, ':: running cleanup hook [stre]')
    self:addLine(delay + 1.88, '')
    self:addLine(delay + 1.91, 'Welcome to {ArchType}!')
    self:addLine(delay + 1.94, '')
    self:addLine(delay + 3.80, '[   <OK>   ] reached target (' .. self:getRandomArchWord() .. ')')
    self:addLine(delay + 3.81, '[   <OK>   ] reached target (' .. self:getRandomArchWord() .. ')')
    self:addLine(delay + 3.82, '[   <OK>   ] created nodes')
    self:addLine(delay + 3.83, '[   <OK>   ] created core path')
    self:addLine(delay + 3.84, '[   <OK>   ] reached core nodes')
    self:addLine(delay + 4.30, '[   <OK>   ] listening on /dev/init')
    self:addLine(delay + 4.31, '[   <OK>   ] listening on device-mapper event procedure')
    self:addLine(delay + 4.32, '[   <OK>   ] listening on logger')
    self:addLine(delay + 4.33, '[   <OK>   ] listening on (' .. self:getRandomArchWord() .. ') core procedure')
    self:addLine(delay + 4.34, '[   <OK>   ] listening on (' .. self:getRandomArchWord() .. ') control procedure')
    self:addLine(delay + 4.80, '[  ;WAIT,  ] allocating user and session (' .. self:getRandomArchWord() .. ') [' .. self:getRandomArchWord() .. ']', 1, {{';WAIT,', ' <OK> '}, {'allocating', 'allocated'}})
    self:addLine(delay + 4.81, '[  ;WAIT,  ] allocating system (' .. self:getRandomArchWord() .. ') [' .. self:getRandomArchWord() .. ']', 1.1, {{';WAIT,', ' <OK> '}, {'allocating', 'allocated'}})
    self:addLine(delay + 5.00, '[  ;WAIT,  ] mounting page file system (' .. self:getRandomArchWord() .. ') [' .. self:getRandomArchWord() .. ']', 1, {{';WAIT,', ' <OK> '}, {'mounting', 'mounted'}})
    self:addLine(delay + 5.01, '[  ;WAIT,  ] starting load core modules (' .. self:getRandomArchWord() .. ') [' .. self:getRandomArchWord() .. ']', 0.8, {{';WAIT,', ' <OK> '}, {'starting', 'started'}})
    self:addLine(delay + 5.2, '[  ;WAIT,  ] starting (' .. self:getRandomArchWord() .. ') devices', 0.4, {{';WAIT,', ' <OK> '}, {'starting', 'started'}})
    self:addLine(delay + 5.60, '[  ;WAIT,  ] starting virtual console', 1.2, {{';WAIT,', ' <OK> '}, {'starting', 'started'}})
    self:addLine(delay + 5.61, '[  ;WAIT,  ] mounting (' .. self:getRandomArchWord() .. ') message queue file system', 1.4, {{';WAIT,', ' <OK> '}, {'mounting', 'mounted'}})
    self:addLine(delay + 5.80, '[   <OK>   ] created list of required static nodes for the current core')
    self:addLine(delay + 5.81, '[  ;WAIT,  ] mounting temporary directory (' .. self:getRandomArchWord() .. ') [' .. self:getRandomArchWord() .. ']', 0.8, {{';WAIT,', ' <OK> '}, {'mounting', 'mounted'}})
    self:addLine(delay + 6.2, '[  ;WAIT,  ] starting root and core file systems [' .. self:getRandomArchWord() .. ']', 1.4, {{';WAIT,', ' <OK> '}, {'starting', 'started'}})
    self:addLine(delay + 6.40, '[  ;WAIT,  ] starting random seed [' .. self:getRandomArchWord() .. ']', 0.4, {{';WAIT,', ' <OK> '}, {'starting', 'started'}})
    self:addLine(delay + 6.41, '[  ;WAIT,  ] creating system users', 0.1, {{';WAIT,', ' <OK> '}, {'creating', 'created'}})
    self:addLine(delay + 6.42, '[  ;WAIT,  ] creating static nodes', 0.6, {{';WAIT,', ' <OK> '}, {'creating', 'created'}})
    self:addLine(delay + 6.80, '[  ;WAIT,  ] mounting configuration file system [' .. self:getRandomArchWord() .. ']', 0.4, {{';WAIT,', ' <OK> '}, {'mounting', 'mounted'}})
    self:addLine(delay + 6.81, '[  ;WAIT,  ] applying core variables [' .. self:getRandomArchWord() .. ']', 0.1, {{';WAIT,', ' <OK> '}, {'applying', 'applied'}})
    self:addLine(delay + 6.82, '[  ;WAIT,  ] starting (' .. self:getRandomArchWord() .. ') (' .. self:getRandomArchWord() .. ') manager', 1.2, {{';WAIT,', ' <OK> '}, {'starting', 'started'}})
    self:addLine(delay + 7.40, '[   <OK>   ] reached target (' .. self:getRandomArchWord() .. ')')
    self:addLine(delay + 7.41, '[   <OK>   ] reached target (' .. self:getRandomArchWord() .. ')')
    self:addLine(delay + 7.41, '[   <OK>   ] reached target (' .. self:getRandomArchWord() .. ')')
    self:addLine(delay + 7.42, '[   <OK>   ] reached target (' .. self:getRandomArchWord() .. ')')
    self:addLine(delay + 7.43, '[   <OK>   ] reached target (' .. self:getRandomArchWord() .. ')')
    self:addLine(delay + 7.80, '[   <OK>   ] reached target (' .. self:getRandomArchWord() .. ')')
    self:addLine(delay + 7.81, '[   <OK>   ] reached target (' .. self:getRandomArchWord() .. ')')
    self:addLine(delay + 8.00, '[   <OK>   ] reached target (' .. self:getRandomArchWord() .. ')')
    self:addLine(delay + 8.40, '[  ;WAIT,  ] starting primary message system path [' .. self:getRandomArchWord() .. ']', 5.6, {{';WAIT,', '@FAIL#'}, {'starting', 'could not start'}})
    self:addLine(delay + 9.80, '[  ;WAIT,  ] starting auxiliary message system path [' .. self:getRandomArchWord() .. ']', 4.2, {{';WAIT,', '@FAIL#'}, {'starting', 'could not start'}})
    self:addLine(delay + 11.00, '[  ;WAIT,  ] solving for optimal path [' .. self:getRandomArchWord() .. ']', 3.0, {{';WAIT,', '@FAIL#'}, {'solving', 'could not solve'}})
    self:addLine(delay + 12.00, '[  ;WAIT,  ] reaching target (' .. self:getRandomArchWord() .. ')', 2.0, {{';WAIT,', '@FAIL#'}, {'reaching', 'could not reach'}})
    self:addLine(delay + 12.01, '[  ;WAIT,  ] reaching target (' .. self:getRandomArchWord() .. ')', 2.0, {{';WAIT,', '@FAIL#'}, {'reaching', 'could not reach'}})
    self:addLine(delay + 12.02, '[  ;WAIT,  ] reaching target (' .. self:getRandomArchWord() .. ')', 2.0, {{';WAIT,', '@FAIL#'}, {'reaching', 'could not reach'}})
    self:addLine(delay + 12.03, '[  ;WAIT,  ] reaching target (' .. self:getRandomArchWord() .. ')', 2.0, {{';WAIT,', '@FAIL#'}, {'reaching', 'could not reach'}})
    self:addLine(delay + 12.04, '[  ;WAIT,  ] reaching target (' .. self:getRandomArchWord() .. ')', 2.0, {{';WAIT,', '@FAIL#'}, {'reaching', 'could not reach'}})
    self:addLine(delay + 12.05, '[  ;WAIT,  ] reaching core target (' .. self:getRandomArchWord() .. ')', 2.0, {{';WAIT,', '@FAIL#'}, {'reaching', 'could not reach'}})
    self:addLine(delay + 12.06, '[  ;WAIT,  ] reaching core target (' .. self:getRandomArchWord() .. ')', 2.0, {{';WAIT,', '@FAIL#'}, {'reaching', 'could not reach'}})
    self:addLine(delay + 12.07, '[  ;WAIT,  ] reaching core target (' .. self:getRandomArchWord() .. ')', 2.0, {{';WAIT,', '@FAIL#'}, {'reaching', 'could not reach'}})
    self:addLine(delay + 12.08, '[  ;WAIT,  ] reaching core target (' .. self:getRandomArchWord() .. ')', 2.0, {{';WAIT,', '@FAIL#'}, {'reaching', 'could not reach'}})
    self:addLine(delay + 12.09, '[  ;WAIT,  ] reaching target (' .. self:getRandomArchWord() .. ')', 2.0, {{';WAIT,', '@FAIL#'}, {'reaching', 'could not reach'}})
    self:addLine(delay + 12.10, '[  ;WAIT,  ] reaching target (' .. self:getRandomArchWord() .. ')', 2.0, {{';WAIT,', '@FAIL#'}, {'reaching', 'could not reach'}})
    self:addLine(delay + 14.25, '')
    self:addLine(delay + 14.30, '@PATHING ERROR DETECTED#')
    self:addLine(delay + 14.35, '')
    for i = 1, 8 do self:addLine(delay + 14.55 + i*0.05, ':: could not reach node @(' .. self:getRandomArchWord() .. ')# @[' .. self:getRandomArchWord() .. ']#') end
    self:addLine(delay + 15.25, '')
    self:addLine(delay + 15.30, ';MANUAL INTERVENTION REQUIRED,')
    self:addLine(delay + 15.35, '')
    self:addLine(delay + 16.20, '[  ;WAIT,  ] starting safe user and session (' .. self:getRandomArchWord() .. ') [' .. self:getRandomArchWord() .. ']', 0.5, {{';WAIT,', ' <OK> '}, {'starting', 'started'}})
    self:addLine(delay + 16.21, ":: mounting '/dev/pathfinder/arch-pathfinder' to /tmp-[root]/")
    self:addLine(delay + 16.22, ":: device '/dev/pathfinder/arch-pathfinder' mounted successfully'")
    self:addLine(delay + 16.40, ':: running PATHFINDER [byte]')
    self:addLine(delay + 16.80, '[   <OK>   ] reached target (' .. self:getRandomArchWord() .. ')')
    self:addLine(delay + 16.81, '[   <OK>   ] reached target (' .. self:getRandomArchWord() .. ')')
    self:addLine(delay + 16.82, '[   <OK>   ] reached target (' .. self:getRandomArchWord() .. ')')
    self:addLine(delay + 17.43, '[   <OK>   ] reached target (' .. self:getRandomArchWord() .. ')')
    self:addLine(delay + 17.44, '[   <OK>   ] reached target (' .. self:getRandomArchWord() .. ')')
    self:addLine(delay + 17.80, '[  ;WAIT,  ] starting primary repair system [' .. self:getRandomArchWord() .. ']', 2.0, {{';WAIT,', ' <OK> '}, {'starting', 'started'}})
    self:addLine(delay + 17.90, '[  ;WAIT,  ] starting auxiliary repair system [' .. self:getRandomArchWord() .. ']', 2.0, {{';WAIT,', ' <OK> '}, {'starting', 'started'}})

    self:addLine(delay + 19.00, '')
    self:addLine(delay + 19.30, '')

    self:bytepathMain(delay + 20.00)
end

function Console:rgbShift()
    self.rgb_shift_mag = random(1, 1.5)
    self.timer:tween(0.1, self, {rgb_shift_mag = 0}, 'in-out-cubic', 'rgb_shift')
end

function Console:glitch(x, y)
    for i = 1, 6 do
        self.timer:after(0.1*i, function()
            self.area:addGameObject('GlitchDisplacement', x + random(-32, 32), y + random(-32, 32)) 
        end)
    end
end

function Console:glitchError()
    for i = 1, 10 do self.timer:after(0.1*i, function() self.area:addGameObject('GlitchDisplacement') end) end
    self.rgb_shift_mag = random(4, 8)
    self.timer:tween(1, self, {rgb_shift_mag = 0}, 'in-out-cubic', 'rgb_shift')
end
