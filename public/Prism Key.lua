-- Key system removed - auto-auth
getgenv().PrismLoaded = true

getgenv().P = {
    Svc = {
        Players = game:GetService("Players"),
        TweenService = game:GetService("TweenService"),
        Lighting = game:GetService("Lighting"),
        RunService = game:GetService("RunService"),
        CoreGui = game:GetService("CoreGui"),
    },
    UI = {},
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

repeat task.wait() until LP

return P
