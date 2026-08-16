if not getgenv().PrismLoaded then
    return
end

getgenv().PrismMain = {
    Svc = {
        Players = game:GetService("Players"),
        TweenService = game:GetService("TweenService"),
        RunService = game:GetService("RunService"),
        CoreGui = game:GetService("CoreGui"),
    },
    UI = {},
}

local PM = getgenv().PrismMain
local LP = PM.Svc.Players.LocalPlayer

-- Early settings loading (before UI creation)
local SETTINGS_FILE = "prism/prism_settings.json"
if readfile then
    pcall(function()
        local data = readfile(SETTINGS_FILE)
        if data then
            local settings = game:GetService("HttpService"):JSONDecode(data)
            PM.autoExecutePrism = settings.autoExecutePrism or false
            PM.autoExecuteCommands = settings.autoExecuteCommands ~= false
            PM.terminalKeybind = settings.terminalKeybind or "F6"
        end
    end)
end

PM.mk = function(class, parent, props)
    local i = Instance.new(class)
    i.Parent = parent
    for k, v in pairs(props or {}) do i[k] = v end
    return i
end

PM.corner = function(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = p
    return c
end

PM.stroke = function(p, c, t, trans)
    local s = Instance.new("UIStroke")
    s.Color = c or Color3.fromRGB(40, 40, 40)
    s.Thickness = t or 1
    s.Transparency = trans or 0
    s.Parent = p
    return s
end

PM.tween = function(obj, time, props, style)
    return PM.Svc.TweenService:Create(obj, TweenInfo.new(time or 0.3, style or Enum.EasingStyle.Quad), props):Play()
end

PM.C = {
    bg = Color3.fromRGB(15, 15, 15),
    card = Color3.fromRGB(28, 28, 28),
    accent = Color3.fromRGB(180, 180, 180),
    text = Color3.fromRGB(230, 230, 230),
    textDim = Color3.fromRGB(90, 90, 90),
    border = Color3.fromRGB(45, 45, 45),
    green = Color3.fromRGB(70, 170, 70),
    red = Color3.fromRGB(170, 70, 70),
}
local C = PM.C

PM.createMainGUI = function()
    if PM.Svc.CoreGui:FindFirstChild("PrismMainGui") then return end
    
    PM.UI.Gui = PM.mk("ScreenGui", PM.Svc.CoreGui, {
        Name = "PrismMainGui",
        DisplayOrder = 1000,
        ResetOnSpawn = false,
    })
    
    PM.UI.Main = PM.mk("Frame", PM.UI.Gui, {
        Name = "MainFrame",
        Size = UDim2.new(0, 460, 0, 56),
        Position = UDim2.new(0.5, -230, 0, -30),
        BackgroundColor3 = C.bg,
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    })
    PM.corner(PM.UI.Main, 14)
    PM.stroke(PM.UI.Main, C.border, 1, 0.4)
    
    PM.UI.StatsFrame = PM.mk("Frame", PM.UI.Main, {
        Name = "StatsFrame",
        Size = UDim2.new(0, 75, 0, 44),
        Position = UDim2.new(0, 14, 0.5, -22),
        BackgroundTransparency = 1,
        ZIndex = 10,
    })
    
    PM.UI.FPSLabelText = PM.mk("TextLabel", PM.UI.StatsFrame, {
        Name = "FPSLabelText",
        Size = UDim2.new(0, 35, 0, 14),
        Position = UDim2.new(0, 0, 0, 2),
        BackgroundTransparency = 1,
        Text = "FPS",
        TextColor3 = C.text,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    
    PM.UI.FPSLabel = PM.mk("TextLabel", PM.UI.StatsFrame, {
        Name = "FPSLabel",
        Size = UDim2.new(0, 40, 0, 14),
        Position = UDim2.new(0, 35, 0, 2),
        BackgroundTransparency = 1,
        Text = " ",
        TextColor3 = C.text,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    PM.UI.PingLabelText = PM.mk("TextLabel", PM.UI.StatsFrame, {
        Name = "PingLabelText",
        Size = UDim2.new(0, 35, 0, 14),
        Position = UDim2.new(0, 0, 0, 23),
        BackgroundTransparency = 1,
        Text = "PING",
        TextColor3 = C.text,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    
    PM.UI.PingLabel = PM.mk("TextLabel", PM.UI.StatsFrame, {
        Name = "PingLabel",
        Size = UDim2.new(0, 40, 0, 14),
        Position = UDim2.new(0, 35, 0, 23),
        BackgroundTransparency = 1,
        Text = " ",
        TextColor3 = C.text,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    
    PM.UI.ButtonsFrame = PM.mk("Frame", PM.UI.Main, {
        Name = "ButtonsFrame",
        Size = UDim2.new(0, 220, 0, 36),
        Position = UDim2.new(0.5, -110, 0.5, -18),
        BackgroundTransparency = 1,
        ZIndex = 10,
    })
    
    PM.UI.ButtonsList = PM.mk("UIListLayout", PM.UI.ButtonsFrame, {
        Padding = UDim.new(0, 8),
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    
    local buttonData = {
        {name = "Commands", layout = 1, image = "rbxassetid://132440478962916"},
        {name = "Terminal", layout = 3, image = "rbxassetid://73577105416536"},
        {name = "NameTags", layout = 5, image = "rbxassetid://99892550804409"},
        {name = "Join", layout = 7, image = "rbxassetid://84437305519060"},
        {name = "Servers", layout = 9, image = "rbxassetid://138470287250966"},
        {name = "Settings", layout = 11, image = "rbxassetid://101119408272746"},
    }
    
    PM.UI.Buttons = {}
    for i, btn in ipairs(buttonData) do
        local button = PM.mk("ImageButton", PM.UI.ButtonsFrame, {
            Name = "Btn_" .. btn.name,
            Size = UDim2.new(0, 32, 0, 28),
            BackgroundColor3 = Color3.fromRGB(20, 20, 26),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            LayoutOrder = btn.layout,
            ZIndex = 10,
        })
        PM.corner(button, 3)
        
        local icon = PM.mk("ImageLabel", button, {
            Name = "Icon",
            Size = UDim2.new(0, 18, 0, 18),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Image = btn.image,
            ImageColor3 = Color3.fromRGB(255, 255, 255),
            ZIndex = 2,
        })
        
        PM.clickSoundEnabled = true
        PM.clickVolume = 0.75
        PM.clickSoundID = "94859356677805"
        PM.hoverSoundEnabled = true
        PM.hoverVolume = 0.75
        PM.hoverSoundID = "107511012621133"

        if not PM.UI.HoverSound then
            PM.UI.HoverSound = PM.mk("Sound", PM.UI.Gui, {
                SoundId = "rbxassetid://" .. PM.hoverSoundID,
                Volume = PM.hoverVolume,
            })
        end

        if not PM.UI.ClickSound then
            PM.UI.ClickSound = PM.mk("Sound", PM.UI.Gui, {
                SoundId = "rbxassetid://" .. PM.clickSoundID,
                Volume = PM.clickVolume,
            })
        end

        PM.playClickSound = function()
            if PM.clickSoundEnabled and PM.UI.ClickSound then
                pcall(function() PM.UI.ClickSound:Play() end)
            end
        end

        PM.playHoverSound = function()
            if PM.hoverSoundEnabled and PM.UI.HoverSound then
                pcall(function() PM.UI.HoverSound:Play() end)
            end
        end
        
        local isHovering = false
        button.MouseEnter:Connect(function()
            isHovering = true
            PM.isHoveringAnyButton = true
            PM.tween(icon, 0.15, {Size = UDim2.new(0, 22, 0, 22), ImageColor3 = Color3.fromRGB(180, 180, 190)})
            PM.playHoverSound()
        end)
        button.MouseLeave:Connect(function()
            isHovering = false
            PM.isHoveringAnyButton = false
            PM.tween(icon, 0.15, {Size = UDim2.new(0, 18, 0, 18), ImageColor3 = Color3.fromRGB(255, 255, 255)})
        end)
        button.MouseButton1Down:Connect(function()
            PM.tween(icon, 0.08, {Size = UDim2.new(0, 16, 0, 16)})
        end)
        button.MouseButton1Up:Connect(function()
            local targetSize = isHovering and UDim2.new(0, 22, 0, 22) or UDim2.new(0, 18, 0, 18)
            PM.tween(icon, 0.08, {Size = targetSize})
        end)
        if btn.name == "Terminal" then
            PM.isTerminalOpen = false
            button.MouseButton1Click:Connect(function()
                PM.playClickSound()
                if PM.isTerminalOpen then
                    PM.isTerminalOpen = false
                    PM.hideTerminalPanel()
                else
                    PM.isTerminalOpen = true
                    if PM.isCommandsOpen then
                        PM.isCommandsOpen = false
                        PM.hideCommandsPanel()
                    end
                    if PM.isServersOpen then
                        PM.isServersOpen = false
                        PM.hideServersPanel()
                    end
                    if PM.UI.NameTagsPanel and PM.UI.NameTagsPanel.Visible then
                        PM.UI.NameTagsPanel.Visible = false
                    end
                    if PM.isJoinOpen then
                        PM.isJoinOpen = false
                        PM.hideJoinPanel()
                    end
                    if PM.isSettingsOpen then
                        PM.isSettingsOpen = false
                        PM.hideSettingsPanel()
                    end
                    PM.toggleTerminalPanel()
                end
            end)
        elseif btn.name == "Commands" then
            PM.isCommandsOpen = false
            button.MouseButton1Click:Connect(function()
                PM.playClickSound()
                if PM.isCommandsOpen then
                    PM.isCommandsOpen = false
                    PM.closeCommandsPanel()
                else
                    PM.isCommandsOpen = true
                    if PM.isTerminalOpen then
                        PM.isTerminalOpen = false
                        PM.hideTerminalPanel()
                    end
                    if PM.isServersOpen then
                        PM.isServersOpen = false
                        PM.hideServersPanel()
                    end
                    if PM.UI.NameTagsPanel and PM.UI.NameTagsPanel.Visible then
                        PM.UI.NameTagsPanel.Visible = false
                    end
                    if PM.isJoinOpen then
                        PM.isJoinOpen = false
                        PM.hideJoinPanel()
                    end
                    if PM.isSettingsOpen then
                        PM.isSettingsOpen = false
                        PM.hideSettingsPanel()
                    end
                    PM.openCommandsPanel()
                end
            end)
        elseif btn.name == "NameTags" then
            PM.isNameTagsEnabled = true
            button.MouseButton1Click:Connect(function()
                PM.playClickSound()
                PM.isNameTagsEnabled = not PM.isNameTagsEnabled
                if PM.isTerminalOpen then
                    PM.isTerminalOpen = false
                    PM.hideTerminalPanel()
                end
                if PM.isCommandsOpen then
                    PM.isCommandsOpen = false
                    PM.hideCommandsPanel()
                end
                if PM.isServersOpen then
                    PM.isServersOpen = false
                    PM.hideServersPanel()
                end
                if PM.isJoinOpen then
                    PM.isJoinOpen = false
                    PM.hideJoinPanel()
                end
                if PM.isSettingsOpen then
                    PM.isSettingsOpen = false
                    PM.hideSettingsPanel()
                end
                PM.toggleNameTagsPanel()
            end)
        elseif btn.name == "Servers" then
            PM.isServersOpen = false
            button.MouseButton1Click:Connect(function()
                PM.playClickSound()
                if PM.isServersOpen then
                    PM.isServersOpen = false
                    PM.closeServersPanel()
                else
                    PM.isServersOpen = true
                    if PM.isTerminalOpen then
                        PM.isTerminalOpen = false
                        PM.hideTerminalPanel()
                    end
                    if PM.isCommandsOpen then
                        PM.isCommandsOpen = false
                        PM.hideCommandsPanel()
                    end
                    if PM.UI.NameTagsPanel and PM.UI.NameTagsPanel.Visible then
                        PM.UI.NameTagsPanel.Visible = false
                    end
                    if PM.isJoinOpen then
                        PM.isJoinOpen = false
                        PM.hideJoinPanel()
                    end
                    if PM.isSettingsOpen then
                        PM.isSettingsOpen = false
                        PM.hideSettingsPanel()
                    end
                    PM.openServersPanel()
                end
            end)
        elseif btn.name == "Join" then
            PM.isJoinOpen = false
            button.MouseButton1Click:Connect(function()
                PM.playClickSound()
                if PM.isJoinOpen then
                    PM.isJoinOpen = false
                    PM.closeJoinPanel()
                else
                    PM.isJoinOpen = true
                    if PM.isTerminalOpen then
                        PM.isTerminalOpen = false
                        PM.hideTerminalPanel()
                    end
                    if PM.isCommandsOpen then
                        PM.isCommandsOpen = false
                        PM.hideCommandsPanel()
                    end
                    if PM.isServersOpen then
                        PM.isServersOpen = false
                        PM.hideServersPanel()
                    end
                    if PM.UI.NameTagsPanel and PM.UI.NameTagsPanel.Visible then
                        PM.UI.NameTagsPanel.Visible = false
                    end
                    if PM.isSettingsOpen then
                        PM.isSettingsOpen = false
                        PM.hideSettingsPanel()
                    end
                    PM.openJoinPanel()
                end
            end)
        elseif btn.name == "Settings" then
            PM.isSettingsOpen = false
            button.MouseButton1Click:Connect(function()
                PM.playClickSound()
                if PM.isSettingsOpen then
                    PM.isSettingsOpen = false
                    PM.closeSettingsPanel()
                else
                    PM.isSettingsOpen = true
                    if PM.isTerminalOpen then
                        PM.isTerminalOpen = false
                        PM.hideTerminalPanel()
                    end
                    if PM.isCommandsOpen then
                        PM.isCommandsOpen = false
                        PM.hideCommandsPanel()
                    end
                    if PM.isServersOpen then
                        PM.isServersOpen = false
                        PM.hideServersPanel()
                    end
                    if PM.isJoinOpen then
                        PM.isJoinOpen = false
                        PM.hideJoinPanel()
                    end
                    if PM.UI.NameTagsPanel and PM.UI.NameTagsPanel.Visible then
                        PM.UI.NameTagsPanel.Visible = false
                    end
                    PM.openSettingsPanel()
                end
            end)
        else
            button.MouseButton1Click:Connect(function()
                PM.playClickSound()
            end)
        end
        
        PM.UI.Buttons[btn.name] = button
    end
    
    PM.createTerminalPanel = function()
        if PM.UI.TerminalPanel then return end
        
        PM.UI.TerminalPanel = PM.mk("Frame", PM.UI.Gui, {
            Name = "TerminalPanel",
            Size = UDim2.new(0, 340, 0, 38),
            Position = UDim2.new(0.5, 0, 0, 35),
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundColor3 = C.bg,
            BackgroundTransparency = 0.18,
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = 100,
            ClipsDescendants = true,
        })
        PM.corner(PM.UI.TerminalPanel, 10)
        PM.stroke(PM.UI.TerminalPanel, C.border, 1, 0.5)
        
        -- Flag to prevent FocusLost from closing immediately after panel opens
        PM.panelJustOpened = false
        PM.keybindJustChanged = false
        
        PM.mk("TextLabel", PM.UI.TerminalPanel, {
            Size = UDim2.new(0, 24, 0, 38),
            Position = UDim2.new(0, 8, 0, 0),
            BackgroundTransparency = 1,
            Text = ">",
            TextColor3 = C.textDim,
            TextSize = 18,
            Font = Enum.Font.Gotham,
            ZIndex = 101,
        })
        
        PM.UI.TerminalAutofill = PM.mk("TextLabel", PM.UI.TerminalPanel, {
            Size = UDim2.new(1, -40, 0, 38),
            Position = UDim2.new(0, 32, 0, 0),
            BackgroundTransparency = 1,
            Text = "",
            TextColor3 = Color3.fromRGB(60, 60, 60), -- Darker than input text
            TextSize = 13,
            Font = Enum.Font.RobotoMono,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 102,
        })
        
        PM.UI.TerminalInput = PM.mk("TextBox", PM.UI.TerminalPanel, {
            Size = UDim2.new(1, -90, 0, 38),
            Position = UDim2.new(0, 32, 0, 0),
            BackgroundTransparency = 1,
            Text = "",
            PlaceholderText = "Enter a command...",
            PlaceholderColor3 = C.textDim,
            TextColor3 = C.textDim,
            TextSize = 13,
            Font = Enum.Font.RobotoMono,
            TextXAlignment = Enum.TextXAlignment.Left,
            ClearTextOnFocus = false,
            TextEditable = true,
            TextStrokeTransparency = 1,
            ZIndex = 105,
        })
        
        -- Keybind button (like Mono's F6 button in terminal)
        local keybindBtn = PM.mk("TextButton", PM.UI.TerminalPanel, {
            Name = "KeybindBtn",
            Size = UDim2.new(0, 46, 0, 22),
            Position = UDim2.new(1, -52, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = C.card,
            BackgroundTransparency = 0.3,
            BorderSizePixel = 0,
            Text = PM.terminalKeybind or "F6",
            TextColor3 = C.textDim,
            TextSize = 10,
            Font = Enum.Font.GothamBold,
            ZIndex = 106,
        })
        PM.corner(keybindBtn, 4)
        
        -- Hover detection to prevent terminal close when rebinding
        PM.isHoveringKeybindBtn = false
        keybindBtn.MouseEnter:Connect(function()
            PM.isHoveringKeybindBtn = true
        end)
        keybindBtn.MouseLeave:Connect(function()
            PM.isHoveringKeybindBtn = false
        end)
        
        keybindBtn.MouseButton1Click:Connect(function()
            if PM.keybindJustChanged then
                PM.keybindJustChanged = false
                keybindBtn.Text = PM.terminalKeybind or "F6"
                keybindBtn.TextColor3 = C.textDim
            else
                PM.keybindJustChanged = true
                keybindBtn.Text = "..."
                keybindBtn.TextColor3 = C.textDim
            end
        end)
        
        -- Capture keybind from terminal panel
        game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if PM.keybindJustChanged and input.UserInputType == Enum.UserInputType.Keyboard then
                PM.keybindJustChanged = false
                PM.terminalKeybind = input.KeyCode.Name
                keybindBtn.Text = PM.terminalKeybind
                keybindBtn.TextColor3 = C.textDim
                -- Regain focus on input after rebinding
                task.delay(0.05, function()
                    if PM.UI.TerminalInput then
                        PM.UI.TerminalInput:CaptureFocus()
                    end
                end)
                -- Save to settings
                if writefile then
                    pcall(function()
                        local settings = {
                            autoExecutePrism = PM.autoExecutePrism or false,
                            autoExecuteCommands = PM.autoExecuteCommands ~= false,
                            terminalKeybind = PM.terminalKeybind,
                        }
                        writefile("prism/prism_settings.json", game:GetService("HttpService"):JSONEncode(settings))
                    end)
                end
            end
        end)
        
        -- Autofill functionality
        local function updateAutofill()
            local input = PM.UI.TerminalInput.Text:lower()
            if input == "" then
                PM.UI.TerminalAutofill.Text = ""
                return
            end
            
            -- Find first matching command
            for cmdName, cmd in pairs(PM.Commands or {}) do
                if cmdName:sub(1, #input) == input then
                    PM.UI.TerminalAutofill.Text = cmd.name
                    return
                end
                -- Check aliases too
                for _, alias in ipairs(cmd.aliases or {}) do
                    if alias:lower():sub(1, #input) == input then
                        PM.UI.TerminalAutofill.Text = cmd.name
                        return
                    end
                end
            end
            
            PM.UI.TerminalAutofill.Text = ""
        end
        
        PM.UI.TerminalInput:GetPropertyChangedSignal("Text"):Connect(updateAutofill)
        
        -- Handle Enter to execute and close
        PM.UI.TerminalInput.FocusLost:Connect(function(enterPressed)
            if enterPressed then
                local cmd = PM.UI.TerminalInput.Text
                local suggestion = PM.UI.TerminalAutofill.Text
                -- If there's an autofill suggestion, use it (like Mono)
                if suggestion and suggestion ~= "" and suggestion ~= " " then
                    cmd = suggestion
                end
                if cmd and cmd ~= "" then
                    PM.UI.TerminalInput.Text = ""
                    PM.UI.TerminalAutofill.Text = ""
                    if PM.executeCommand then
                        PM.executeCommand(cmd)
                    end
                end
                -- Close after executing command
                PM.isTerminalOpen = false
                PM.closeTerminalPanel()
            else
                -- Close on focus loss (clicking outside) - check blocking flags here
                if PM.panelJustOpened or PM.keybindJustChanged or PM.isHoveringKeybindBtn or PM.isHoveringAnyButton then
                    return
                end
                PM.isTerminalOpen = false
                PM.closeTerminalPanel()
            end
        end)
        
        -- Handle Tab for autofill and Escape to close
        game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if not PM.UI.TerminalPanel or not PM.UI.TerminalPanel.Visible then return end
            
            -- Skip keybind handling if panel just opened (prevents F6 from immediately closing)
            if PM.panelJustOpened then return end
            
            if input.KeyCode == Enum.KeyCode.Tab then
                local suggestion = PM.UI.TerminalAutofill.Text
                if suggestion and suggestion ~= "" then
                    PM.UI.TerminalInput.Text = suggestion
                    PM.UI.TerminalInput.CursorPosition = #suggestion + 1
                    PM.UI.TerminalAutofill.Text = ""
                end
            elseif input.KeyCode == Enum.KeyCode.Escape then
                PM.isTerminalOpen = false
                PM.closeTerminalPanel()
            end
        end)
        
    end
    
    PM.openTerminalPanel = function()
        if not PM.UI.TerminalPanel then
            PM.createTerminalPanel()
        end
        -- Keybind only opens, never closes (like Mono's bar)
        if PM.UI.TerminalPanel.Visible then return end
        
        -- Set flag to prevent immediate close
        PM.panelJustOpened = true
        task.delay(0.1, function()
            PM.panelJustOpened = false
        end)
        
        PM.isTerminalOpen = true
        PM.UI.TerminalPanel.Visible = true
        PM.UI.TerminalPanel.Size = UDim2.new(0, 0, 0, 38)
        PM.tween(PM.UI.TerminalPanel, 0.25, {Size = UDim2.new(0, 340, 0, 38)})
        PM.UI.TerminalInput:CaptureFocus()
    end
    
    -- For button toggle (opens and closes)
    PM.toggleTerminalPanel = function()
        if not PM.UI.TerminalPanel then
            PM.createTerminalPanel()
        end
        if PM.UI.TerminalPanel.Visible then
            PM.isTerminalOpen = false
            PM.closeTerminalPanel()
        else
            -- Set flag to prevent immediate close
            PM.panelJustOpened = true
            task.delay(0.1, function()
                PM.panelJustOpened = false
            end)
            
            PM.isTerminalOpen = true
            PM.UI.TerminalPanel.Visible = true
            PM.UI.TerminalPanel.Size = UDim2.new(0, 0, 0, 38)
            PM.tween(PM.UI.TerminalPanel, 0.25, {Size = UDim2.new(0, 340, 0, 38)})
            PM.UI.TerminalInput:CaptureFocus()
        end
    end
    
    PM.closeTerminalPanel = function()
        if not PM.UI.TerminalPanel or not PM.UI.TerminalPanel.Visible then return end
        
        PM.UI.TerminalInput:ReleaseFocus()
        PM.UI.TerminalInput.Text = ""
        PM.UI.TerminalAutofill.Text = ""
        PM.tween(PM.UI.TerminalPanel, 0.25, {Size = UDim2.new(0, 0, 0, 38)})
        task.delay(0.25, function()
            PM.UI.TerminalPanel.Visible = false
            PM.UI.TerminalPanel.Size = UDim2.new(0, 340, 0, 38)
        end)
    end
    
    PM.hideTerminalPanel = function()
        if not PM.UI.TerminalPanel then return end
        PM.UI.TerminalInput:ReleaseFocus()
        PM.UI.TerminalPanel.Visible = false
        PM.UI.TerminalPanel.Size = UDim2.new(0, 340, 0, 38)
    end

    PM.createCommandsPanel = function()
        if PM.UI.CommandsPanel then return end
        
        PM.UI.CommandsPanel = PM.mk("Frame", PM.UI.Gui, {
            Name = "CommandsPanel",
            Size = UDim2.new(0, 280, 0, 320),
            Position = UDim2.new(0.5, -140, 0, 35),
            BackgroundColor3 = C.bg,
            BackgroundTransparency = 0.2,
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = 100,
            ClipsDescendants = true,
        })
        PM.corner(PM.UI.CommandsPanel, 12)
        PM.stroke(PM.UI.CommandsPanel, C.border, 1, 0.4)
        
        PM.UI.CommandsTitle = PM.mk("TextLabel", PM.UI.CommandsPanel, {
            Size = UDim2.new(1, 0, 0, 36),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            Text = "Commands",
            TextColor3 = C.text,
            TextSize = 14,
            Font = Enum.Font.GothamBlack,
            TextYAlignment = Enum.TextYAlignment.Center,
            ZIndex = 101,
        })
        
        PM.UI.CommandsClose = PM.mk("TextButton", PM.UI.CommandsPanel, {
            Size = UDim2.new(0, 24, 0, 24),
            Position = UDim2.new(1, -30, 0, 6),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Text = "X",
            TextColor3 = C.text,
            TextSize = 11,
            Font = Enum.Font.GothamBold,
            ZIndex = 101,
        })
        PM.corner(PM.UI.CommandsClose, 6)
        
        PM.UI.CommandsClose.MouseEnter:Connect(function()
            PM.UI.CommandsClose.TextColor3 = Color3.fromRGB(255, 80, 80)
        end)
        PM.UI.CommandsClose.MouseLeave:Connect(function()
            PM.UI.CommandsClose.TextColor3 = C.text
        end)
        
        PM.UI.CommandsClose.MouseButton1Click:Connect(function()
            PM.playClickSound()
            PM.isCommandsOpen = false
            PM.UI.CommandsSearch.Text = ""
            PM.closeCommandsPanel()
        end)
        
        PM.UI.CommandsSearch = PM.mk("TextBox", PM.UI.CommandsPanel, {
            Name = "CommandsSearch",
            Size = UDim2.new(1, -16, 0, 28),
            Position = UDim2.new(0, 8, 0, 38),
            BackgroundColor3 = C.card,
            BackgroundTransparency = 0.5,
            BorderSizePixel = 0,
            Text = "",
            PlaceholderText = "Search commands...",
            PlaceholderColor3 = C.textDim,
            TextColor3 = C.text,
            TextSize = 12,
            Font = Enum.Font.Gotham,
            ClearTextOnFocus = true,
            ZIndex = 101,
        })
        PM.corner(PM.UI.CommandsSearch, 6)
        
        PM.UI.CommandsScroll = PM.mk("ScrollingFrame", PM.UI.CommandsPanel, {
            Size = UDim2.new(1, -10, 1, -80),
            Position = UDim2.new(0, 9, 0, 70),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = C.border,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ZIndex = 101,
        })
        
        PM.UI.CommandsList = PM.mk("UIListLayout", PM.UI.CommandsScroll, {
            Padding = UDim.new(0, 2),
            SortOrder = Enum.SortOrder.Name,
        })
        
        PM.UI.CommandsList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            PM.UI.CommandsScroll.CanvasSize = UDim2.new(0, 0, 0, PM.UI.CommandsList.AbsoluteContentSize.Y)
        end)
        
        PM.UI.CommandButtons = {}
        
        PM.UI.CommandsSearch:GetPropertyChangedSignal("Text"):Connect(function()
            local search = PM.UI.CommandsSearch.Text:lower()
            local visibleCount = 0
            for _, data in ipairs(PM.UI.CommandButtons) do
                local match = data.name:lower():find(search, 1, true) or data.desc:lower():find(search, 1, true)
                data.btn.Visible = match or search == ""
                if data.btn.Visible then visibleCount = visibleCount + 1 end
            end
            PM.UI.CommandsScroll.CanvasSize = UDim2.new(0, 0, 0, visibleCount * 38)
        end)
    end
    
    PM.openCommandsPanel = function()
        if not PM.UI.CommandsPanel then
            PM.createCommandsPanel()
        end
        if PM.UI.CommandsPanel.Visible then return end
        
        PM.UI.CommandsPanel.Visible = true
        PM.UI.CommandsPanel.Size = UDim2.new(0, 280, 0, 0)
        PM.tween(PM.UI.CommandsPanel, 0.3, {Size = UDim2.new(0, 280, 0, 320)})
    end
    
    PM.closeCommandsPanel = function()
        if not PM.UI.CommandsPanel or not PM.UI.CommandsPanel.Visible then return end
        
        PM.UI.CommandsSearch.Text = ""
        PM.tween(PM.UI.CommandsPanel, 0.3, {Size = UDim2.new(0, 280, 0, 0)})
        task.delay(0.3, function()
            PM.UI.CommandsPanel.Visible = false
            PM.UI.CommandsPanel.Size = UDim2.new(0, 280, 0, 320)
        end)
    end
    
    PM.hideCommandsPanel = function()
        if not PM.UI.CommandsPanel then return end
        PM.UI.CommandsSearch.Text = ""
        PM.UI.CommandsPanel.Visible = false
        PM.UI.CommandsPanel.Size = UDim2.new(0, 280, 0, 320)
    end

    PM.createNameTagsPanel = function()
        if PM.UI.NameTagsPanel then return end
        
        PM.UI.NameTagsPanel = PM.mk("Frame", PM.UI.Gui, {
            Name = "NameTagsPanel",
            Size = UDim2.new(0, 120, 0, 26),
            Position = UDim2.new(0.5, -60, 0, 35),
            BackgroundColor3 = C.bg,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = 100,
        })
        PM.corner(PM.UI.NameTagsPanel, 6)
        PM.stroke(PM.UI.NameTagsPanel, C.border, 1, 1)
        
        PM.UI.NameTagsLabel = PM.mk("TextLabel", PM.UI.NameTagsPanel, {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = "Nametags On",
            TextColor3 = C.text,
            TextSize = 11,
            Font = Enum.Font.GothamBlack,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextTransparency = 1,
            ZIndex = 101,
        })
    end
    
    PM.toggleNameTagsPanel = function()
        if not PM.UI.NameTagsPanel then
            PM.createNameTagsPanel()
        end
        
        -- Sync the actual nametags system with the toggle state
        PM.nametagsEnabled = PM.isNameTagsEnabled
        
        -- Handle toggle ON/OFF
        if not PM.isNameTagsEnabled then
            -- Turning OFF: restore all default nametags
            local PlayersService = game:GetService("Players")
            for uid, state in pairs(PM.defaultNametagStates) do
                local plr = PlayersService:GetPlayerByUserId(uid)
                if plr and plr.Character then
                    pcall(function()
                        local humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
                        if humanoid then
                            humanoid.DisplayDistanceType = state
                        end
                    end)
                end
            end
        else
            -- Turning ON: hide default nametags for Prism users
            local PlayersService = game:GetService("Players")
            local LP = PlayersService.LocalPlayer
            for _, plr in ipairs(PlayersService:GetPlayers()) do
                if plr ~= LP and plr.Character and PM.shouldShowTag(plr) then
                    pcall(function()
                        local humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
                        if humanoid then
                            if not PM.defaultNametagStates[plr.UserId] then
                                PM.defaultNametagStates[plr.UserId] = humanoid.DisplayDistanceType
                            end
                            humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
                        end
                    end)
                end
            end
        end
        
        if PM.isNameTagsEnabled then
            PM.UI.NameTagsLabel.Text = "Nametags On"
        else
            PM.UI.NameTagsLabel.Text = "Nametags Off"
        end
        
        if PM.fadeOutTask then
            task.cancel(PM.fadeOutTask)
        end
        
        if not PM.UI.NameTagsPanel.Visible then
            PM.UI.NameTagsPanel.Visible = true
            PM.UI.NameTagsPanel.BackgroundTransparency = 1
            PM.UI.NameTagsLabel.TextTransparency = 1
            PM.UI.NameTagsPanel.UIStroke.Transparency = 1
            
            PM.tween(PM.UI.NameTagsPanel, 0.2, {BackgroundTransparency = 0.15})
            PM.tween(PM.UI.NameTagsPanel.UIStroke, 0.2, {Transparency = 0.4})
            PM.tween(PM.UI.NameTagsLabel, 0.2, {TextTransparency = 0})
        end
        
        PM.fadeOutTask = task.delay(1.5, function()
            PM.tween(PM.UI.NameTagsLabel, 0.3, {TextTransparency = 1})
            PM.tween(PM.UI.NameTagsPanel, 0.3, {BackgroundTransparency = 1})
            PM.tween(PM.UI.NameTagsPanel.UIStroke, 0.3, {Transparency = 1})
            task.delay(0.3, function()
                PM.UI.NameTagsPanel.Visible = false
            end)
        end)
    end

    PM.createServersPanel = function()
        if PM.UI.ServersPanel then return end
        
        PM.UI.ServersPanel = PM.mk("Frame", PM.UI.Gui, {
            Name = "ServersPanel",
            Size = UDim2.new(0, 280, 0, 0),
            Position = UDim2.new(0.5, -140, 0, 35),
            BackgroundColor3 = C.bg,
            BackgroundTransparency = 0.2,
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = 100,
            ClipsDescendants = true,
        })
        PM.corner(PM.UI.ServersPanel, 12)
        PM.stroke(PM.UI.ServersPanel, C.border, 1, 0.4)
        
        PM.UI.ServersTitle = PM.mk("TextLabel", PM.UI.ServersPanel, {
            Size = UDim2.new(1, 0, 0, 36),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            Text = "Servers",
            TextColor3 = C.text,
            TextSize = 14,
            Font = Enum.Font.GothamBlack,
            TextYAlignment = Enum.TextYAlignment.Center,
            ZIndex = 101,
        })
        
        PM.UI.ServersClose = PM.mk("TextButton", PM.UI.ServersPanel, {
            Size = UDim2.new(0, 24, 0, 24),
            Position = UDim2.new(1, -30, 0, 6),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Text = "X",
            TextColor3 = C.text,
            TextSize = 11,
            Font = Enum.Font.GothamBold,
            ZIndex = 101,
        })
        PM.corner(PM.UI.ServersClose, 6)
        
        PM.UI.ServersClose.MouseEnter:Connect(function()
            PM.UI.ServersClose.TextColor3 = Color3.fromRGB(255, 80, 80)
        end)
        PM.UI.ServersClose.MouseLeave:Connect(function()
            PM.UI.ServersClose.TextColor3 = C.text
        end)
        
        PM.UI.ServersClose.MouseButton1Click:Connect(function()
            PM.playClickSound()
            PM.isServersOpen = false
            PM.closeServersPanel()
        end)
        
        PM.UI.ServersFilterFrame = PM.mk("Frame", PM.UI.ServersPanel, {
            Size = UDim2.new(1, -16, 0, 28),
            Position = UDim2.new(0, 8, 0, 38),
            BackgroundColor3 = C.card,
            BackgroundTransparency = 0.5,
            BorderSizePixel = 0,
            ZIndex = 101,
        })
        PM.corner(PM.UI.ServersFilterFrame, 6)
        
        PM.UI.ServersFilterList = PM.mk("UIListLayout", PM.UI.ServersFilterFrame, {
            Padding = UDim.new(0, 4),
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
        })
        
        -- Exclude Full Servers Background
        PM.UI.ExcludeFullBg = PM.mk("Frame", PM.UI.ServersPanel, {
            Size = UDim2.new(1, -16, 0, 26),
            Position = UDim2.new(0, 8, 0, 70),
            BackgroundColor3 = C.card,
            BackgroundTransparency = 0.5,
            BorderSizePixel = 0,
            ZIndex = 100,
        })
        PM.corner(PM.UI.ExcludeFullBg, 6)
        
        -- Exclude Full Servers Label
        PM.UI.ExcludeFullLabel = PM.mk("TextLabel", PM.UI.ServersPanel, {
            Size = UDim2.new(1, -56, 0, 20),
            Position = UDim2.new(0, 13, 0, 72),
            BackgroundTransparency = 1,
            Text = "Exclude full servers",
            TextColor3 = C.text,
            TextSize = 10,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 101,
        })
        
        -- Toggle Switch (Mono.lua style)
        PM.UI.ExcludeFullSwitch = PM.mk("Frame", PM.UI.ServersPanel, {
            Size = UDim2.new(0, 26, 0, 13),
            Position = UDim2.new(1, -39, 0, 81),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = Color3.fromRGB(50, 50, 50),
            BorderSizePixel = 0,
            ZIndex = 101,
        })
        PM.corner(PM.UI.ExcludeFullSwitch, 10)
        
        -- Toggle Circle
        PM.UI.ExcludeFullCircle = PM.mk("Frame", PM.UI.ExcludeFullSwitch, {
            Size = UDim2.new(0, 9, 0, 9),
            Position = UDim2.new(0, 2, 0.5, -4),
            BackgroundColor3 = Color3.fromRGB(235, 235, 235),
            BorderSizePixel = 0,
            ZIndex = 102,
        })
        PM.corner(PM.UI.ExcludeFullCircle, 10)
        
        -- Toggle Hit Button
        PM.UI.ExcludeFullToggle = PM.mk("TextButton", PM.UI.ExcludeFullSwitch, {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = "",
            ZIndex = 103,
        })
        
        -- Set initial visual state (ON by default with medium gray)
        PM.UI.ExcludeFullSwitch.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        PM.UI.ExcludeFullCircle.Position = UDim2.new(1, -11, 0.5, -4)
        
        PM.UI.ExcludeFullToggle.MouseButton1Click:Connect(function()
            PM.playClickSound()
            PM.excludeFullServers = not PM.excludeFullServers
            if PM.excludeFullServers then
                PM.tween(PM.UI.ExcludeFullSwitch, 0.2, {BackgroundColor3 = Color3.fromRGB(80, 80, 80)})
                PM.tween(PM.UI.ExcludeFullCircle, 0.2, {Position = UDim2.new(1, -11, 0.5, -4)})
            else
                PM.tween(PM.UI.ExcludeFullSwitch, 0.2, {BackgroundColor3 = Color3.fromRGB(50, 50, 50)})
                PM.tween(PM.UI.ExcludeFullCircle, 0.2, {Position = UDim2.new(0, 2, 0.5, -4)})
            end
            PM.serversFetched = false
            PM.fetchServers()
        end)
        
        PM.serversFilter = "most"
        PM.excludeFullServers = true
        PM.serverListData = {}
        PM.serversFetched = false
        
        local filters = {
            {name = "Most", id = "most", order = 1},
            {name = "Low Ping", id = "lowping", order = 2},
            {name = "Fewest", id = "fewest", order = 3},
        }
        
        PM.UI.ServersFilterButtons = {}
        for _, filter in ipairs(filters) do
            local btn = PM.mk("TextButton", PM.UI.ServersFilterFrame, {
                Size = UDim2.new(0, 80, 0, 24),
                BackgroundColor3 = C.bg,
                BackgroundTransparency = filter.id == "most" and 0.3 or 0.7,
                BorderSizePixel = 0,
                Text = filter.name,
                TextColor3 = C.text,
                TextSize = 9,
                Font = Enum.Font.Gotham,
                Name = filter.id,
                LayoutOrder = filter.order,
                ZIndex = 102,
            })
            PM.corner(btn, 4)
            
            btn.MouseButton1Click:Connect(function()
                PM.playClickSound()
                PM.serversFilter = filter.id
                for _, b in ipairs(PM.UI.ServersFilterButtons) do
                    PM.tween(b, 0.15, {BackgroundTransparency = b.Name == filter.id and 0.3 or 0.7})
                end
                PM.renderServerList()
            end)
            
            table.insert(PM.UI.ServersFilterButtons, btn)
        end
        
        PM.UI.ServersScroll = PM.mk("ScrollingFrame", PM.UI.ServersPanel, {
            Size = UDim2.new(1, -10, 1, -110),
            Position = UDim2.new(0, 9, 0, 100),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = C.border,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ZIndex = 101,
        })
        
        PM.UI.ServersList = PM.mk("UIListLayout", PM.UI.ServersScroll, {
            Padding = UDim.new(0, 2),
            SortOrder = Enum.SortOrder.Name,
        })
        
        PM.UI.ServersList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            PM.UI.ServersScroll.CanvasSize = UDim2.new(0, 0, 0, PM.UI.ServersList.AbsoluteContentSize.Y)
        end)
        
    end
    
    PM.fetchServers = function()
        local HttpService = game:GetService("HttpService")
        local success, result = pcall(function()
            return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
        end)
        
        if success and result and result.data then
            PM.serverListData = {}
            for _, server in ipairs(result.data) do
                if not PM.excludeFullServers or server.playing < server.maxPlayers then
                    table.insert(PM.serverListData, server)
                end
            end
            PM.serversFetched = true
            PM.renderServerList()
            return true
        else
            return false
        end
    end
    
    PM.renderServerList = function()
        if not PM.UI.ServersScroll then return end
        
        for _, child in ipairs(PM.UI.ServersScroll:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        
        local servers = {}
        for _, server in ipairs(PM.serverListData) do
            table.insert(servers, server)
        end
        
        if PM.serversFilter == "lowping" then
            table.sort(servers, function(a, b)
                return (a.ping or math.huge) < (b.ping or math.huge)
            end)
        elseif PM.serversFilter == "most" then
            table.sort(servers, function(a, b)
                return (a.playing or 0) > (b.playing or 0)
            end)
        elseif PM.serversFilter == "fewest" then
            table.sort(servers, function(a, b)
                return (a.playing or 0) < (b.playing or 0)
            end)
        end
        
        local displayCount = math.min(#servers, 25)
        for i = 1, displayCount do
            local server = servers[i]
            if not server then break end
            
            local ping = server.ping or 0
            local playing = server.playing or 0
            local maxPlayers = server.maxPlayers or 0
            local pingColor = ping < 50 and Color3.fromRGB(80, 220, 120) or ping < 100 and Color3.fromRGB(255, 200, 80) or Color3.fromRGB(255, 80, 80)
            
            local btn = PM.mk("TextButton", PM.UI.ServersScroll, {
                Size = UDim2.new(1, -6, 0, 32),
                BackgroundColor3 = C.card,
                BackgroundTransparency = 0.5,
                BorderSizePixel = 0,
                Text = "",
                Name = "Server_" .. i,
                ZIndex = 102,
            })
            PM.corner(btn, 6)
            
            PM.mk("TextLabel", btn, {
                Size = UDim2.new(0.4, 0, 1, 0),
                Position = UDim2.new(0, 8, 0, 0),
                BackgroundTransparency = 1,
                Text = "Ping: " .. ping .. "ms",
                TextColor3 = pingColor,
                TextSize = 10,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 103,
            })
            
            PM.mk("TextLabel", btn, {
                Size = UDim2.new(0.5, 0, 1, 0),
                Position = UDim2.new(0.5, -8, 0, 0),
                BackgroundTransparency = 1,
                Text = playing .. "/" .. maxPlayers .. " players",
                TextColor3 = C.text,
                TextSize = 10,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Right,
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
                game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, server.id, PM.Svc.Players.LocalPlayer)
            end)
        end
        
    end
    
    PM.openServersPanel = function()
        if not PM.UI.ServersPanel then
            PM.createServersPanel()
        end
        
        PM.isServersOpen = true
        PM.UI.ServersPanel.Visible = true
        PM.UI.ServersPanel.Size = UDim2.new(0, 280, 0, 0)
        PM.tween(PM.UI.ServersPanel, 0.3, {Size = UDim2.new(0, 280, 0, 320)})
        
        if not PM.serversFetched then
            task.spawn(function()
                PM.fetchServers()
            end)
        end
    end
    
    PM.closeServersPanel = function()
        if not PM.UI.ServersPanel or not PM.UI.ServersPanel.Visible then return end
        
        PM.isServersOpen = false
        PM.tween(PM.UI.ServersPanel, 0.3, {Size = UDim2.new(0, 280, 0, 0)})
        task.delay(0.3, function()
            PM.UI.ServersPanel.Visible = false
            PM.UI.ServersPanel.Size = UDim2.new(0, 280, 0, 320)
        end)
    end
    
    PM.hideServersPanel = function()
        if not PM.UI.ServersPanel then return end
        PM.isServersOpen = false
        PM.UI.ServersPanel.Visible = false
        PM.UI.ServersPanel.Size = UDim2.new(0, 280, 0, 320)
    end
    
    -- ========== JOIN PRISM USERS PANEL ==========
    PM.createJoinPanel = function()
        if PM.UI.JoinPanel then return end
        
        PM.UI.JoinPanel = PM.mk("Frame", PM.UI.Gui, {
            Name = "JoinPanel",
            Size = UDim2.new(0, 280, 0, 0),
            Position = UDim2.new(0.5, -140, 0, 35),
            BackgroundColor3 = C.bg,
            BackgroundTransparency = 0.2,
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = 100,
            ClipsDescendants = true,
        })
        PM.corner(PM.UI.JoinPanel, 12)
        PM.stroke(PM.UI.JoinPanel, C.border, 1, 0.4)
        
        -- Title
        PM.UI.JoinTitle = PM.mk("TextLabel", PM.UI.JoinPanel, {
            Size = UDim2.new(1, 0, 0, 36),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            Text = "Join Prism Users",
            TextColor3 = C.text,
            TextSize = 14,
            Font = Enum.Font.GothamBlack,
            TextYAlignment = Enum.TextYAlignment.Center,
            ZIndex = 101,
        })
        
        -- Close button
        PM.UI.JoinClose = PM.mk("TextButton", PM.UI.JoinPanel, {
            Size = UDim2.new(0, 24, 0, 24),
            Position = UDim2.new(1, -30, 0, 6),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Text = "X",
            TextColor3 = C.text,
            TextSize = 11,
            Font = Enum.Font.GothamBold,
            ZIndex = 101,
        })
        PM.corner(PM.UI.JoinClose, 6)
        
        PM.UI.JoinClose.MouseEnter:Connect(function()
            PM.UI.JoinClose.TextColor3 = Color3.fromRGB(255, 80, 80)
        end)
        PM.UI.JoinClose.MouseLeave:Connect(function()
            PM.UI.JoinClose.TextColor3 = C.text
        end)
        
        PM.UI.JoinClose.MouseButton1Click:Connect(function()
            PM.playClickSound()
            PM.isJoinOpen = false
            PM.closeJoinPanel()
        end)
        
        -- Filter buttons frame
        PM.UI.JoinFilterFrame = PM.mk("Frame", PM.UI.JoinPanel, {
            Size = UDim2.new(1, -16, 0, 28),
            Position = UDim2.new(0, 8, 0, 38),
            BackgroundColor3 = C.card,
            BackgroundTransparency = 0.5,
            BorderSizePixel = 0,
            ZIndex = 101,
        })
        PM.corner(PM.UI.JoinFilterFrame, 6)
        
        local filterList = PM.mk("UIListLayout", PM.UI.JoinFilterFrame, {
            Padding = UDim.new(0, 4),
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
        })
        
        -- Filter buttons
        PM.UI.JoinFilterButtons = {}
        local filters = {
            {name = "This Game", id = "This Game"},
            {name = "All Games", id = "All Games"},
            {name = "Friends", id = "Friends"},
        }
        for _, filter in ipairs(filters) do
            local btn = PM.mk("TextButton", PM.UI.JoinFilterFrame, {
                Name = filter.id,
                Size = UDim2.new(0, 76, 0, 24),
                BackgroundColor3 = C.bg,
                BackgroundTransparency = filter.id == "All Games" and 0.3 or 0.7,
                BorderSizePixel = 0,
                Text = filter.name,
                TextColor3 = C.text,
                TextSize = 9,
                Font = Enum.Font.Gotham,
                ZIndex = 102,
            })
            PM.corner(btn, 4)
            table.insert(PM.UI.JoinFilterButtons, btn)
        end
        
        -- Search box
        PM.UI.JoinSearch = PM.mk("TextBox", PM.UI.JoinPanel, {
            Name = "JoinSearch",
            Size = UDim2.new(1, -16, 0, 28),
            Position = UDim2.new(0, 8, 0, 70),
            BackgroundColor3 = C.card,
            BackgroundTransparency = 0.5,
            Text = "",
            PlaceholderText = "Search users...",
            TextColor3 = C.text,
            PlaceholderColor3 = Color3.fromRGB(120, 120, 120),
            TextSize = 10,
            Font = Enum.Font.Gotham,
            ClearTextOnFocus = false,
            ZIndex = 101,
        })
        PM.corner(PM.UI.JoinSearch, 6)
        
        -- User scroll frame (no refresh button, so larger)
        PM.UI.JoinScroll = PM.mk("ScrollingFrame", PM.UI.JoinPanel, {
            Name = "JoinScroll",
            Size = UDim2.new(1, -10, 1, -106),
            Position = UDim2.new(0, 9, 0, 102),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = C.border,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ZIndex = 101,
        })
        
        PM.UI.JoinList = PM.mk("UIListLayout", PM.UI.JoinScroll, {
            Padding = UDim.new(0, 2),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })
        
        PM.UI.JoinList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            PM.UI.JoinScroll.CanvasSize = UDim2.new(0, 0, 0, PM.UI.JoinList.AbsoluteContentSize.Y)
        end)
        
        -- Join panel logic
        spawn(function()
            local HttpService = game:GetService("HttpService")
            local TeleportService = game:GetService("TeleportService")
            local SERVERS_URL = "https://prismscript.vercel.app/api/prism/servers"
            local PLAYER_TTL = 35
            local currentJoinFilter = "All Games"
            local cachedUsers = {}
            
            local function fetchPrismUsers()
                local url
                if currentJoinFilter == "This Game" then
                    url = SERVERS_URL .. "/" .. tostring(game.PlaceId) .. ".json"
                else
                    url = SERVERS_URL .. "/"
                end
                
                local ok, result = pcall(function()
                    return request({
                        Url = url,
                        Method = "GET"
                    })
                end)
                
                if not ok or not result or not result.Body or result.Body == "null" then
                    return {}
                end
                
                local ok2, data = pcall(function()
                    return HttpService:JSONDecode(result.Body)
                end)
                
                if not ok2 or not data then
                    return {}
                end
                
                -- API returns { servers: { placeId: { jobId: { userId: data } } } }
                -- Unwrap the servers key if present
                local serversData = data.servers or data
                
                local users = {}
                local now = os.time()
                local PlayersService = game:GetService("Players")
                local LocalPlayer = PlayersService.LocalPlayer
                
                if currentJoinFilter == "This Game" then
                    -- Data structure: { servers: { placeId: { jobId: { userId: data } } } }
                    local placeData = serversData[tostring(game.PlaceId)] or serversData[game.PlaceId]
                    if type(placeData) == "table" then
                        for jobId, jobData in pairs(placeData) do
                            if type(jobData) == "table" then
                                for userIdStr, userInfo in pairs(jobData) do
                                    local userId = tonumber(userIdStr)
                                    if userId and userId ~= LocalPlayer.UserId and type(userInfo) == "table" then
                                        local timestamp = tonumber(userInfo.timestamp) or 0
                                        local age = now - timestamp
                                        if age <= PLAYER_TTL then
                                            table.insert(users, {
                                                userId = userId,
                                                username = userInfo.username or "Unknown",
                                                displayName = userInfo.displayName or userInfo.username or "Unknown",
                                                gameName = userInfo.gameName or "Unknown",
                                                placeId = game.PlaceId,
                                                jobId = jobId,
                                                timestamp = userInfo.timestamp
                                            })
                                        end
                                    end
                                end
                            end
                        end
                    end
                else
                    for placeIdStr, placeData in pairs(serversData) do
                        if type(placeData) == "table" then
                            for jobId, jobData in pairs(placeData) do
                                if type(jobData) == "table" then
                                    for userIdStr, userInfo in pairs(jobData) do
                                        local userId = tonumber(userIdStr)
                                        local placeId = tonumber(placeIdStr)
                                        if userId and userId ~= LocalPlayer.UserId and placeId and type(userInfo) == "table" then
                                            local age = now - (tonumber(userInfo.timestamp) or 0)
                                            if age <= PLAYER_TTL then
                                                table.insert(users, {
                                                    userId = userId,
                                                    username = userInfo.username or "Unknown",
                                                    displayName = userInfo.displayName or userInfo.username or "Unknown",
                                                    gameName = userInfo.gameName or "Unknown",
                                                    placeId = placeId,
                                                    jobId = jobId,
                                                    timestamp = userInfo.timestamp
                                                })
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                
                if currentJoinFilter == "Friends" then
                    local friendsOnly = {}
                    for _, user in ipairs(users) do
                        local success, isFriend = pcall(function()
                            return LocalPlayer:IsFriendsWith(user.userId)
                        end)
                        if success and isFriend then
                            table.insert(friendsOnly, user)
                        end
                    end
                    users = friendsOnly
                end
                
                table.sort(users, function(a, b)
                    return (a.username or ""):lower() < (b.username or ""):lower()
                end)
                
                return users
            end
            
            local function renderUsers(users, searchQuery)
                local scroll = PM.UI.JoinScroll
                if not scroll then return end
                
                for _, child in ipairs(scroll:GetChildren()) do
                    if child:IsA("Frame") or child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("ImageLabel") then
                        child:Destroy()
                    end
                end
                
                local filtered = {}
                if searchQuery and searchQuery ~= "" then
                    local q = searchQuery:lower()
                    for _, user in ipairs(users) do
                        local name = (user.username or ""):lower()
                        local display = (user.displayName or ""):lower()
                        if name:find(q, 1, true) or display:find(q, 1, true) then
                            table.insert(filtered, user)
                        end
                    end
                else
                    filtered = users
                end
                
                for _, user in ipairs(filtered) do
                    local isCurrentServer = (user.placeId == game.PlaceId and user.jobId == game.JobId)
                    local isCurrentGame = (user.placeId == game.PlaceId)
                    
                    local item = PM.mk("TextButton", scroll, {
                        Name = "UserItem_" .. user.userId,
                        Size = UDim2.new(1, -6, 0, 46),
                        BackgroundColor3 = C.card,
                        BackgroundTransparency = 0.5,
                        BorderSizePixel = 0,
                        Text = "",
                        AutoButtonColor = false,
                    })
                    PM.corner(item, 6)
                    
                    -- Avatar
                    local avatar = PM.mk("ImageLabel", item, {
                        Name = "Avatar",
                        Size = UDim2.new(0, 32, 0, 32),
                        Position = UDim2.new(0, 8, 0.5, -16),
                        BackgroundColor3 = Color3.fromRGB(50, 50, 50),
                        Image = "rbxthumb://type=AvatarHeadShot&id=" .. user.userId .. "&w=48&h=48",
                        ScaleType = Enum.ScaleType.Crop,
                    })
                    PM.corner(avatar, 16)
                    
                    -- Username
                    local nameLabel = PM.mk("TextLabel", item, {
                        Size = UDim2.new(1, -110, 0, 14),
                        Position = UDim2.new(0, 48, 0, 5),
                        BackgroundTransparency = 1,
                        Text = "@" .. user.username,
                        TextColor3 = C.text,
                        TextSize = 11,
                        Font = Enum.Font.GothamBold,
                        TextXAlignment = Enum.TextXAlignment.Left,
                    })
                    
                    -- Game info
                    local infoLabel = PM.mk("TextLabel", item, {
                        Size = UDim2.new(1, -110, 0, 12),
                        Position = UDim2.new(0, 48, 0, 20),
                        BackgroundTransparency = 1,
                        Text = user.gameName or "Unknown",
                        TextColor3 = isCurrentServer and Color3.fromRGB(140, 200, 140) or (isCurrentGame and Color3.fromRGB(180, 180, 200) or Color3.fromRGB(140, 140, 140)),
                        TextSize = 9,
                        Font = Enum.Font.Gotham,
                        TextXAlignment = Enum.TextXAlignment.Left,
                    })
                    
                    -- Join button (shown as indicator, not clickable on item)
                    local joinIndicator = PM.mk("TextLabel", item, {
                        Name = "JoinIndicator",
                        Size = UDim2.new(0, 50, 0, 20),
                        Position = UDim2.new(1, -58, 0.5, 0),
                        AnchorPoint = Vector2.new(0, 0.5),
                        BackgroundColor3 = isCurrentServer and Color3.fromRGB(60, 60, 60) or Color3.fromRGB(200, 200, 200),
                        BackgroundTransparency = 0,
                        Text = isCurrentServer and "Current" or "Join",
                        TextColor3 = isCurrentServer and Color3.fromRGB(140, 140, 140) or Color3.fromRGB(0, 0, 0),
                        TextSize = 9,
                        Font = Enum.Font.GothamBold,
                    })
                    PM.corner(joinIndicator, 4)
                    
                    if not isCurrentServer then
                        item.MouseEnter:Connect(function()
                            item.BackgroundTransparency = 0.3
                        end)
                        item.MouseLeave:Connect(function()
                            item.BackgroundTransparency = 0.5
                        end)
                        item.MouseButton1Click:Connect(function()
                            PM.playClickSound()
                            TeleportService:TeleportToPlaceInstance(user.placeId, user.jobId, LocalPlayer)
                        end)
                    else
                        item.Active = false
                    end
                end
            end
            
            PM.refreshJoinUsers = function()
                cachedUsers = fetchPrismUsers()
                renderUsers(cachedUsers, PM.UI.JoinSearch and PM.UI.JoinSearch.Text or "")
            end
            
            local function setFilterActive(filterName)
                currentJoinFilter = filterName
                for _, btn in ipairs(PM.UI.JoinFilterButtons) do
                    PM.tween(btn, 0.15, {BackgroundTransparency = btn.Name == filterName and 0.3 or 0.7})
                end
                PM.refreshJoinUsers()
            end
            
            -- Filter button connections
            local filterFrame = PM.UI.JoinFilterFrame
            if filterFrame then
                for _, child in ipairs(filterFrame:GetChildren()) do
                    if child:IsA("TextButton") then
                        child.MouseButton1Click:Connect(function()
                            PM.playClickSound()
                            setFilterActive(child.Name)
                        end)
                    end
                end
            end
            
            -- Search connection
            if PM.UI.JoinSearch then
                PM.UI.JoinSearch:GetPropertyChangedSignal("Text"):Connect(function()
                    renderUsers(cachedUsers, PM.UI.JoinSearch.Text)
                end)
            end
            
            -- Initial filter
            setFilterActive("All Games")
        end)
    end
    
    PM.openJoinPanel = function()
        if not PM.UI.JoinPanel then
            PM.createJoinPanel()
        end
        
        PM.isJoinOpen = true
        PM.UI.JoinPanel.Visible = true
        PM.UI.JoinPanel.Size = UDim2.new(0, 280, 0, 0)
        PM.tween(PM.UI.JoinPanel, 0.3, {Size = UDim2.new(0, 280, 0, 320)})
        
        -- Refresh users when opening
        if PM.refreshJoinUsers then
            PM.refreshJoinUsers()
        end
    end
    
    PM.closeJoinPanel = function()
        if not PM.UI.JoinPanel or not PM.UI.JoinPanel.Visible then return end
        
        PM.isJoinOpen = false
        PM.tween(PM.UI.JoinPanel, 0.3, {Size = UDim2.new(0, 280, 0, 0)})
        task.delay(0.3, function()
            PM.UI.JoinPanel.Visible = false
            PM.UI.JoinPanel.Size = UDim2.new(0, 280, 0, 320)
        end)
    end
    
    PM.hideJoinPanel = function()
        if not PM.UI.JoinPanel then return end
        PM.isJoinOpen = false
        PM.UI.JoinPanel.Visible = false
        PM.UI.JoinPanel.Size = UDim2.new(0, 280, 0, 320)
    end

    PM.createSettingsPanel = function()
        if PM.UI.SettingsPanel then return end

        PM.UI.SettingsPanel = PM.mk("Frame", PM.UI.Gui, {
            Name = "SettingsPanel",
            Size = UDim2.new(0, 280, 0, 320),
            Position = UDim2.new(0.5, -140, 0, 35),
            BackgroundColor3 = C.bg,
            BackgroundTransparency = 0.2,
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = 100,
            ClipsDescendants = true,
        })
        PM.corner(PM.UI.SettingsPanel, 12)
        PM.stroke(PM.UI.SettingsPanel, C.border, 1, 0.4)

        PM.UI.SettingsTitle = PM.mk("TextLabel", PM.UI.SettingsPanel, {
            Size = UDim2.new(1, 0, 0, 36),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            Text = "Settings",
            TextColor3 = C.text,
            TextSize = 14,
            Font = Enum.Font.GothamBlack,
            TextYAlignment = Enum.TextYAlignment.Center,
            ZIndex = 101,
        })

        PM.UI.SettingsClose = PM.mk("TextButton", PM.UI.SettingsPanel, {
            Size = UDim2.new(0, 24, 0, 24),
            Position = UDim2.new(1, -30, 0, 6),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Text = "X",
            TextColor3 = C.text,
            TextSize = 11,
            Font = Enum.Font.GothamBold,
            ZIndex = 101,
        })
        PM.corner(PM.UI.SettingsClose, 6)

        PM.UI.SettingsClose.MouseEnter:Connect(function()
            PM.UI.SettingsClose.TextColor3 = Color3.fromRGB(255, 80, 80)
        end)
        PM.UI.SettingsClose.MouseLeave:Connect(function()
            PM.UI.SettingsClose.TextColor3 = C.text
        end)

        PM.UI.SettingsClose.MouseButton1Click:Connect(function()
            PM.playClickSound()
            PM.isSettingsOpen = false
            PM.closeSettingsPanel()
        end)

        PM.UI.SettingsButtonContainer = PM.mk("Frame", PM.UI.SettingsPanel, {
            Name = "ButtonContainer",
            Size = UDim2.new(1, -16, 0, 28),
            Position = UDim2.new(0, 8, 0, 38),
            BackgroundColor3 = C.card,
            BackgroundTransparency = 0.5,
            BorderSizePixel = 0,
            ZIndex = 101,
        })
        PM.corner(PM.UI.SettingsButtonContainer, 6)

        PM.mk("UIListLayout", PM.UI.SettingsButtonContainer, {
            Padding = UDim.new(0, 4),
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
        })

        local function makeTabBtn(name, text, layout, isActive)
            local btn = PM.mk("TextButton", PM.UI.SettingsButtonContainer, {
                Name = name,
                Size = UDim2.new(0.5, -6, 1, -6),
                BackgroundColor3 = C.bg,
                BackgroundTransparency = isActive and 0.3 or 0.7,
                BorderSizePixel = 0,
                Text = text,
                TextColor3 = C.text,
                TextSize = 9,
                Font = Enum.Font.Gotham,
                AutoButtonColor = false,
                LayoutOrder = layout,
                ZIndex = 102,
            })
            PM.corner(btn, 4)

            btn.MouseEnter:Connect(function()
                if PM.activeSettingsTab ~= btn then
                    PM.tween(btn, 0.15, {BackgroundTransparency = 0.5})
                end
            end)
            btn.MouseLeave:Connect(function()
                if PM.activeSettingsTab ~= btn then
                    PM.tween(btn, 0.15, {BackgroundTransparency = 0.7})
                end
            end)

            return btn
        end

        PM.UI.SettingsTabAutoExec = makeTabBtn("AutoExecBtn", "Auto Execute", 1, true)
        PM.UI.SettingsTabSound = makeTabBtn("SoundBtn", "Sound", 2, false)
        PM.activeSettingsTab = PM.UI.SettingsTabAutoExec

        local function setActiveTab(activeBtn)
            PM.activeSettingsTab = activeBtn
            for _, btn in ipairs({PM.UI.SettingsTabAutoExec, PM.UI.SettingsTabSound}) do
                PM.tween(btn, 0.15, {BackgroundTransparency = 0.7})
            end
            PM.tween(activeBtn, 0.15, {BackgroundTransparency = 0.3})
            if PM.UI.AutoExecContent then
                PM.UI.AutoExecContent.Visible = (activeBtn == PM.UI.SettingsTabAutoExec)
            end
            if PM.UI.SoundContent then
                PM.UI.SoundContent.Visible = (activeBtn == PM.UI.SettingsTabSound)
            end
        end

        PM.UI.SettingsTabAutoExec.MouseButton1Click:Connect(function()
            PM.playClickSound()
            setActiveTab(PM.UI.SettingsTabAutoExec)
        end)
        PM.UI.SettingsTabSound.MouseButton1Click:Connect(function()
            PM.playClickSound()
            setActiveTab(PM.UI.SettingsTabSound)
        end)

        PM.UI.AutoExecContent = PM.mk("Frame", PM.UI.SettingsPanel, {
            Name = "AutoExecContent",
            Size = UDim2.new(1, 0, 0, 240),
            Position = UDim2.new(0, 0, 0, 70),
            BackgroundTransparency = 1,
            ZIndex = 101,
        })

        local function createToggleRow(parent, name, labelText, yPos, defaultState, onToggle)
            local bg = PM.mk("Frame", parent, {
                Name = name .. "Bg",
                Size = UDim2.new(1, -16, 0, 26),
                Position = UDim2.new(0, 8, 0, yPos),
                BackgroundColor3 = C.card,
                BackgroundTransparency = 0.5,
                BorderSizePixel = 0,
                ZIndex = 102,
            })
            PM.corner(bg, 6)

            PM.mk("TextLabel", bg, {
                Size = UDim2.new(1, -56, 0, 20),
                Position = UDim2.new(0, 8, 0, 3),
                BackgroundTransparency = 1,
                Text = labelText,
                TextColor3 = C.text,
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

            return bg
        end

        -- Save settings to file (settings already loaded at top of script)
        local function saveSettings()
            if not writefile then return end
            pcall(function()
                if not isfolder("prism") then
                    makefolder("prism")
                end
                local settings = {
                    autoExecutePrism = PM.autoExecutePrism,
                    autoExecuteCommands = PM.autoExecuteCommands,
                    terminalKeybind = PM.terminalKeybind,
                }
                writefile("prism/prism_settings.json", game:GetService("HttpService"):JSONEncode(settings))
            end)
        end
        
        -- Initialize with loaded or default values (loaded at top of script)
        local autoExecPrismDefault = PM.autoExecutePrism or false
        local autoExecCommandsDefault = PM.autoExecuteCommands ~= false
        PM.terminalKeybind = PM.terminalKeybind or "F6"
        
        PM.autoExecutePrism = autoExecPrismDefault
        PM.autoExecuteCommands = autoExecCommandsDefault

        createToggleRow(PM.UI.AutoExecContent, "AutoExecPrism", "Auto execute prism", 0, autoExecPrismDefault, function(state)
            PM.autoExecutePrism = state
            saveSettings()
            -- Setup/clear auto execute on teleport when toggle changes
            local queueTeleport = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport) or (krnl and krnl.queue_on_teleport)
            if queueTeleport and state then
                pcall(function()
                    queueTeleport([[loadstring(game:HttpGet("https://prismscript.vercel.app/Prism.lua"))()]])
                end)
            end
        end)

        createToggleRow(PM.UI.AutoExecContent, "AutoExecuteCommands", "Auto execute commands", 28, autoExecCommandsDefault, function(state)
            PM.autoExecuteCommands = state
            saveSettings()
        end)

        PM.UI.AutoExecSearch = PM.mk("TextBox", PM.UI.AutoExecContent, {
            Name = "AutoExecSearch",
            Size = UDim2.new(1, -16, 0, 28),
            Position = UDim2.new(0, 8, 0, 56),
            BackgroundColor3 = C.card,
            BackgroundTransparency = 0.5,
            BorderSizePixel = 0,
            Text = "",
            PlaceholderText = "Search commands...",
            PlaceholderColor3 = C.textDim,
            TextColor3 = C.text,
            TextSize = 12,
            Font = Enum.Font.Gotham,
            ClearTextOnFocus = true,
            ZIndex = 102,
        })
        PM.corner(PM.UI.AutoExecSearch, 6)

        PM.UI.AutoExecScroll = PM.mk("ScrollingFrame", PM.UI.AutoExecContent, {
            Name = "AutoExecScroll",
            Size = UDim2.new(1, -10, 1, -88),
            Position = UDim2.new(0, 9, 0, 88),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = C.border,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ZIndex = 102,
        })

        PM.UI.AutoExecList = PM.mk("UIListLayout", PM.UI.AutoExecScroll, {
            Padding = UDim.new(0, 2),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })

        PM.UI.AutoExecList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            PM.UI.AutoExecScroll.CanvasSize = UDim2.new(0, 0, 0, PM.UI.AutoExecList.AbsoluteContentSize.Y)
        end)

        -- ========== SOUND CONTENT ==========
        PM.UI.SoundContent = PM.mk("Frame", PM.UI.SettingsPanel, {
            Name = "SoundContent",
            Size = UDim2.new(1, 0, 0, 240),
            Position = UDim2.new(0, 0, 0, 70),
            BackgroundTransparency = 1,
            Visible = false,
            ZIndex = 101,
        })

        PM.UI.SoundScroll = PM.mk("ScrollingFrame", PM.UI.SoundContent, {
            Name = "SoundScroll",
            Size = UDim2.new(1, -10, 1, 0),
            Position = UDim2.new(0, 9, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = C.border,
            CanvasSize = UDim2.new(0, 0, 0, 266),
            ZIndex = 102,
        })

        local function makeSectionLabel(parent, text, yPos)
            PM.mk("TextLabel", parent, {
                Size = UDim2.new(1, -16, 0, 14),
                Position = UDim2.new(0, 8, 0, yPos),
                BackgroundTransparency = 1,
                Text = text,
                TextColor3 = C.textDim,
                TextSize = 9,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 103,
            })
        end

        local function makeSliderRow(parent, name, labelText, yPos, defaultValue, onChange)
            local bg = PM.mk("Frame", parent, {
                Name = name .. "Bg",
                Size = UDim2.new(1, -16, 0, 38),
                Position = UDim2.new(0, 8, 0, yPos),
                BackgroundColor3 = C.card,
                BackgroundTransparency = 0.5,
                BorderSizePixel = 0,
                ZIndex = 103,
            })
            PM.corner(bg, 6)

            PM.mk("TextLabel", bg, {
                Size = UDim2.new(1, -80, 0, 16),
                Position = UDim2.new(0, 8, 0, 4),
                BackgroundTransparency = 1,
                Text = labelText,
                TextColor3 = C.text,
                TextSize = 10,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 104,
            })

            local valueLabel = PM.mk("TextLabel", bg, {
                Name = "ValueLabel",
                Size = UDim2.new(0, 40, 0, 16),
                Position = UDim2.new(1, -48, 0, 4),
                BackgroundTransparency = 1,
                Text = string.format("%.2f", defaultValue),
                TextColor3 = C.textDim,
                TextSize = 9,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Right,
                ZIndex = 104,
            })

            local track = PM.mk("TextButton", bg, {
                Name = name .. "Track",
                Size = UDim2.new(1, -20, 0, 4),
                Position = UDim2.new(0, 10, 0, 26),
                BackgroundColor3 = Color3.fromRGB(30, 30, 38),
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false,
                ZIndex = 104,
            })
            PM.corner(track, 4)

            local fill = PM.mk("Frame", track, {
                Name = name .. "Fill",
                Size = UDim2.new(defaultValue, 0, 1, 0),
                BackgroundColor3 = C.text,
                BorderSizePixel = 0,
                ZIndex = 105,
            })
            PM.corner(fill, 4)

            local knob = PM.mk("Frame", track, {
                Name = name .. "Knob",
                Size = UDim2.new(0, 10, 0, 10),
                Position = UDim2.new(defaultValue, -5, 0.5, -5),
                BackgroundColor3 = C.text,
                BorderSizePixel = 0,
                ZIndex = 106,
            })
            PM.corner(knob, 6)

            local currentValue = defaultValue
            local isDragging = false

            local function updateSlider(input)
                local sliderWidth = track.AbsoluteSize.X
                local relativeX = math.clamp(input.Position.X - track.AbsolutePosition.X, 0, sliderWidth)
                local newValue = relativeX / sliderWidth
                currentValue = newValue
                fill.Size = UDim2.new(newValue, 0, 1, 0)
                knob.Position = UDim2.new(newValue, -5, 0.5, -5)
                valueLabel.Text = string.format("%.2f", newValue)
                if onChange then onChange(newValue) end
            end

            knob.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    isDragging = true
                end
            end)

            track.MouseButton1Down:Connect(function(input)
                isDragging = true
                updateSlider(input)
            end)

            game:GetService("UserInputService").InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 and isDragging then
                    isDragging = false
                end
            end)

            game:GetService("UserInputService").InputChanged:Connect(function(input)
                if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    updateSlider(input)
                end
            end)

            return bg
        end

        local function makeSoundIDRow(parent, name, labelText, yPos, defaultID, onChange)
            local bg = PM.mk("Frame", parent, {
                Name = name .. "Bg",
                Size = UDim2.new(1, -16, 0, 48),
                Position = UDim2.new(0, 8, 0, yPos),
                BackgroundColor3 = C.card,
                BackgroundTransparency = 0.5,
                BorderSizePixel = 0,
                ZIndex = 103,
            })
            PM.corner(bg, 6)

            PM.mk("TextLabel", bg, {
                Size = UDim2.new(1, -16, 0, 16),
                Position = UDim2.new(0, 8, 0, 4),
                BackgroundTransparency = 1,
                Text = labelText,
                TextColor3 = C.text,
                TextSize = 10,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 104,
            })

            local box = PM.mk("TextBox", bg, {
                Size = UDim2.new(1, -20, 0, 20),
                Position = UDim2.new(0, 10, 0, 22),
                BackgroundColor3 = C.bg,
                BackgroundTransparency = 0.3,
                BorderSizePixel = 0,
                ClearTextOnFocus = false,
                PlaceholderText = "Sound Asset ID...",
                PlaceholderColor3 = C.textDim,
                Text = defaultID,
                TextColor3 = C.text,
                TextSize = 10,
                Font = Enum.Font.Gotham,
                ZIndex = 104,
            })
            PM.corner(box, 3)

            box.FocusLost:Connect(function()
                if box.Text ~= "" and onChange then
                    onChange(box.Text)
                end
            end)

            return bg
        end

        -- CLICK SOUND section
        makeSectionLabel(PM.UI.SoundScroll, "CLICK SOUND", 0)
        createToggleRow(PM.UI.SoundScroll, "ClickSoundToggle", "Enable Click Sound", 16, PM.clickSoundEnabled, function(state)
            PM.clickSoundEnabled = state
        end)
        makeSliderRow(PM.UI.SoundScroll, "ClickVolume", "Click Volume", 44, PM.clickVolume, function(val)
            PM.clickVolume = val
            if PM.UI.ClickSound then PM.UI.ClickSound.Volume = val end
        end)
        makeSoundIDRow(PM.UI.SoundScroll, "ClickSoundID", "Click Sound ID", 84, PM.clickSoundID, function(id)
            PM.clickSoundID = id
            if PM.UI.ClickSound then PM.UI.ClickSound.SoundId = "rbxassetid://" .. id end
        end)

        -- HOVER SOUND section
        makeSectionLabel(PM.UI.SoundScroll, "HOVER SOUND", 134)
        createToggleRow(PM.UI.SoundScroll, "HoverSoundToggle", "Enable Hover Sound", 150, PM.hoverSoundEnabled, function(state)
            PM.hoverSoundEnabled = state
        end)
        makeSliderRow(PM.UI.SoundScroll, "HoverVolume", "Hover Volume", 178, PM.hoverVolume, function(val)
            PM.hoverVolume = val
            if PM.UI.HoverSound then PM.UI.HoverSound.Volume = val end
        end)
        makeSoundIDRow(PM.UI.SoundScroll, "HoverSoundID", "Hover Sound ID", 218, PM.hoverSoundID, function(id)
            PM.hoverSoundID = id
            if PM.UI.HoverSound then PM.UI.HoverSound.SoundId = "rbxassetid://" .. id end
        end)

        setActiveTab(PM.UI.SettingsTabAutoExec)
    end

    PM.openSettingsPanel = function()
        if not PM.UI.SettingsPanel then
            PM.createSettingsPanel()
        end
        PM.isSettingsOpen = true
        PM.UI.SettingsPanel.Visible = true
        PM.UI.SettingsPanel.Size = UDim2.new(0, 280, 0, 0)
        PM.tween(PM.UI.SettingsPanel, 0.3, {Size = UDim2.new(0, 280, 0, 320)})
    end

    PM.closeSettingsPanel = function()
        if not PM.UI.SettingsPanel or not PM.UI.SettingsPanel.Visible then return end
        PM.isSettingsOpen = false
        PM.tween(PM.UI.SettingsPanel, 0.3, {Size = UDim2.new(0, 280, 0, 0)})
        task.delay(0.3, function()
            PM.UI.SettingsPanel.Visible = false
            PM.UI.SettingsPanel.Size = UDim2.new(0, 280, 0, 320)
        end)
    end

    PM.hideSettingsPanel = function()
        if not PM.UI.SettingsPanel then return end
        PM.isSettingsOpen = false
        PM.UI.SettingsPanel.Visible = false
        PM.UI.SettingsPanel.Size = UDim2.new(0, 280, 0, 320)
    end

    PM.UI.LeftDivider = PM.mk("Frame", PM.UI.Main, {
        Name = "LeftDivider",
        Size = UDim2.new(0, 1, 0, 44),
        Position = UDim2.new(0, 70, 0.5, -22),
        BackgroundColor3 = C.border,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        ZIndex = 10,
    })

    PM.UI.RightDivider = PM.mk("Frame", PM.UI.Main, {
        Name = "RightDivider",
        Size = UDim2.new(0, 1, 0, 44),
        Position = UDim2.new(1, -70, 0.5, -22),
        BackgroundColor3 = C.border,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        ZIndex = 10,
    })
    
    PM.UI.RightFrame = PM.mk("Frame", PM.UI.Main, {
        Name = "RightFrame",
        Size = UDim2.new(0, 130, 0, 44),
        Position = UDim2.new(1, -136, 0.5, -22),
        BackgroundTransparency = 1,
        ZIndex = 10,
    })
    
    PM.UI.PrismLabel = PM.mk("TextLabel", PM.UI.RightFrame, {
        Name = "PrismLabel",
        Size = UDim2.new(1, -32, 0, 14),
        Position = UDim2.new(0, 25, 0, 2),
        BackgroundTransparency = 1,
        Text = "PRISM",
        TextColor3 = C.text,
        TextSize = 11,
        Font = Enum.Font.GothamBlack,
        TextXAlignment = Enum.TextXAlignment.Right,
    })

    PM.UI.ExecutorLabel = PM.mk("TextLabel", PM.UI.RightFrame, {
        Name = "ExecutorLabel",
        Size = UDim2.new(1, -32, 0, 14),
        Position = UDim2.new(0, 25, 0, 23),
        BackgroundTransparency = 1,
        Text = "Executor",
        TextColor3 = C.text,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Right,
    })
    
    PM.UI.LogoFrame = PM.mk("Frame", PM.UI.RightFrame, {
        Name = "LogoFrame",
        Size = UDim2.new(0, 26, 0, 26),
        Position = UDim2.new(1, -26, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        Rotation = 315,
    })
    
    PM.UI.LogoBg = PM.mk("ImageLabel", PM.UI.LogoFrame, {
        Name = "LogoBg",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Image = "rbxassetid://6734565426",
        ImageColor3 = C.accent,
    })
    
    local currentRotation = 315
    PM.Svc.RunService.Heartbeat:Connect(function(deltaTime)
        if PM.UI.Gui and PM.UI.Gui.Parent and PM.UI.LogoFrame then
            currentRotation = currentRotation + (120 * deltaTime)
            PM.UI.LogoFrame.Rotation = currentRotation
        end
    end)
    
    task.spawn(function()
        PM.UI.Main.Position = UDim2.new(0.5, -230, 0, -120)
        task.wait(0.2)
        PM.tween(PM.UI.Main, 0.6, {Position = UDim2.new(0.5, -230, 0, -30)})
    end)
    
    local frames = 0
    local lastT = tick()
    PM.Svc.RunService.RenderStepped:Connect(function()
        frames = frames + 1
        local now = tick()
        if now - lastT >= 1 then
            local fps = frames
            frames = 0
            lastT = now
            if PM.UI.FPSLabel then
                PM.UI.FPSLabel.Text = fps
                if fps < 30 then
                    PM.UI.FPSLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
                elseif fps < 60 then
                    PM.UI.FPSLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
                else
                    PM.UI.FPSLabel.TextColor3 = Color3.fromRGB(80, 220, 120)
                end
            end
        end
    end)
    
    task.spawn(function()
        while PM.UI.Gui and PM.UI.Gui.Parent do
            local ping = math.round(LP:GetNetworkPing() * 1000)
            if PM.UI.PingLabel then
                PM.UI.PingLabel.Text = ping
                if ping < 50 then
                    PM.UI.PingLabel.TextColor3 = Color3.fromRGB(80, 220, 120)
                elseif ping < 150 then
                    PM.UI.PingLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
                else
                    PM.UI.PingLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
                end
            end
            task.wait(2)
        end
    end)
    
    local function getExecutor()
        if syn then return "Synapse X" end
        if KRNL_LOADED then return "KRNL" end
        if getexecutorname then return getexecutorname() end
        if identifyexecutor then return identifyexecutor() end
        if delta then return "Delta" end
        if fluxus then return "Fluxus" end
        if codex then return "Codex" end
        if arceus then return "Arceus X" end
        if wave then return "Wave" end
        if trigon then return "Trigon" end
        if hydrogen then return "Hydrogen" end
        return "Unknown"
    end
    
    local execName = getExecutor()
    if PM.UI.ExecutorLabel then
        PM.UI.ExecutorLabel.Text = execName
    end
    
    -- Fetch servers on execute and auto-refresh every 5 minutes
    task.spawn(function()
        PM.fetchServers()
        while true do
            task.wait(300) -- 5 minutes
            PM.fetchServers()
        end
    end)
    
    -- NameTags System (Improved - faster check-ins, instant updates, explicit cleanup)
    spawn(function()
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local TweenService = game:GetService("TweenService")
        local HttpService = game:GetService("HttpService")
        local LP = Players.LocalPlayer
        
        -- Custom Tags Configuration
        PM.CustomTags = {
            -- Add custom tags here: [UserId] = {tagText = "Custom Name", effect = "typing" | "glitch" | "flicker", customPfp = "rbxassetid://... or data:image/..."}
            [5712636024] = {tagText = "Prism Owner", effect = "flicker", customPfp = "data:image/jpeg;base64,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"},
            [11087809132] = {tagText = "Prism Owner", effect = "flicker", customPfp = "data:image/jpeg;base64,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"},
            [2326644104] = {tagText = "Prism Co-Owner", effect = "flicker"},
        }
        
        PM.nametagsEnabled = true
        PM.nameTagBills = {}
        PM.nameTagConnections = {}
        PM.defaultNametagStates = {}
        PM.otherMonoUsers = {}
        
        -- Timing config
        local CHECKIN_INTERVAL = 3  -- seconds (faster for freshness)
        local FETCH_INTERVAL = 3     -- seconds (faster to catch new players)
        local PLAYER_TTL = 35        -- seconds (buffer above check-in)
        
        local BASE_URL = "https://prismscript.vercel.app/api/prism/nametags"
        local lastCheckIn = 0
        local lastFetch = 0
        local isCheckInPending = false
        local isFetchPending = false
        
        -- Get actual game name
        local cachedGameName = nil
        local function getGameName()
            if cachedGameName then return cachedGameName end
            local success, result = pcall(function()
                local info = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
                return info and info.Name
            end)
            if success and result then
                cachedGameName = result
                return result
            end
            return "Unknown"
        end
        
        -- Check in to database (faster, with debouncing)
        local function checkIn()
            if isCheckInPending then return end
            isCheckInPending = true
            
            pcall(function()
                local path = BASE_URL .. "/servers/" .. tostring(game.PlaceId) .. "/" .. tostring(game.JobId) .. "/" .. tostring(LP.UserId) .. ".json"
                request({
                    Url = path,
                    Method = "PUT",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = HttpService:JSONEncode({
                        username = LP.Name,
                        displayName = LP.DisplayName,
                        timestamp = os.time(),
                        jobId = tostring(game.JobId),
                        gameName = getGameName()
                    })
                })
            end)
            
            lastCheckIn = tick()
            isCheckInPending = false
        end
        
        -- Remove from database on leave (EXPLICIT CLEANUP)
        local function checkOut()
            pcall(function()
                local path = BASE_URL .. "/servers/" .. tostring(game.PlaceId) .. "/" .. tostring(game.JobId) .. "/" .. tostring(LP.UserId) .. ".json"
                request({
                    Url = path,
                    Method = "DELETE"
                })
            end)
        end
        
        local function hideDefaultNametag(char, userId)
            pcall(function()
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    if userId and not PM.defaultNametagStates[userId] then
                        PM.defaultNametagStates[userId] = humanoid.DisplayDistanceType
                    end
                    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
                end
                local head = char:FindFirstChild("Head")
                if head then
                    for _, child in ipairs(head:GetChildren()) do
                        if child:IsA("BillboardGui") then
                            child:Destroy()
                        end
                    end
                    local conn = head.ChildAdded:Connect(function(child)
                        if child:IsA("BillboardGui") then
                            child:Destroy()
                        end
                    end)
                    table.insert(PM.nameTagConnections, conn)
                end
            end)
        end
        
        -- Create Prism Tag function (must be defined before fetchOtherUsers)
        local function createPrismTag(plr, head)
            local customConfig = PM.CustomTags[plr.UserId]
            local isDatabaseUser = PM.otherMonoUsers[tostring(plr.UserId)]
            
            if not customConfig and not isDatabaseUser then
                return nil
            end
            
            -- Store original nametag state before hiding
            pcall(function()
                local humanoid = head.Parent and head.Parent:FindFirstChildOfClass("Humanoid")
                if humanoid and not PM.defaultNametagStates[plr.UserId] then
                    PM.defaultNametagStates[plr.UserId] = humanoid.DisplayDistanceType
                end
            end)
            
            -- Use custom config or default for database users
            local tagText = customConfig and customConfig.tagText or "Prism User"
            local tagEffect = customConfig and customConfig.effect or "typing"
            
            local bill = Instance.new("BillboardGui")
            bill.Name = "PrismTag_" .. plr.UserId
            bill.Active = true
            bill.AlwaysOnTop = true
            bill.ClipsDescendants = false
            bill.LightInfluence = 1
            bill.Size = UDim2.fromOffset(250, 75)
            bill.StudsOffsetWorldSpace = Vector3.new(0, 2.5, 0)
            bill.ResetOnSpawn = false
            bill.Adornee = head
            bill.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            bill.Parent = PM.UI.Gui
            
            local frame = Instance.new("Frame")
            frame.Name = "TagFrame"
            frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            frame.BackgroundTransparency = 0.1
            frame.Size = UDim2.fromScale(1, 1)
            frame.Parent = bill
            local frameCorner = Instance.new("UICorner")
            frameCorner.CornerRadius = UDim.new(0.2, 0)
            frameCorner.Parent = frame
            
            local frameBG = Instance.new("UIGradient")
            frameBG.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 60, 60)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(40, 40, 40)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 25, 25))
            })
            frameBG.Parent = frame
            
            local stroke = Instance.new("UIStroke")
            stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            stroke.Color = Color3.fromRGB(200, 200, 200)
            stroke.Thickness = 2
            stroke.Parent = frame
            local strokeGrad = Instance.new("UIGradient")
            strokeGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(180, 180, 180)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
            })
            strokeGrad.Parent = stroke
            
            local pfp = Instance.new("ImageLabel")
            pfp.Name = "Pfp"
            pfp.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            pfp.BackgroundTransparency = 0
            pfp.Position = UDim2.fromScale(0.05, 0.167)
            pfp.Size = UDim2.fromScale(0.215, 0.7)
            pfp.ZIndex = 5
            pfp.ScaleType = Enum.ScaleType.Crop
            pfp.Parent = frame
            local pfpCorner = Instance.new("UICorner")
            pfpCorner.CornerRadius = UDim.new(1, 0)
            pfpCorner.Parent = pfp
            local pfpStroke = Instance.new("UIStroke")
            pfpStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            pfpStroke.Color = Color3.fromRGB(220, 220, 220)
            pfpStroke.Thickness = 2
            pfpStroke.Parent = pfp
            
            spawn(function()
                local ok, img = pcall(function()
                    -- Check for custom profile picture first
                    if customConfig and customConfig.customPfp then
                        -- Support: rbxassetid://..., data:image/..., or allowed URL
                        return customConfig.customPfp
                    end
                    -- Fall back to default avatar thumbnail
                    return Players:GetUserThumbnailAsync(plr.UserId, Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size100x100)
                end)
                if ok and img and pfp.Parent then pfp.Image = img end
            end)
            
            local tagLbl = Instance.new("TextLabel")
            tagLbl.Name = "TagText"
            tagLbl.BackgroundTransparency = 1
            tagLbl.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json")
            tagLbl.Position = UDim2.fromScale(0.29955, 0)
            tagLbl.Size = UDim2.fromScale(0.7, 0.5)
            tagLbl.Text = tagText
            tagLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
            tagLbl.TextSize = 22
            tagLbl.TextStrokeTransparency = 0
            tagLbl.TextWrapped = true
            tagLbl.TextXAlignment = Enum.TextXAlignment.Left
            tagLbl.TextYAlignment = Enum.TextYAlignment.Bottom
            tagLbl.ZIndex = 6
            tagLbl.Parent = frame
            
            -- Text effect (only for owners with customConfig)
            if customConfig and customConfig.effect then
                local fullText = tagText
                spawn(function()
                    if customConfig.effect == "flicker" then
                        while tagLbl.Parent do
                            tagLbl.Text = fullText
                            
                            -- Slow flicker 3 times
                            for _ = 1, 3 do
                                wait(math.random(1.3, 1.5))
                                tagLbl.TextTransparency = 1
                                wait(math.random(0.5, 0.7))
                                tagLbl.TextTransparency = 0
                            end
                            
                            -- Fast flicker burst
                            local fastFlickerCount = math.random(2, 4)
                            for _ = 1, fastFlickerCount do
                                wait(math.random(0.05, 0.1))
                                tagLbl.TextTransparency = 1
                                wait(math.random(0.02, 0.05))
                                tagLbl.TextTransparency = 0
                            end
                        end
                    end
                end)
            end
            

            
            local userLbl = Instance.new("TextLabel")
            userLbl.Name = "NameText"
            userLbl.BackgroundTransparency = 1
            userLbl.FontFace = Font.new("rbxasset://fonts/families/ComicNeueAngular.json")
            userLbl.Position = UDim2.fromScale(0.29955, 0.5)
            userLbl.Size = UDim2.fromScale(0.7, 0.5)
            userLbl.Text = "@" .. plr.Name
            userLbl.TextColor3 = Color3.new(1, 1, 1)
            userLbl.TextSize = 16
            userLbl.TextStrokeTransparency = 0
            userLbl.TextWrapped = true
            userLbl.TextXAlignment = Enum.TextXAlignment.Left
            userLbl.TextYAlignment = Enum.TextYAlignment.Top
            userLbl.ZIndex = 6
            userLbl.Parent = frame
            
            -- Click-to-teleport overlay (covers entire tag, invisible)
            local clickBtn = Instance.new("TextButton")
            clickBtn.Name = "ClickToTeleport"
            clickBtn.BackgroundTransparency = 1
            clickBtn.Text = ""
            clickBtn.Size = UDim2.fromScale(1, 1)
            clickBtn.Position = UDim2.fromScale(0, 0)
            clickBtn.ZIndex = 20
            clickBtn.AutoButtonColor = false
            clickBtn.Parent = frame
            
            clickBtn.MouseButton1Click:Connect(function()
                local myChar = LP.Character
                local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
                local targetHRP = head.Parent and head.Parent:FindFirstChild("HumanoidRootPart")
                if myHRP and targetHRP then
                    myHRP.CFrame = targetHRP.CFrame + Vector3.new(0, 3, 0)
                end
            end)
            
            return bill
        end
        
        -- Fetch other users (cached, only re-fetch periodically)
        local function fetchOtherUsers(force)
            if isFetchPending and not force then return end
            if not force and (tick() - lastFetch) < FETCH_INTERVAL then return end
            
            isFetchPending = true
            
            pcall(function()
                local path = BASE_URL .. "/servers/" .. tostring(game.PlaceId) .. "/" .. tostring(game.JobId) .. ".json"
                local result = request({
                    Url = path,
                    Method = "GET"
                })
                if result and result.Body then
                    local data = HttpService:JSONDecode(result.Body)
                    PM.otherMonoUsers = data or {}
                    
                    -- Create tags for existing players now in database
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if plr ~= LP and PM.otherMonoUsers[tostring(plr.UserId)] and not PM.nameTagBills[plr.UserId] then
                            if plr.Character and plr.Character:FindFirstChild("Head") then
                                spawn(function()
                                    hideDefaultNametag(plr.Character, plr.UserId)
                                    local bill = createPrismTag(plr, plr.Character.Head)
                                    if bill then
                                        PM.nameTagBills[plr.UserId] = bill
                                    end
                                end)
                            end
                        end
                    end
                end
            end)
            
            lastFetch = tick()
            isFetchPending = false
        end
        

        
        -- Check if player should have tag
        PM.shouldShowTag = function(plr)
            return PM.CustomTags[plr.UserId] or PM.otherMonoUsers[tostring(plr.UserId)]
        end
        
        -- ========== INSTANT UPDATES ==========
        
        -- Track players who joined recently for retry logic
        local recentJoins = {}
        
        -- On player join: immediate check-in and fetch with retries
        local function onPlayerAdded(plr)
            if plr == LP then return end
            
            -- Immediate fetch when new player joins
            spawn(function()
                fetchOtherUsers(true)  -- force fetch
            end)
            
            -- Retry fetching multiple times to catch their check-in
            -- New players need time to load script and check in
            local uid = plr.UserId
            recentJoins[uid] = true
            
            spawn(function()
                for i = 1, 8 do  -- retry up to 8 times over 16 seconds
                    wait(2)  -- wait 2s between retries
                    if not recentJoins[uid] then break end  -- stop if they left
                    if PM.nameTagBills[uid] then break end  -- stop if tag already created
                    
                    fetchOtherUsers(true)
                    
                    -- Check if they're now in database and create tag
                    if PM.otherMonoUsers[tostring(uid)] and plr.Character and plr.Character:FindFirstChild("Head") then
                        hideDefaultNametag(plr.Character, uid)
                        local bill = createPrismTag(plr, plr.Character.Head)
                        if bill then
                            PM.nameTagBills[uid] = bill
                            break  -- success, stop retrying
                        end
                    end
                end
                recentJoins[uid] = nil  -- clean up retry flag
            end)
            
            plr.CharacterAdded:Connect(function(char)
                wait(0.1)
                local head = char:FindFirstChild("Head")
                if head and PM.shouldShowTag(plr) then
                    hideDefaultNametag(char, plr.UserId)
                    local bill = createPrismTag(plr, head)
                    if bill then
                        PM.nameTagBills[plr.UserId] = bill
                    end
                end
            end)
            
            if plr.Character then
                spawn(function()
                    wait(0.1)
                    local head = plr.Character and plr.Character:FindFirstChild("Head")
                    if head and PM.shouldShowTag(plr) then
                        hideDefaultNametag(plr.Character, plr.UserId)
                        local bill = createPrismTag(plr, head)
                        if bill then
                            PM.nameTagBills[plr.UserId] = bill
                        end
                    end
                end)
            end
        end
        
        -- On player leave: explicit database cleanup
        Players.PlayerRemoving:Connect(function(plr)
            local uid = plr.UserId
            
            -- Stop retrying for this player
            recentJoins[uid] = nil
            
            -- If we're leaving, remove from database
            if plr == LP then
                checkOut()
            end
            
            -- Restore nametag and cleanup
            pcall(function()
                if plr.Character then
                    local humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
                    if humanoid and PM.defaultNametagStates[uid] then
                        humanoid.DisplayDistanceType = PM.defaultNametagStates[uid]
                    end
                end
            end)
            
            if PM.nameTagBills[uid] then
                PM.nameTagBills[uid]:Destroy()
                PM.nameTagBills[uid] = nil
            end
            if PM.nameTagConnections[uid] then
                PM.nameTagConnections[uid]:Disconnect()
                PM.nameTagConnections[uid] = nil
            end
            
            PM.defaultNametagStates[uid] = nil
        end)
        
        -- ========== TIMING LOOPS ==========
        
        -- Check-in loop (5s interval)
        spawn(function()
            while PM.UI.Gui and PM.UI.Gui.Parent do
                if PM.nametagsEnabled then
                    checkIn()
                end
                wait(CHECKIN_INTERVAL)
            end
        end)
        
        -- Fetch loop (5s interval)
        spawn(function()
            while PM.UI.Gui and PM.UI.Gui.Parent do
                if PM.nametagsEnabled then
                    fetchOtherUsers(false)
                end
                wait(FETCH_INTERVAL)
            end
        end)
        
        -- ========== INITIALIZE ==========
        
        -- Immediate check-in on load
        checkIn()
        
        -- Immediate fetch on load
        fetchOtherUsers(true)
        
        -- Setup existing players
        for _, plr in ipairs(Players:GetPlayers()) do
            onPlayerAdded(plr)
        end
        Players.PlayerAdded:Connect(onPlayerAdded)
        
        -- Heartbeat: Restore default nametags for players who shouldn't have Prism tags
        -- Also create tags for recent joins who just appeared in database
        RunService.Heartbeat:Connect(function()
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LP and plr.Character then
                    local shouldShow = PM.shouldShowTag(plr)
                    local hasBillboard = PM.nameTagBills[plr.UserId] and PM.nameTagBills[plr.UserId].Parent
                    
                    -- If should show but doesn't have billboard, create it (catch late check-ins)
                    if shouldShow and not hasBillboard then
                        local head = plr.Character:FindFirstChild("Head")
                        if head then
                            spawn(function()
                                hideDefaultNametag(plr.Character, plr.UserId)
                                local bill = createPrismTag(plr, head)
                                if bill then
                                    PM.nameTagBills[plr.UserId] = bill
                                end
                            end)
                        end
                    end
                    
                    -- If shouldn't show but has billboard, destroy it and restore default
                    if not shouldShow and hasBillboard then
                        pcall(function()
                            PM.nameTagBills[plr.UserId]:Destroy()
                            PM.nameTagBills[plr.UserId] = nil
                        end)
                        pcall(function()
                            if PM.nameTagConnections[plr.UserId] then
                                PM.nameTagConnections[plr.UserId]:Disconnect()
                                PM.nameTagConnections[plr.UserId] = nil
                            end
                        end)
                        pcall(function()
                            local humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
                            if humanoid and PM.defaultNametagStates[plr.UserId] then
                                humanoid.DisplayDistanceType = PM.defaultNametagStates[plr.UserId]
                            end
                        end)
                    end
                end
            end
        end)
        
        -- Cleanup on destroy
        PM.UI.Gui.Destroying:Connect(function()
            -- Explicit checkout on destroy
            checkOut()
            
            -- Restore all default nametags
            for uid, state in pairs(PM.defaultNametagStates) do
                local plr = Players:GetPlayerByUserId(uid)
                if plr and plr.Character then
                    pcall(function()
                        local humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
                        if humanoid then
                            humanoid.DisplayDistanceType = state
                        end
                    end)
                end
            end
            
            -- Destroy all billboards
            for uid, bill in pairs(PM.nameTagBills) do
                pcall(function()
                    if bill and bill.Parent then
                        bill:Destroy()
                    end
                end)
            end
        end)
    end)
end

repeat task.wait() until LP

pcall(PM.createMainGUI)

-- Panel population is handled by Prism Commands.lua after it loads

-- Global terminal keybind handler (only opens, never closes like Mono's bar)
game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    local keybind = PM.terminalKeybind or "F6"
    if input.KeyCode.Name == keybind then
        -- Skip if panel just opened (prevents immediate close after opening)
        if PM.panelJustOpened then return end
        -- Create panel if it doesn't exist
        if not PM.UI.TerminalPanel and PM.createTerminalPanel then
            PM.createTerminalPanel()
        end
        -- Only open if not already visible (never close with keybind)
        if PM.UI.TerminalPanel and not PM.UI.TerminalPanel.Visible and PM.openTerminalPanel then
            -- Hide other panels before opening terminal (like button click does)
            if PM.isCommandsOpen then
                PM.isCommandsOpen = false
                PM.hideCommandsPanel()
            end
            if PM.isServersOpen then
                PM.isServersOpen = false
                PM.hideServersPanel()
            end
            if PM.UI.NameTagsPanel and PM.UI.NameTagsPanel.Visible then
                PM.UI.NameTagsPanel.Visible = false
            end
            if PM.isJoinOpen then
                PM.isJoinOpen = false
                PM.hideJoinPanel()
            end
            if PM.isSettingsOpen then
                PM.isSettingsOpen = false
                PM.hideSettingsPanel()
            end
            PM.openTerminalPanel()
        end
    end
end)

-- Auto execute prism on teleport (like Mono's auto load)
local queueTeleport = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport) or (krnl and krnl.queue_on_teleport)

if queueTeleport and PM.autoExecutePrism then
    pcall(function()
        queueTeleport([[loadstring(game:HttpGet("https://prismscript.vercel.app/Prism.lua"))()]])
    end)
end

return PM
