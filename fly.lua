-- HungDao9999 | Bay + Xuyên Tường + E Instant NO ANIMATION
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

if PlayerGui:FindFirstChild("HungDaoFlyGUI") then
	PlayerGui.HungDaoFlyGUI:Destroy()
	task.wait(0.3)
end

local SPEED = 500
local POINTS_GO = {
	Vector3.new(147, 3.38, -138),
	Vector3.new(2588, -0.43, -138.4),
	Vector3.new(2588.35, -0.43, -100.66)
}
local POINTS_BACK = {
	Vector3.new(2588.35, -0.43, -100.66),
	Vector3.new(2588, -0.43, -138.4),
	Vector3.new(147, 3.38, -138)
}
local arrivalThreshold = 5

local ENABLED = false
local flyConn, noclipConn, deleteVIPConn, blockUIConn, instantPickupConn

local function getChar()
	local c = player.Character or player.CharacterAdded:Wait()
	return c, c:WaitForChild("HumanoidRootPart"), c:WaitForChild("Humanoid")
end

-- XÓA CẢ Ô VIP/CAO CẤP
local function deleteVIPObjects()
	if deleteVIPConn then deleteVIPConn:Disconnect() end
	
	local function scanAndDelete()
		pcall(function()
			for _, obj in pairs(workspace:GetDescendants()) do
				if obj:IsA("BasePart") or obj:IsA("Model") or obj:IsA("MeshPart") then
					local name = obj.Name:lower()
					if name:find("vip") or name:find("premium") or 
					   name:find("cao") or name:find("cap") or
					   name:find("robux") then
						obj:Destroy()
					end
				end
				
				if obj:IsA("BillboardGui") or obj:IsA("SurfaceGui") then
					for _, child in pairs(obj:GetDescendants()) do
						if child:IsA("TextLabel") or child:IsA("TextButton") then
							local text = child.Text:lower()
							if text:find("robux") or text:find("cao") or 
							   text:find("cấp") or text:find("cap") or
							   text:find("vip") or text:find("premium") or
							   text:find("mua") or text:find("nạp") then
								if obj.Parent then
									obj.Parent:Destroy()
								else
									obj:Destroy()
								end
								break
							end
						end
					end
				end
			end
		end)
	end
	
	scanAndDelete()
	deleteVIPConn = RunService.Heartbeat:Connect(function()
		if tick() % 60 < 0.1 then
			scanAndDelete()
		end
	end)
end

-- CHẶN THÔNG BÁO MUA
local function blockPurchaseNotifications()
	if blockUIConn then blockUIConn:Disconnect() end
	
	task.spawn(function()
		while ENABLED or blockUIConn do
			pcall(function()
				for _, gui in pairs(PlayerGui:GetChildren()) do
					if gui:IsA("ScreenGui") and gui.Name ~= "HungDaoFlyGUI" then
						for _, obj in pairs(gui:GetDescendants()) do
							if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("Frame") then
								local hasText = false
								local textContent = ""
								
								if obj:IsA("TextLabel") or obj:IsA("TextButton") then
									textContent = obj.Text:lower()
									hasText = true
								end
								
								if hasText and (
									textContent:find("robux") or 
									textContent:find("cao cấp") or 
									textContent:find("cao cap") or
									textContent:find("vip") or 
									textContent:find("premium") or
									textContent:find("mua") or 
									textContent:find("nạp") or
									textContent:find("purchase") or
									textContent:find("buy")
								) then
									gui:Destroy()
									break
								end
							end
						end
					end
				end
			end)
			task.wait(0.1)
		end
	end)
end

local function enableNoclip(char)
	if noclipConn then noclipConn:Disconnect() end
	noclipConn = RunService.Stepped:Connect(function()
		if not ENABLED then return end
		for _, v in pairs(char:GetDescendants()) do
			if v:IsA("BasePart") then
				v.CanCollide = false
				v.Massless = true
			end
		end
	end)
end

