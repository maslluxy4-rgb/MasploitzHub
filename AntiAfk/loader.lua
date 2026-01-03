-- Masploitz Anti-AFK Loader
-- GitHub: https://github.com/maslluxy4-rgb/MasploitzHub/tree/main/AntiAfk

local GITHUB_BASE = "https://raw.githubusercontent.com/maslluxy4-rgb/MasploitzHub/main/AntiAfk/"

-- prevent double load
if getgenv().__MASPLOITZ_LOADER_RUNNING then
    warn("Masploitz Loader already running")
    return
end
getgenv().__MASPLOITZ_LOADER_RUNNING = true

print("🔥 Loading Masploitz Anti-AFK System...")

-- Shared config between backend and UI
getgenv().MasploitzConfig = getgenv().MasploitzConfig or {
    GAME_ID = 139217467707445,
    MIN_PLAYERS = 20,

    WALK_SPEED_NORMAL = 16,
    WALK_SPEED_FAST = 28,
    MAX_WALK_DISTANCE = 5,
    MIN_WALK_DISTANCE = 1,

    MIN_JUMPS = 1,
    MAX_JUMPS = 10,
    JUMP_INTERVAL = 0.25,

    RANDOM_MOVE_MIN = 1,
    RANDOM_MOVE_MAX = 60,
    REGULAR_MOVE_INTERVAL = 10,
    MICRO_MOVE_MIN = 4,
    MICRO_MOVE_MAX = 8,
    SPOT_CHECK_INTERVAL = 1,
    BLOCK_CHECK_INTERVAL = 1,

    PLAYER_RADIUS = 20,
    FRONT_CHECK_ANGLE = 45,
    FRONT_CHECK_DISTANCE = 15,
    BLOCK_CHECK_ANGLE = 360,
    BLOCK_CHECK_DISTANCE = 10,

    AUTO_HOP_TIME = 19 * 60,

    AUTO_EQUIP_TOOL = "Sign",
    TOOL_WAIT_TIMEOUT = 999999,

    SPAWN_POSITIONS = {},

    UI_POSITION = UDim2.new(0.5, -210, 0.5, -165),
    UI_SIZE = UDim2.new(0, 420, 0, 330),
    UI_BG_COLOR = Color3.fromRGB(15, 45, 65),
    UI_ACCENT_COLOR = Color3.fromRGB(80, 150, 200),
    UI_HEADER_COLOR = Color3.fromRGB(10, 35, 55),

    ENABLE_CHAT_MESSAGES = false,
    CHAT_INTERVAL_MIN = 120,
    CHAT_INTERVAL_MAX = 300,
    ENABLE_EMOTES = true,
    EMOTE_INTERVAL_MIN = 60,
    EMOTE_INTERVAL_MAX = 180,
    ENABLE_CAMERA_MOVE = true,
    CAMERA_INTERVAL_MIN = 30,
    CAMERA_INTERVAL_MAX = 90,

    CHAT_MESSAGES = { "afk", "brb", "back", "nice", "lol", "gg" },

    DEBUG_MODE = true
}

-- loaders
local function loadBackend()
    local ok, err = pcall(function()
        loadstring(game:HttpGet(GITHUB_BASE .. "backend.lua"))()
    end)

    if not ok then
        warn("❌ Backend error:", err)
        return false
    end

    -- backend must expose state or it didn't really load
    if not getgenv().MasploitzState then
        warn("❌ Backend exited early (no state)")
        return false
    end

    print("✅ Backend loaded successfully")
    return true
end

local function loadUI()
    local ok, err = pcall(function()
        loadstring(game:HttpGet(GITHUB_BASE .. "ui.lua"))()
    end)

    if not ok then
        warn("❌ UI error:", err)
        return false
    end

    print("✅ UI loaded successfully")
    return true
end

-- infinite retry loop (safe)
task.spawn(function()
    local delayTime = 1

    while true do
        if loadBackend() then
            task.wait(0.5)

            if loadUI() then
                print("🎯 Masploitz Anti-AFK fully loaded!")
                break
            end
        end

        task.wait(delayTime)
        delayTime = math.min(delayTime * 1.5, 30)
    end
end)
