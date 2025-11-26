local plr = game.Players.LocalPlayer
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local defaultFrame = ReplicatedStorage:WaitForChild("PlayerFrame")
local templateViewport = defaultFrame:WaitForChild("ViewportFrame")
local defaultRig = templateViewport:WaitForChild("Rig") -- posed R15 dummy

local ui = script.Parent
local event = ReplicatedStorage:WaitForChild("updateSlots")

local IdleAnimation = game.ReplicatedStorage:WaitForChild("IdleAnimation")

local function playIdleOnRig(rig)
	local humanoid = rig:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local animator = humanoid.Animator
	
	local ani = animator:LoadAnimation(IdleAnimation)
	ani:Play()
	
	print("Playing Idle Ani")
end

local function applyAppearanceToRig(rig, userId)
	-- Get a temporary avatar model (can be R6, we only care about clothes/etc.)
	local success, avatarOrErr = pcall(function()
		return Players:CreateHumanoidModelFromUserId(userId)
	end)

	if not success or not avatarOrErr then
		warn("Failed to create avatar model for userId", userId, avatarOrErr)
		return
	end

	local avatar = avatarOrErr

	-- Grab clothing / colors / extras from avatar
	local shirt       = avatar:FindFirstChildOfClass("Shirt")
	local pants       = avatar:FindFirstChildOfClass("Pants")
	local tShirt      = avatar:FindFirstChildOfClass("ShirtGraphic")
	local bodyColors  = avatar:FindFirstChildOfClass("BodyColors")
	local accessories = {}
	for _, acc in ipairs(avatar:GetChildren()) do
		if acc:IsA("Accessory") then
			table.insert(accessories, acc)
		end
	end

	-- Face decal (for classic heads)
	local avatarHead = avatar:FindFirstChild("Head")
	local avatarFace = avatarHead and avatarHead:FindFirstChildOfClass("Decal")

	-- Wipe old clothing/accessories from dummy
	for _, child in ipairs(rig:GetChildren()) do
		if child:IsA("Shirt")
			or child:IsA("Pants")
			or child:IsA("ShirtGraphic")
			or child:IsA("BodyColors")
			or child:IsA("Accessory") then
			child:Destroy()
		end
	end

	local rigHead = rig:FindFirstChild("Head")
	if rigHead then
		for _, child in ipairs(rigHead:GetChildren()) do
			if child:IsA("Decal") then
				child:Destroy()
			end
		end
	end

	-- Apply onto dummy
	if shirt then
		shirt:Clone().Parent = rig
	end

	if pants then
		pants:Clone().Parent = rig
	end

	if tShirt then
		tShirt:Clone().Parent = rig
	end

	if bodyColors then
		bodyColors:Clone().Parent = rig
	end

	for _, acc in ipairs(accessories) do
		acc:Clone().Parent = rig
	end

	if avatarFace and rigHead then
		local newFace = avatarFace:Clone()
		newFace.Parent = rigHead
	end

	-- Clean up temp avatar
	avatar:Destroy()
end


-- Reorder so local player is always 'first'
local function sortOrder(list)
	local userId = plr.UserId

	-- copy input so we don't accidentally mutate the original
	local result = {
		first = list.first,
		second = list.second,
		third = list.third,
	}

	-- if we're already first, done
	if result.first == userId then
		return result
	end

	-- if we're second, swap first/second
	if result.second == userId then
		result.first, result.second = result.second, result.first
		return result
	end

	-- if we're third, rotate us to first
	if result.third == userId then
		result.first, result.second, result.third = result.third, result.first, result.second
		return result
	end

	-- if we aren't in the list for some reason, just return it as-is
	return result
end

local function createRigForUser(userId)
	-- Let Roblox build the full avatar model directly (rig + appearance)
	local success, rigOrErr = pcall(function()
		return Players:CreateHumanoidModelFromUserId(userId)
	end)

	if not success or not rigOrErr then
		warn("Failed to create humanoid model for userId", userId, rigOrErr)
		return nil
	end

	local rig = rigOrErr

	-- Ensure PrimaryPart for framing
	if not rig.PrimaryPart then
		local hrp = rig:FindFirstChild("HumanoidRootPart") or rig:FindFirstChildWhichIsA("BasePart")
		if hrp then
			rig.PrimaryPart = hrp
		end
	end

	-- Put it at the origin for now (no fancy Origin attribute yet)
	if rig.PrimaryPart then
		rig:PivotTo(CFrame.new(0, 0, 0))
	end

	return rig
end

local function setupViewport(frame, userId)
	local viewport = frame:WaitForChild("ViewportFrame")
	local rig = viewport:WaitForChild("Rig")  -- this is the cloned posed R15 dummy

	-- IMPORTANT: do NOT delete camera or rig. They’re set up in the template.
	-- Just apply appearance:
	applyAppearanceToRig(rig, userId)
	
	playIdleOnRig(rig)
end

-- Remove old slots
local function clearSlots()
	for _, child in ipairs(ui:GetChildren()) do
		if child.Name == "PlayerFrame" or child:GetAttribute("IsPlayerFrame") then
			child:Destroy()
		end
	end
end

local function createSlot(userId, index)
	if not userId then return end

	local frame = defaultFrame:Clone()
	frame.Name = "PlayerFrame" .. index
	frame:SetAttribute("IsPlayerFrame", true)
	frame.Parent = ui:WaitForChild("PlayerSpot" .. index)

	local player = Players:GetPlayerByUserId(userId)
	local nameLabel = frame:FindFirstChild("NameTag", true)
	if player and nameLabel and nameLabel:IsA("TextLabel") then
		nameLabel.Text = "lvl" .. " | " .. player.DisplayName
	end

	setupViewport(frame, userId)
end

event.OnClientEvent:Connect(function(order)
	-- re-order so local player is first
	local sorted = sortOrder(order)

	-- rebuild the frames
	clearSlots()

	createSlot(sorted.first, 1)
	createSlot(sorted.second, 2)
	createSlot(sorted.third, 3)
end)
