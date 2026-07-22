-- Paused overlay shown when the player hits Esc / loses focus in Stage.
-- Renders AFTER the Stage shader pipeline so glitch/scanline artifacts
-- on the paused frame don't smear over the menu. The dimming layer
-- keeps the game readable in the background, and the menu sits in
-- its own self-contained box at viewport-centre.

Paused = Object:extend()

function Paused:new(stage)
    self.stage = stage
    self.font = fonts.Anonymous_8
    self.resume = true
    fadeVolume('music', 1, 0.05)
end

function Paused:update(dt)
    if input:pressed('left') or input:pressed('right') then self.resume = not self.resume end
    if input:pressed('return') or input:pressed('up') then
        if self.resume then
            self.stage:pause()
            fadeVolume('music', 2, 0.25)
        else
            playMenuBack()
            gotoRoom('Console')
        end
    end
end

function Paused:draw()
    love.graphics.setFont(self.font)

    -- Dimming overlay (covers the whole viewport). Drawn at the end of the
    -- Stage render pipeline (after drawGameCanvas), so it's stable and
    -- isn't shifted by glitch/displacement distortion.
    love.graphics.setColor(0, 0, 0, 0.65)
    love.graphics.rectangle('fill', 0, 0, gw, gh)

    love.graphics.setColor(1, 1, 1, 1)

    -- Layout: two pill-shaped buttons in the centre of the viewport.
    local btn_w, btn_h = 96, 22
    local gap = 12
    local total_w = btn_w * 2 + gap
    local cx = math.floor((gw - total_w) / 2)
    local cy = math.floor((gh - btn_h) / 2)

    -- RESUME button
    if self.resume then
        love.graphics.setColor(skill_point_color[1]/255, skill_point_color[2]/255, skill_point_color[3]/255, 0.95)
    else
        love.graphics.setColor(34/255, 34/255, 38/255, 1)
    end
    love.graphics.rectangle('fill', cx, cy, btn_w, btn_h)

    if self.resume then
        love.graphics.setColor(0, 0, 0, 1)
    else
        love.graphics.setColor(222/255, 222/255, 222/255, 0.45)
    end
    love.graphics.print('RESUME',
        cx + btn_w/2 - self.font:getWidth('RESUME')/2,
        cy + math.floor((btn_h - self.font:getHeight())/2))

    -- MENU button
    if not self.resume then
        love.graphics.setColor(skill_point_color[1]/255, skill_point_color[2]/255, skill_point_color[3]/255, 0.95)
    else
        love.graphics.setColor(34/255, 34/255, 38/255, 1)
    end
    love.graphics.rectangle('fill', cx + btn_w + gap, cy, btn_w, btn_h)

    if not self.resume then
        love.graphics.setColor(0, 0, 0, 1)
    else
        love.graphics.setColor(222/255, 222/255, 222/255, 0.45)
    end
    love.graphics.print('MENU',
        cx + btn_w + gap + btn_w/2 - self.font:getWidth('MENU')/2,
        cy + math.floor((btn_h - self.font:getHeight())/2))

    -- Hint label below the buttons.
    love.graphics.setColor(1, 1, 1, 0.75)
    local hint = '<- ->  switch    enter  confirm'
    local hint_w = self.font:getWidth(hint)
    love.graphics.print(hint,
        math.floor((gw - hint_w) / 2),
        cy + btn_h + 8)
end
