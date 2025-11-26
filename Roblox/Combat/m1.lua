-- NOTE: Too much logic handled on client. Anything I write today would rely on server more.

local uis = game:GetService("UserInputService")
local rs = game:GetService("RunService")
local debris = game:GetService("Debris")

local plr = game.Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local humanoid = char.Humanoid

local cancel = false
local punchConnection = nil
local stunConnection = nil

local dmgEvent = game.ReplicatedStorage.Events.Client.DamageEvent
local attack = game.ReplicatedStorage.Events.Server.m1
local stunHandler = game.ReplicatedStorage.Events.Client.Stun

local p1 = game.ReplicatedStorage.Animations.BaseAnis.Punch1
local p2 = game.ReplicatedStorage.Animations.BaseAnis.Punch2
local p3 = game.ReplicatedStorage.Animations.BaseAnis.Punch3
local p4 = game.ReplicatedStorage.Animations.BaseAnis.Punch4

local anim1 = humanoid.Animator:LoadAnimation(p1)
local anim2 = humanoid.Animator:LoadAnimation(p2)
local anim3 = humanoid.Animator:LoadAnimation(p3)
local anim4 = humanoid.Animator:LoadAnimation(p4)
local anim = anim1

local combo = 1
local cooldown = false
local comboCooldown = false
local comboCDT = 1.5

local damage = 10 --- subject to (and expecting) change

function check()
	if cooldown or comboCooldown then return false end
	if char:GetAttribute("Downed") then return false end
	if char:GetAttribute("stunned") then return false end
	if char:GetAttribute("Blocking") then return false end
	if char:GetAttribute("Dashing") then return false end
	if char:GetAttribute("Attacking") then return false end
	return true
end

dmgEvent.OnClientEvent:Connect(function(dmg)
	if char:GetAttribute("IFrame") then return end
	cancel = true -- cancel m1 attack if hit
	if char:FindFirstChild("m1Effect") then
		char:FindFirstChild("m1Effect"):Destroy()
	end
	cooldown = true
	local assertTime = 1
	while assertTime > 0 do
		cooldown = true
		assertTime -= 0.1
	end
	cooldown = false
end)

function punch()
	if not check() then return end
	
	cancel = false
	
	startComboTimer()
	
	spawn(function()
		cooldown = true
		task.wait(0.35)
		cooldown = false
	end)
	
	combo += 1
	
	if combo > 4 then
		resetCombo()
	end
	
	humanoid.WalkSpeed = 12
	
	local arm = nil
	if combo == 1 then
		anim = anim1
		arm = char:FindFirstChild("Right Arm")
	elseif combo == 2 then
		anim = anim2
		arm = char:FindFirstChild("Left Arm")
	elseif combo == 3 then
		anim = anim3
		arm = char:FindFirstChild("Left Arm")
	elseif combo == 4 then
		anim = anim4
		arm = char:FindFirstChild("Right Arm")
	end

	if anim then
		anim:Play()
	end

	if arm then
		createPunchEffect(arm)
		createPunchTrail(arm)
	end
	
	if punchConnection then
		punchConnection:Disconnect()
	end
	
	punchConnection = rs.Heartbeat:Connect(function()
		if cancel then 
			anim:Stop()
			punchConnection:Disconnect()
			for _, child in char:GetChildren() do
				if child.Name == "m1Effect" then
					child:Destroy()
				end
			end
			return
		end
	end)
	
	task.delay(0.2, function()
		if not cancel then
			attack:FireServer(damage, uis:IsKeyDown(Enum.KeyCode.Space))
		end
		if not char:GetAttribute("Stunned") then
			humanoid.WalkSpeed = 16
		end
	end)
	
end

function freeze()
	spawn(function()
		humanoid.WalkSpeed = 0
		char:SetAttribute("Running", false)
		wait(0.5)
		humanoid.WalkSpeed = 16
	end)
end

