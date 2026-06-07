getgenv().PrismLoaded = false

getgenv().P = {
    Svc = {
        Players = game:GetService("Players"),
        TweenService = game:GetService("TweenService"),
        Lighting = game:GetService("Lighting"),
        RunService = game:GetService("RunService"),
        CoreGui = game:GetService("CoreGui"),
    },
    UI = {},
    
    -- Valid keys
    Keys = {
        "PRISM-A3G4-X7K9-M2P4",
    },
    
    -- Whitelisted UserIds
    Whitelist = {
        --5712636024,
    },
}

local LP = P.Svc.Players.LocalPlayer

P.mk = function(class, parent, props)
    local i = Instance.new(class)
    i.Parent = parent
    for k, v in pairs(props or {}) do i[k] = v end
    return i
end

P.corner = function(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = p
    return c
end

P.stroke = function(p, c, t, trans)
    local s = Instance.new("UIStroke")
    s.Color = c or Color3.fromRGB(40, 40, 40)
    s.Thickness = t or 1
    s.Transparency = trans or 0
    s.Parent = p
    return s
end

P.gradient = function(p, colors, rot)
    local g = Instance.new("UIGradient")
    g.Color = colors or ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 30, 120)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(140, 60, 180)),
    })
    g.Rotation = rot or 90
    g.Parent = p
    return g
end

P.tween = function(obj, time, props, style)
    return P.Svc.TweenService:Create(obj, TweenInfo.new(time or 0.3, style or Enum.EasingStyle.Quad), props):Play()
end

