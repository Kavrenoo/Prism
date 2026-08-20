local BASE = "https://prismscript.vercel.app"

local function loadScript(url, name)
    local ok, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    if not ok then
        warn("Prism: Failed to load " .. name .. ": " .. tostring(result))
    else
        print("Prism: Loaded " .. name)
    end
    return ok, result
end

-- Set auth flag to true immediately (key system removed)
getgenv().PrismLoaded = true
print("Prism: Set PrismLoaded flag")

-- 1. Main UI
local mainOk = loadScript(BASE .. "/Prism%20Main.lua", "Main")
if mainOk then
    print("Prism: PrismMain exists:", getgenv().PrismMain ~= nil)
else
    warn("Prism: Main failed to load, Commands will not work")
end

-- 2. Commands
loadScript(BASE .. "/Prism%20Commands.lua", "Commands")
