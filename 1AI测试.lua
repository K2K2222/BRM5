local WindUI = {}
do
	local Player = game:GetService("Players").LocalPlayer
	local function createWindow(title)
		local gui = Instance.new("ScreenGui")
		gui.Name = "WindUI_" .. title
		gui.ResetOnSpawn = false
		gui.Parent = (Player:FindFirstChildOfClass("PlayerGui") or game:GetService("CoreGui"))
		
		local mainFrame = Instance.new("Frame")
		mainFrame.Size = UDim2.new(0, 400, 0, 300)
		mainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
		mainFrame.BackgroundColor3 = Color3.fromRGB(30,30,30)
		mainFrame.BorderSizePixel = 0
		mainFrame.Parent = gui
		
		local titleBar = Instance.new("TextLabel")
		titleBar.Size = UDim2.new(1,0,0,30)
		titleBar.BackgroundColor3 = Color3.fromRGB(20,20,20)
		titleBar.TextColor3 = Color3.fromRGB(255,255,255)
		titleBar.Text = title
		titleBar.Font = Enum.Font.SourceSansBold
		titleBar.TextSize = 16
		titleBar.BorderSizePixel = 0
		titleBar.Parent = mainFrame
		
		local tabContainer = Instance.new("Frame")
		tabContainer.Size = UDim2.new(0,100,1,-30)
		tabContainer.Position = UDim2.new(0,0,0,30)
		tabContainer.BackgroundColor3 = Color3.fromRGB(25,25,25)
		tabContainer.BorderSizePixel = 0
		tabContainer.Parent = mainFrame
		
		local contentArea = Instance.new("Frame")
		contentArea.Size = UDim2.new(1,-100,1,-30)
		contentArea.Position = UDim2.new(0,100,0,30)
		contentArea.BackgroundColor3 = Color3.fromRGB(35,35,35)
		contentArea.BorderSizePixel = 0
		contentArea.Parent = mainFrame
		
		local tabs = {}
		local currentTab = nil
		
		local function addTab(name)
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(1,0,0,30)
			btn.Position = UDim2.new(0,0,0,#tabs*30)
			btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
			btn.TextColor3 = Color3.fromRGB(200,200,200)
			btn.Text = name
			btn.Font = Enum.Font.SourceSans
			btn.TextSize = 14
			btn.BorderSizePixel = 0
			btn.Parent = tabContainer
			
			local page = Instance.new("Frame")
			page.Size = UDim2.new(1,0,1,0)
			page.BackgroundColor3 = Color3.fromRGB(35,35,35)
			page.BorderSizePixel = 0
			page.Visible = false
			page.Parent = contentArea
			
			btn.MouseButton1Click:Connect(function()
				for _, t in ipairs(tabs) do
					t.page.Visible = false
					t.btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
				end
				page.Visible = true
				btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
				currentTab = {btn = btn, page = page, name = name}
			end)
			
			local tab = {btn = btn, page = page, name = name}
			table.insert(tabs, tab)
			if #tabs == 1 then
				btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
				page.Visible = true
				currentTab = tab
			end
			return tab
		end
		
		local function addLabel(tab, text)
			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(1, -20, 0, 20)
			label.Position = UDim2.new(0,10,0,10 + #tab.page:GetChildren()*25)
			label.BackgroundTransparency = 1
			label.TextColor3 = Color3.fromRGB(255,255,255)
			label.Text = text
			label.Font = Enum.Font.SourceSans
			label.TextSize = 14
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.Parent = tab.page
			return label
		end
		
		local function addSlider(tab, text, min, max, default, callback)
			local container = Instance.new("Frame")
			container.Size = UDim2.new(1, -20, 0, 45)
			container.Position = UDim2.new(0,10,0,10 + #tab.page:GetChildren()*25)
			container.BackgroundTransparency = 1
			container.Parent = tab.page
			
			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(1,0,0,18)
			label.BackgroundTransparency = 1
			label.TextColor3 = Color3.fromRGB(255,255,255)
			label.Text = text .. ": " .. default
			label.Font = Enum.Font.SourceSans
			label.TextSize = 14
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.Parent = container
			
			local track = Instance.new("Frame")
			track.Size = UDim2.new(1,0,0,8)
			track.Position = UDim2.new(0,0,0,22)
			track.BackgroundColor3 = Color3.fromRGB(60,60,60)
			track.BorderSizePixel = 0
			track.Parent = container
			
			local fill = Instance.new("Frame")
			fill.Size = UDim2.new((default-min)/(max-min),0,1,0)
			fill.BackgroundColor3 = Color3.fromRGB(0,170,255)
			fill.BorderSizePixel = 0
			fill.Parent = track
			
			local knob = Instance.new("TextButton")
			knob.Size = UDim2.new(0,14,0,14)
			knob.Position = UDim2.new((default-min)/(max-min), -7, 0.5, -7)
			knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
			knob.BorderSizePixel = 0
			knob.Text = ""
			knob.Parent = track
			Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)
			
			local dragging = false
			local function updateFromMouse()
				local rel = math.clamp((getMouse().X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
				local val = math.floor(min + rel * (max - min) + 0.5)
				val = math.clamp(val, min, max)
				fill.Size = UDim2.new(rel,0,1,0)
				kn