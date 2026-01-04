-- Masploitz Anti-AFK Loader
local GITHUB_BASE = "https://raw.githubusercontent.com/maslluxy4-rgb/MasploitzHub/main/AntiAfk/"
print("🔥 Loading Masploitz Anti-AFK System...")

-- Shared config
getgenv().MasploitzConfig = {
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
    SPOT_CHECK_INTERVAL = 60,
    BLOCK_CHECK_INTERVAL = 1,
    PLAYER_RADIUS = 20,
    FRONT_CHECK_ANGLE = 45,
    FRONT_CHECK_DISTANCE = 15,
    BLOCK_CHECK_ANGLE = 360,
    BLOCK_CHECK_DISTANCE = 10,
    AUTO_HOP_TIME = 19 * 60,
    AUTO_EQUIP_TOOL = "Sign",
    TOOL_WAIT_TIMEOUT = 999999,
    AUTO_RE_EQUIP = true,
    RE_EQUIP_INTERVAL = 120,
    SPAWN_POSITIONS = {
        Vector3.new(-3.06, 6.54, -48.03),
        Vector3.new(12.67, 6.74, -46.14),
        Vector3.new(37.71, 6.74, -36.19),
        Vector3.new(-24.34, 6.74, -38.91),
        Vector3.new(40.35, 6.74, -21.97),
        Vector3.new(-15.39, 6.74, 46.85),
        Vector3.new(23.11, 6.74, 47.31),
        Vector3.new(42.23, 6.34, 30.49)
    },
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
    CHAT_MESSAGES = {"afk","brb","back","nice","lol","gg"},
    DEBUG_MODE = true
}

-- Load Backend
local backendSuccess, backendError = pcall(function()
    loadstring(game:HttpGet(GITHUB_BASE .. "backend.lua"))()
end)

if not backendSuccess then
    warn("❌ Failed to load backend:", backendError)
    return
end

print("✅ Backend loaded successfully")
wait(0.5)

-- Load UI
local uiSuccess, uiError = pcall(function()
    loadstring(game:HttpGet(GITHUB_BASE .. "ui.lua"))()
end)

if not uiSuccess then
    warn("❌ Failed to load UI:", uiError)
    return
end

print("✅ UI loaded successfully")
print("🎯 Masploitz Anti-AFK fully loaded!")
