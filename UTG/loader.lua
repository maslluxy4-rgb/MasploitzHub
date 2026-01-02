-- Masploitz Hub Loader
-- Usage: loadstring(game:HttpGet("https://raw.githubusercontent.com/maslluxy4-rgb/MasploitzHub/main/UTG/loader.lua"))()

local REPO_URL = "https://raw.githubusercontent.com/maslluxy4-rgb/MasploitzHub/main/UTG/"

print("[Masploitz] Loading UI and Backend modules...")

local success, backend = pcall(function()
    return loadstring(game:HttpGet(REPO_URL .. "backend.lua"))()
end)

if not success then
    warn("[Masploitz] Failed to load backend:", backend)
    return
end

local success, ui = pcall(function()
    return loadstring(game:HttpGet(REPO_URL .. "UI.lua"))()
end)

if not success then
    warn("[Masploitz] Failed to load UI:", ui)
    return
end

print("[Masploitz] Successfully loaded! Initializing...")

-- Initialize the hub
ui.init(backend)

print("[Masploitz] Hub initialized successfully!")
