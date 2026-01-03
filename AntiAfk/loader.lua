-- Masploitz Anti-AFK Loader
-- Safe bootstrap + backend loader

-- prevent double load
if getgenv().__MASPLOITZ_LOADER_RUNNING then
    warn("Masploitz Loader already running")
    return
end
getgenv().__MASPLOITZ_LOADER_RUNNING = true

-- config safety
getgenv().MasploitzConfig = getgenv().MasploitzConfig or {}
local cfg = getgenv().MasploitzConfig

cfg.GAME_ID = cfg.GAME_ID or game.PlaceId
cfg.CENTER_POSITION = cfg.CENTER_POSITION or Vector3.new(0, 0, 0)

cfg.PLAYER_RADIUS = cfg.PLAYER_RADIUS or 20
cfg.FRONT_CHECK_DISTANCE = cfg.FRONT_CHECK_DISTANCE or 15
cfg.FRONT_CHECK_ANGLE = cfg.FRONT_CHECK_ANGLE or 45
cfg.BLOCK_CHECK_DISTANCE = cfg.BLOCK_CHECK_DISTANCE or 10

cfg.DEBUG_MODE = cfg.DEBUG_MODE == true

-- backend url
local BACKEND_URL =
    "https://raw.githubusercontent.com/maslluxy4-rgb/MasploitzHub/main/AntiAfk/backend.lua"

-- load backend safely
local function loadBackend()
    local src

    local ok, err = pcall(function()
        src = game:HttpGet(BACKEND_URL)
    end)
    if not ok or type(src) ~= "string" or #src < 20 then
        warn("Masploitz Loader: HttpGet failed")
        return false
    end

    local fn
    ok, err = pcall(function()
        fn = loadstring(src)
    end)
    if not ok or type(fn) ~= "function" then
        warn("Masploitz Loader: loadstring failed")
        return false
    end

    ok, err = pcall(fn)
    if not ok then
        warn("Masploitz Backend error:", err)
        return false
    end

    -- verify backend actually initialized
    if not getgenv().MasploitzState then
        warn("Masploitz Backend did not initialize state")
        return false
    end

    return true
end

-- retry loop (infinite but safe)
task.spawn(function()
    local delayTime = 1

    while true do
        local success = loadBackend()
        if success then
            print("Masploitz Loader: Backend loaded")
            break
        end

        task.wait(delayTime)
        delayTime = math.min(delayTime * 1.5, 30)
    end
end)
