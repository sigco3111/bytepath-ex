Classes = Object:extend()

function Classes:new()
    self.timer = Timer()
    self.area = Area(self)

    -- Reset camera state from whatever previous room left behind.
    camera:lookAt(gw/2, gh/2)
    camera.scale = 1
    if Camera.smooth and Camera.smooth.damped then
        camera.smoother = Camera.smooth.none and Camera.smooth.none() or nil
    end

    self.font = fonts.Anonymous_8
    self.main_canvas = love.graphics.newCanvas(gw, gh)
    self.final_canvas = love.graphics.newCanvas(gw, gh)
    self.temp_canvas = love.graphics.newCanvas(gw, gh)
    self.glitch_canvas = love.graphics.newCanvas(gw, gh)
    self.rgb_canvas = love.graphics.newCanvas(gw, gh)
    -- Single offscreen target so the viewport fits the live window via drawGameCanvas.
    self.render_canvas = love.graphics.newCanvas(gw, gh)
    self.rgb_shift_mag = 0

    self.classes = {
        [1] = {'Gunner', 'Tanker', 'Runner', 'Cycler'},
        [2] = {'Buster', 'Buffer', 'Berserker', 'Shielder', 'Regeneer', 'Recycler', 'Absorber', 'Turner', 'Driver', 'Swapper', 'Barrager', 'Seeker'},
        [3] = {'Buster', 'Buffer', 'Berserker', 'Shielder', 'Regeneer', 'Recycler', 'Absorber', 'Turner', 'Driver', 'Swapper', 'Barrager', 'Seeker'},
        [4] = {'Buster', 'Buffer', 'Berserker', 'Shielder', 'Regeneer', 'Recycler', 'Absorber', 'Turner', 'Driver', 'Swapper', 'Barrager', 'Seeker'},
        [5] = {'Repeater', 'Launcher', 'Panzer', 'Reserver', 'Deployer', 'Booster', 'Processor', 'Gambler'},
        [6] = {'Repeater', 'Launcher', 'Panzer', 'Reserver', 'Deployer', 'Booster', 'Processor', 'Gambler'},
        [7] = {'Discharger', 'Hoamer', 'Splitter', 'Spinner', 'Bouncer', 'Blaster', 'Raider', 'Waver', 'Bomber', 'Zoomer', 'Racer', 'Miner'},
        [8] = {'Discharger', 'Hoamer', 'Splitter', 'Spinner', 'Bouncer', 'Blaster', 'Raider', 'Waver', 'Bomber', 'Zoomer', 'Racer', 'Miner'},
        [9] = {'Piercer', 'Dasher', 'Engineer', 'Threader'},
    }

    for _, class in ipairs(classes) do
        for i = 1, 9 do
            for j = #self.classes[i], 1, -1 do
                if class == self.classes[i][j] then
                    table.remove(self.classes[i], j)
                end
            end
        end
    end

    self.class_colors = { 
        ['Gunner'] = ammo_color, ['Tanker'] = hp_color, ['Runner'] = boost_color, ['Cycler'] = default_color,
        ['Buster'] = ammo_color, ['Buffer'] = ammo_color, ['Berserker'] = ammo_color, ['Shielder'] = hp_color,
        ['Regeneer'] = hp_color, ['Recycler'] = hp_color, ['Absorber'] = boost_color, ['Turner'] = boost_color,
        ['Driver'] = boost_color, ['Swapper'] = default_color, ['Barrager'] = default_color, ['Seeker'] = default_color,
        ['Repeater'] = ammo_color, ['Launcher'] = ammo_color, ['Panzer'] = hp_color, ['Reserver'] = hp_color, 
        ['Deployer'] = boost_color, ['Booster'] = boost_color, ['Processor'] = default_color, ['Gambler'] = default_color,
        ['Discharger'] = boost_color, ['Hoamer'] = skill_point_color, ['Splitter'] = boost_color, ['Bouncer'] = default_color,
        ['Blaster'] = default_color, ['Raider'] = skill_point_color, ['Waver'] = ammo_color, ['Bomber'] = hp_color, ['Zoomer'] = boost_color,
        ['Racer'] = boost_color, ['Miner'] = ammo_color, ['Piercer'] = ammo_color, ['Dasher'] = boost_color, ['Engineer'] = hp_color, ['Threader'] = default_color
    }

    self.class_info = {
        ['Gunner'] = {
            'CLASS: GUNNER',
            '',
            '+15% ASPD',
            '+25% PSPD',
        },

        ['Tanker'] = {
            'CLASS: TANKER',
            '',
            '+25% HP',
            '+25% Ammo',
        },

        ['Runner'] = {
            'CLASS: RUNNER',
            '',
            '+25% MVSPD',
            '+25% Boost',
        },

        ['Cycler'] = {
            'CLASS: CYCLER',
            '',
            '+25% Luck',
            '+25% Cycle Speed',
        },

        ['Buster'] = {
            'CLASS: BUSTER',
            '',
            '+50% Projectile Size',
            '+25% Projectile Duration',
            '-15% HP',
            '-15% ASPD',
        },

        ['Buffer'] = {
            'CLASS: BUFFER',
            '',
            '+50% Stat Boost Duration',
            '-20% Boost',
        },

        ['Berserker'] = {
            'CLASS: BERSERKER',
            '',
            'Consecutive kills grant you RAMPAGE',
            'RAMPAGE grants you buffs as it grows',
            'RAMPAGE grants you +1% ASPD per 10',
            'RAMPAGE grants you +1% PSPD per 10',
            '-25% Luck',
        },

        ['Shielder'] = {
            'CLASS: SHIELDER',
            '',
            '+25% Shield Projectile Chance',
            '+25% Projectile Duration',
            '-25% Shield Projectile Damage',
        },

        ['Regeneer'] = {
            'CLASS: REGENEER',
            '',
            'Restores 25 HP on Item Pickup',
            '-15% MVSPD',
        },

        ['Recycler'] = {
            'CLASS: RECYCLER',
            '',
            'When ammo reaches 0:',
            '    Create a protective barrier that',
            '    protects for the next (AMMO/50)',
            '    projectile hits',
            '+50% Ammo Consumption',
        },

        ['Absorber'] = {
            'CLASS: ABSORBER',
            '',
            'Absorbs hits',
            'Absorbed projectiles consume 25 boost',
            'Absorbed hits consume 50 boost',
            'Cannot absorb without enough boost',
        },

        ['Turner'] = {
            'CLASS: TURNER',
            '',
            'Boosting up increases turn rate',
            'Boosting down decreases turn rate',
        },

        ['Driver'] = {
            'CLASS: DRIVER',
            '',
            '+30% Invulnerability Time',
            '+30% Boost Recharge Rate',
            '+30% Size',
        },

        ['Swapper'] = {
            'CLASS: SWAPPER',
            '',
            'Gain a buff when attack is changed',
            '-10% HP',
            '-10% Ammo',
            '-10% MVSPD',
            '-10% PSPD',
        },

        ['Barrager'] = {
            'CLASS: BARRAGER',
            '',
            '+5% Barrage on Kill Chance',
            '+10% Barrage on Cycle Chance',
            '+2 Barrage Projectiles',
            "Can't Launch Homing Projectiles",
            '-25% ASPD',
        },

        ['Seeker'] = {
            'CLASS: SEEKER',
            '',
            '+10% Launch Homing Proj on Kill Chance',
            '+5% Launch Homing Proj on Cycle Chance',
            '+1 Homing Projectile',
            "Can't Barrage",
            '-25% ASPD',
        },

        ['Processor'] = {
            'CLASS: PROCESSOR',
            '',
            '+50% Cycle Speed',
            '-25% HP',
            '-50% Spawn SP Chance',
        },

        ['Gambler'] = {
            'CLASS: GAMBLER',
            '',
            '+50% Luck',
            "Can't trigger \"On Cycle\" events",
        },

        ['Panzer'] = {
            'CLASS: PANZER',
            '',
            '+50% HP',
            '+50% Size',
            '-25% MVSPD',
        },

        ['Reserver'] = {
            'CLASS: RESERVER',
            '',
            'When ammo reaches 0:',
            '    Change to new attack',
            '+50% Ammo',
            '-25% ASPD',
        },

        ['Repeater'] = {
            'CLASS: REPEATER',
            '',
            '+50% ASPD',
            '-25% Damage',
        },

        ['Launcher'] = {
            'CLASS: LAUNCHER',
            '',
            '+75% PSPD',
            '+25% Projectile Duration',
            '-20% HP',
            '-20% Ammo',
        },

        ['Deployer'] = {
            'CLASS: DEPLOYER',
            '',
            '+25% MVSPD',
            '-25% Size',
            '+25% Chance to Drop Mines',
        },

        ['Booster'] = {
            'CLASS: BOOSTER',
            '',
            '+50% Boost',
            '-25% Ammo',
            '-25% Luck',
        },

        ['Discharger'] = {
            'CLASS: DISCHARGER',
            '',
            '+2 Lightning Bolts',
            '+50% Lightning Trigger Distance',
            'Lightning Targets Projectiles',
        },

        ['Hoamer'] = {
            'CLASS: HOAMER',
            '',
            '+50% Homing Speed',
            '+1 Homing Projectile',
            '+10% Chance to Attack Twice',
        },

        ['Splitter'] = {
            'CLASS: SPLITTER',
            '',
            '+15% Split Projectile Split Chance',
            '+25% PSPD',
        },

        ['Spinner'] = {
            'CLASS: SPINNER',
            '',
            '+50% Chance to Create Spin Proj on Expiration',
            '+25% Projectile Duration',
        },

        ['Bouncer'] = {
            'CLASS: BOUNCER',
            '',
            '+4 Bounce to Bounce Projectiles',
            '-50% PSPD',
        },

        ['Blaster'] = {
            'CLASS: BLASTER',
            '',
            '+8 Blast Projectiles',
            'If Blast Projs are Shield Projs:',
            '    +500% Projectile Duration',
        },

        ['Raider'] = {
            'CLASS: RAIDER',
            '',
            '+50% Luck to SP Related Passives',
            '+100% Chance to Spawn SP',
        },

        ['Waver'] = {
            'CLASS: WAVER',
            '',
            '+50% Projectile Waviness',
            '+50% Projectile Angle Change Frequency',
        },

        ['Bomber'] = {
            'CLASS: BOMBER',
            '',
            '+25% Area',
            '+25% Chance to Attack Twice',
        },

        ['Zoomer'] = {
            'CLASS: ZOOMER',
            '',
            '+30% MVSPD',
            '-30% Size',
        },

        ['Racer'] = {
            'CLASS: RACER',
            '',
            'Ammo gives Boost instead',
            '-50% Ammo',
        },

        ['Miner'] = {
            'CLASS: MINER',
            '',
            '+50% Resource Spawn Rate',
            '+25% Item Spawn Rate',
        },

        ['Piercer'] = {
            'CLASS: PIERCER',
            '',
            '+2 Projectile Pierce',
            '-15% HP',
            '-15% Ammo',
            '-15% Boost',
            '-15% MVSPD',
            '-15% ASPD',
        },

        ['Dasher'] = {
            'CLASS: DASHER',
            '',
            'Boosting forward twice dashes forward',
            'Become invulnerable for 1s after dash',
            'Dash consumes 50 boost',
            'Creates 10 explosions after dash',
        },

        ['Engineer'] = {
            'CLASS: ENGINEER',
            '',
            '2 drones follow the player',
            "Drones inherit player's passives",
            'Drones are invulnerable',
            'Drones have +50% ASPD',
            'Drones deal -50% damage',
            '-50% Ammo',
        },

        ['Threader'] = {
            'CLASS: THREADER',
            '',
            'Adds 3 additional cycles',
            'Each cycle has:',
            '    -53% Cycle Speed',
            '    -78% Cycle Speed',
            '    -94% Cycle Speed',
        },
    }

    self.selection_index = 1

    self.timer:every(0.1, function() 
        self.area:addGameObject('GlitchDisplacement') 
    end)
