Steam = nil
-- BYTEPATH는 Steamworks 없이도 싱글플레이로 실행할 수 있습니다.
-- 원본의 FFI Steamworks 로딩은 macOS용 Steam SDK가 없으면 require 단계에서 실패하므로 비활성화합니다.

Object = require 'libraries/classic/classic'
Timer = require 'libraries/enhanced_timer/EnhancedTimer'
Input = require 'libraries/boipushy/Input'
fn = require 'libraries/moses/moses'
Camera = require 'libraries/hump/camera'
Physics = require 'libraries/windfield'
Vector = require 'libraries/hump/vector-light'
draft = require('libraries/draft/draft')()
bitser = require 'libraries/bitser/bitser'
Math = require 'libraries/mlib/mlib'
Grid = require 'libraries/grid/grid'
Cam = require 'libraries/STALKER-X/Camera'
Tim = require 'libraries/chrono/Timer'
binser = require 'libraries/binser/binser'
HC = require 'libraries/HC'
ffi = require('ffi')

-- require 'enet'
require 'libraries/sound'
require 'libraries/utf8'
require 'GameObject'
require 'utils'
require 'globals'
require 'tree'
require 'rooms/Options'

function love.load()
    time = 0
    start_time = os.time()
    start_date = os.date("*t")
    trailer_mode = true

    love.filesystem.setIdentity('BYTEPATH')
    love.graphics.setDefaultFilter('nearest', 'nearest')
    love.graphics.setLineStyle('rough')
    love.graphics.setBackgroundColor(background_color[1]/255, background_color[2]/255, background_color[3]/255)
    love.keyboard.setKeyRepeat(false)
    loadFonts('resources/fonts')
    loadGraphics('resources/graphics')
    loadShaders('resources/shaders')
    local object_files = {}
    recursiveEnumerate('objects', object_files)
    requireFiles(object_files)
    local room_files = {}
    recursiveEnumerate('rooms', room_files)
    requireFiles(room_files)

    timer = Timer()
    input = Input()
    camera = Camera()
    sound()

    --[[
    input:bind('f1', function()
        print("Before collection: " .. collectgarbage("count")/1024)
        collectgarbage()
        print("After collection: " .. collectgarbage("count")/1024)
        print("Object count: ")
        local counts = type_count()
        for k, v in pairs(counts) do print(k, v) end
        print("-------------------------------------")
    end)
    ]]--

    --[[
    input:bind('f2', function() gotoRoom('Stage') end)
    input:bind('f3', function()
        if current_room then
            current_room:destroy()
            current_room = nil
        end
    end)
    ]]--

    input:bind('left', 'left')
    input:bind('right', 'right')
    input:bind('up', 'up')
    input:bind('down', 'down')
    input:bind('a', 'left')
    input:bind('d', 'right')
    input:bind('w', 'up')
    input:bind('s', 'down')
    input:bind('mouse1', 'left_click')
    input:bind('wheelup', 'zoom_in')
    input:bind('wheeldown', 'zoom_out')
    input:bind('return', 'return')
    input:bind('backspace', 'backspace')
    input:bind('escape', 'escape')
    input:bind('dpleft', 'left')
    input:bind('dpright', 'right')
    input:bind('dpup', 'up')
    input:bind('dpdown', 'down')
    input:bind('fright', 'up')
    input:bind('fdown', 'down')
    input:bind('fleft', 'return')
    input:bind('select', 'escape')
    input:bind('start', 'return')
    input:bind('tab', 'tab')

    load()

    if first_run_ever then
        display_mode = 'windowed'
        window_scale = 2
        applyDisplayMode()
    else applyDisplayMode() end

    current_room = nil
    -- BYTEPATH는 첫 프레임에 Console을 보여주기 위해 즉시 gotoRoom을 호출한다.
    gotoRoom('Console')

    slow_amount = 1
    fps = 60
    disable_expensive_shaders = false
    pre_disable_expensive_shaders = false
    disable_expensive_shaders_time = 0

    playRandomSong()

    update_times = {}
    update_index = 1
    draw_times = {}
    draw_index = 1

    --[[
    timer:every(1, function()
        local update_sum = 0
        for _, time in ipairs(update_times) do update_sum = update_sum + time end
        local update_time = update_sum/#update_times
        update_times = {}
        update_index = 1

        local draw_sum = 0
        for _, time in ipairs(draw_times) do draw_sum = draw_sum + time end
        local draw_time = draw_sum/#draw_times
        draw_times = {}
        draw_index = 1

        print('update: ' .. 1000*update_time, 'draw: ' .. 1000*draw_time, 'total: ' .. 1000*(update_time + draw_time))
    end)
    ]]--