local function disableNoclip(char)
	if noclipConn then 
		noclipConn:Disconnect() 
		noclipConn = nil
	end
	task.wait(0.1)
	for _, v in pairs(char:GetDescendants()) do
		if v:IsA("BasePart") then
			if v.Name == "HumanoidRootPart" then
				v.CanCollide = false
			else
				v.CanCollide = true
			end
			v.Massless = false
		end
	end
end

local function flyDirectTo(hrp, targetPos)
	if not hrp or not hrp.Parent or not ENABLED then
		return false
	end
	print("Flying to: " .. tostring(targetPos))
	local startTime = tick()
	local timeout = 120
	local completed = false
	if flyConn then flyConn:Disconnect() end
	flyConn = RunService.Heartbeat:Connect(function(dt)
		if not ENABLED or not hrp or not hrp.Parent then
			completed = false
			if flyConn then flyConn:Disconnect() end
			return
		end
		local currentPos = hrp.Position
		local direction = (targetPos - currentPos).Unit
		local distance = (targetPos - currentPos).Magnitude
		if distance <= arrivalThreshold then
			hrp.CFrame = CFrame.new(targetPos)
			completed = true
			if flyConn then flyConn:Disconnect() end
			return
		end
		if tick() - startTime > timeout then
			completed = false
			if flyConn then flyConn:Disconnect() end
			return
		end
		local moveDistance = math.min(SPEED * dt, distance)
		local newPos = currentPos + (direction * moveDistance)
		hrp.CFrame = CFrame.new(newPos)
	end)
	while not completed and ENABLED do
		if tick() - startTime > timeout then
			if flyConn then flyConn:Disconnect() end
			return false
		end
		task.wait()
	end
	return completed
end

-- ★★★ INSTANT E PICKUP - BỎ QUA ANIMATION HOÀN TOÀN ★★★
local currentPrompt = nil
local promptFired = {}

local function enableInstantEPickup()
	if instantPickupConn then instantPickupConn:Disconnect() end
	
	-- PHƯƠNG PHÁP 1: Bắt PromptShown và fire NGAY LẬP TỨC
	instantPickupConn = ProximityPromptService.PromptShown:Connect(function(prompt)
		if not ENABLED then return end
		
		task.spawn(function()
			pcall(function()
				-- Kiểm tra Robux prompt
				local suspiciousKeywords = {
					"buy", "purchase", "robux", "vip", "premium",
					"cao", "cấp", "cap", "mua", "nạp"
				}
				
				local name = prompt.Name:lower()
				local actionText = prompt.ActionText:lower()
				local objectText = prompt.ObjectText and prompt.ObjectText:lower() or ""
				
				local isRobuxPrompt = false
				for _, keyword in ipairs(suspiciousKeywords) do
					if name:find(keyword) or actionText:find(keyword) or objectText:find(keyword) then
						isRobuxPrompt = true
						break
					end
				end
				
				if isRobuxPrompt then
					-- Tắt Robux prompts
					prompt.Enabled = false
					prompt.MaxActivationDistance = 0
					task.wait(0.1)
					if prompt.Parent then
						prompt.Parent:Destroy()
					end
					return
				end
				
				-- ✅ PROMPT BÌNH THƯỜNG - FIRE NGAY KHÔNG CHỜ
				currentPrompt = prompt
				
				-- Set instant settings
				prompt.HoldDuration = 0
				prompt.MaxActivationDistance = 999
				prompt.RequiresLineOfSight = false
				
				-- FIRE NGAY LẬP TỨC - KHÔNG CHỜ ANIMATION
				fireproximityprompt(prompt, 0, true)
				
				-- Đánh dấu đã fire
				promptFired[prompt] = true
				
				-- Reset sau 1 giây
				task.delay(1, function()
					promptFired[prompt] = nil
				end)
			end)
		end)
	end)
	
	-- PHƯƠNG PHÁP 2: Quét liên tục và modify prompts
	task.spawn(function()
		while ENABLED do
			pcall(function()
				for _, obj in pairs(workspace:GetDescendants()) do
					if obj:IsA("ProximityPrompt") and obj.Enabled then
						local suspiciousKeywords = {
							"buy", "purchase", "robux", "vip", "premium",
							"cao", "cấp", "cap", "mua", "nạp"
						}
						
						local isRobuxPrompt = false
						local name = obj.Name:lower()
						local actionText = obj.ActionText:lower()
						
						for _, keyword in ipairs(suspiciousKeywords) do
							if name:find(keyword) or actionText:find(keyword) then
								isRobuxPrompt = true
								break
							end
						end
						
						if not isRobuxPrompt then
							obj.HoldDuration = 0
							obj.MaxActivationDistance = 999
							obj.RequiresLineOfSight = false
							obj.Style = Enum.ProximityPromptStyle.Custom
						else
							obj.Enabled = false
						end
					end
				end
			end)
			task.wait(0.2)
		end
	end)
	
	-- PHƯƠNG PHÁP 3: Tắt animations
	task.spawn(function()
		while ENABLED do
			pcall(function()
				local char = player.Character
				if char then
					local humanoid = char:FindFirstChild("Humanoid")
					if humanoid then
						for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
							-- Chỉ tắt animation của việc nhặt (thường có "pickup", "collect" trong tên)
							local animName = track.Animation.AnimationId:lower()
							if animName:find("pickup") or animName:find("collect") or 
							   animName:find("grab") or animName:find("take") then
								track:Stop()
							end
						end
					end
				end
			end)
			task.wait(0.05)
		end
	end)
