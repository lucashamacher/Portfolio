-- NOTE: ALSO FROM OLD PROJECT

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")
local userInputService = game:GetService("UserInputService")
local wallCheckDistance = 2  -- Distance for wall detection
local jumpPower = 85  -- Jump power for double jump
local maxWallJumps = 3  -- Maximum number of wall jumps allowed
local wallJumpCount = 0  -- Current number of wall jumps
local check = false

local Animations = game.ReplicatedStorage.Animations.BaseAnis
--local doubleAni = humanoid:LoadAnimation(Animations.DoubleJump)
local events = game.ReplicatedStorage.Events.Server

-- Function to handle double jumping
local function doubleJump()
	local jpSave = humanoid.JumpPower
	if humanoid.FloorMaterial == Enum.Material.Air and character:GetAttribute("canDouble") then
		--doubleAni:Play()
		humanoid.JumpPower = jumpPower
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		character:SetAttribute("canDouble", false)

		-- Reset double jump capability upon landing
		spawn(function()
			while humanoid.FloorMaterial == Enum.Material.Air do
				wait()
			end
			humanoid.JumpPower = jpSave -- Reset jump power when landing
			wait(0.2)  -- Small delay before allowing another double jump
			character:SetAttribute("canDouble", true)
		end)
	end
end

-- Function to check if the player is near a climbable wall
local function isNearWall()
	local rayOrigin = humanoidRootPart.Position
	local rayDirection = humanoidRootPart.CFrame.LookVector * wallCheckDistance
	local wallRay = Ray.new(rayOrigin, rayDirection)

	-- Raycast to detect if there's a wall
	local hitPart, hitPosition = workspace:FindPartOnRayWithIgnoreList(wallRay, {character})

	-- Ensure the hit part is not the part the player is standing on
	if hitPart and hitPart ~= humanoidRootPart then
		return true, hitPart  -- Return hitPart for further use
	end
	return false
end

-- Function to handle wall jumping
local function wallJump()
	if humanoid.FloorMaterial ~= Enum.Material.Air or wallJumpCount >= maxWallJumps then
		-- If unable to wall jump, check if double jump is available
		if wallJumpCount >= maxWallJumps and character:GetAttribute("canDouble") then
			doubleJump()
		end
		return
	end

	-- Check for wall to calculate push direction
	local nearWall, hitPart = isNearWall()
	if nearWall then
		-- Calculate push direction based on the character's facing direction
		local pushOffDirection = -humanoidRootPart.CFrame.LookVector + Vector3.new(0, 1, 0)  -- Push slightly upward and away from the wall

		-- Change the humanoid state to jumping
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)

		-- Create BodyVelocity for wall jump
		local jumpVelocity = Instance.new("BodyVelocity")
		jumpVelocity.Velocity = (pushOffDirection.unit * 60) + Vector3.new(0, 100, 0)  -- Adjusted force for better push-off
		jumpVelocity.MaxForce = Vector3.new(4000, 2000, 4000)
		jumpVelocity.Parent = humanoidRootPart

		wallJumpCount = wallJumpCount + 1  -- Increment wall jump count

		wait(0.1)  -- Time to simulate the jump
		jumpVelocity:Destroy()  -- Cleanup BodyVelocity after the jump
	end
end

-- Monitor for input for wall climbing and double jumping
userInputService.InputBegan:Connect(function(input, isProcessed)
	if isProcessed or check then return end
	if character:GetAttribute("Downed") then return end
	if input.KeyCode == Enum.KeyCode.Q then
		check = true
		task.wait(0.5)
		check = false
	end
	if input.KeyCode == Enum.KeyCode.Space then
		-- Check for wall climbing if airborne
		if humanoid.FloorMaterial == Enum.Material.Air and isNearWall() then
			events.StopSprint:FireServer()
			wallJump()
		elseif humanoid.FloorMaterial == Enum.Material.Air then
			doubleJump()
		end
	end
end)

-- Monitor state changes to reset wall jump count
humanoid.StateChanged:Connect(function(_, newState)
	if newState == Enum.HumanoidStateType.Freefall or newState == Enum.HumanoidStateType.Jumping then
		-- Player is in the air, do nothing
	elseif newState == Enum.HumanoidStateType.Physics or newState == Enum.HumanoidStateType.Seated then
		-- Player has landed; reset wall jump count
		if humanoid.FloorMaterial ~= Enum.Material.Air then
			wallJumpCount = 0  -- Reset wall jump count on landing
		end
	end
end)

-- Reset wall jump count when touching the ground directly
humanoidRootPart.Touched:Connect(function(hit)
	if humanoid.FloorMaterial ~= Enum.Material.Air then
		wallJumpCount = 0  -- Reset wall jump count when touching the ground
	end
end)
