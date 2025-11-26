local Player = game.Players.LocalPlayer
local Mouse = Player:GetMouse()
local Character = Player.Character or Player.CharacterAdded:Wait()
local hum = Character.Humanoid
local HRP = Character:WaitForChild("HumanoidRootPart")
local attackRange = 40
local cooldownTime = 7.5
local highlightedEnemy = nil
local fireAttack = game.ReplicatedStorage.Events.Nitro.NitroBlitzHit
local fe = game.ReplicatedStorage.Events.Nitro.NitroFatigue

local ani = hum:LoadAnimation(game.ReplicatedStorage.Animations.BaseAnis.Punch2) -- placeholder

local highlight = Instance.new("SelectionBox")
highlight.LineThickness = 0.1
highlight.Color3 = Color3.fromRGB(255, 255, 255) -- white color as an example

local function applySelfDamage(fatigueLevel, attackDamage)
	local selfDamageMultiplier = 0

	-- Determine self-damage multiplier based on fatigue level
	if fatigueLevel >= 70 then
		selfDamageMultiplier = 0.33  -- Heavy self-damage
	elseif fatigueLevel >= 50 then
		selfDamageMultiplier = 0.15  -- Medium self-damage
	elseif fatigueLevel >= 20 then
		selfDamageMultiplier = 0.1   -- Light self-damage
	end

	-- Calculate self-damage
	local selfDamage = attackDamage * selfDamageMultiplier

	-- Prevent damage from bringing health below a minimum threshold
	local minHealth = 11
	if hum.Health - selfDamage < minHealth then
		selfDamage = hum.Health - minHealth  -- Adjust self-damage to prevent dying
	end

	-- Fire the server to apply official self-damage
	hum:TakeDamage(selfDamage)

	-- UI feedback (flash effect)
	local ui = game.Players.LocalPlayer:FindFirstChild("PlayerGui"):FindFirstChild("FatigueUI")
	if ui then
		local damageFlash = ui:FindFirstChild("DamageFlash")
		damageFlash.Visible = true
		wait(0.2)
		damageFlash.Visible = false
	end
end

local function hitAttack(enemy)
	local fatigue = require(Player.PlayerScripts.NitroStamina)
	fatigue:addFatigue(10)
	
	applySelfDamage(fatigue.fatigue,10)
	
	ani:Play()
	
	fireAttack:FireServer(enemy)
end

-- Function to find the closest enemy within range
local function getClosestEnemy()
	local closestEnemy = nil
	local shortestDistance = math.huge

	-- Raycast from the player's camera to where the mouse is aiming
	local ray = workspace:Raycast(HRP.Position, Mouse.Hit.p - HRP.Position, RaycastParams.new())
	local targetPoint = ray and ray.Position or Mouse.Hit.p

	-- Find all enemies in the workspace
	for _, enemy in ipairs(workspace.Characters:GetChildren()) do
		if enemy ~= Character then
			if enemy:FindFirstChild("HumanoidRootPart") then
				local aimbox = Instance.new("Part")
				aimbox.Transparency = 1
				aimbox.CFrame = enemy.HumanoidRootPart.CFrame
				aimbox.Size = Vector3.new(15, 15, 10)
				aimbox.CanCollide = false
				aimbox.Anchored = true
				aimbox.Parent = workspace
				aimbox.BrickColor = BrickColor.new("Really red")
				local distance = (aimbox.Position - targetPoint).magnitude
				if distance <= attackRange and distance < shortestDistance then
					closestEnemy = enemy
					shortestDistance = distance
				end
				game:GetService("Debris"):AddItem(aimbox, 0.1)
			end
		end
	end
	return closestEnemy
end

-- Function to highlight an enemy
local function highlightEnemy(enemy)
	if enemy and enemy:FindFirstChild("HumanoidRootPart") and enemy.Humanoid.Health > 0 then
		highlight.Parent = enemy
		highlight.Adornee = enemy
		highlightedEnemy = enemy
	end
end

-- Function to remove highlighting
local function removeHighlight()
	highlight.Parent = nil
	highlight.Adornee = nil
	highlightedEnemy = nil
end

