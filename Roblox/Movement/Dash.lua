-- NOTE: This script is from an older project, but is still something I wrote, even if a while back.

local UIS = game:GetService("UserInputService")

local camera = workspace.CurrentCamera
local DKeyDown = false
local SKeyDown = false
local AKeyDown = false
local WKeyDown = false


local Player = game.Players.LocalPlayer
local Char = Player.Character or Player.CharacterAdded:Wait()
while Char.Parent == nil do
	Char.AncestryChanged:wait()
end
local blocking = Char:GetAttribute("Blocking")
local attacking = Char:GetAttribute("Attacking")
local HumRP = Char:WaitForChild("HumanoidRootPart")
local Hum = Char:WaitForChild("Humanoid")
local RollFrontAnim = Hum:LoadAnimation(script:WaitForChild("RollFront"))
local BackRollAnim = Hum:LoadAnimation(script:WaitForChild("BackRoll"))
local LeftRollAnim = Hum:LoadAnimation(script:WaitForChild("RightRoll"))
local RightRollAnim = Hum:LoadAnimation(script:WaitForChild("LeftRoll"))
local DashDebounce = false
local DashingDebounce = false
local CanDoAnything = true

local sprint = Char:GetAttribute("Running")
local d = script.Dash
local d2 = script.Dash
local d3 = script.DashL

local de = game.ReplicatedStorage.Events.Server.DashEvent

local function createShockwaveEffect(position, direction)
	local shockwave = Instance.new("Part")
	shockwave.Shape = Enum.PartType.Ball
	shockwave.Size = Vector3.new(1, 1, 1)
	shockwave.Orientation = direction
	shockwave.Position = position
	shockwave.Transparency = 0
	shockwave.Material = Enum.Material.ForceField
	shockwave.Color = Color3.new(1, 1, 1)
	shockwave.Anchored = true
	shockwave.CanCollide = false
	shockwave.Parent = workspace

	game:GetService("TweenService"):Create(shockwave, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Vector3.new(10, 10, 10), Transparency = 1}):Play()
	game.Debris:AddItem(shockwave, 0.3)
end

local function createTrail(part)
	local tip
	if not part then 
		print("part ".. tostring(part) .. " not found")
	end
	if part.Name == "Left Arm" then
		tip = part.LeftGripAttachment
	end
	if part.Name == "Right Arm" then
		tip = part.RightGripAttachment
	end
	if part.Name == "Left Leg" then
		tip = part.LeftFootAttachment
	end
	if part.Name == "Right Leg" then
		tip = part.RightFootAttachment
	end

	-- Create a Trail object
	local trail = Instance.new("Trail")
	trail.Lifetime = 0.5 -- Adjust based on desired effect
	trail.MinLength = 1
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),  
		NumberSequenceKeypoint.new(1,1) -- Fully fades out at the end
	})
	trail.FaceCamera = true
	trail.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255)) 
	trail.WidthScale = NumberSequence.new(0.1, 0.05)
	trail.TextureMode = Enum.TextureMode.Wrap
	trail.MaxLength = math.huge

	-- Create an attachment at the end point
	local temp = Instance.new("Part")
	temp.CFrame = part.CFrame
	temp.CanCollide = false
	temp.Transparency = 1
	temp.Size = Vector3.new(1,1,1)
	temp.Parent = part.Parent  -- Keep it within the character model

	-- Weld the temp part to the root part so it moves with the character
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = temp
	weld.Part1 = part.Parent:FindFirstChild("HumanoidRootPart") or part
	weld.Parent = temp

	local attachment1 = Instance.new("Attachment")
	attachment1.Parent = temp
	attachment1.Position = Vector3.new(0, 0, 0) -- Adjust based on effect needs

	-- Attach the trail to the two attachments
	trail.Attachment0 = tip
	trail.Attachment1 = attachment1

	-- Parent the trail to the part
	trail.Parent = part

	-- Clean up
	game.Debris:AddItem(temp, 0.75)
	game.Debris:AddItem(trail, 0.75)
end



