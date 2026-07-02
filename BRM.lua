local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local mouse = player:GetMouse()

local gui = Instance.new("ScreenGui")
gui.Name = "BRM5"
gui.ResetOnSpawn = false
pcall(function() gui.Parent = gethui() end)
if not gui.Parent then gui.Parent = CoreGui end
pcall(function() syn.protect_gui(gui) end)

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 200, 0, 35)
mainFrame.Position = UDim2.new(0.5, -100, 0, 50)
mainFrame.BackgroundColor3 = Color3.fromRGB(25,25,25)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,1,0)
title.BackgroundTransparency = 1
title.Text = "BRM5"
title.TextColor3 = Color3.fromRGB(255,255,255)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.Parent = mainFrame

local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1,0,0,25)
tabBar.Position = UDim2.new(0,0,1,0)
tabBar.BackgroundColor3 = Color3.fromRGB(35,35,35)
tabBar.BorderSizePixel = 0
tabBar.Parent = mainFrame

local content = Instance.new("Frame")
content.Size = UDim2.new(1,0,0,300)
content.Position = UDim2.new(0,0,1,25)
content.BackgroundColor3 = Color3.fromRGB(20,20,20)
content.BorderSizePixel = 0
content.ClipsDescendants = true
content.Parent = mainFrame

local function clearContent()
    for _, v in pairs(content:GetChildren()) do v:Destroy() end
end

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
    btn.Parent = tabBar
    return btn
end

local combatTab = createTabBtn("Combat", 0)
local moveTab = createTabBtn("Move", 60)
local visTab = createTabBtn("Visuals", 120)

local state = {
    speed = 16,
    fly = false,
    flySpeed = 50,
    noclip = false,
    god = false,
    infAmmo = false,
    fastReload = false,
    dmgMul = 1,
    silentAim = false,
    esp = false,
    teleport = false
}

local speedList = {16, 30, 50, 100, 200}
local speedIdx = 1
local dmgList = {1, 5, 10, 50, 100}
local dmgIdx = 1
local flySpdList = {20, 50, 100, 200}
local flySpdIdx = 2

local getChar = function() return player.Character end
local getHum = function() local c=getChar() return c and c:FindFirstChild("Humanoid") end
local getRoot = function() local c=getChar() return c and c:FindFirstChild("HumanoidRootPart") end

local godConn
local function setGod(v)
    local hum = getHum() if not hum then return end
    if v then
        hum.MaxHealth = 1e9; hum.Health = 1e9
        hum.BreakJointsOnDeath = false
        if godConn then godConn:Disconnect() end
        godConn = hum.HealthChanged:Connect(function()
            if state.god and hum.Health < hum.MaxHealth then hum.Health = hum.MaxHealth end
        end)
    else
        hum.MaxHealth = 100; hum.Health = 100
        hum.BreakJointsOnDeath = true
        if godConn then godConn:Disconnect() end
    end
end

local flyGyro, flyVel
local function startFly()
    local root = getRoot(); local hum = getHum()
    if not root or not hum then return end
    flyGyro = Instance.new("BodyGyro"); flyGyro.MaxTorque = Vector3.new(1,1,1)*1e9; flyGyro.CFrame = camera.CFrame; flyGyro.Parent = root
    flyVel = Instance.new("BodyVelocity"); flyVel.MaxForce = Vector3.new(1,1,1)*1e9; flyVel.Velocity = Vector3.zero; flyVel.Parent = root
    hum.PlatformStand = true
end
local function stopFly()
    if flyGyro then flyGyro:Destroy() end
    if flyVel then flyVel:Destroy() end
    local hum = getHum() if hum then hum.PlatformStand = false end
end

local function setNoclip(v)
    local c = getChar() if not c then return end
    for _, p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = not v end end
end

local function getNearestNPC(dist)
    local root = getRoot() if not root then return nil end
    local myPos = root.Position
    local nearest, shortest = nil, dist or 500
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= getChar() then