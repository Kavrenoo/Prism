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
    if PM.UI.Gui then
        pcall(function() PM.UI.Gui:Destroy() end)
    end
    getgenv().PrismMain = nil
    getgenv().PrismLoaded = false
end)

registerCommand("reload", "Reload Prism script", {}, function(args)
    -- Clean up existing UI
    if PM.UI.Gui then
        pcall(function() PM.UI.Gui:Destroy() end)
    end
    getgenv().PrismMain = nil
    getgenv().PrismLoaded = false
    -- Reload from URL
    loadstring(game:HttpGet("https://prismscript.vercel.app/Prism.lua"))()
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
task.delay(0.5, function()
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
end)

return PM.Commands
