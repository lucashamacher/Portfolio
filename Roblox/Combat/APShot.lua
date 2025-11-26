local uis = game:GetService("UserInputService")
local ReplicatedStorage = game.ReplicatedStorage
local Player = game.Players.LocalPlayer
local character = Player.Character or Player.CharacterAdded:Wait()
local humanoid = character:FindFirstChild("Humanoid")
local hrp = character.HumanoidRootPart
local mouse = Player:GetMouse()

local ani = humanoid:LoadAnimation(ReplicatedStorage.Animations.Nitro.APShot)

local cooldown = false
local cooltime = 5

local FatigueEvent = ReplicatedStorage.Events.Nitro.NitroFatigue

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
	if humanoid.Health - selfDamage < minHealth then
		selfDamage = humanoid.Health - minHealth  -- Adjust self-damage to prevent dying
	end

	-- Fire the server to apply official self-damage
	humanoid:TakeDamage(selfDamage)

	-- UI feedback (flash effect)
	local ui = game.Players.LocalPlayer:FindFirstChild("PlayerGui"):FindFirstChild("FatigueUI")
	if ui then
		local damageFlash = ui:FindFirstChild("DamageFlash")
		damageFlash.Visible = true
		wait(0.2)
		damageFlash.Visible = false
	end
end

function APShot() 
	cooldown = true
	local NitroFatigue = require(Player.PlayerScripts.NitroStamina)
	local fireAPShot = ReplicatedStorage.Events.Nitro.APShot
	local staminaCost = 20
	
	ani:Play()
	ani:AdjustSpeed(0.65)
	hrp.Anchored = true
	task.wait(0.3)

	NitroFatigue:addFatigue(staminaCost)
	
	local damage = 20 * NitroFatigue.fatigue / 20 --placeholder
	
	applySelfDamage(NitroFatigue.fatigue * 10, damage)
	
	local root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local aimDirection = (mouse.Hit.Position - root.Position).unit
	fireAPShot:FireServer(aimDirection, damage)
	
	task.wait(0.2)

	hrp.Anchored = false
	task.wait(cooltime - 0.5)
	cooldown = false
	
end

uis.InputBegan:Connect(function(i,e)
	if e then return end
	if character:GetAttribute("Downed") then return end
	local attacking = character:GetAttribute("Attacking")
	local stunned = character:GetAttribute("stunned")
	local blocking = character:GetAttribute("Blocking")
	local dash = character:GetAttribute("Dash")
	local sweating = character:GetAttribute("Sweating")
	if cooldown then return end
	if attacking then return end
	if stunned then return end
	if sweating then return end
	if i.KeyCode == Enum.KeyCode.Z then
		APShot()
	end
end)
