-- Wait for PrismMain to be initialized by Main.lua
local PM = getgenv().PrismMain
if not PM then
    -- Retry for up to 5 seconds waiting for Main.lua to load
    for i = 1, 50 do
        task.wait(0.1)
        PM = getgenv().PrismMain
        if PM then break end
    end
end
if not PM then return end

PM.Commands = PM.Commands or {}

local function registerCommand(name, desc, aliases, execute, excludeFromAutoExec)
    PM.Commands[name:lower()] = {
        name = name,
        desc = desc,
        aliases = aliases or {},
        execute = execute,
        excludeFromAutoExec = excludeFromAutoExec or false,
    }
end

-- ========== CHAT COMMAND HANDLING ==========

local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local ChatPrefix = "'"

-- Hook into chat
local function onChat(msg)
    if not msg:sub(1, 1) == ChatPrefix then return end
    
    -- Remove prefix and parse command
    local input = msg:sub(2):gsub("^%s+", "")
    if input == "" then return end
    
    local parts = {}
    for part in input:gmatch("%S+") do
        table.insert(parts, part)
    end
    
    local cmdName = parts[1]:lower()
    table.remove(parts, 1)
    
    -- Find and execute command
    local cmd = PM.Commands[cmdName]
    if not cmd then
        -- Check aliases
        for _, c in pairs(PM.Commands) do
            for _, alias in ipairs(c.aliases) do
                if alias:lower() == cmdName then
                    cmd = c
                    break
                end
            end
            if cmd then break end
        end
    end
    
    if cmd then
        pcall(function() cmd.execute(parts) end)
    end
end

-- Connect to chat
if LP then
    LP.Chatted:Connect(onChat)
end

-- ========== BUILT-IN COMMANDS ==========

registerCommand("destroy", "Destroy Prism UI and cleanup", {}, function(args)
    -- Clean up existing UI
    if PM.UI.Gui then
        pcall(function() PM.UI.Gui:Destroy() end)
    end
    -- Disconnect auto-hide connection if active
    if PM.HideAllPlayerAddedConn then
        pcall(function() PM.HideAllPlayerAddedConn:Disconnect() end)
        PM.HideAllPlayerAddedConn = nil
    end
    -- Disconnect auto-mute connection if active
    if PM.MuteAllPlayerAddedConn then
        pcall(function() PM.MuteAllPlayerAddedConn:Disconnect() end)
        PM.MuteAllPlayerAddedConn = nil
    end
    -- Disconnect jerk respawn connection if active
    if PM.JerkRespawnConn then
        pcall(function() PM.JerkRespawnConn:Disconnect() end)
        PM.JerkRespawnConn = nil
    end
    -- Unhide all hidden players
    for uid, data in pairs(PM.HiddenPlayers or {}) do
        if data.connection then pcall(function() data.connection:Disconnect() end) end
        if data.audioDevice then pcall(function() data.audioDevice.Muted = false end) end
    end
    PM.HiddenPlayers = {}
    -- Unmute all muted players
    for uid, data in pairs(PM.MutedPlayers or {}) do
        if data.connection then pcall(function() data.connection:Disconnect() end) end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        local adi = p:FindFirstChildOfClass("AudioDeviceInput")
        if adi then
            pcall(function() adi.Muted = false end)
        end
    end
    PM.MutedPlayers = {}
    -- Clear state flags
    PM.JerkActive = false
    PM.AntiVCBanRan = false
    -- Cleanup Walk On Air
    if PM.WOA then
        if PM.WOA.renderConn then pcall(function() PM.WOA.renderConn:Disconnect() end) end
        if PM.WOA.platform then pcall(function() PM.WOA.platform:Destroy() end) end
        if PM.WOA.Gui then pcall(function() PM.WOA.Gui:Destroy() end) end
        PM.WOA = nil
    end
    local plat = workspace:FindFirstChild("PrismWalkAirPlatform")
    if plat then pcall(function() plat:Destroy() end) end
    -- Clear globals
    getgenv().PrismMain = nil
    getgenv().PrismLoaded = false
end, true)

registerCommand("reload", "Reload Prism script", {}, function(args)
    -- Clean up existing UI
    if PM.UI.Gui then
        pcall(function() PM.UI.Gui:Destroy() end)
    end
    -- Cleanup Walk On Air
    if PM.WOA then
        if PM.WOA.renderConn then pcall(function() PM.WOA.renderConn:Disconnect() end) end
        if PM.WOA.platform then pcall(function() PM.WOA.platform:Destroy() end) end
        if PM.WOA.Gui then pcall(function() PM.WOA.Gui:Destroy() end) end
    end
    local plat = workspace:FindFirstChild("PrismWalkAirPlatform")
    if plat then pcall(function() plat:Destroy() end) end
    getgenv().PrismMain = nil
    getgenv().PrismLoaded = false
    -- Reload from URL
    loadstring(game:HttpGet("https://prismscript.vercel.app/Prism.lua"))()
end, true)

registerCommand("rejoin", "Rejoin current server", {}, function(args)
    game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
end, true)

registerCommand("serverhopmost", "Join server with most players", {}, function(args)
    local ok, result = pcall(function()
        return game:GetService("HttpService"):JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100"))
    end)
    if ok and result and result.data then
        local best = nil
        for _, server in ipairs(result.data) do
            local playing = server.playing or 0
            local maxP = server.maxPlayers or 0
            if server.id ~= game.JobId and maxP > 0 and playing < maxP then
                if not best or playing > (best.playing or 0) then
                    best = server
                end
            end
        end
        if best then
            game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, best.id, LP)
        end
    end
end, true)

registerCommand("serverhopping", "Join server with lowest ping", {}, function(args)
    local ok, result = pcall(function()
        return game:GetService("HttpService"):JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
    end)
    if ok and result and result.data then
        local best = nil
        for _, server in ipairs(result.data) do
            local playing = server.playing or 0
            local maxP = server.maxPlayers or 0
            if server.id ~= game.JobId and maxP > 0 and playing < maxP then
                if not best or (server.ping or math.huge) < (best.ping or math.huge) then
                    best = server
                end
            end
        end
        if best then
            game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, best.id, LP)
        end
    end
end, true)

registerCommand("serverhopfew", "Join server with fewest players", {}, function(args)
    local ok, result = pcall(function()
        return game:GetService("HttpService"):JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
    end)
    if ok and result and result.data then
        local best = nil
        for _, server in ipairs(result.data) do
            local playing = server.playing or 0
            local maxP = server.maxPlayers or 0
            if server.id ~= game.JobId and maxP > 0 and playing < maxP then
                if not best or playing < (best.playing or math.huge) then
                    best = server
                end
            end
        end
        if best then
            game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, best.id, LP)
        end
    end
end, true)

