Options = Object:extend()

function Options:new()
    self.timer = Tim()
    self.font = fonts.Anonymous_8 or fonts.m5x7_16 or fonts.pixeled_8
    camera:lookAt(gw/2, gh/2)
    camera.scale = 1
    self.area = Area(self)

    -- Build a single "list" of selectable rows. The order is fixed; the
    -- selection index walks the list. Some rows are settings (toggle /
    -- slider), the last row is "back".
    self.rows = {
        {kind = 'header',   text = '~ OPTIONS'},
        {kind = 'mode',     key = 'display_mode', label = 'display mode'},
        {kind = 'scale',    key = 'window_scale', label = 'window size'},
        {kind = 'monitor',  key = 'display',      label = 'monitor'},
        {kind = 'action',   action = 'back',       label = '~ back to console'},
    }
    self.index = 2  -- first selectable (skip header)
    self.buttons = {
        left  = {x = 32, y = gh - 24, w = 64, h = 16, label = '<- left'},
        right = {x = gw - 96, y = gh - 24, w = 64, h = 16, label = 'right ->'},
        apply = {x = gw/2 - 32, y = gh - 24, w = 64, h = 16, label = 'enter'},
        back  = {x = 8, y = 8, w = 56, h = 16, label = '~ back'},
    }

    input:unbindAll()
    input:bind('left', 'left')
    input:bind('right', 'right')
    input:bind('up', 'up')
    input:bind('down', 'down')
    input:bind('return', 'enter')
    input:bind('escape', 'back')
    input:bind('mouse1', 'click')
end

function Options:update(dt)
    self.timer:update(dt)
    self.area:update(dt)

    if input:pressed('up') then
        self.index = self.index - 1
        if self.index < 2 then self.index = #self.rows end
        playMenuSwitch()
    elseif input:pressed('down') then
        self.index = self.index + 1
        if self.index > #self.rows then self.index = 2 end
        playMenuSwitch()
    elseif input:pressed('left') or input:pressed('right') then
        local row = self.rows[self.index]
        if not row or row.kind == 'header' or row.kind == 'action' then return end
        local dir = input:pressed('right') and 1 or -1
        if row.kind == 'mode' then
            local i = 1
            for k, v in ipairs(display_mode_list) do
                if v == display_mode then i = k; break end
            end
            i = ((i - 1 + dir) % #display_mode_list) + 1
            display_mode = display_mode_list[i]
            applyDisplayMode()
            playMenuSwitch()
        elseif row.kind == 'scale' then
            -- Scale slider is irrelevant for fullscreen / desktop
            if display_mode == 'windowed' then
                window_scale = clampWindowScale(window_scale + dir)
                applyDisplayMode()
                playMenuSwitch()
            end
        elseif row.kind == 'monitor' then
            local n = love.window.getDisplayCount()
            if n <= 1 then return end
            display = ((display - 1 + dir) % n) + 1
            applyDisplayMode()
            playMenuSwitch()
        end
    elseif input:pressed('enter') then
        local row = self.rows[self.index]
        if row and row.kind == 'action' and row.action == 'back' then
            playKeystroke()
            gotoRoom('Console')
        end
    end

    if input:pressed('click') then
        local mx, my = love.mouse.getPosition()
        -- Letterbox: convert window coords to game canvas coords
        local ox, oy, s = getLetterboxOffset()
        local gx, gy = (mx - ox) / s, (my - oy) / s
        for k, b in pairs(self.buttons) do
            if gx >= b.x and gx <= b.x + b.w and gy >= b.y and gy <= b.y + b.h then
                if k == 'left' then
                    self:_step(-1)
                elseif k == 'right' then
                    self:_step(1)
                elseif k == 'apply' then
                    local row = self.rows[self.index]
                    if row and row.kind == 'action' and row.action == 'back' then
                        gotoRoom('Console')
                    end
                elseif k == 'back' then
                    gotoRoom('Console')
                end
            end
        end
    end
end

function Options:_step(dir)
    local row = self.rows[self.index]
    if not row or row.kind == 'header' or row.kind == 'action' then return end
    if row.kind == 'mode' then
        local i = 1
        for k, v in ipairs(display_mode_list) do
            if v == display_mode then i = k; break end
        end
        i = ((i - 1 + dir) % #display_mode_list) + 1
        display_mode = display_mode_list[i]
    elseif row.kind == 'scale' and display_mode == 'windowed' then
        window_scale = clampWindowScale(window_scale + dir)
    elseif row.kind == 'monitor' then
        local n = love.window.getDisplayCount()
        if n > 1 then display = ((display - 1 + dir) % n) + 1 end
    end
    applyDisplayMode()
    playMenuSwitch()
end

function Options:draw()
    -- LÖVE 11.5 path: render straight to the screen via drawGameCanvas
    love.graphics.setCanvas()
    love.graphics.setShader()
    love.graphics.setBlendMode('alpha')
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    local font = self.font
    love.graphics.setFont(font)

    -- Title
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print('OPTIONS', gw/2 - 28, 8)

    -- Rows
    local y = 32
    for i, row in ipairs(self.rows) do
        if row.kind == 'header' then
            love.graphics.setColor(default_color[1]/255, default_color[2]/255, default_color[3]/255, 1)
            love.graphics.print(row.text, 8, y)
        elseif row.kind == 'action' then
            local r, g, b = default_color[1]/255, default_color[2]/255, default_color[3]/255
            if i == self.index then
                love.graphics.setColor(0, 0, 0, 1)
                love.graphics.rectangle('fill', 8, y - 1, gw - 16, 9)
                love.graphics.setColor(r, g, b, 1)
            else
                love.graphics.setColor(r, g, b, 0.6)
            end
            love.graphics.print(row.label, 8, y)
        else
            -- Setting row: "label: value"
            local value
            if row.key == 'display_mode' then
                if display_mode == 'windowed' then value = 'windowed'
                elseif display_mode == 'fullscreen' then value = 'fullscreen (exclusive)'
                else value = 'desktop (borderless)' end
            elseif row.key == 'window_scale' then
                if display_mode == 'windowed' then
                    value = window_scale .. 'x  (' .. gw*window_scale .. 'x' .. gh*window_scale .. ')'
                else
                    value = '- (windowed mode only)'
                end
            elseif row.key == 'display' then
                value = 'monitor ' .. display .. ' / ' .. love.window.getDisplayCount()
            end

            local r, g, b = default_color[1]/255, default_color[2]/255, default_color[3]/255
            if i == self.index then
                love.graphics.setColor(0, 0, 0, 1)
                love.graphics.rectangle('fill', 8, y - 1, gw - 16, 9)
                love.graphics.setColor(r, g, b, 1)
            else
                love.graphics.setColor(r, g, b, 0.6)
            end
            love.graphics.print(row.label .. ':', 8, y)
            love.graphics.print(value, 96, y)
        end
        y = y + 12
    end

    -- Bottom hint
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.print('up/down = select   left/right = change   enter/click = back', 8, gh - 12)
end

function Options:destroy() end
