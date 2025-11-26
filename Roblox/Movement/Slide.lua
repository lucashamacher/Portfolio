-- NOTE: Also from prior project

local UIS = game:GetService("UserInputService")
local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()

local slideAnim = Instance.new("Animation")
local ca = tostring(script:WaitForChild("SlideAnim").AnimationId)
slideAnim.AnimationId = ca

local keybind = Enum.KeyCode.LeftControl
local canslide = true
local dash = char:GetAttribute("Dash")
local blocking = char:GetAttribute("Blocking")

UIS.InputBegan:Connect (function(input,gameprocessed)
	if gameprocessed then return end
	if char:GetAttribute("Downed") then return end
	if not canslide then return end
	if dash then return end
	if blocking then return end
	if char.Humanoid.FloorMaterial == Enum.Material.Air then return end
	if input.KeyCode == keybind then
		canslide = false

		local playAnim = char.Humanoid:LoadAnimation(slideAnim)
		playAnim:Play()
		local snd = script.Slide
		snd:Play()
		local slide = Instance.new("BodyVelocity")
		slide.MaxForce = Vector3.new(1,0,1) *30000
		slide.Velocity = char.HumanoidRootPart.CFrame.lookVector * 100
		slide.Parent = char.HumanoidRootPart

		for count = 1, 8 do
			wait(0.1)
			slide.Velocity *= 0.7
		end
		playAnim:Stop()
		slide:Destroy()
		task.wait(0.3)
		canslide = true	
	end
end)

