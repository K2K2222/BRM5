--[[
    Blackhawk Rescue Mission 5 - 手机优化 PvE 脚本 (中文界面)
    完全适配手机，含屏幕虚拟按键，无需键盘
]]

-- 服务
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local mouse = player:GetMouse()

-- 检测设备
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ==================== WindUI 全控件库 ====================
local WindUI = {}
local mainGui = Instance.new("ScreenGui")
mainGui.Name = "WindUI_Mobile"
mainGui.ResetOnSpawn = false
mainGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
if syn and syn.protect_gui then syn.protect_gui(mainGui) end
if gethui and type(gethui)=="function" then mainGui.Parent = gethui() else mainGui.Parent = CoreGui end

local function connectSliderTouch(sliderBar, knob, fill, valueLabel, minVal, maxVal, callback)
    local value = minVal
    local dragging = false
    local function update(input)
        local pos
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            pos = UserInputService:GetMouseLocation()
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
            pos = Vector2.new(input.Position.X, input.Position.Y)
        end
        if not pos then return end
        local barAbs = sliderBar.AbsolutePosition
        local barSize = sliderBar.AbsoluteSize
        local relX = math.clamp(pos.X - barAbs.X, 0, barSize.X)
        local percent = relX / barSize.X
        value = math.floor(minVal + (maxVal - minVal) * percent + 0.5)
        valueLabel.Text = tostring(value)
        fill.Size = UDim2.new(percent, 0, 1, 0)
        knob.Position = UDim2.new(percent, -7, 0.5, -7)
        callback(value)
    end
    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)
    sliderBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            update(input)
        end
    end)
    local ctrl = {}
    ctrl.SetValue = function(v)
        value = math.clamp(v, minVal, maxVal)
        local p = (value-minVal)/(maxVal-minVal)
        fill.Size = UDim2.new(p,0,1,0)
        knob.Position = UDim2.new(p,-7,0.5,-7)
        valueLabel.Text = tostring(value)
        callback(value)
    end
    return ctrl
end

function WindUI:CreateWindow(cfg)
    local win = {}
    local uiScale = isMobile and 0.8 or 1
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 300*uiScale, 0, 34*uiScale)
    mainFrame.Position = UDim2.new(0, 20, 0, isMobile and 60 or 80)
    mainFrame.BackgroundColor3 = Color3.fromRGB(18,18,18)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = not isMobile
    mainFrame.Draggable = not isMobile
    mainFrame.Parent = mainGui

    local topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(1,0,0,30*uiScale)
    topBar.BackgroundColor3 = Color3.fromRGB(25,25,25)
    topBar.BorderSizePixel = 0
    topBar.Parent = mainFrame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0,140*uiScale,1,0)
    title.Position = UDim2.new(0,8*uiScale,0,0)
    title.BackgroundTransparency = 1
    title.Text = cfg.Name or "BRM5"
    title.TextColor3 = Color3.fromRGB(255,255,255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 13*uiScale
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = topBar

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0,26*uiScale,0,26*uiScale)
    closeBtn.Position = UDim2.new(1,-30*uiScale,0,2*uiScale)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 14*uiScale
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = topBar
    closeBtn.MouseButton1Click:Connect(function() mainGui:Destroy() end)

    local tabContainer = Instance.new("Frame")
    tabContainer.Size = UDim2.new(1,0,0,28*uiScale)
    tabContainer.Pos