end

function Classes:update(dt)
    self.timer:update(dt)
    self.area:update(dt)

    -- Console
    local pmx, pmy = love.mouse.getPosition()
    local text = 'CONSOLE'
    local w = self.font:getWidth(text)
    local x, y = gw - w - 15, 5
    if (pmx >= sx*x and pmx <= sx*(x + w + 10) and pmy >= sy*y and pmy <= sy*(y + 16) and input:pressed('left_click')) or input:pressed('escape') then
        save()
        playMenuBack()
        gotoRoom('Console')
    end

    local n = 3
    if rank == 1 then n = 4 end
    if rank >= 2 and rank <= 4 then n = 3 end
    if rank >= 5 and rank <= 6 then n = 2 end
    if rank >= 7 and rank <= 8 then n = 4 end
    if rank == 9 then n = 4 end
    if rank == 10 then return end

    if input:pressed('left') then
        self.selection_index = self.selection_index - 1
        if self.selection_index == 0 or self.selection_index == n or self.selection_index == 2*n or self.selection_index == 3*n then 
            self.selection_index = self.selection_index + n
            if self.selection_index > #self.classes[rank] then self.selection_index = #self.classes[rank] end
        end
        playMenuSwitch()
        self:changedIndex()
    end
    if input:pressed('right') then
        self.selection_index = self.selection_index + 1
        if self.selection_index == n+1 or self.selection_index == 2*n+1 or self.selection_index == 3*n+1 then self.selection_index = self.selection_index - n
        elseif self.selection_index > #self.classes[rank] then
            if rank >= 1 and rank <= n then self.selection_index = 1
            elseif rank >= n+1 and rank <= 2*n then self.selection_index = n+1
            elseif rank >= 2*n+1 and rank <= 3*n then self.selection_index = 2*n+1
            elseif rank >= 3*n+1 and rank <= #self.classes[rank] then self.selection_index = 3*n+1 end
        end
        playMenuSwitch()
        self:changedIndex()
    end
    if input:pressed('up') then
        self.selection_index = self.selection_index - n
        if self.selection_index < 1 then 
            self.selection_index = #self.classes[rank] + self.selection_index
            if self.selection_index > #self.classes[rank] then self.selection_index = #self.classes[rank] end
        end
        playMenuSwitch()
        self:changedIndex()
    end
    if input:pressed('down') then
        self.selection_index = self.selection_index + n
        if self.selection_index > #self.classes[rank] then 
            self.selection_index = self.selection_index - #self.classes[rank]
            if self.selection_index < 1 then self.selection_index = 1 end
        end
        playMenuSwitch()
        self:changedIndex()
    end

    if input:pressed('return') then
        if skill_points >= rank*5 then
            skill_points = skill_points - rank*5
            spent_sp = spent_sp + rank*5
            if rank == 2 or rank == 3 or rank == 4 then
                classes[rank] = table.remove(self.classes[2], self.selection_index)
                classes[rank] = table.remove(self.classes[3], self.selection_index)
                classes[rank] = table.remove(self.classes[4], self.selection_index)
            elseif rank == 5 or rank == 6 then
                classes[rank] = table.remove(self.classes[5], self.selection_index)
                classes[rank] = table.remove(self.classes[6], self.selection_index)
            elseif rank == 7 or rank == 8 then
                classes[rank] = table.remove(self.classes[7], self.selection_index)
                classes[rank] = table.remove(self.classes[8], self.selection_index)
            else
                classes[rank] = table.remove(self.classes[rank], self.selection_index)
            end
            rank = rank + 1
            self.selection_index = 1
            playMenuSelect()
            self:rgbShift()
        else
            self.cant_buy_error = 'NOT ENOUGH SKILL POINTS'
            self.timer:after(0.5, function() self.cant_buy_error = false end)
            playMenuError()
            self:glitchError()
        end
    end
