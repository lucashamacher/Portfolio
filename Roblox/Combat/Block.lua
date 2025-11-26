local uis = game:GetService("UserInputService")
local ts = game:GetService("TweenService")
local ss = game:GetService("SoundService")

local replicatedStorage = game.ReplicatedStorage
local be = replicatedStorage.Events.Server.BlockEvent
local se = replicatedStorage.Events.Server.StopBlock

local plr = game.Players.LocalPlayer
local char = plr.Character
local hum = char.Humanoid
local animator = hum.Animator
local hrp = char.HumanoidRootPart
local quirkString = plr:WaitForChild("Quirk")
local quirk = quirkString.Value
local blockAni = animator:LoadAnimation(replicatedStorage.Animations.BaseAnis.BlockAnim)

local cooldown = false
local stunned = char:GetAttribute("stunned")
local attacking = char:GetAttribute("Attacking")
local blocking  = char:GetAttribute("Blocking")

function debounce(key)
	local f = true
	while f do
		cooldown = true
		if (key == Enum.KeyCode.F) then
			f = uis:IsKeyDown(Enum.KeyCode.F)
		end
		wait()
	end
	cooldown = false
end

function stopBlock()
	blockAni:Stop()
	se:FireServer()
	local gui = plr.PlayerGui
	gui.BlockBarBillboard.Enabled = false
end

function block(key, running)
	be:FireServer()	
	wait(.05)
	blockAni:Play()
	local gui = plr.PlayerGui
	gui.BlockBarBillboard.Enabled = true
	local f = true
	while f do
		hum.WalkSpeed = 8
		if (key == Enum.KeyCode.F) then
			f = uis:IsKeyDown(Enum.KeyCode.F)
		end
		if char:GetAttribute("Attacking") or char:GetAttribute("Dash") or char:GetAttribute("stunned") or char:GetAttribute("Running") then 
			blockAni:Stop()
			stopBlock()
			debounce(key)
			f = false
		end
		wait()
	end
	stopBlock()
end

uis.InputBegan:Connect(function(i, e)
	if e then return end
	if char:GetAttribute("Downed") then return end
	if stunned or attacking or blocking then return end
	local bind = Enum.KeyCode[script.Bind.Value]
	if i.KeyCode == bind then
		block(i.KeyCode, char:GetAttribute("Running"))
	end
	if i.KeyCode == Enum.KeyCode.LeftShift then
		stopBlock()
	end
end)
