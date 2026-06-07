local PM = getgenv().PrismMain
if not PM then return end

PM.Commands = PM.Commands or {}

local function registerCommand(name, desc, aliases, execute)
    PM.Commands[name:lower()] = {
        name = name,
        desc = desc,
        aliases = aliases or {},
        execute = execute,
    }
end

-- ========== UTILITY COMMANDS ==========

registerCommand("help", "List all available commands", {"?", "cmds"}, function(args)
    PM.printTerminal("Available commands:")
    for _, cmd in pairs(PM.Commands) do
        PM.printTerminal("  " .. cmd.name .. " - " .. cmd.desc)
    end
end)

registerCommand("clear", "Clear the terminal output", {"cls"}, function(args)
    if PM.UI.TerminalOutput then
        PM.UI.TerminalOutput.Text = ""
    end
end)

registerCommand("rejoin", "Rejoin the current server", {"rj"}, function(args)
    game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, PM.Svc.Players.LocalPlayer)
end)

registerCommand("serverhop", "Join a different server", {"sh", "hop"}, function(args)
    local TeleportService = game:GetService("TeleportService")
    local HttpService = game:GetService("HttpService")
    local ok, result = pcall(function()
        return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
    end)
    if ok and result and result.data then
        for _, server in ipairs(result.data) do
            if server.id ~= game.JobId and server.playing < server.maxPlayers then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, PM.Svc.Players.LocalPlayer)
                return
            end
        end
        PM.printTerminal("No available servers found.")
    else
        PM.printTerminal("Failed to fetch servers.")
    end
end)

registerCommand("goto", "Teleport to a player", {"to"}, function(args)
    local targetName = table.concat(args, " ")
    if targetName == "" then
        PM.printTerminal("Usage: goto <player>")
        return
    end
    local Players = game:GetService("Players")
    local target = Players:FindFirstChild(targetName) or Players:FindFirstChild(targetName:lower())
    if not target then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Name:lower():find(targetName:lower(), 1, true) or plr.DisplayName:lower():find(targetName:lower(), 1, true) then
                target = plr
                break
            end
        end
    end
    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        local myChar = PM.Svc.Players.LocalPlayer.Character
        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if myHRP then
            myHRP.CFrame = target.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
            PM.printTerminal("Teleported to " .. target.Name)
        end
    else
        PM.printTerminal("Player not found or no character.")
    end
end)

registerCommand("walkspeed", "Set your walkspeed", {"ws", "speed"}, function(args)
    local speed = tonumber(args[1]) or 16
    local myChar = PM.Svc.Players.LocalPlayer.Character
    local humanoid = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = speed
        PM.printTerminal("WalkSpeed set to " .. speed)
    else
        PM.printTerminal("Humanoid not found.")
    end
end)

registerCommand("jumppower", "Set your jump power", {"jp"}, function(args)
    local power = tonumber(args[1]) or 50
    local myChar = PM.Svc.Players.LocalPlayer.Character
    local humanoid = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.JumpPower = power
        PM.printTerminal("JumpPower set to " .. power)
    else
        PM.printTerminal("Humanoid not found.")
    end
end)

registerCommand("reset", "Reset your character", {"die"}, function(args)
    local myChar = PM.Svc.Players.LocalPlayer.Character
    local humanoid = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.Health = 0
    end
end)

registerCommand("fps", "Show current FPS", {}, function(args)
    if PM.UI.FPSLabel then
        PM.printTerminal("Current FPS: " .. PM.UI.FPSLabel.Text)
    else
        PM.printTerminal("FPS counter not available.")
    end
end)

registerCommand("ping", "Show current ping", {}, function(args)
    if PM.UI.PingLabel then
        PM.printTerminal("Current Ping: " .. PM.UI.PingLabel.Text .. "ms")
    else
        PM.printTerminal("Ping counter not available.")
    end
end)

-- ========== COMMANDS PANEL POPULATION ==========

PM.populateCommandsPanel = function()
    if not PM.UI.CommandsScroll then return end

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

-- Populate after a short delay to ensure UI exists
task.delay(0.5, function()
    PM.createTerminalOutput()
    PM.populateCommandsPanel()
end)

return PM.Commands