end

function love.update(dt)
    local start_time = os.clock()

    time = time + dt
    timer:update(dt*slow_amount)
    camera:update(dt*slow_amount)
    soundUpdate(dt*slow_amount)
    if current_room then current_room:update(dt*slow_amount) end

    -- Disable expensive shaders if FPS remains below 10 for 1 seconds
    fps = love.timer.getFPS()
    if fps < 10 and not pre_disable_expensive_shaders then 
        pre_disable_expensive_shaders = true 
        disable_expensive_shaders_time = love.timer.getTime()
    end
    if fps > 10 and pre_disable_expensive_shaders then pre_disable_expensive_shaders = false end
    if love.timer.getTime() - disable_expensive_shaders_time > 3 and pre_disable_expensive_shaders then 
        disable_expensive_shaders = true 
        pre_disable_expensive_shaders = false
    end

    update_times[update_index] = os.clock() - start_time
    update_index = update_index + 1
end

function love.draw()
    local start_time = os.clock()

    if current_room then current_room:draw() end

    if flash_frames then
        flash_frames = flash_frames - 1
        if flash_frames == -1 then flash_frames = nil end
    end
    if flash_frames then
        love.graphics.setColor(background_color[1]/255, background_color[2]/255, background_color[3]/255)
        local ox, oy, s = getLetterboxOffset()
        love.graphics.rectangle('fill', ox, oy, gw*s, gh*s)
        love.graphics.setColor(1, 1, 1)
    end

    draw_times[draw_index] = os.clock() - start_time
    draw_index = draw_index + 1
end

function love.keypressed(key)
    if current_room and current_room.keypressed then current_room:keypressed(key) end
end

-- Player dragged the window edge in windowed mode: figure out the new
-- window_scale from the live size and persist it. (Ignored in fullscreen.)
function love.resize(w, h)
    if (display_mode or 'windowed') ~= 'windowed' then return end
    local sx_new = math.max(1, math.floor(w / gw + 0.5))
    local sy_new = math.max(1, math.floor(h / gh + 0.5))
    local s = math.min(sx_new, sy_new)
    if s ~= window_scale then
        window_scale = clampWindowScale(s)
        sx, sy = window_scale, window_scale
        if save then pcall(save) end
    end
end

function love.focus(f)
    if not f then
        if current_room and current_room:is(Stage) and not current_room.paused then
            current_room:pause()
        end
    end
end

function love.quit()
    save()
    -- Steam already tracks how long each player plays for and since this is the only thing I'm tracking it's unnecessary to run a server for only that info
    -- sendDataToServer(binser.serialize({id = id, duration = os.difftime(os.time(), start_time), start_date = start_date, end_date = os.date("*t")}))
end

-- Display mode options
display_mode_list = {'windowed', 'fullscreen', 'desktop'}
window_scale_min, window_scale_max = 1, 6

function clampWindowScale(s)
    if type(s) ~= 'number' then return 2 end
    if s < window_scale_min then return window_scale_min end
    if s > window_scale_max then return window_scale_max end
    return math.floor(s)
end