registerCommand("serverhopany", "Join any random server (may be full)", {}, function(args)
    local ok, result = pcall(function()
        return game:GetService("HttpService"):JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
    end)
    if ok and result and result.data then
        local servers = {}
        for _, server in ipairs(result.data) do
            if server.id ~= game.JobId then
                table.insert(servers, server)
            end
        end
        if #servers > 0 then
            local randomServer = servers[math.random(1, #servers)]
            game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, randomServer.id, LP)
        end
    end
end, true)

-- Hidden players state
PM.HiddenPlayers = {}

local function applyHide(char, savedState)
    if not char then return savedState end
    savedState = savedState or { parts = {}, guis = {}, particles = {}, beams = {}, sounds = {}, lights = {}, hum = {} }
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        pcall(function()
            savedState.hum.displayDistType = hum.DisplayDistanceType
            savedState.hum.healthDist = hum.HealthDisplayDistance
            savedState.hum.nameDist = hum.NameDisplayDistance
            hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
            hum.HealthDisplayDistance = 0
            hum.NameDisplayDistance = 0
        end)
    end
    for _, desc in ipairs(char:GetDescendants()) do
        if desc:IsA("BillboardGui") then
            pcall(function()
                savedState.guis[desc] = desc.Enabled
                desc.Enabled = false
            end)
        end
    end
    for _, desc in ipairs(char:GetDescendants()) do
        if desc:IsA("ParticleEmitter") or desc:IsA("Fire") or desc:IsA("Sparkles") or desc:IsA("Smoke") then
            pcall(function()
                savedState.particles[desc] = desc.Enabled
                desc.Enabled = false
            end)
        end
    end
    for _, desc in ipairs(char:GetDescendants()) do
        if desc:IsA("Beam") or desc:IsA("Trail") then
            pcall(function()
                savedState.beams[desc] = desc.Enabled
                desc.Enabled = false
            end)
        end
    end
    for _, desc in ipairs(char:GetDescendants()) do
        if desc:IsA("Sound") then
            pcall(function()
                savedState.sounds[desc] = desc.Volume
                desc.Volume = 0
            end)
        end
    end
    for _, desc in ipairs(char:GetDescendants()) do
        if desc:IsA("PointLight") or desc:IsA("SpotLight") or desc:IsA("SurfaceLight") then
            pcall(function()
                savedState.lights[desc] = desc.Brightness
                desc.Brightness = 0
            end)
        end
    end
    for _, desc in ipairs(char:GetDescendants()) do
        if desc:IsA("BasePart") or desc:IsA("Decal") or desc:IsA("Texture") then
            pcall(function()
                savedState.parts[desc] = desc.Transparency
                desc.Transparency = 1
            end)
        end
    end
    return savedState
end

registerCommand("hide", "Hide a player locally", {}, function(args)
    local targetName = args[1] or ""
    if targetName == "" then return end
    local q = targetName:lower()
    local target = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            if p.Name:lower() == q or p.DisplayName:lower() == q then
                target = p
                break
            end
        end
    end
    if not target then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP then
                if p.Name:lower():sub(1, #q) == q or p.DisplayName:lower():sub(1, #q) == q then
                    target = p
                    break
                end
            end
        end
    end
    if not target then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP then
                if p.Name:lower():find(q, 1, true) or p.DisplayName:lower():find(q, 1, true) then
                    target = p
                    break
                end
            end
        end
    end
    if not target then return end
    if PM.HiddenPlayers[target.UserId] then return end
    local adi = target:FindFirstChildOfClass("AudioDeviceInput")
    if adi then pcall(function() adi.Muted = true end) end
    local savedState = nil
    if target.Character then savedState = applyHide(target.Character, nil) end
    local conn = target.CharacterAdded:Connect(function(char)
        task.wait(0.1)
        savedState = applyHide(char, savedState)
    end)
    PM.HiddenPlayers[target.UserId] = { connection = conn, audioDevice = adi, savedState = savedState }
end, true)

registerCommand("unhide", "Unhide a player", {}, function(args)
    local targetName = args[1] or ""
    if targetName == "" then return end
    local q = targetName:lower()
    local target = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            if p.Name:lower():find(q, 1, true) or p.DisplayName:lower():find(q, 1, true) then
                target = p
                break
            end
        end
    end
    if not target then return end
    if not PM.HiddenPlayers[target.UserId] then return end
    local data = PM.HiddenPlayers[target.UserId]
    if data.connection then pcall(function() data.connection:Disconnect() end) end
    if data.audioDevice then pcall(function() data.audioDevice.Muted = false end) end
    if target.Character and data.savedState then
        local state = data.savedState
        pcall(function()
            local hum = target.Character:FindFirstChildOfClass("Humanoid")
            if hum and state.hum then
                hum.DisplayDistanceType = state.hum.displayDistType or Enum.HumanoidDisplayDistanceType.Viewer
                hum.HealthDisplayDistance = state.hum.healthDist or 100
                hum.NameDisplayDistance = state.hum.nameDist or 100
            end
        end)
        for desc, orig in pairs(state.parts or {}) do pcall(function() desc.Transparency = orig end) end
        for desc, orig in pairs(state.guis or {}) do pcall(function() desc.Enabled = orig end) end
        for desc, orig in pairs(state.particles or {}) do pcall(function() desc.Enabled = orig end) end
        for desc, orig in pairs(state.beams or {}) do pcall(function() desc.Enabled = orig end) end
        for desc, orig in pairs(state.sounds or {}) do pcall(function() desc.Volume = orig end) end
        for desc, orig in pairs(state.lights or {}) do pcall(function() desc.Brightness = orig end) end
    end
    -- Mark as manually unhidden so hideall won't re-hide
    if PM.HiddenPlayers[target.UserId] then
        PM.HiddenPlayers[target.UserId].manuallyUnhidden = true
    end
end, true)

registerCommand("hideall", "Hide all other players", {}, function(args)
    -- Hide all currently existing players (unless manually unhidden)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and not PM.HiddenPlayers[p.UserId] then
            local adi = p:FindFirstChildOfClass("AudioDeviceInput")
            if adi then pcall(function() adi.Muted = true end) end
            local savedState = nil
            if p.Character then savedState = applyHide(p.Character, nil) end
            local conn = p.CharacterAdded:Connect(function(char)
                task.wait(0.1)
                -- Skip if player was manually unhidden
                if PM.HiddenPlayers[p.UserId] and PM.HiddenPlayers[p.UserId].manuallyUnhidden then return end
                savedState = applyHide(char, savedState)
            end)
            PM.HiddenPlayers[p.UserId] = { connection = conn, audioDevice = adi, savedState = savedState }
        end
    end
    -- Auto-hide new players who join
    if not PM.HideAllPlayerAddedConn then
        PM.HideAllPlayerAddedConn = Players.PlayerAdded:Connect(function(p)
            if p ~= LP and not PM.HiddenPlayers[p.UserId] then
                local adi = p:FindFirstChildOfClass("AudioDeviceInput")
                if adi then pcall(function() adi.Muted = true end) end
                local savedState = nil
                if p.Character then savedState = applyHide(p.Character, nil) end
                local conn = p.CharacterAdded:Connect(function(char)
                    task.wait(0.1)
                    -- Skip if player was manually unhidden
                    if PM.HiddenPlayers[p.UserId] and PM.HiddenPlayers[p.UserId].manuallyUnhidden then return end
                    savedState = applyHide(char, savedState)
                end)
                PM.HiddenPlayers[p.UserId] = { connection = conn, audioDevice = adi, savedState = savedState }
            end
        end)
    end
end, true)

registerCommand("unhideall", "Unhide all players", {}, function(args)
    -- Disconnect the auto-hide connection
    if PM.HideAllPlayerAddedConn then
        pcall(function() PM.HideAllPlayerAddedConn:Disconnect() end)
        PM.HideAllPlayerAddedConn = nil
    end
    for uid, data in pairs(PM.HiddenPlayers) do
        if data.connection then pcall(function() data.connection:Disconnect() end) end
        if data.audioDevice then pcall(function() data.audioDevice.Muted = false end) end
        for _, p in ipairs(Players:GetPlayers()) do
            if p.UserId == uid and p.Character and data.savedState then
                local state = data.savedState
                pcall(function()
                    local hum = p.Character:FindFirstChildOfClass("Humanoid")
                    if hum and state.hum then
                        hum.DisplayDistanceType = state.hum.displayDistType or Enum.HumanoidDisplayDistanceType.Viewer
                        hum.HealthDisplayDistance = state.hum.healthDist or 100
                        hum.NameDisplayDistance = state.hum.nameDist or 100
                    end
                end)
                for desc, orig in pairs(state.parts or {}) do pcall(function() desc.Transparency = orig end) end
                for desc, orig in pairs(state.guis or {}) do pcall(function() desc.Enabled = orig end) end
                for desc, orig in pairs(state.particles or {}) do pcall(function() desc.Enabled = orig end) end
                for desc, orig in pairs(state.beams or {}) do pcall(function() desc.Enabled = orig end) end
                for desc, orig in pairs(state.sounds or {}) do pcall(function() desc.Volume = orig end) end
                for desc, orig in pairs(state.lights or {}) do pcall(function() desc.Brightness = orig end) end
                break
            end
        end
    end
    PM.HiddenPlayers = {}
end, true)

-- Muted players tracking table
PM.MutedPlayers = {}

registerCommand("mute", "Mute a player's voice chat", {}, function(args)
    local targetName = args[1] or ""
    if targetName == "" then return end
    local q = targetName:lower()
    local target = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            if p.Name:lower() == q or p.DisplayName:lower() == q then
                target = p
                break
            end
        end
    end
    if not target then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP then
                if p.Name:lower():find(q, 1, true) or p.DisplayName:lower():find(q, 1, true) then
                    target = p
                    break
                end
            end
        end
    end
    if target then
        local adi = target:FindFirstChildOfClass("AudioDeviceInput")
        if adi then
            pcall(function() adi.Muted = true end)
            PM.MutedPlayers[target.UserId] = adi
        end
    end
end, true)

registerCommand("unmute", "Unmute a player's voice chat", {}, function(args)
    local targetName = args[1] or ""
    if targetName == "" then return end
    local q = targetName:lower()
    local target = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            if p.Name:lower() == q or p.DisplayName:lower() == q then
                target = p
                break
            end
        end
    end
    if not target then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP then
                if p.Name:lower():find(q, 1, true) or p.DisplayName:lower():find(q, 1, true) then
                    target = p
                    break
                end
            end
        end
    end
    if target then
        local adi = target:FindFirstChildOfClass("AudioDeviceInput")
        if adi then
            pcall(function() adi.Muted = false end)
        end
        -- Mark as manually unmuted so muteall won't re-mute
        if PM.MutedPlayers[target.UserId] then
            PM.MutedPlayers[target.UserId].manuallyUnmuted = true
        end
    end
end, true)

registerCommand("muteall", "Mute all other players", {}, function(args)
    -- Mute all currently existing players (unless manually unmuted)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and not PM.MutedPlayers[p.UserId] then
            local adi = p:FindFirstChildOfClass("AudioDeviceInput")
            if adi then
                pcall(function() adi.Muted = true end)
            end
            -- Hook CharacterAdded for respawns
            local conn = p.CharacterAdded:Connect(function(char)
                task.wait(0.1)
                -- Skip if player was manually unmuted
                if PM.MutedPlayers[p.UserId] and PM.MutedPlayers[p.UserId].manuallyUnmuted then return end
                local newAdi = p:FindFirstChildOfClass("AudioDeviceInput")
                if newAdi then
                    pcall(function() newAdi.Muted = true end)
                end
            end)
            PM.MutedPlayers[p.UserId] = { connection = conn }
        end
    end
    -- Auto-mute new players who join (unless manually unmuted)
    if not PM.MuteAllPlayerAddedConn then
        PM.MuteAllPlayerAddedConn = Players.PlayerAdded:Connect(function(p)
            if p ~= LP and not PM.MutedPlayers[p.UserId] then
                local adi = p:FindFirstChildOfClass("AudioDeviceInput")
                if adi then
                    pcall(function() adi.Muted = true end)
                end
                local conn = p.CharacterAdded:Connect(function(char)
                    task.wait(0.1)
                    -- Skip if player was manually unmuted
                    if PM.MutedPlayers[p.UserId] and PM.MutedPlayers[p.UserId].manuallyUnmuted then return end
                    local newAdi = p:FindFirstChildOfClass("AudioDeviceInput")
                    if newAdi then
                        pcall(function() newAdi.Muted = true end)
                    end
                end)
                PM.MutedPlayers[p.UserId] = { connection = conn }
            end
        end)
    end
end, true)

registerCommand("unmuteall", "Unmute all players", {}, function(args)
    -- Disconnect the auto-mute connection
    if PM.MuteAllPlayerAddedConn then
        pcall(function() PM.MuteAllPlayerAddedConn:Disconnect() end)
        PM.MuteAllPlayerAddedConn = nil
    end
    for uid, data in pairs(PM.MutedPlayers) do
        if data.connection then pcall(function() data.connection:Disconnect() end) end
        for _, p in ipairs(Players:GetPlayers()) do
            if p.UserId == uid then
                local adi = p:FindFirstChildOfClass("AudioDeviceInput")
                if adi then
                    pcall(function() adi.Muted = false end)
                end
            end
        end
    end
    PM.MutedPlayers = {}
end, true)

registerCommand("to", "Teleport to player", {}, function(args)
    local targetName = table.concat(args, " ")
    if targetName == "" then return end
    local q = targetName:lower()
    local target = nil
    -- Exact match
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            if p.Name:lower() == q or p.DisplayName:lower() == q then
                target = p
                break
            end
        end
    end
    -- Prefix match
    if not target then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP then
                if p.Name:lower():sub(1, #q) == q or p.DisplayName:lower():sub(1, #q) == q then
                    target = p
                    break
                end
            end
        end
    end
    -- Substring match
    if not target then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP then
                if p.Name:lower():find(q, 1, true) or p.DisplayName:lower():find(q, 1, true) then
                    target = p
                    break
                end
            end
        end
    end
    if not target then return end
    if target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        local myChar = LP.Character
        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if myHRP then
            myHRP.CFrame = target.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
        end
    end
end, true)

registerCommand("tptospawn", "Teleport to spawn", {}, function(args)
    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local spawnPart = workspace:FindFirstChildOfClass("SpawnLocation")
    if not spawnPart then
        spawnPart = workspace:FindFirstChild("SpawnLocation", true)
    end
    if spawnPart then
        local h = char:FindFirstChildOfClass("Humanoid")
        local hipH = h and h.HipHeight or 2.3
        local hrpHalf = root.Size.Y * 0.5
        root.CFrame = CFrame.new(spawnPart.Position + Vector3.new(0, spawnPart.Size.Y * 0.5 + hrpHalf + hipH, 0))
    end
end)

registerCommand("tptool", "Click to teleport tool", {}, function(args)
    if PM.TpToolActive then return end
    PM.TpToolActive = true
    
    local function giveTool()
        local bp = LP.Backpack
        local char = LP.Character
        if (bp and bp:FindFirstChild("Teleport Tool")) or (char and char:FindFirstChild("Teleport Tool")) then return end
        
        local tool = Instance.new("Tool")
        tool.Name = "Teleport Tool"
        tool.RequiresHandle = false
        tool.ToolTip = "Click to teleport"
        
        tool.Activated:Connect(function()
            local c = LP.Character
            if not c then return end
            local h = c:FindFirstChildOfClass("Humanoid")
            local root = c:FindFirstChild("HumanoidRootPart")
            if not root then return end

            local mouse = LP:GetMouse()
            local hipH = h and h.HipHeight or 2.3
            local hrpHalfHeight = root.Size.Y * 0.5
            local sinkBuffer = math.max(0.5, hipH * 0.15) + hrpHalfHeight * 0.25
            local hit = mouse.Hit.Position

            local targetPos
            if mouse.Target and PM.WOA and PM.WOA.enabled then
                -- WOA active: confirm real ground below the hit point
                local rcParams = RaycastParams.new()
                local excludes = { c }
                if PM.WOA.platform then table.insert(excludes, PM.WOA.platform) end
                rcParams.FilterDescendantsInstances = excludes
                rcParams.FilterType = Enum.RaycastFilterType.Exclude
                local groundCheck = workspace:Raycast(Vector3.new(hit.X, hit.Y + 0.5, hit.Z), Vector3.new(0, -15000, 0), rcParams)
                if groundCheck then
                    targetPos = Vector3.new(hit.X, hit.Y + hipH + sinkBuffer, hit.Z)
                else
                    targetPos = Vector3.new(hit.X, PM.WOA.baseY + hipH + 0.5, hit.Z)
                end
            else
                targetPos = Vector3.new(hit.X, hit.Y + hipH + sinkBuffer, hit.Z)
            end

            local lookDir = (Vector3.new(targetPos.X, root.Position.Y, targetPos.Z) - root.Position)
            lookDir = lookDir.Magnitude > 0.01 and lookDir.Unit or root.CFrame.LookVector
            root.CFrame = CFrame.new(targetPos, targetPos + lookDir)
            if h then h.Sit = false; h.AutoRotate = true end
        end)
        
        tool.Parent = bp
        
        -- Detect removal
        local function checkGone()
            local bp2 = LP.Backpack
            local char2 = LP.Character
            local inBp = bp2 and bp2:FindFirstChild("Teleport Tool")
            local inChar = char2 and char2:FindFirstChild("Teleport Tool")
            if not inBp and not inChar then
                PM.TpToolActive = false
                if PM.TpToolConn then pcall(function() PM.TpToolConn:Disconnect() end); PM.TpToolConn = nil end
                if PM.TpWatchConn1 then pcall(function() PM.TpWatchConn1:Disconnect() end); PM.TpWatchConn1 = nil end
                if PM.TpWatchConn2 then pcall(function() PM.TpWatchConn2:Disconnect() end); PM.TpWatchConn2 = nil end
            end
        end
        
        local function onRemoved(child)
            if child == tool then task.defer(checkGone) end
        end
        
        if bp then PM.TpWatchConn1 = bp.ChildRemoved:Connect(onRemoved) end
        if char then PM.TpWatchConn2 = char.ChildRemoved:Connect(onRemoved) end
    end
    
    giveTool()
    
    -- Re-give after respawn
    if PM.TpToolConn then pcall(function() PM.TpToolConn:Disconnect() end) end
    PM.TpToolConn = LP.CharacterAdded:Connect(function()
        task.wait(0.5)
        giveTool()
    end)
end)

registerCommand("jerk", "Jerk animation tool", {}, function(args)
    if PM.JerkActive then return end
    PM.JerkActive = true
    local function giveJerk()
        local char = LP.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local bp = LP:FindFirstChild("Backpack")
        if not hum or not bp then return end
        if bp:FindFirstChild("Jerk") or char:FindFirstChild("Jerk") then return end
        local tool = Instance.new("Tool")
        tool.Name = "Jerk"
        tool.ToolTip = ";)"
        tool.RequiresHandle = false
        tool.Parent = bp
        local jorkin = false
        local track
        local function stopJerk()
            jorkin = false
            if track then track:Stop() track = nil end
        end
        tool.Equipped:Connect(function() jorkin = true end)
        tool.Unequipped:Connect(stopJerk)
        hum.Died:Connect(stopJerk)
        task.spawn(function()
            while task.wait() do
                if not (tool and tool.Parent) then break end
                if jorkin then
                    local isR15 = hum.RigType == Enum.HumanoidRigType.R15
                    if not track then
                        local anim = Instance.new("Animation")
                        anim.AnimationId = isR15 and "rbxassetid://698251653" or "rbxassetid://72042024"
                        track = hum:LoadAnimation(anim)
                    end
                    track:Play()
                    track:AdjustSpeed(isR15 and 0.7 or 0.65)
                    track.TimePosition = 0.6
                    task.wait(0.1)
                    while track and track.TimePosition < (isR15 and 0.7 or 0.65) do task.wait(0.1) end
                    if track then track:Stop() track = nil end
                end
            end
        end)
    end
    giveJerk()
    if PM.JerkRespawnConn then PM.JerkRespawnConn:Disconnect() end
    PM.JerkRespawnConn = LP.CharacterAdded:Connect(function()
        task.wait(0.5)
        giveJerk()
    end)
end)

registerCommand("antivcban", "Anti voice chat ban", {}, function(args)
    if PM.AntiVCBanRan then return end
    PM.AntiVCBanRan = true
    game:GetService("VoiceChatService"):rejoinVoice()
    task.wait(0.02)
    for _, Connection in ipairs(getconnections(game:GetService("VoiceChatInternal").StateChanged)) do
        Connection:Disable()
    end
end)

-- Walk On Air state
PM.WOA = { enabled = false, platform = nil, baseY = 0, startY = nil, up = false, down = false, renderConn = nil, Gui = nil }

local function WOA_GetHR()
    local char = LP.Character
    if not char then return nil, nil end
    local h = char:FindFirstChildOfClass("Humanoid")
    local r = char:FindFirstChild("HumanoidRootPart")
    return h, r
end

local function WOA_GetFootY(h, root)
    local char = LP.Character
    local rcParams = RaycastParams.new()
    rcParams.FilterDescendantsInstances = char and {char} or {}
    rcParams.FilterType = Enum.RaycastFilterType.Exclude
    local hit = workspace:Raycast(root.Position, Vector3.new(0, -50, 0), rcParams)
    if hit then return hit.Position.Y end
    local hipH = h and h.HipHeight or 2.3
    local hrpHalf = root.Size.Y * 0.5
    return root.Position.Y - hrpHalf - hipH
end

local function WOA_Destroy()
    if PM.WOA.renderConn then PM.WOA.renderConn:Disconnect(); PM.WOA.renderConn = nil end
    if PM.WOA.platform then PM.WOA.platform:Destroy(); PM.WOA.platform = nil end
    PM.WOA.enabled = false; PM.WOA.up = false; PM.WOA.down = false
end

local function WOA_Create()
    local h, root = WOA_GetHR(); if not root then return end
    WOA_Destroy(); PM.WOA.enabled = true; PM.WOA.startY = WOA_GetFootY(h, root); PM.WOA.baseY = PM.WOA.startY
    local part = Instance.new("Part")
    part.Name = "PrismWalkAirPlatform"
    part.Size = Vector3.new(20, 5, 20)
    part.Anchored = true; part.CanCollide = true; part.Material = Enum.Material.SmoothPlastic
    part.Transparency = 1; part.CastShadow = false
    part.CFrame = CFrame.new(root.Position.X, PM.WOA.baseY - 2.5, root.Position.Z)
    part.Parent = workspace
    PM.WOA.platform = part
    local RunService = game:GetService("RunService")
    PM.WOA.renderConn = RunService.RenderStepped:Connect(function()
        if not PM.WOA.enabled then return end
        local _, r = WOA_GetHR(); if not r or not PM.WOA.platform then return end
        if PM.WOA.up   then PM.WOA.baseY = PM.WOA.baseY + 0.2 end
        if PM.WOA.down then PM.WOA.baseY = PM.WOA.baseY - 0.2 end
        PM.WOA.platform.CFrame = CFrame.new(r.Position.X, PM.WOA.baseY - 2.5, r.Position.Z)
    end)
end

registerCommand("walkonair", "Walk on air with adjustable height", {"woa", "airwalk"}, function(args)
    local CoreGui = game:GetService("CoreGui")
    local function guiExists(guiName)
        if CoreGui:FindFirstChild(guiName) then return true end
        if LP:FindFirstChild("PlayerGui") and LP.PlayerGui:FindFirstChild(guiName) then return true end
        if get_hidden_gui or gethui then
            if (get_hidden_gui or gethui)():FindFirstChild(guiName) then return true end
        end
        return false
    end
    if guiExists("Prism_WOAGUI") then return end

    local success, err = pcall(function()
        local UserInputService = game:GetService("UserInputService")
        local RunService = game:GetService("RunService")
        local TweenService = game:GetService("TweenService")

        local ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "Prism_WOAGUI"
        ScreenGui.ResetOnSpawn = false
        ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        PM.WOA.Gui = ScreenGui

        if syn and syn.protect_gui then
            syn.protect_gui(ScreenGui)
            ScreenGui.Parent = CoreGui
        elseif gethui then
            ScreenGui.Parent = gethui()
        else
            ScreenGui.Parent = CoreGui
        end

        local MainFrame = Instance.new("Frame")
        MainFrame.Name = "MainFrame"
        MainFrame.Size = UDim2.new(0, 239, 0, 130)
        MainFrame.Position = UDim2.new(0, 1142, 0, 320)
        MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
        MainFrame.BackgroundTransparency = 0.3
        MainFrame.BorderSizePixel = 0
        MainFrame.ClipsDescendants = true
        MainFrame.Parent = ScreenGui

        local MainCorner = Instance.new("UICorner")
        MainCorner.CornerRadius = UDim.new(0, 14)
        MainCorner.Parent = MainFrame

        local MainStroke = Instance.new("UIStroke")
        MainStroke.Color = Color3.fromRGB(60, 60, 60)
        MainStroke.Thickness = 1
        MainStroke.Parent = MainFrame

        local TitleBar = Instance.new("Frame")
        TitleBar.Name = "TitleBar"
        TitleBar.Size = UDim2.new(1, 0, 0, 40)
        TitleBar.BackgroundTransparency = 1
        TitleBar.Parent = MainFrame

        local dragging = false
        local dragStart = nil
        local startPos = nil

        TitleBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = MainFrame.Position
            end
        end)

        TitleBar.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)

        local TitleLabel = Instance.new("TextLabel")
        TitleLabel.Name = "Title"
        TitleLabel.Size = UDim2.new(1, -80, 1, 0)
        TitleLabel.Position = UDim2.new(0, 14, 0, 0)
        TitleLabel.BackgroundTransparency = 1
        TitleLabel.Text = "Prism  •  Walk On Air"
        TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        TitleLabel.TextSize = 13
        TitleLabel.Font = Enum.Font.GothamBold
        TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
        TitleLabel.Parent = TitleBar

        local MinBtn = Instance.new("TextButton")
        MinBtn.Name = "Minimize"
        MinBtn.Size = UDim2.new(0, 24, 0, 24)
        MinBtn.Position = UDim2.new(1, -52, 0.5, -12)
        MinBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        MinBtn.BackgroundTransparency = 0.4
        MinBtn.BorderSizePixel = 0
        MinBtn.Text = "—"
        MinBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
        MinBtn.TextSize = 11
        MinBtn.Font = Enum.Font.GothamBold
        MinBtn.Parent = TitleBar

        local MinCorner = Instance.new("UICorner")
        MinCorner.CornerRadius = UDim.new(0, 6)
        MinCorner.Parent = MinBtn

        local CloseBtn = Instance.new("TextButton")
        CloseBtn.Name = "Close"
        CloseBtn.Size = UDim2.new(0, 24, 0, 24)
        CloseBtn.Position = UDim2.new(1, -26, 0.5, -12)
        CloseBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        CloseBtn.BackgroundTransparency = 0.4
        CloseBtn.BorderSizePixel = 0
        CloseBtn.Text = "X"
        CloseBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
        CloseBtn.TextSize = 11
        CloseBtn.Font = Enum.Font.GothamBold
        CloseBtn.Parent = TitleBar

        local CloseCorner = Instance.new("UICorner")
        CloseCorner.CornerRadius = UDim.new(0, 6)
        CloseCorner.Parent = CloseBtn

        CloseBtn.MouseButton1Click:Connect(function()
            ScreenGui:Destroy()
            WOA_Destroy()
            PM.WOA.Gui = nil
        end)

        local ContentFrame = Instance.new("Frame")
        ContentFrame.Name = "Content"
        ContentFrame.Size = UDim2.new(1, 0, 1, -44)
        ContentFrame.Position = UDim2.new(0, 0, 0, 44)
        ContentFrame.BackgroundTransparency = 1
        ContentFrame.ClipsDescendants = true
        ContentFrame.Parent = MainFrame

        local isMinimized = false
        local originalSize = UDim2.new(0, 239, 0, 130)
        local minimizedSize = UDim2.new(0, 239, 0, 40)
        local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

        MinBtn.MouseButton1Click:Connect(function()
            isMinimized = not isMinimized
            if isMinimized then
                MinBtn.Text = "+"
                local tween = TweenService:Create(MainFrame, tweenInfo, {Size = minimizedSize})
                tween:Play()
                tween.Completed:Connect(function() ContentFrame.Visible = false end)
            else
                MinBtn.Text = "—"
                ContentFrame.Visible = true
                TweenService:Create(MainFrame, tweenInfo, {Size = originalSize}):Play()
            end
        end)

        local ContentLayout = Instance.new("UIListLayout")
        ContentLayout.Padding = UDim.new(0, 6)
        ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
        ContentLayout.Parent = ContentFrame

        local ContentPadding = Instance.new("UIPadding")
        ContentPadding.PaddingTop = UDim.new(0, 4)
        ContentPadding.PaddingBottom = UDim.new(0, 4)
        ContentPadding.PaddingLeft = UDim.new(0, 8)
        ContentPadding.PaddingRight = UDim.new(0, 8)
        ContentPadding.Parent = ContentFrame

        -- Resize Handle
        local ResizeHandle = Instance.new("TextButton")
        ResizeHandle.Name = "ResizeHandle"
        ResizeHandle.Size = UDim2.new(0, 16, 0, 16)
        ResizeHandle.Position = UDim2.new(1, -18, 1, -18)
        ResizeHandle.BackgroundTransparency = 1
        ResizeHandle.Text = ""
        ResizeHandle.Parent = MainFrame

        local ResizeIcon = Instance.new("ImageLabel")
        ResizeIcon.Name = "ResizeIcon"
        ResizeIcon.Size = UDim2.new(0, 10, 0, 10)
        ResizeIcon.Position = UDim2.new(0, 3, 0, 3)
        ResizeIcon.BackgroundTransparency = 1
        ResizeIcon.Image = "rbxassetid://3926305904"
        ResizeIcon.ImageRectOffset = Vector2.new(924, 724)
        ResizeIcon.ImageRectSize = Vector2.new(36, 36)
        ResizeIcon.ImageColor3 = Color3.fromRGB(150, 150, 150)
        ResizeIcon.Parent = ResizeHandle

        local resizing = false
        local resizeStart = nil
        local startSize = nil
        local MIN_SIZE = Vector2.new(200, 100)
        local MAX_SIZE = Vector2.new(500, 400)

        ResizeHandle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                resizing = true
                resizeStart = input.Position
                startSize = Vector2.new(MainFrame.AbsoluteSize.X, MainFrame.AbsoluteSize.Y)
            end
        end)

        ResizeHandle.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                resizing = false
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - resizeStart
                local newWidth = math.clamp(startSize.X + delta.X, MIN_SIZE.X, MAX_SIZE.X)
                local newHeight = math.clamp(startSize.Y + delta.Y, MIN_SIZE.Y, MAX_SIZE.Y)
                MainFrame.Size = UDim2.new(0, newWidth, 0, newHeight)
                originalSize = UDim2.new(0, newWidth, 0, newHeight)
            end
        end)

        local ToggleSection = Instance.new("Frame")
        ToggleSection.Name = "ToggleSection"
        ToggleSection.Size = UDim2.new(1, 0, 0, 36)
        ToggleSection.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        ToggleSection.BackgroundTransparency = 0.4
        ToggleSection.BorderSizePixel = 0
        ToggleSection.LayoutOrder = 1
        ToggleSection.Parent = ContentFrame

        local ToggleSectionCorner = Instance.new("UICorner")
        ToggleSectionCorner.CornerRadius = UDim.new(0, 10)
        ToggleSectionCorner.Parent = ToggleSection

        local ToggleLabel = Instance.new("TextLabel")
        ToggleLabel.Name = "Label"
        ToggleLabel.Size = UDim2.new(1, -100, 1, 0)
        ToggleLabel.Position = UDim2.new(0, 12, 0, 0)
        ToggleLabel.BackgroundTransparency = 1
        ToggleLabel.Text = "Enable"
        ToggleLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
        ToggleLabel.TextSize = 12
        ToggleLabel.Font = Enum.Font.Gotham
        ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
        ToggleLabel.Parent = ToggleSection

        local Pill = Instance.new("Frame")
        Pill.Name = "Pill"
        Pill.Size = UDim2.new(0, 26, 0, 13)
        Pill.Position = UDim2.new(1, -36, 0.5, 0)
        Pill.AnchorPoint = Vector2.new(0, 0.5)
        Pill.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        Pill.BorderSizePixel = 0
        Pill.Parent = ToggleSection

        local PillCorner = Instance.new("UICorner")
        PillCorner.CornerRadius = UDim.new(0, 10)
        PillCorner.Parent = Pill

        local Knob = Instance.new("Frame")
        Knob.Name = "Knob"
        Knob.Size = UDim2.new(0, 9, 0, 9)
        Knob.Position = UDim2.new(0, 2, 0.5, -4)
        Knob.BackgroundColor3 = Color3.fromRGB(235, 235, 235)
        Knob.BorderSizePixel = 0
        Knob.Parent = Pill

        local KnobCorner = Instance.new("UICorner")
        KnobCorner.CornerRadius = UDim.new(0, 10)
        KnobCorner.Parent = Knob

        local PillHit = Instance.new("TextButton")
        PillHit.Size = UDim2.new(1, 0, 1, 0)
        PillHit.BackgroundTransparency = 1
        PillHit.Text = ""
        PillHit.Parent = Pill

        local woaOn = false
        local function SetWOA(val)
            woaOn = val
            ToggleLabel.Text = val and "Disable" or "Enable"
            if val then
                TweenService:Create(Pill, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(80, 80, 80)}):Play()
                TweenService:Create(Knob, TweenInfo.new(0.2), {Position = UDim2.new(1, -11, 0.5, -4)}):Play()
            else
                TweenService:Create(Pill, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}):Play()
                TweenService:Create(Knob, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0.5, -4)}):Play()
            end
            if val then WOA_Create() else WOA_Destroy() end
        end

        PillHit.MouseButton1Click:Connect(function() SetWOA(not woaOn) end)

        local BtnSection = Instance.new("Frame")
        BtnSection.Name = "BtnSection"
        BtnSection.Size = UDim2.new(1, 0, 0, 36)
        BtnSection.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        BtnSection.BackgroundTransparency = 0.4
        BtnSection.BorderSizePixel = 0
        BtnSection.LayoutOrder = 2
        BtnSection.Parent = ContentFrame

        local BtnSectionCorner = Instance.new("UICorner")
        BtnSectionCorner.CornerRadius = UDim.new(0, 10)
        BtnSectionCorner.Parent = BtnSection

        local BtnLayout = Instance.new("UIListLayout")
        BtnLayout.FillDirection = Enum.FillDirection.Horizontal
        BtnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        BtnLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        BtnLayout.Padding = UDim.new(0, 6)
        BtnLayout.SortOrder = Enum.SortOrder.LayoutOrder
        BtnLayout.Parent = BtnSection

        local UpBtn = Instance.new("TextButton")
        UpBtn.Name = "UpBtn"
        UpBtn.Size = UDim2.new(0, 62, 0, 24)
        UpBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        UpBtn.BackgroundTransparency = 0.4
        UpBtn.BorderSizePixel = 0
        UpBtn.Text = "▲  Up"
        UpBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
        UpBtn.TextSize = 11
        UpBtn.Font = Enum.Font.GothamBold
        UpBtn.LayoutOrder = 1
        UpBtn.Parent = BtnSection

        local UpBtnCorner = Instance.new("UICorner")
        UpBtnCorner.CornerRadius = UDim.new(0, 6)
        UpBtnCorner.Parent = UpBtn

        local ResetBtn = Instance.new("TextButton")
        ResetBtn.Name = "ResetBtn"
        ResetBtn.Size = UDim2.new(0, 62, 0, 24)
        ResetBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        ResetBtn.BackgroundTransparency = 0.4
        ResetBtn.BorderSizePixel = 0
        ResetBtn.Text = "Reset"
        ResetBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
        ResetBtn.TextSize = 11
        ResetBtn.Font = Enum.Font.GothamBold
        ResetBtn.LayoutOrder = 2
        ResetBtn.Parent = BtnSection

        local ResetBtnCorner = Instance.new("UICorner")
        ResetBtnCorner.CornerRadius = UDim.new(0, 6)
        ResetBtnCorner.Parent = ResetBtn

        local DownBtn = Instance.new("TextButton")
        DownBtn.Name = "DownBtn"
        DownBtn.Size = UDim2.new(0, 62, 0, 24)
        DownBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        DownBtn.BackgroundTransparency = 0.4
        DownBtn.BorderSizePixel = 0
        DownBtn.Text = "▼  Down"
        DownBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
        DownBtn.TextSize = 11
        DownBtn.Font = Enum.Font.GothamBold
        DownBtn.LayoutOrder = 3
        DownBtn.Parent = BtnSection

        local DownBtnCorner = Instance.new("UICorner")
        DownBtnCorner.CornerRadius = UDim.new(0, 6)
        DownBtnCorner.Parent = DownBtn

        UpBtn.MouseButton1Down:Connect(function() PM.WOA.up = true end)
        UpBtn.MouseButton1Up:Connect(function() PM.WOA.up = false end)
        UpBtn.MouseLeave:Connect(function() PM.WOA.up = false end)

        DownBtn.MouseButton1Down:Connect(function() PM.WOA.down = true end)
        DownBtn.MouseButton1Up:Connect(function() PM.WOA.down = false end)
        DownBtn.MouseLeave:Connect(function() PM.WOA.down = false end)

        ResetBtn.MouseButton1Click:Connect(function()
            if PM.WOA.enabled and PM.WOA.startY ~= nil then
                PM.WOA.baseY = PM.WOA.startY
            end
        end)

        ScreenGui.Destroying:Connect(function()
            WOA_Destroy()
            local plat = workspace:FindFirstChild("PrismWalkAirPlatform")
            if plat then pcall(function() plat:Destroy() end) end
        end)
    end)

    if not success then
        warn("[Prism] Failed to load Walk On Air GUI: " .. tostring(err))
    end
