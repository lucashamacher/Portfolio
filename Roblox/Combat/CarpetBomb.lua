local uis = game:GetService("UserInputService")
local ReplicatedStorage = game.ReplicatedStorage

local Player = game.Players.LocalPlayer
local character = Player.Character or Player.CharacterAdded:Wait()
local humanoid = character:FindFirstChild("Humanoid")
local hrp = character.HumanoidRootPart

local FatigueEvent = ReplicatedStorage.Events.Nitro.NitroFatigue
local fatigue = Player.PlayerScripts.NitroStamina

local cooldown = false
local cooltime = 10

local event = ReplicatedStorage.Events.Nitro.NitroCarpet

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

local function cd()
	spawn(function()
		cooldown = true
		task.wait(cooltime)
		cooldown = false
	end)
end

local function carpet()
	local fatigue = require(Player.PlayerScripts.NitroStamina)
	cd()
	fatigue:addFatigue(5 // 2)
	event:FireServer(5)
	
	task.wait(1)
	
	local i = 0
	repeat
		task.wait(0.25) -- carpet bombs should be every quarter second
		fatigue:addFatigue(5 // 2)
		applySelfDamage(fatigue.fatigue, 5)
		i+=1
	until i == 8
end

local function checks()
	if cooldown then return true end
	if character.HumanoidRootPart.Anchored then return true end
	if character:GetAttribute("Attacking") then return true end
	if character:GetAttribute("stunned") then return true end
	if character:GetAttribute("Dash") then return true end
	if character:GetAttribute("Blocking") then return true end
	if character:GetAttribute("Sweating") then return true end
	return false
end

uis.InputBegan:Connect(function(i,e)
	if e then return end
	if character:GetAttribute("Downed") then return end
	if checks() then return end
	if i.KeyCode == Enum.KeyCode.X then
		carpet()
	end
end)
