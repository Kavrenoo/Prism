local BASE = "https://prismscript.vercel.app"

local function loadScript(url)
    local ok, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    return ok, result
end

-- Reset auth flag so re-executions wait properly
getgenv().PrismLoaded = false

-- 1. Key system
loadScript(BASE .. "/Prism%20Key.lua")

-- 2. Wait for auth
repeat task.wait() until getgenv().PrismLoaded

-- 3. Main UI
loadScript(BASE .. "/Prism%20Main.lua")

-- 4. Commands
loadScript(BASE .. "/Prism%20Commands.lua")
