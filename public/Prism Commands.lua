print("[Prism Debug] Prism Commands.lua loading...")
local PM = getgenv().PrismMain
if not PM then 
    print("[Prism Debug] ERROR: PrismMain not found!")
    return 
end
print("[Prism Debug] PrismMain found")

PM.Commands = PM.Commands or {}
print("[Prism Debug] PM.Commands initialized")

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

local cmdCount = 0
for name, _ in pairs(PM.Commands) do
    print("[Prism Debug] Registered command: " .. name)
    cmdCount = cmdCount + 1
end
print("[Prism Debug] All commands registered, total: " .. tostring(cmdCount))

-- ========== COMMANDS PANEL POPULATION ==========

PM.populateCommandsPanel = function()
    print("[Prism Debug] populateCommandsPanel called")
    if not PM.UI.CommandsScroll then 
        print("[Prism Debug] ERROR: CommandsScroll does not exist!")
        return 
    end
    print("[Prism Debug] CommandsScroll found, clearing children...")

    local childCount = 0
    for _, child in ipairs(PM.UI.CommandsScroll:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
            childCount = childCount + 1
        end
    end
    print("[Prism Debug] Cleared " .. childCount .. " old buttons")

    PM.UI.CommandButtons = {}
    print("[Prism Debug] CommandButtons reset")

    local sorted = {}
    local cmdCount = 0
    for _, cmd in pairs(PM.Commands) do
        table.insert(sorted, cmd)
        cmdCount = cmdCount + 1
    end
    print("[Prism Debug] Found " .. cmdCount .. " commands to display")
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
    print("[Prism Debug] populateCommandsPanel complete - created " .. count .. " buttons")
end

-- ========== AUTO EXEC PANEL POPULATION ==========

PM.autoExecStates = {}

PM.populateAutoExecPanel = function()
    print("[Prism Debug] populateAutoExecPanel called")
    if not PM.UI.AutoExecScroll then 
        print("[Prism Debug] ERROR: AutoExecScroll does not exist!")
        return 
    end
    print("[Prism Debug] AutoExecScroll found, clearing children...")

    local childCount = 0
    for _, child in ipairs(PM.UI.AutoExecScroll:GetChildren()) do
        if child:IsA("Frame") and child.Name ~= "UIListLayout" then
            child:Destroy()
            childCount = childCount + 1
        end
    end
    print("[Prism Debug] Cleared " .. childCount .. " old rows")

    PM.UI.AutoExecRows = {}
    print("[Prism Debug] AutoExecRows reset")

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
    local cmdCount = 0
    for _, cmd in pairs(PM.Commands) do
        table.insert(sorted, cmd)
        cmdCount = cmdCount + 1
    end
    print("[Prism Debug] Found " .. cmdCount .. " commands for auto exec")
    table.sort(sorted, function(a, b) return a.name:lower() < b.name:lower() end)

    for i, cmd in ipairs(sorted) do
        local isEnabled = PM.autoExecStates[cmd.name] or false
        local row, switch, circle, hitBtn = makeToggleRow(
            PM.UI.AutoExecScroll,
            "AutoExec_" .. cmd.name,
            cmd.name,
            i,
            isEnabled,
            function(state)
                PM.autoExecStates[cmd.name] = state
            end
        )
        table.insert(PM.UI.AutoExecRows, {name = cmd.name, row = row})
    end
    print("[Prism Debug] populateAutoExecPanel complete - created " .. #PM.UI.AutoExecRows .. " rows")
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

-- Populate panels after this file loads
-- Use a longer delay to ensure Prism Main.lua has fully created the UI
task.delay(0.5, function()
    print("[Prism Debug] Commands.lua - Starting delayed population...")
    
    -- Ensure panels exist
    if not PM.UI.CommandsPanel then
        print("[Prism Debug] Commands.lua - Creating CommandsPanel...")
        if PM.createCommandsPanel then PM.createCommandsPanel() end
    end
    if not PM.UI.SettingsPanel then
        print("[Prism Debug] Commands.lua - Creating SettingsPanel...")
        if PM.createSettingsPanel then PM.createSettingsPanel() end
    end
    
    -- Now populate
    print("[Prism Debug] Commands.lua - Calling populateCommandsPanel...")
    PM.populateCommandsPanel()
    
    print("[Prism Debug] Commands.lua - Calling populateAutoExecPanel...")
    PM.populateAutoExecPanel()
    
    print("[Prism Debug] Commands.lua - Calling createTerminalOutput...")
    PM.createTerminalOutput()
    
    -- Connect auto exec search
    if PM.UI.AutoExecSearch then
        print("[Prism Debug] Commands.lua - Connecting AutoExecSearch filter...")
        PM.UI.AutoExecSearch:GetPropertyChangedSignal("Text"):Connect(function()
            PM.filterAutoExecPanel(PM.UI.AutoExecSearch.Text)
        end)
    end
    
    print("[Prism Debug] Commands.lua - Population complete!")
end)

return PM.Commands
