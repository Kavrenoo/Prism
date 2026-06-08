local PM = getgenv().PrismMain
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
    -- Destroy walk on air if active
    if PM.WOA_Destroy then
        pcall(PM.WOA_Destroy)
        PM.WOA_Destroy = nil
    end
    if PM.WOA_Panel then
        pcall(function() PM.WOA_Panel:Destroy() end)
        PM.WOA_Panel = nil
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
    -- Clear globals
    getgenv().PrismMain = nil
    getgenv().PrismLoaded = false
end, true)

registerCommand("reload", "Reload Prism script", {}, function(args)
    -- Clean up existing UI
    if PM.UI.Gui then
        pcall(function() PM.UI.Gui:Destroy() end)
    end
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

registerCommand("hide", "Hide a player locally", {}, function(args), true)
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
end)

registerCommand("unhide", "Unhide a player", {}, function(args), true)
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
end)

registerCommand("hideall", "Hide all other players", {}, function(args), true)
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
end)

registerCommand("unhideall", "Unhide all players", {}, function(args), true)
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
end)

-- Muted players tracking table
PM.MutedPlayers = {}

registerCommand("mute", "Mute a player's voice chat", {}, function(args), true)
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
end)

registerCommand("unmute", "Unmute a player's voice chat", {}, function(args), true)
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
end)

registerCommand("muteall", "Mute all other players", {}, function(args), true)
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
end)

registerCommand("unmuteall", "Unmute all players", {}, function(args), true)
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
end)

registerCommand("to", "Teleport to player", {}, function(args), true)
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
end)

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
            
            local targetPos = Vector3.new(hit.X, hit.Y + hipH + sinkBuffer, hit.Z)
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
    -- Load saved auto exec states first
    PM.loadAutoExecStates()
    
    if not PM.UI.CommandsPanel then
        if PM.createCommandsPanel then PM.createCommandsPanel() end
    end
    if not PM.UI.SettingsPanel then
        if PM.createSettingsPanel then PM.createSettingsPanel() end
    end
    
    PM.populateCommandsPanel()
    PM.populateAutoExecPanel()
    PM.createTerminalOutput()
    
    if PM.UI.AutoExecSearch then
        PM.UI.AutoExecSearch:GetPropertyChangedSignal("Text"):Connect(function()
            PM.filterAutoExecPanel(PM.UI.AutoExecSearch.Text)
        end)
    end
    
    -- Execute auto exec commands after everything is loaded
    PM.executeAutoExecCommands()
end)

return PM.Commands