-- Apply the current display_mode / window_scale / display values to the window.
-- Always called after the user picks something in the Options screen.
-- Persists the choice so the next launch comes up the same way.
function applyDisplayMode()
    local mode = display_mode or 'windowed'
    display = display or 1
    window_scale = clampWindowScale(window_scale or 2)
    sx, sy = window_scale, window_scale

    if mode == 'windowed' then
        fullscreen = false
        local w, h = gw * window_scale, gh * window_scale
        love.window.setMode(w, h, {
            display = display,
            fullscreen = false,
            borderless = false,
            resizable = true,
            minwidth = gw,
            minheight = gh,
        })
    elseif mode == 'fullscreen' then
        fullscreen = true
        local w, h = love.window.getDesktopDimensions(display)
        love.window.setMode(w, h, {
            display = display,
            fullscreen = true,
            fullscreentype = 'exclusive',
            borderless = false,
        })
        sx, sy = math.floor(w / gw), math.floor(h / gh)
        window_scale = sx
    else -- 'desktop' (borderless fullscreen at desktop resolution)
        fullscreen = true
        local w, h = love.window.getDesktopDimensions(display)
        love.window.setMode(w, h, {
            display = display,
            fullscreen = true,
            fullscreentype = 'desktop',
            borderless = true,
        })
        sx, sy = math.floor(w / gw), math.floor(h / gh)
        window_scale = sx
    end

    -- Persist after every change so a crash or kill -9 still keeps the choice.
    if save then pcall(save) end
end

-- Compatibility wrappers for any older call sites
function resize(x, y, fs)
    window_scale = clampWindowScale(x)
    display_mode = fs and 'fullscreen' or 'windowed'
    applyDisplayMode()
end

function resizeFullscreen()
    display_mode = 'desktop'
    applyDisplayMode()
end

function changeToDisplay(n)
    display = n
    resize(getScaleBasedOnDisplay())
end

function getScaleBasedOnDisplay()
    local w, h = love.window.getDesktopDimensions(display)
    local sw, sh = math.floor(w/gw), math.floor(h/gh)
    if sw == sh then return math.min(sw, sh) - 1
    else return math.min(sw, sh) end
end



-- Effects --
function flash(frames)
    flash_frames = frames
end

function slow(amount, duration)
    slow_amount = amount
    timer:tween('slow', duration, _G, {slow_amount = 1}, 'in-out-cubic')
end

function frameStop(duration, object_types)
    if current_room then current_room.area:frameStop(duration, object_types) end
end



-- Save/Load --
function save()
    local transient_save_data = {}
    local permanent_save_data = {}

    permanent_save_data.id = id
    permanent_save_data.loop = loop
    permanent_save_data.sx = sx
    permanent_save_data.sy = sy
    permanent_save_data.high_score = high_score
    permanent_save_data.main_volume = main_volume
    permanent_save_data.sfx_volume = sfx_volume
    permanent_save_data.music_volume = music_volume
    permanent_save_data.screen_shake = screen_shake
    permanent_save_data.distortion = distortion
    permanent_save_data.glitch = glitch
    permanent_save_data.muted = muted
    permanent_save_data.fullscreen = fullscreen
    permanent_save_data.display_mode = display_mode
    permanent_save_data.display = display
    permanent_save_data.window_scale = window_scale
    permanent_save_data.achievements = achievements

    transient_save_data.skill_points = skill_points
    transient_save_data.bought_node_indexes = bought_node_indexes
    transient_save_data.run = run
    transient_save_data.classes = classes
    transient_save_data.rank = rank
    transient_save_data.device = device
    transient_save_data.unlocked_devices = unlocked_devices
    transient_save_data.display = display
    transient_save_data.keys = keys
    transient_save_data.found_keys = found_keys
    transient_save_data.max_tree_nodes = max_tree_nodes
    transient_save_data.spent_sp = spent_sp

    bitser.dumpLoveFile('permanent_save', permanent_save_data)
    bitser.dumpLoveFile('transient_save', transient_save_data)

    --[[
    local data, len = bitser.dumps(save_data)
    print('FileWrite: ' .. tostring(Steam.remotestorage.FileWrite('save', data, len)))
    ]]--