end, true)

-- ========== COMMANDS PANEL POPULATION ==========

PM.populateCommandsPanel = function()
    if not PM.UI.CommandsScroll then return end

    local childCount = 0
    for _, child in ipairs(PM.UI.CommandsScroll:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    PM.UI.CommandButtons = {}

    local sorted = {}
    for _, cmd in pairs(PM.Commands) do
        table.insert(sorted, cmd)
    end
    table.sort(sorted, function(a, b) return a.name:lower() < b.name:lower() end)

    for _, cmd in ipairs(sorted) do
        local btn = PM.mk("TextButton", PM.UI.CommandsScroll, {
            Name = cmd.name,
            Size = UDim2.new(1, -6, 0, 36),
            BackgroundColor3 = PM.C and PM.C.card or Color3.fromRGB(28, 28, 28),
            BackgroundTransparency = 0.5,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            ZIndex = 102,
        })
        PM.corner(btn, 6)

        PM.mk("TextLabel", btn, {
            Size = UDim2.new(1, -16, 0, 16),
            Position = UDim2.new(0, 8, 0, 2),
            BackgroundTransparency = 1,
            Text = cmd.name,
            TextColor3 = PM.C and PM.C.text or Color3.fromRGB(230, 230, 230),
            TextSize = 11,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 103,
        })

        PM.mk("TextLabel", btn, {
            Size = UDim2.new(1, -16, 0, 14),
            Position = UDim2.new(0, 8, 0, 18),
            BackgroundTransparency = 1,
            Text = cmd.desc,
            TextColor3 = PM.C and PM.C.textDim or Color3.fromRGB(90, 90, 90),
            TextSize = 9,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 103,
        })

        btn.MouseEnter:Connect(function()
            PM.tween(btn, 0.15, {BackgroundTransparency = 0.2})
        end)
        btn.MouseLeave:Connect(function()
            PM.tween(btn, 0.15, {BackgroundTransparency = 0.5})
        end)
        btn.MouseButton1Click:Connect(function()
            PM.playClickSound()
            cmd.execute({})
        end)

        table.insert(PM.UI.CommandButtons, {name = cmd.name, desc = cmd.desc, btn = btn})
    end

    local count = #PM.UI.CommandButtons
    PM.UI.CommandsScroll.CanvasSize = UDim2.new(0, 0, 0, count * 38)
end

-- ========== AUTO EXEC PANEL POPULATION ==========

PM.autoExecStates = {}

PM.populateAutoExecPanel = function()
    if not PM.UI.AutoExecScroll then return end

    local childCount = 0
    for _, child in ipairs(PM.UI.AutoExecScroll:GetChildren()) do
        if child:IsA("Frame") and child.Name ~= "UIListLayout" then
            child:Destroy()
        end
    end

    PM.UI.AutoExecRows = {}

    local function makeToggleRow(parent, name, labelText, layoutOrder, defaultState, onToggle)
        local bg = PM.mk("Frame", parent, {
            Name = name .. "Bg",
            Size = UDim2.new(1, -6, 0, 26),
            BackgroundColor3 = PM.C and PM.C.card or Color3.fromRGB(28, 28, 28),
            BackgroundTransparency = 0.5,
            BorderSizePixel = 0,
            LayoutOrder = layoutOrder,
            ZIndex = 102,
        })
        PM.corner(bg, 6)

        PM.mk("TextLabel", bg, {
            Size = UDim2.new(1, -56, 0, 20),
            Position = UDim2.new(0, 8, 0, 3),
            BackgroundTransparency = 1,
            Text = labelText,
            TextColor3 = PM.C and PM.C.text or Color3.fromRGB(230, 230, 230),
            TextSize = 10,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 103,
        })

        local switch = PM.mk("Frame", bg, {
            Name = name .. "Switch",
            Size = UDim2.new(0, 26, 0, 13),
            Position = UDim2.new(1, -36, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = defaultState and Color3.fromRGB(80, 80, 80) or Color3.fromRGB(50, 50, 50),
            BorderSizePixel = 0,
            ZIndex = 103,
        })
        PM.corner(switch, 10)

        local circle = PM.mk("Frame", switch, {
            Name = name .. "Circle",
            Size = UDim2.new(0, 9, 0, 9),
            Position = defaultState and UDim2.new(1, -11, 0.5, -4) or UDim2.new(0, 2, 0.5, -4),
            BackgroundColor3 = Color3.fromRGB(235, 235, 235),
            BorderSizePixel = 0,
            ZIndex = 104,
        })
        PM.corner(circle, 10)

        local hitBtn = PM.mk("TextButton", switch, {
            Name = name .. "Hit",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = "",
            ZIndex = 105,
        })

        local state = defaultState
        hitBtn.MouseButton1Click:Connect(function()
            PM.playClickSound()
            state = not state
            if state then
                PM.tween(switch, 0.2, {BackgroundColor3 = Color3.fromRGB(80, 80, 80)})
                PM.tween(circle, 0.2, {Position = UDim2.new(1, -11, 0.5, -4)})
            else
                PM.tween(switch, 0.2, {BackgroundColor3 = Color3.fromRGB(50, 50, 50)})
                PM.tween(circle, 0.2, {Position = UDim2.new(0, 2, 0.5, -4)})
            end
            if onToggle then onToggle(state) end
        end)

        return bg, switch, circle, hitBtn
    end

    local sorted = {}
    for _, cmd in pairs(PM.Commands) do
        table.insert(sorted, cmd)
    end
    table.sort(sorted, function(a, b) return a.name:lower() < b.name:lower() end)

    for i, cmd in ipairs(sorted) do
        -- Skip commands that should not be auto-executed
        if cmd.excludeFromAutoExec then continue end
        
        local isEnabled = PM.autoExecStates[cmd.name] or false
        local row, switch, circle, hitBtn = makeToggleRow(
            PM.UI.AutoExecScroll,
            "AutoExec_" .. cmd.name,
            cmd.name,
            i,
            isEnabled,
            function(state)
                PM.autoExecStates[cmd.name] = state
                PM.saveAutoExecStates()
            end
        )
        table.insert(PM.UI.AutoExecRows, {name = cmd.name, row = row})
    end
end

PM.filterAutoExecPanel = function(query)
    query = (query or ""):lower()
    for _, data in ipairs(PM.UI.AutoExecRows or {}) do
        local match = data.name:lower():find(query, 1, true) or query == ""
        data.row.Visible = match
    end
end

-- ========== TERMINAL EXECUTION ==========

PM.printTerminal = function(text)
    if not PM.UI.TerminalOutput then return end
    PM.UI.TerminalOutput.Text = PM.UI.TerminalOutput.Text .. "\n" .. text
end

PM.executeCommand = function(input)
    input = input:gsub("^%s+", ""):gsub("%s+$", "")
    if input == "" then return end

    local parts = {}
    for part in input:gmatch("%S+") do
        table.insert(parts, part)
    end

    local cmdName = parts[1]:lower()
    table.remove(parts, 1)

    local cmd = PM.Commands[cmdName]
    if not cmd then
        -- check aliases
        for _, c in pairs(PM.Commands) do
            for _, alias in ipairs(c.aliases) do
                if alias:lower() == cmdName then
                    cmd = c
                    break
                end
            end
            if cmd then break end
        end
    end

    if cmd then
        pcall(function()
            cmd.execute(parts)
        end)
    else
        PM.printTerminal("Unknown command: '" .. cmdName .. "'. Type 'help' for a list of commands.")
    end
end

-- ========== TERMINAL OUTPUT LABEL ==========

PM.createTerminalOutput = function()
    if PM.UI.TerminalOutput then return end
    if not PM.UI.TerminalPanel then return end

    PM.UI.TerminalOutput = PM.mk("TextLabel", PM.UI.TerminalPanel, {
        Name = "TerminalOutput",
        Size = UDim2.new(1, -20, 0, 200),
        Position = UDim2.new(0, 10, 0, 38),
        BackgroundTransparency = 1,
        Text = "Type 'help' for available commands.",
        TextColor3 = PM.C and PM.C.text or Color3.fromRGB(230, 230, 230),
        TextSize = 11,
        Font = Enum.Font.RobotoMono,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        ZIndex = 101,
    })
end

-- ========== AUTO EXECUTE FUNCTIONALITY ==========

PM.AUTOEXEC_SAVE_FILE = "prism/prism_autoexec.json"

-- Save auto exec states to file
PM.saveAutoExecStates = function()
    if not writefile then return end
    
    local states = {}
    for name, cmd in pairs(PM.Commands) do
        if not cmd.excludeFromAutoExec then
            states[name] = PM.autoExecStates[name] or false
        end
    end
    
    pcall(function()
        if not isfolder("prism") then
            makefolder("prism")
        end
        writefile(PM.AUTOEXEC_SAVE_FILE, game:GetService("HttpService"):JSONEncode(states))
    end)
end

-- Load auto exec states from file
PM.loadAutoExecStates = function()
    if not readfile then return end
    
    pcall(function()
        local data = readfile(PM.AUTOEXEC_SAVE_FILE)
        if data then
            local states = game:GetService("HttpService"):JSONDecode(data)
            for name, state in pairs(states) do
                PM.autoExecStates[name] = state
            end
        end
    end)
end

-- Execute auto exec commands on startup
PM.executeAutoExecCommands = function()
    -- Wait for GUI to fully load
    task.wait(1)
    
    -- Check if auto execute is enabled globally
    if PM.autoExecuteCommands == false then return end
    
    for name, cmd in pairs(PM.Commands) do
        -- Skip excluded commands
        if not cmd.excludeFromAutoExec then
            local isEnabled = PM.autoExecStates[name] or false
            if isEnabled then
                pcall(function()
                    cmd.execute({})
                end)
            end
        end
    end
end

-- Populate panels after this file loads
task.delay(0.5, function()
    -- Wait for Main.lua to create the UI functions if needed
    local retries = 0
    while (not PM.createCommandsPanel or not PM.createSettingsPanel) and retries < 20 do
        task.wait(0.1)
        retries = retries + 1
    end
    
    -- Load saved auto exec states first
    if PM.loadAutoExecStates then PM.loadAutoExecStates() end
    
    -- Create panels if they don't exist
    if not PM.UI.CommandsPanel and PM.createCommandsPanel then
        PM.createCommandsPanel()
    end
    if not PM.UI.SettingsPanel and PM.createSettingsPanel then
        PM.createSettingsPanel()
    end
    
    -- Populate the panels
    PM.populateCommandsPanel()
    PM.populateAutoExecPanel()
    if PM.createTerminalOutput then PM.createTerminalOutput() end
    
    if PM.UI.AutoExecSearch then
        PM.UI.AutoExecSearch:GetPropertyChangedSignal("Text"):Connect(function()
            PM.filterAutoExecPanel(PM.UI.AutoExecSearch.Text)
        end)
    end
    
    -- Execute auto exec commands after everything is loaded
    PM.executeAutoExecCommands()
end)

return PM.Commands