UIS.InputBegan:Connect(function(Input,IsTyping)
	if IsTyping then return end
	if Char:GetAttribute("Downed") then return end
	if Char:GetAttribute("stunned") then return end
	if DashDebounce then return end
	if HumRP.Anchored then return end
	if Char:FindFirstChild("PBSTUN") then return end
	if blocking or attacking then return end
	if Char:FindFirstChild("noJump") then return end
	if CanDoAnything == true then
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.KeyCode == Enum.KeyCode.LeftControl then
		if Char:GetAttribute("QuirkMobility") then return end
			DashDebounce = true
			task.wait(0.3)
			DashDebounce = false
		elseif Input.KeyCode == Enum.KeyCode.Q then
			if DashDebounce == false then
				de:FireServer()
				Char:SetAttribute("NoLean", true)
				DashDebounce = true
				CanDoAnything = false
				delay(0.3,function()
					CanDoAnything = true
				end)
				delay(1.5,function()
					DashDebounce = false
				end)
				if WKeyDown then
					RollFrontAnim:Play()
					DashingDebounce = true
					d:Play()
					createShockwaveEffect(HumRP.Position, Vector3.new(0,0,0))
					createTrail(Char:FindFirstChild("Left Arm"))
					createTrail(Char:FindFirstChild("Right Arm"))
					createTrail(Char:FindFirstChild("Left Leg"))
					createTrail(Char:FindFirstChild("Right Leg"))
					delay(0.25,function()
						DashingDebounce = false
					end)
					repeat
						HumRP.Velocity = HumRP.CFrame.lookVector * 140 + Vector3.new(0,17.5,0)
						wait(0.1)
					until DashingDebounce == false
				elseif SKeyDown then
					DashingDebounce = true
					BackRollAnim:Play()
					d:Play()
					createShockwaveEffect(HumRP.Position, Vector3.new(0,0,0))
					createTrail(Char:FindFirstChild("Left Arm"))
					createTrail(Char:FindFirstChild("Right Arm"))
					createTrail(Char:FindFirstChild("Left Leg"))
					createTrail(Char:FindFirstChild("Right Leg"))
					delay(0.25,function()
						DashingDebounce = false
					end)

					repeat
						HumRP.Velocity = HumRP.CFrame.lookVector * -140 + Vector3.new(0,15,0)
						wait(0.1)
					until DashingDebounce == false
				elseif DKeyDown then
					DashingDebounce = true
					LeftRollAnim:Play()
					d2:Play()
					createShockwaveEffect(HumRP.Position, Vector3.new(90,0,0))
					createTrail(Char:FindFirstChild("Left Arm"))
					createTrail(Char:FindFirstChild("Right Arm"))
					createTrail(Char:FindFirstChild("Left Leg"))
					createTrail(Char:FindFirstChild("Right Leg"))
					delay(0.25,function()
						DashingDebounce = false
					end)

					repeat
					
						HumRP.Velocity = HumRP.CFrame.rightVector * 140 + Vector3.new(0,15,0)
						wait(0.11)
					until DashingDebounce == false
				elseif AKeyDown then
					DashingDebounce = true
					d2:Play()
					RightRollAnim:Play()
					createShockwaveEffect(HumRP.Position, Vector3.new(90,0,0))
					createTrail(Char:FindFirstChild("Left Arm"))
					createTrail(Char:FindFirstChild("Right Arm"))
					createTrail(Char:FindFirstChild("Left Leg"))
					createTrail(Char:FindFirstChild("Right Leg"))
					delay(0.25,function()
						DashingDebounce = false
					end)

					repeat
						
						HumRP.Velocity = HumRP.CFrame.rightVector * -140 + Vector3.new(0,15,0)
						wait(0.11)
					until DashingDebounce == false
				end	
				if sprint then
					Hum.WalkSpeed = 16 * 1.5
				end
				Char:SetAttribute("NoLean", false)
			end	
			end
		end
	end)

local RunService = game:GetService("RunService")

RunService.RenderStepped:Connect(function()
	WKeyDown = UIS:IsKeyDown(Enum.KeyCode.W)
	AKeyDown = UIS:IsKeyDown(Enum.KeyCode.A)
	SKeyDown = UIS:IsKeyDown(Enum.KeyCode.S)
	DKeyDown = UIS:IsKeyDown(Enum.KeyCode.D)
end)