function resetCombo()
	if combo > 4 then freeze() end
	combo = 1
	if comboTimer then
		comboTimer:Disconnect()
		comboTimer = nil
	end
	spawn(function()
		task.wait(1)
		humanoid.JumpPower = 50
	end)
	spawn(function()
		comboCooldown = true
		wait(0.75)
		comboCooldown = false
	end)
end

function startComboTimer()
	if comboTimer then
		comboTimer:Disconnect()
	end


	comboCDT = 1.5

	comboTimer = game:GetService("RunService").Stepped:Connect(function(_, dt)
		comboCDT = comboCDT - dt
		humanoid.JumpPower = 0
		if comboCDT <= 0 then
			resetCombo()
		end
	end)
end

uis.InputBegan:Connect(function(i,e)
	if e then return end
	if i.UserInputType == Enum.UserInputType.MouseButton1 then
		punch()
	end
	if i.KeyCode == Enum.KeyCode.Q then
		cooldown = true
		task.wait(0.5)
		cooldown = false
	end
	if i.KeyCode == Enum.KeyCode.LeftControl then
		cooldown = true
		task.wait(.8)
		cooldown = false
	end
	if i.KeyCode == Enum.KeyCode.Space then
		cooldown = true
		task.wait(0.3)
		cooldown = false
	end
end)

function createPunchEffect(arm)
	if not arm then return end

	local effect = Instance.new("Part")
	effect.Size = arm.Size * 1.1 -- Make it larger than the arm
	effect.Shape = Enum.PartType.Block
	effect.Material = Enum.Material.ForceField
	effect.Color = Color3.fromRGB(255, 0, 0)
	effect.Transparency = 0
	effect.CanCollide = false
	effect.Anchored = false
	effect.Position = arm.Position
	effect.CFrame = arm.CFrame
	effect.Parent = char -- Parent to the character model for visibility
	
	effect.Name = "m1Effect"

	-- Create the weld and ensure it matches the arm's rotation
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = arm
	weld.Part1 = effect
	weld.Parent = effect

	debris:AddItem(effect, 0.3)
end

function createPunchTrail(arm)
	if not arm then return end
	local tip
	local shoulder
	if arm.Name == "Left Arm" then
		tip = arm.LeftGripAttachment
		shoulder = arm.LeftShoulderAttachment
	end
	if arm.Name == "Right Arm" then
		tip = arm.RightGripAttachment
		shoulder = arm.RightShoulderAttachment
	end

	-- Create a Trail object
	local trail = Instance.new("Trail")
	trail.Lifetime = 0.25 -- The trail will last for 0.5 seconds
	trail.MinLength = 1 -- The minimum length of the trail
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),  -- Fully opaque at the start
		NumberSequenceKeypoint.new(1, 1)   -- Fully transparent at the end
	})
	trail.Color = ColorSequence.new(Color3.fromRGB(255, 255,255)) -- Red color for the trail
	trail.WidthScale = NumberSequence.new(0.5, 0.1) -- Wide at the start, narrow at the end
	trail.TextureMode = Enum.TextureMode.Wrap
	trail.FaceCamera = true

	-- Attach the trail to the two attachments
	trail.Attachment0 = tip
	trail.Attachment1 = shoulder
	trail.Name = "m1Effect"

	-- Parent the trail to the arm (it will follow the arm's movement)
	trail.Parent = arm

	-- Clean up the trail after it finishes its lifetime
	debris:AddItem(trail, 0.5)
end

stunHandler.OnClientEvent:Connect(function(dur)
	char:SetAttribute("stunned", true)
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	if stunConnection then
		stunConnection:Disconnect()
	end
	stunConnection = rs.Heartbeat:Connect(function(dt)
		dur -= dt
		if dur <= 0 then
			stunConnection:Disconnect()
			humanoid.WalkSpeed = 16
			humanoid.JumpPower = 50
			char:SetAttribute("stunned", false)
			return
		end
	end)
end)