P.createKeyGUI = function()
    if P.Svc.CoreGui:FindFirstChild("PrismKeyGui") then return end
    
    local C = {
        bg = Color3.fromRGB(15, 15, 15),
        card = Color3.fromRGB(28, 28, 28),
        accent = Color3.fromRGB(180, 180, 180),
        text = Color3.fromRGB(230, 230, 230),
        textDim = Color3.fromRGB(90, 90, 90),
        border = Color3.fromRGB(45, 45, 45),
        success = Color3.fromRGB(70, 170, 70),
        error = Color3.fromRGB(170, 70, 70),
    }
    
    P.UI.Gui = P.mk("ScreenGui", P.Svc.CoreGui, {
        Name = "PrismKeyGui",
        DisplayOrder = 999,
        ResetOnSpawn = false,
    })
    
    local blur = P.mk("BlurEffect", P.Svc.Lighting, {Name = "PrismBlur", Size = 0})
    P.UI.Blur = blur
    
    P.UI.Main = P.mk("Frame", P.UI.Gui, {
        Size = UDim2.new(0, 420, 0, 56),
        Position = UDim2.new(0.5, -210, 0, -120),
        BackgroundColor3 = C.bg,
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    })
    P.corner(P.UI.Main, 14)
    P.stroke(P.UI.Main, C.border, 1, 0.4)
    
    P.mk("TextLabel", P.UI.Main, {
        Size = UDim2.new(0, 150, 0, 18),
        Position = UDim2.new(0, 16, 0, 10),
        BackgroundTransparency = 1,
        Text = "PRISM",
        TextColor3 = C.text,
        TextSize = 15,
        Font = Enum.Font.GothamBlack,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    
    P.UI.Status = P.mk("TextLabel", P.UI.Main, {
        Size = UDim2.new(0, 250, 0, 14),
        Position = UDim2.new(0, 16, 0, 30),
        BackgroundTransparency = 1,
        Text = "Initializing...",
        TextColor3 = C.text,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    
    P.UI.ProgressFrame = P.mk("Frame", P.UI.Main, {
        Size = UDim2.new(1, -20, 0, 3),
        Position = UDim2.new(0, 10, 0, 48),
        BackgroundColor3 = C.card,
        BorderSizePixel = 0,
    })
    P.corner(P.UI.ProgressFrame, 2)
    
    P.UI.Progress = P.mk("Frame", P.UI.ProgressFrame, {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = C.accent,
        BorderSizePixel = 0,
    })
    P.corner(P.UI.Progress, 2)
    
    P.UI.InputArea = P.mk("Frame", P.UI.Main, {
        Size = UDim2.new(1, -24, 0, 90),
        Position = UDim2.new(0, 12, 0, 56),
        BackgroundTransparency = 1,
        Visible = false,
    })
    
    P.UI.KeyBox = P.mk("TextBox", P.UI.InputArea, {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = C.card,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        ClearTextOnFocus = true,
        PlaceholderText = "Enter access key...",
        PlaceholderColor3 = Color3.fromRGB(70, 70, 70),
        Text = "",
        TextColor3 = C.text,
        TextSize = 12,
        Font = Enum.Font.RobotoMono,
    })
    P.corner(P.UI.KeyBox, 8)
    P.stroke(P.UI.KeyBox, C.border, 1, 0.5)
    P.mk("UIPadding", P.UI.KeyBox, {PaddingLeft = UDim.new(0, 12)})
    
    P.UI.SubmitBtn = P.mk("TextButton", P.UI.InputArea, {
        Size = UDim2.new(0.48, -4, 0, 34),
        Position = UDim2.new(0, 0, 0, 46),
        BackgroundColor3 = C.accent,
        BorderSizePixel = 0,
        Text = "VERIFY",
        TextColor3 = C.bg,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
    })
    P.corner(P.UI.SubmitBtn, 8)
    
    P.UI.GetKeyBtn = P.mk("TextButton", P.UI.InputArea, {
        Size = UDim2.new(0.48, -4, 0, 34),
        Position = UDim2.new(0.52, 4, 0, 46),
        BackgroundColor3 = C.card,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        Text = "GET KEY",
        TextColor3 = C.text,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
    })
    P.corner(P.UI.GetKeyBtn, 8)
    P.stroke(P.UI.GetKeyBtn, C.border, 1, 0.5)
    
    P.UI.HoverSound = P.mk("Sound", P.UI.Gui, {
        SoundId = "rbxassetid://107511012621133",
        Volume = 0.75,
    })
    P.UI.ClickSound = P.mk("Sound", P.UI.Gui, {
        SoundId = "rbxassetid://94859356677805",
        Volume = 0.75,
    })
    
    P.UI.SubmitBtn.MouseEnter:Connect(function()
        P.tween(P.UI.SubmitBtn, 0.15, {BackgroundColor3 = Color3.fromRGB(210, 210, 210)})
        pcall(function() P.UI.HoverSound:Play() end)
    end)
    P.UI.SubmitBtn.MouseLeave:Connect(function()
        P.tween(P.UI.SubmitBtn, 0.15, {BackgroundColor3 = C.accent})
    end)
    P.UI.SubmitBtn.MouseButton1Click:Connect(function()
        pcall(function() P.UI.ClickSound:Play() end)
    end)
    
    P.UI.GetKeyBtn.MouseEnter:Connect(function()
        P.tween(P.UI.GetKeyBtn, 0.15, {BackgroundColor3 = Color3.fromRGB(45, 45, 45)})
        pcall(function() P.UI.HoverSound:Play() end)
    end)
    P.UI.GetKeyBtn.MouseLeave:Connect(function()
        P.tween(P.UI.GetKeyBtn, 0.15, {BackgroundColor3 = C.card})
    end)
    P.UI.GetKeyBtn.MouseButton1Click:Connect(function()
        pcall(function() P.UI.ClickSound:Play() end)
        if setclipboard then
            setclipboard("https://discord.gg/QfUFaWh2cY")
            P.UI.Status.Text = " link copied!"
            P.UI.Status.TextColor3 = C.text
            task.delay(3, function()
                if P.UI.Status.Text == " link copied!" then
                    P.UI.Status.Text = "Authentication required"
                    P.UI.Status.TextColor3 = C.textDim
                end
            end)
        end
    end)
    
    local isWhitelisted = false
    for _, id in ipairs(P.Whitelist) do
        if LP.UserId == id then isWhitelisted = true break end
    end
    
    task.spawn(function()
        task.wait(0.2)
        P.tween(P.UI.Main, 0.6, {Position = UDim2.new(0.5, -210, 0, -30)})
        P.tween(blur, 0.6, {Size = 14})
        
        task.wait(0.5)
        P.tween(P.UI.Progress, 1.5, {Size = UDim2.new(0.25, 0, 1, 0)})
        task.wait(1.5)
        
        if isWhitelisted then
            P.UI.Status.Text = "Whitelisted user"
            P.UI.Status.TextColor3 = Color3.fromRGB(230, 230, 230)
            task.wait(0.5)
            P.finishKeySystem(true)
        else
            local savedKey = P.loadSavedKey()
            if savedKey and P.isValidKey(savedKey) then
                P.UI.Status.Text = "Authenticated"
                P.UI.Status.TextColor3 = Color3.fromRGB(230, 230, 230)
                task.wait(0.5)
                P.finishKeySystem(true)
            else
                P.UI.InputArea.Visible = true
                P.UI.Status.Text = "Authentication required"
                P.UI.Status.TextColor3 = C.textDim
                P.tween(P.UI.Main, 0.3, {Size = UDim2.new(0, 420, 0, 140)})
            end
        end
    end)
    
    P.UI.SubmitBtn.MouseButton1Click:Connect(P.checkKey)
    P.UI.KeyBox.FocusLost:Connect(function(enter) if enter then P.checkKey() end end)
end

P.KEY_SAVE_FILE = "prism/prism key.txt"

P.saveKey = function(key)
    if writefile then
        pcall(function()
            if makefolder and not isfolder("prism") then
                makefolder("prism")
            end
            writefile(P.KEY_SAVE_FILE, key)
        end)
    end
end

P.loadSavedKey = function()
    if readfile then
        local success, data = pcall(function()
            return readfile(P.KEY_SAVE_FILE)
        end)
        if success and data then
            return data
        end
    end
    return nil
end

P.isValidKey = function(key)
    local k = key:gsub("%s+", ""):upper()
    for _, validKey in ipairs(P.Keys) do
        if k == validKey:upper() then return true end
    end
    return false
end

P.checkKey = function()
    local C = {
        card = Color3.fromRGB(28, 28, 28),
        success = Color3.fromRGB(70, 170, 70),
        error = Color3.fromRGB(170, 70, 70),
        textDim = Color3.fromRGB(90, 90, 90),
    }
    
    local input = P.UI.KeyBox.Text:gsub("%s+", ""):upper()
    
    local valid = false
    for _, key in ipairs(P.Keys) do
        if input == key:upper() then valid = true break end
    end
    
    if valid then
        P.saveKey(input)
        P.finishKeySystem(true)
    else
        P.UI.Status.Text = "Invalid key"
        P.UI.Status.TextColor3 = C.error
    end
end

P.finishKeySystem = function(success)
    if not success then return end
    
    P.tween(P.UI.Main, 0.3, {Size = UDim2.new(0, 420, 0, 56)})
    P.UI.InputArea.Visible = false
    
    P.UI.Status.Text = "Validating..."
    P.UI.Status.TextColor3 = Color3.fromRGB(230, 230, 230)
    P.tween(P.UI.Progress, 0.5, {Size = UDim2.new(0.35, 0, 1, 0)})
    task.wait(0.5)
    
    P.UI.Status.Text = "Enjoy"
    P.UI.Status.TextColor3 = Color3.fromRGB(230, 230, 230)
    P.tween(P.UI.Progress, 1.1, {Size = UDim2.new(0.8, 0, 1, 0)})
    task.wait(1.1)
    
    P.UI.Status.Text = "Loading Prism..."
    P.UI.Status.TextColor3 = Color3.fromRGB(230, 230, 230)
    P.tween(P.UI.Progress, 0.8, {Size = UDim2.new(1, 0, 1, 0)})
    task.wait(0.8)
    
    P.UI.Status.Text = "System Loaded"
    P.UI.Status.TextColor3 = Color3.fromRGB(230, 230, 230)
    task.wait(0.5)
    
    P.tween(P.UI.Blur, 0.5, {Size = 0})
    P.tween(P.UI.Main, 0.5, {Position = UDim2.new(0.5, -210, 0, -200), BackgroundTransparency = 1})
    
    for _, child in ipairs(P.UI.Main:GetDescendants()) do
        if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
            P.tween(child, 0.3, {TextTransparency = 1})
        elseif child:IsA("Frame") then
            P.tween(child, 0.3, {BackgroundTransparency = 1})
        elseif child:IsA("UIStroke") then
            P.tween(child, 0.3, {Transparency = 1})
        end
    end
    
    task.delay(0.5, function()
        if P.UI.Gui then
            P.UI.Gui:Destroy()
            if P.UI.Blur then P.UI.Blur:Destroy() end
        end
        getgenv().PrismLoaded = true
    end)
end

repeat task.wait() until LP

local ok, err = pcall(P.createKeyGUI)
if not ok then
end

return P