end

function Classes:draw()
    -- Same render pattern as SkillTree: paint the viewport into self.render_canvas
    -- (480×270), then hand it to drawGameCanvas so the viewport fills the live
    -- window via the standard letterbox scaling instead of just sitting in the
    -- top-left corner.
    love.graphics.setFont(self.font)
    love.graphics.setCanvas(self.render_canvas)
    love.graphics.clear(0, 0, 0, 1)
    camera:attach(0, 0, gw, gh)

    local drawNormalButton = function(x, y, w, h, text, color)
        -- color: {r,g,b} 0..1 expected; caller passes globals that are 0..255 — divide here
        local function to01(c) return {c[1]/255, c[2]/255, c[3]/255} end
        drawCenteredRectangle('fill', x, y, w, h, {16/255, 16/255, 16/255})
        drawCenteredRectangle('line', x, y, w, h, {4/255, 4/255, 4/255})
        printCenteredText(text, x, y, self.font, to01(color or default_color))
    end

    local drawInvertedButton = function(x, y, w, h, text, color)
        -- Inverted = light fill, dark text. Always readable regardless of selection state.
        drawCenteredRectangle('fill', x, y, w, h, {222/255, 222/255, 222/255})
        drawCenteredRectangle('line', x, y, w, h, {1, 1, 1})
        printCenteredText(text, x, y, self.font, {16/255, 16/255, 16/255})
        -- Selection marker: drawn AFTER the button so it sits on top of the glitch/distort.
        love.graphics.setColor(1, 1, 1)
        love.graphics.print('>', x - w/2 - 6, y - 4)
        love.graphics.print('<', x + w/2 + 1, y - 4)
    end

    -- for i = 1, 9 do love.graphics.rectangle('line', 8, 50 + (i-1)*24, gw/2 + gw/6, 20) end
    for i = 1, rank do
        if i == 10 then goto continue end
        local n = 3
        if i == 1 then n = 4 end
        if i >= 2 and i <= 4 then n = 3 end
        if i >= 5 and i <= 6 then n = 2 end
        if i >= 7 and i <= 8 then n = 4 end
        if i == 9 then n = 4 end
        local y = 28 + (i-1)*24 + 10
        drawNormalButton(8 + 24, y, 48, 16, 'Rank ' .. i, default_color)
        if not classes[i] then drawNormalButton(8 + 24 + 56, y, 64, 16, 'COST: ' .. tostring(rank*5) .. 'SP', skill_point_color) end
        if classes[i] then drawNormalButton(8 + 24 + 48, y, 48, 16, classes[i], self.class_colors[classes[i]])
        else
            for j = 1, #self.classes[i] do
                if self.selection_index == j then drawInvertedButton(92 + 60 + ((j-1) % n)*48, y + (math.ceil(j/n)-1)*24, 48, 16, self.classes[i][j])
                else drawNormalButton(92 + 60 + ((j-1) % n)*48, y + (math.ceil(j/n)-1)*24, 48, 16, self.classes[i][j], self.class_colors[self.classes[i][j]]) end
            end
        end
    end
    ::continue::

    if self.visible and rank < 10 and self.classes[rank] and self.classes[rank][self.selection_index] then
        local offset = 0
        if rank == 1 then offset = 48 end
        local x, y = offset + 8 + gw/2 + 32 + 12, 38
        local info = self.class_info[self.classes[rank][self.selection_index]]
        if info then
            -- Background plate so text is always readable on top of glitch/distort artifacts
            love.graphics.setColor(0, 0, 0, 0.55)
            love.graphics.rectangle('fill', x - 6, y - 6, gw - x - 8, #info * 12 + 4)
            for i, line_text in ipairs(info) do
                love.graphics.setColor(1, 1, 1)
                love.graphics.print(line_text, x, y + 12*(i-1), 0, 1, 1, 0, self.font:getHeight()/2)
            end
        end
    end

    -- Console button
    local pmx, pmy = love.mouse.getPosition()
    local text = 'CONSOLE'
    local w = self.font:getWidth(text)
    local x, y = gw - w - 15, 5
    love.graphics.setColor(0, 0, 0, 222/255)
    love.graphics.rectangle('fill', x, y, w + 10, 16)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(text, x + 5, y + 3)
    if pmx >= sx*x and pmx <= sx*(x + w + 10) and pmy >= sy*y and pmy <= sy*(y + 16) then love.graphics.rectangle('line', x, y, w + 10, 16) end

    love.graphics.setColor(1, 1, 1)
    love.graphics.print('~ CLASSES:', 8, 10)
    love.graphics.setColor({skill_point_color[1]/255, skill_point_color[2]/255, skill_point_color[3]/255})
    love.graphics.print('~ SP: ' .. tostring(skill_points), 8, gh - 20)
    love.graphics.setColor(1, 1, 1)

    -- Can't buy
    if self.cant_buy_error then
        local text = self.cant_buy_error
        local w = self.font:getWidth(text)
        local x, y = gw/2 - w/2 - 5, gh/2 - 12
        local r, g, b = hp_color[1]/255, hp_color[2]/255, hp_color[3]/255
        love.graphics.setColor(r, g, b, 0.9)
        love.graphics.rectangle('fill', x, y, w + 10, 24)
        love.graphics.setColor(0, 0, 0)
        love.graphics.print(text, math.floor(x + 5), math.floor(y + 8))
    end

    local r, g, b = skill_point_color[1]/255, skill_point_color[2]/255, skill_point_color[3]/255
    love.graphics.setColor(r, g, b)
    love.graphics.print(skill_points .. 'SP', gw - 20, 26, 0, 1, 1, math.floor(self.font:getWidth(skill_points .. 'SP')/2), math.floor(self.font:getHeight()/2))
    love.graphics.setColor(1, 1, 1)

    camera:detach()

    -- Hand the viewport off to drawGameCanvas so it fills the live window.
    love.graphics.setCanvas()
    drawGameCanvas(self.render_canvas)
end

function Classes:destroy()
    
end

function Classes:changedIndex()
    self.timer:every(0.035, function() self.visible = not self.visible end, 5)
    self.timer:after(0.035*5 + 0.02, function() self.visible = true end)
end

function Classes:rgbShift()
    self.rgb_shift_mag = random(2, 4)
    self.timer:tween('rgb_shift', 0.25, self, {rgb_shift_mag = 0}, 'in-out-cubic')
end

function Classes:glitch(x, y)
    for i = 1, 6 do
        self.timer:after(0.1*i, function()
            self.area:addGameObject('GlitchDisplacement', x + random(-32, 32), y + random(-32, 32)) 
        end)
    end
end

function Classes:glitchError()
    for i = 1, 10 do self.timer:after(0.1*i, function() self.area:addGameObject('GlitchDisplacement') end) end
    self.rgb_shift_mag = random(4, 8)
    self.timer:tween('rgb_shift', 1, self, {rgb_shift_mag = 0}, 'in-out-cubic')
end
