--[[
    BRM5 中文优化版 - 稳定兼容
    移除 Drawing，使用 BillboardGui 替代 ESP
--]]
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local mouse = player:GetMouse()

-- 兼容手机
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- 安全调用封装
local function safeCall(func, ...)
    local success, result = pcall(func, ...)
    return success and result or nil
end

-- UI 库（简化但功能完整）
local mainGui = Instance.new("ScreenGui")
mainGui.Name = "BRM5_GUI"
mainGui.ResetOnSpawn = false
mainGui.Parent = CoreGui
if pcall(function() syn.protect_gui(mainGui) end) then end
if pcall(function() mainGui.Parent = gethui() end) then end

-- 创建按钮的辅助函数
local function createBtn(text, parent, pos, size, callback)
    local btn = Instance.new("TextButton")
    btn.Size = size or UDim2.new(0, 200, 0, 40)
    btn.Position = pos or UDim2.new(0, 10, 0, 10)
    btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    btn.BorderSizePixel = 0
    btn.Parent = parent
    if callback then btn.MouseButton1Click:Connect(callback) end
    return btn
end

-- 创建滑块
local function createSlider(text, parent, pos, min, max, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 200, 0, 50)
    frame.Position = pos
    frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
    frame.BorderSizePixel = 0
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,0,0,20)
    label.Position = UDim2.new(0,0,0,0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255,255,255)
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.Parent = frame

    local valLabel = Instance.new("TextLabel")
    valLabel.Size = UDim2.new(0,40,0,20)
    valLabel.Position = UDim2.new(1,-40,0,0)
    valLabel.BackgroundTransparency = 1
    valLabel.Text = tostring(default)
    valLabel.TextColor3 = Color3.fromRGB(200,200,200)
    valLabel.Font = Enum.Font.Gotham
    valLabel.TextSize = 11
    valLabel.TextXAlignment = Enum.TextXAlignment.Right
    valLabel.Parent = frame

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1,-20,0,8)
    bar.Position = UDim2.new(0,10,0,26)
    bar.BackgroundColor3 = Color3.fromRGB(50,50,50)
    bar.BorderSizePixel = 0
    bar.Parent = frame

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0,0,1,0)
    fill.BackgroundColor3 = Color3.fromRGB(0,120,255)
    fill.BorderSizePixel = 0
    fill.Parent = bar

    local knob = Instance.new("TextButton")
    knob.Size = UDim2.new(0,14,0,14)
    knob.Position = UDim2.new(0,-7,0.5,-7)
    knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
    knob.Text = ""
    knob.BorderSizePixel = 0
    knob.Parent = bar

    local value = default
    local dragging = false
    local function update(input)
        local mousePos = UserInputService:GetMouseLocation()
        local barAbs = bar.AbsolutePosition
        local barSize = bar.AbsoluteSize
        local relX = math.clamp(mousePos.X - barAbs.X, 0, barSize.X)
        local percent = relX / barSize.X
        value = math.floor(min + (max - min) * percent + 0.5)
        valLabel.Text = tostring(value)
        fill.Size = UDim2.new(percent,0,1,0)
        knob.Position = UDim2.new(percent,-7,0.5,-7)
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
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            update(input)
        end
    end)
    local initPercent = (value-min)/(max-min)
    fill.Size = UDim2.new(initPercent,0,1,0)
    knob.Position = UDim2.new(initPercent,-7,0.5,-7)
end

-- 主界面
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 220, 0, 30)
mainFrame.Position = UDim2.new(0, 20, 0, 60)
mainFrame.BackgroundColor3 = Color3.fromRGB(20,20,20)
mainFrame.BorderSizePixel = 0
mainFrame.Active = not isMobile
mainFrame.Dragg