local function dashToEnemy()
	if highlightedEnemy and highlightedEnemy.HumanoidRootPart then
		local dashSpeed = 200  -- Adjust speed for your dash
		local maxTime = 3  -- Max time for dash to prevent endless dash if target is unreachable
		local targetPos = highlightedEnemy.HumanoidRootPart.Position
		local startPos = HRP.Position

		-- Create a LinearVelocity object to apply force to the character
		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.MaxForce = Vector3.new(10000, 10000, 10000)  -- High force to override gravity and apply dash
		bodyVelocity.P = 10000  -- Increase the 'P' value for responsiveness (force per unit of velocity change)
		bodyVelocity.Parent = HRP  -- Attach it to the HumanoidRootPart

		---- Create a BodyGyro to prevent unwanted rotation during the dash
		--local bodyGyro = Instance.new("BodyGyro")
		--bodyGyro.MaxTorque = Vector3.new(400000, 400000, 400000)  -- High torque to stop rotation
		--bodyGyro.CFrame = HRP.CFrame  -- Keep the character's orientation steady
		--bodyGyro.Parent = HRP  -- Attach to HumanoidRootPart

		local startTime = tick()

		-- Dash movement loop
		local dashConnection
		dashConnection = game:GetService("RunService").Heartbeat:Connect(function()
			local elapsed = tick() - startTime
			-- Update the target position and direction continuously
			targetPos = highlightedEnemy.HumanoidRootPart.Position
			local direction = (targetPos - HRP.Position).Unit  -- Recalculate the direction every frame
			HRP.CFrame = CFrame.lookAt(HRP.Position, targetPos)
			bodyVelocity.Velocity = (direction + Vector3.new(0,0.1,0)) * dashSpeed  -- Update velocity with the new direction

			-- Check if we've reached or surpassed the target or elapsed time
			if (HRP.Position - targetPos).magnitude <= 3 or elapsed >= maxTime then
				-- Stop applying velocity and remove momentum
				bodyVelocity:Destroy()  -- Destroy BodyVelocity to stop any further movement
				--bodyGyro:Destroy()  -- Remove BodyGyro to allow rotation after the dash
				HRP.Velocity = Vector3.new(0, 0, 0)  -- Reset the velocity to stop any movement
				HRP.RotVelocity = Vector3.new(0, 0, 0)  -- Reset angular velocity to stop spinning

				-- Ensure character is no longer anchored and clean up
				hitAttack(highlightedEnemy)  -- Trigger attack logic
				dashConnection:Disconnect()  -- Disconnect the heartbeat connection
				highlightedEnemy = nil
			end
		end)

		-- Optional: Clean up after a delay if needed
		wait(maxTime)
		bodyVelocity:Destroy()  -- Clean up velocity object after the dash
		--bodyGyro:Destroy()  -- Clean up BodyGyro if not destroyed during the dash
	end
end

-- When the player presses E, they start aiming
local aiming = false
local cooldown = false

-- Main loop to constantly update target while aiming
game:GetService("RunService").RenderStepped:Connect(function()
	if not aiming then return end
	local newTarget = getClosestEnemy()

	-- If we have a new target, highlight it
	if newTarget and newTarget ~= highlightedEnemy then
		removeHighlight()
		highlightEnemy(newTarget)
	elseif not newTarget then
		removeHighlight()
	end
end)

Mouse.KeyDown:Connect(function(key)
	if Character:GetAttribute("Downed") then return end
	Character = Player.Character or Player.CharacterAdded:Wait()
	if key == "e" and not cooldown then
		aiming = true
		-- Anchor the player during aiming
		Character.Humanoid.WalkSpeed = 0
	end
end)

Mouse.KeyUp:Connect(function(key)
	if Character:GetAttribute("Downed") then return end
	if key == "e" and aiming then
		aiming = false
		-- Unanchor player when finished aiming
		Character.Humanoid.WalkSpeed = 16
		Character:SetAttribute("Running", false)

		if highlightedEnemy then
			-- Fire the attack and do the desired effects
			print("Firing attack at", highlightedEnemy.Name)

			highlight.Parent = nil
			highlight.Adornee = nil

			-- Apply dash logic
			dashToEnemy()
			
			-- Apply cooldown
			cooldown = true
			wait(cooldownTime)
			cooldown = false
		end
	end
end)