end

local function disableInstantPickup()
	if instantPickupConn then 
		instantPickupConn:Disconnect() 
		instantPickupConn = nil
	end
	currentPrompt = nil
	promptFired = {}
end

local function stopAndCleanup()
	print("Stopping...")
	ENABLED = false
	
	if flyConn then 
		flyConn:Disconnect() 
		flyConn = nil
	end
	if deleteVIPConn then
		deleteVIPConn:Disconnect()
		deleteVIPConn = nil
	end
	if blockUIConn then
		blockUIConn:Disconnect()
		blockUIConn = nil
	end
	
	local success, char, hrp, hum = pcall(getChar)
	if not success or not char then
		print("Character not found")
		return
	end
	disableNoclip(char)
	workspace.Gravity = 196.2
	if hum then
		hum.PlatformStand = false
		hum.Sit = false
		hum:ChangeState(Enum.HumanoidStateType.Freefall)
	end
	if hrp then
		hrp.Anchored = false
		hrp.Velocity = Vector3.new(0, 0, 0)
		hrp.RotVelocity = Vector3.new(0, 0, 0)
		hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
	end
	task.wait(0.3)
	if hum then
		hum:ChangeState(Enum.HumanoidStateType.GettingUp)
		task.wait(0.2)
		hum:ChangeState(Enum.HumanoidStateType.Running)
	end
	for _, part in pairs(char:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.CanCollide = true
			part.Massless = false
			part.Velocity = Vector3.new(0, 0, 0)
			part.RotVelocity = Vector3.new(0, 0, 0)
		end
	end
	disableInstantPickup()
	print("Stopped successfully")
end

local function run(points, direction)
	local char, hrp, hum = getChar()
	enableNoclip(char)
	enableInstantEPickup()
	deleteVIPObjects()
	blockPurchaseNotifications()
	workspace.Gravity = 0
	hum:ChangeState(Enum.HumanoidStateType.Physics)
	print("Flying " .. direction .. "...")
	for i, pos in ipairs(points) do
		if not ENABLED then break end
		print("Point " .. i .. "/" .. #points)
		local success = flyDirectTo(hrp, pos)
		if not success then
			print("Failed at point " .. i)
			break
		end
		print("Reached point " .. i)
		task.wait(0.3)
	end
	if ENABLED then
		print("Completed " .. direction .. "!")
		stopAndCleanup()
	end
end

-- GUI
local gui = Instance.new("ScreenGui", PlayerGui)
gui.ResetOnSpawn = false
gui.Name = "HungDaoFlyGUI"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.fromOffset(220, 100)
frame.Position = UDim2.fromScale(0.4, 0.45)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.Active = true
frame.Draggable = true
frame.BorderSizePixel = 0

local corner = Instance.new("UICorner", frame)
corner.CornerRadius = UDim.new(0, 12)

local stroke = Instance.new("UIStroke", frame)
stroke.Color = Color3.fromRGB(255, 255, 255)
stroke.Thickness = 2

local btnGo = Instance.new("TextButton", frame)
btnGo.Size = UDim2.new(0.42, 0, 0.5, 0)
btnGo.Position = UDim2.new(0.05, 0, 0.35, 0)
btnGo.Font = Enum.Font.GothamBold
btnGo.TextSize = 18
btnGo.TextColor3 = Color3.new(1, 1, 1)
btnGo.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
btnGo.Text = "DI"
btnGo.BorderSizePixel = 0

local btnGoCorner = Instance.new("UICorner", btnGo)
btnGoCorner.CornerRadius = UDim.new(0, 8)

local btnGoStroke = Instance.new("UIStroke", btnGo)
btnGoStroke.Color = Color3.fromRGB(255, 255, 255)
btnGoStroke.Thickness = 1

local btnBack = Instance.new("TextButton", frame)
btnBack.Size = UDim2.new(0.42, 0, 0.5, 0)
btnBack.Position = UDim2.new(0.53, 0, 0.35, 0)
btnBack.Font = Enum.Font.GothamBold
btnBack.TextSize = 18
btnBack.TextColor3 = Color3.new(1, 1, 1)
btnBack.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
btnBack.Text = "VE"
btnBack.BorderSizePixel = 0

local btnBackCorner = Instance.new("UICorner", btnBack)
btnBackCorner.CornerRadius = UDim.new(0, 8)

local btnBackStroke = Instance.new("UIStroke", btnBack)
btnBackStroke.Color = Color3.fromRGB(255, 255, 255)
btnBackStroke.Thickness = 1

local label = Instance.new("TextLabel", frame)
label.Size = UDim2.new(0.9, 0, 0.2, 0)
label.Position = UDim2.new(0.05, 0, 0.05, 0)
label.Font = Enum.Font.GothamBold
label.TextSize = 14
label.TextColor3 = Color3.new(1, 1, 1)
label.BackgroundTransparency = 1
label.Text = "READY"

btnGo.MouseButton1Click:Connect(function()
	if ENABLED then
		stopAndCleanup()
		btnGo.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		btnBack.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		label.Text = "STOPPED"
		task.wait(1)
		label.Text = "READY"
		return
	end
	ENABLED = true
	btnGo.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
	btnBack.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	label.Text = "FLYING..."
	task.spawn(function()
		run(POINTS_GO, "GO")
		btnGo.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		label.Text = "DONE"
		task.wait(1)
		label.Text = "READY"
	end)
end)

btnBack.MouseButton1Click:Connect(function()
	if ENABLED then
		stopAndCleanup()
		btnGo.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		btnBack.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		label.Text = "STOPPED"
		task.wait(1)
		label.Text = "READY"
		return
	end
	ENABLED = true
	btnBack.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
	btnGo.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	label.Text = "RETURNING..."
	task.spawn(function()
		run(POINTS_BACK, "BACK")
		btnBack.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		label.Text = "DONE"
		task.wait(1)
		label.Text = "READY"
	end)
end)

player.CharacterAdded:Connect(function()
	if ENABLED then
		task.wait(1)
		stopAndCleanup()
		btnGo.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		btnBack.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		label.Text = "READY"
	end
end)

print("HungDao9999 ULTIMATE! Bấm E = Nhặt NGAY + Xóa VIP")
