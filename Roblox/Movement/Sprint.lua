-- NOTE: I didn't know how to animation cancel at this point, but I do now.

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character.HumanoidRootPart
local animator = humanoid.Animator

local fx = game.ReplicatedStorage.Fx

local DefaultFOV = 70

local WALKSPEED = 16
local RUNSPEED = WALKSPEED * 1.75

local events = game.ReplicatedStorage.Events.Server

local lastRun = 0
local direction = 1
local lastPosition = character.PrimaryPart.Position

local running = false
local blocking = character:GetAttribute("Blocking")
local sprintAni = animator:LoadAnimation(script.Run)
local walkAni = animator:LoadAnimation(script.WalkAnim)
local blockAni = animator:LoadAnimation(game.ReplicatedStorage.Animations.BaseAnis.BlockAnim)

local uis = game:GetService("UserInputService")
local ts = game:GetService("TweenService")
local rs = game:GetService("RunService")

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include
params.FilterDescendantsInstances = {workspace.Map}

local block = character:GetAttribute("Blocking")
local dash = character:GetAttribute("Dash")
local running = character:GetAttribute("Running") or false

local toggleSprint = game.ReplicatedStorage.Events.Client.toggleSprint

local function walk()
	running = false
	sprintAni:Stop()
	events.StopSprint:FireServer()
	if sprintAni then
		sprintAni:Stop()
	end
	task.wait(0.15)
	humanoid.WalkSpeed = WALKSPEED
	running = false
	direction = 0
	local properties = {FieldOfView = DefaultFOV}
	local Info = TweenInfo.new(0.5,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,0.1)
	local T = game:GetService("TweenService"):Create(game.Workspace.CurrentCamera,Info,properties)
	T:Play()
	if character:GetAttribute("Downed") then return end
end

local function sprint()
	wait(0.1)
	local animator = humanoid:FindFirstChild("Animator")
	running = true
	walkAni:Stop()
	events.StartSprint:FireServer()
	sprintAni:Play()
	humanoid.WalkSpeed = RUNSPEED
	running = true
	direction = 1
	local properties = {FieldOfView = DefaultFOV + 15}
	local Info = TweenInfo.new(0.5,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,0.1)
	local T = game:GetService("TweenService"):Create(game.Workspace.CurrentCamera,Info,properties)
	T:Play()
	while running do
		if character:GetAttribute("Downed") then walk() end
		wait()
		humanoid.WalkSpeed = RUNSPEED
		if humanoid.MoveDirection.Magnitude < 0.5 then
			sprintAni:Stop()
			while humanoid.MoveDirection.Magnitude < 0.5 do
				wait()
				if not running then return end
			end
			sprintAni:Play()
		else
			if not sprintAni then
				sprintAni:Play()
			end
		end
		if character:GetAttribute("Attacking") or character:GetAttribute("stunned") or character:GetAttribute("Blocking") then
			walk()
			return
		end
		if hrp.Anchored then
			sprintAni:Stop()
		end
		if humanoid.FloorMaterial == Enum.Material.Air then
			sprintAni:AdjustSpeed(0.25)
			while humanoid.FloorMaterial == Enum.Material.Air do
				wait()
			end
			sprintAni:AdjustSpeed(1)
		end
	end
end


uis.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if character:GetAttribute("Downed") then return end
	if input.KeyCode == Enum.KeyCode.LeftShift then
		if running then
			walk()
		else
			sprint()
		end
	end
	if input.KeyCode == Enum.KeyCode.F then
		walk()
	end
end)

toggleSprint.OnClientEvent:Connect(function()
	if running then
		walk()
	else
		sprint()
	end
end)

spawn(walk)
