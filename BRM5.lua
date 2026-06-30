--[[
    BRM5 Delta 注入器兼容版
    安卓适用，无滑块，无Drawing，纯按钮操作
]]
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local mouse = player:GetMouse()

-- 安全创建 GUI
local gui = Instance.new("ScreenGui")
gui.Name = "BRM5_Delta"
gui.ResetOnSpawn = false
pcall(function() gui.Parent = (gethui and gethui()) or CoreGui end)
if not gui.Parent then gui.Parent = CoreGui end

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 180, 0, 35)
mainFrame.Position = UDim2.new(0.5, -90, 0, 40)
mainFrame.BackgroundColor3 = Color3.fromRGB(25,25,25)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,1,0)
title.BackgroundTransparency = 1
title.Text = "BRM5 功能"
title.TextColor3 = Color3.fromRGB(255,255,255)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.Parent = mainFrame

-- 功能标签容器
local tabContainer = Instance.new("Frame")
tabContainer.Size = UDim2.new(0,180,0,25)
tabContainer.Position = UDim2.new(0,0,1,0)
tabContainer.BackgroundColor3 = Color3.fromRGB(35,35,35)
tabContainer.BorderSizePixel = 0
tabContainer.Parent = mainFrame

local content = Instance.new("Frame")
content.Size = UDim2.new(0,180,0,280)
content.Position = UDim2.new(0,0,1,25)
content.BackgroundColor3 = Color3.fromRGB(20,20,20)
content.BorderSizePixel = 0
content.ClipsDescendants = true
content.Parent = mainFrame

-- 标签按钮
local function createTabBtn(text, x)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 60, 1, 0)
    btn.Position = UDim2.new(0, x, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(200,200,200)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 12
    btn.BorderSizePixel = 0
    btn.Parent = tabContainer
    return btn
end

local function clearContent()
    for _, v in pairs(content:GetChildren()) do v:Destroy() end
end

-- 通用创建按钮
local function addButton(text, y, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,-20,0,30)
    btn.Position = UDim2.new(0,10,0,y)
    btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 12
    btn.BorderSizePixel = 0
    btn.Parent = content
    if callback then btn.MouseButton1Click:Connect(function() callback(btn) end) end
    return btn
end

-- 获取角色
local getChar = function() return player.Character end
local getHum = function() local c=getChar() return c and c:FindFirstChild("Humanoid") end
local getRoot = function() local c=getChar() return c and c:FindFirstChild("HumanoidRootPart") end

-- 状态
local state = {
    speed = 16, -- 当前速度
    fly = false,
    noclip = false,
    silentAim = false,
    autoTrigger = false,
    god = false,
    infAmmo = false,
    fastReload = false,
    dmgMul = 1,
    teleport = false,
    esp = false
}

-- 速度档位
local speedLevels = {16, 30, 50, 100, 200}
local speedIdx = 1

-- 伤害倍率档位
local dmgLevels = {1, 5, 10, 50, 100}
local dmgIdx = 1

-- 飞行速度档位
local flySpeedLevels = {20, 50, 100, 200}
local flySpeedIdx = 2
local flySpeed = 50

-- 飞行组件
local flyGyro, flyVel
local function startFly()
    local root, hum = getRoot(), getHum()
    if not root or not hum then return end
    flyGyro = Instance.new("BodyGyro")
    flyGyro.MaxTorque = Vector3.new(1,1,1)*1e9
    flyGyro.CFrame = camera.CFrame
    flyGyro.Parent = root
    flyVel = Instance.new("BodyVelocity")
    flyVel.MaxForce = Vector3.new(1,1,1)*1e9
    flyVel.Velocity = Vector3.zero
    flyVel.Parent = root
    hum.PlatformStand = true
end
local function stopFly()
    if flyGyro then flyGyro:Destroy() end
    if flyVel then flyVel:Destroy() end
    local hum = getHum()
    if hum then hum.PlatformStand = false end
end

-- 穿墙
local function setNoclip(v)
    local c = getChar()
    if not c then return end
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = not v end
    end
end

-- 无敌
local godConn
local function applyGod(v)
    local hum = getHum()
    if not hum then return end
    if v then
        hum.MaxHealth = 1e9
        hum.Health = 1e9
        hum.BreakJointsOnDeath = false
        if godConn then godConn:Disconnect() end
        godConn = hum.HealthChanged:Connect(function()
            if state.god and hum.Health < hum.MaxHealth then hum.Health = hum.MaxHealth end
        end)
    else
        hum.MaxHealth = 100
        hum.Health = 100
        hum.BreakJointsOnDeath = true
        if godConn then godConn:Disconnect() end
    end
end

-- 目标搜索
local function getNearestNPC(dist)
    local root = getRoot()
    if not root then return nil end
    local myPos = root.Position
    local nearest, shortest = nil