end

function loadAchievementsFromSteam()
    print(Steam)
    if Steam then 
        for _, achievement_name in ipairs(achievement_names) do
            local steam_achievement_name = achievement_name:upper():gsub(' ', '_')
            local b = ffi.new('bool[1]')
            Steam.userstats.GetAchievement(steam_achievement_name, b)
            achievements[achievement_name] = b[0]
            -- print('Steam Achievement Load: ', achievement_name, b[0])
        end
    end
end

function load()
    local loadPermanentVariables = function(save_data)
        id = save_data.id
        loop = save_data.loop
        sx = save_data.sx
        sy = save_data.sy
        high_score = save_data.high_score
        main_volume = save_data.main_volume
        sfx_volume = save_data.sfx_volume
        music_volume = save_data.music_volume
        screen_shake = save_data.screen_shake
        distortion = save_data.distortion
        glitch = save_data.glitch
        muted = save_data.muted
        fullscreen = save_data.fullscreen
        display_mode = save_data.display_mode or (save_data.fullscreen and 'desktop' or 'windowed')
        display = save_data.display
        window_scale = save_data.window_scale or sx or 2
        achievements = save_data.achievements
    end

    local loadTransientVariables = function(save_data)
        skill_points = save_data.skill_points
        bought_node_indexes = save_data.bought_node_indexes
        run = save_data.run
        classes = save_data.classes
        rank = save_data.rank
        device = save_data.device
        unlocked_devices = save_data.unlocked_devices
        keys = save_data.keys
        found_keys = save_data.found_keys
        max_tree_nodes = save_data.max_tree_nodes
        spent_sp = save_data.spent_sp
    end

    local localLoad = function()
        if love.filesystem.exists('permanent_save') then
            local save_data = bitser.loadLoveFile('permanent_save')
            loadPermanentVariables(save_data)
        end
        if love.filesystem.exists('transient_save') then
            local save_data = bitser.loadLoveFile('transient_save')
            loadTransientVariables(save_data)
        else first_run_ever = true end
    end

    --[[
    if Steam.remotestorage.FileExists('save') then
        local file_size = Steam.remotestorage.GetFileSize('save')
		local buffer = ffi.new("uint8_t[?]", file_size)
        local read_amount = Steam.remotestorage.FileRead('save', buffer, file_size)
        print('FileRead: ' .. read_amount)
        if read_amount == 0 then
            localLoad()
            loadAchievementsFromSteam()
        else
            local save_data = bitser.loads(ffi.string(buffer, file_size))
            loadVariables(save_data)
            loadAchievementsFromSteam()
        end
    else 
        localLoad() 
        loadAchievementsFromSteam()
    end
    ]]--

    localLoad()
    loadAchievementsFromSteam()
end

function removeSave()
    -- print('FileDelete: ' .. tostring(Steam.remotestorage.FileDelete('save')))
    love.filesystem.remove('transient_save')
end

-- Room --
function gotoRoom(room_type, ...)
    if current_room and current_room.destroy then current_room:destroy() end
    current_room = _G[room_type](...)
end

-- Load --
function recursiveEnumerate(folder, file_list)
    local items = love.filesystem.getDirectoryItems(folder)
    for _, item in ipairs(items) do
        local file = folder .. '/' .. item
        if love.filesystem.isFile(file) then
            table.insert(file_list, file)
        elseif love.filesystem.isDirectory(file) then
            recursiveEnumerate(file, file_list)
        end
    end
end

function requireFiles(files)
    for _, file in ipairs(files) do
        local file = file:sub(1, -5)
        require(file)
    end
end

function loadFonts(path)
    fonts = {}
    local font_paths = {}
    recursiveEnumerate(path, font_paths)
    for i = 8, 16, 1 do
        for _, font_path in pairs(font_paths) do
            local last_forward_slash_index = font_path:find("/[^/]*$")
            local font_name = font_path:sub(last_forward_slash_index+1, -5)
            local font = love.graphics.newFont(font_path, i)
            font:setFilter('nearest', 'nearest')
            fonts[font_name .. '_' .. i] = font
        end
    end
