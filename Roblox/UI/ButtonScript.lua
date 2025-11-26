local button = script.Parent
local plr = game.Players.LocalPlayer
local readyEvent = game.ReplicatedStorage:WaitForChild("SetReadyStatus")

local colors = {
	Grey = Color3.fromRGB(50, 50, 50),
	White = Color3.fromRGB(255,255,255),
	Black = Color3.fromRGB(0,0,0)
}

local function getStatus()
	local status = false
	
	if button.Text ~= "Ready Up" then
		status = true
	end
	
	return status
end

local function updateUI(status)
	if status == false then
		button.Text = "Unready"
		button.BackgroundColor3 = colors.White
		button.TextColor3 = colors.Black
	else
		button.Text = "Ready Up"
		button.BackgroundColor3 = colors.Grey
		button.TextColor3 = colors.White
	end
end

button.Activated:Connect(function()
	button.Active = false
	local status = getStatus()
	
	updateUI(status)
	
	readyEvent:FireServer(not status) --toggle status
	
	button.Active = true --make button pressable again
end)