end

function loadGraphics(path)
    assets = {}
    local asset_paths = {}
    recursiveEnumerate(path, asset_paths)
    for _, asset_path in pairs(asset_paths) do
        local last_forward_slash_index = asset_path:find("/[^/]*$")
        local asset_name = asset_path:sub(last_forward_slash_index+1, -5)
        local image = love.graphics.newImage(asset_path, {mipmaps = true})
        assets[asset_name] = image
    end
end

function loadShaders(path)
    shaders = {}
    local shader_paths = {}
    recursiveEnumerate(path, shader_paths)
    for _, shader_path in pairs(shader_paths) do
        local last_forward_slash_index = shader_path:find("/[^/]*$")
        local shader_name = shader_path:sub(last_forward_slash_index+1, -6)
        local shader = love.graphics.newShader(shader_path)
        shaders[shader_name] = shader
    end
end



-- Memory --
function count_all(f)
    local seen = {}
	local count_table
	count_table = function(t)
		if seen[t] then return end
		f(t)
		seen[t] = true
		for k,v in pairs(t) do
			if type(v) == "table" then
				count_table(v)
			elseif type(v) == "userdata" then
				f(v)
			end
		end
	end
	count_table(_G)
end

function type_count()
	local counts = {}
	local enumerate = function (o)
		local t = type_name(o)
		counts[t] = (counts[t] or 0) + 1
	end
	count_all(enumerate)
	return counts
end

global_type_table = nil
function type_name(o)
	if global_type_table == nil then
		global_type_table = {}
		for k,v in pairs(_G) do
			global_type_table[v] = k
		end
		global_type_table[0] = "table"
	end
	return global_type_table[getmetatable(o) or 0] or "Unknown"
end

-- LÖVE 0.10.2용 커스텀 love.run은 LÖVE 11.5의 love.handlers 변경과
-- 호환되지 않아 draw가 호출되지 않는 검은 화면을 만든다.
-- 기본 LÖVE 11.5 루프를 사용하도록 통째로 비활성화한다.
-- 480x270 게임 캔버스를 윈도우 크기에 맞게 letterbox로 매핑한다.
function getLetterboxOffset()
    local win_w, win_h = love.graphics.getDimensions()
    local scale = math.min(win_w / gw, win_h / gh)
    local draw_w, draw_h = gw * scale, gh * scale
    local ox, oy = (win_w - draw_w) / 2, (win_h - draw_h) / 2
    return ox, oy, scale
end

function drawGameCanvas(canvas)
    local ox, oy, scale = getLetterboxOffset()
    love.graphics.draw(canvas, ox, oy, 0, scale, scale)
end

function legacy_love_run_disabled()
    if love.math then love.math.setRandomSeed(os.time()) end
    if love.load then love.load(arg) end
    if love.timer then love.timer.step() end

    local dt = 0
    local fixed_dt = 1/60
    local accumulator = 0

    while true do
        if love.event then
            love.event.pump()
            for name, a, b, c, d, e, f in love.event.poll() do
                if name == 'quit' then
                    if not love.quit or not love.quit() then
                        return a
                    end
                end
                love.handlers[name](a, b, c, d, e, f)
            end
        end

        if love.timer then
            love.timer.step()
            dt = love.timer.getDelta()
        end

        accumulator = accumulator + dt
        while accumulator >= fixed_dt do
            if love.update then love.update(fixed_dt) end
            accumulator = accumulator - fixed_dt
        end

        if love.graphics and love.graphics.isActive() then
            love.graphics.clear(love.graphics.getBackgroundColor())
            love.graphics.origin()
            if love.draw then love.draw() end
            love.graphics.present()
        end

        if love.timer then love.timer.sleep(0.001) end
    end
end
