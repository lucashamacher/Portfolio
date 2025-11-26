local Players = game:GetService("Players")
local plr = Players.LocalPlayer
local pui = plr:WaitForChild("PlayerGui")
local ui = pui:WaitForChild("PregameUI")


local leftKeys = {PC = Enum.KeyCode.Q, Console = Enum.KeyCode.ButtonL1}
local rightKeys = {PC = Enum.KeyCode.E, Console = Enum.KeyCode.ButtonR1}

local current = 0
local currentTab = "Lobby"

local sections = {
	Lobby = ui:WaitForChild("LobbyTab"),
	Customize = ui:WaitForChild("CustomizeTab"),
	Pass = ui:WaitForChild("PassTab"),
	Shop = ui:WaitForChild("ShopTab"),
	Rolls = ui:WaitForChild("RollsTab"),
	Settings = ui:WaitForChild("SettingsTab")
}

local buttonsFrame = ui:WaitForChild("Tabs")

local buttons = {
	Customize = buttonsFrame:WaitForChild("Customize"),
	Lobby = buttonsFrame:WaitForChild("Lobby"),
	Pass = buttonsFrame:WaitForChild("Pass"),
	Rolls = buttonsFrame:WaitForChild("Rolls"),
	Shop = buttonsFrame:WaitForChild("Shop"),
	Settings = buttonsFrame:WaitForChild("Settings")
}

local colors = {
	Yellow = Color3.fromRGB(255,255,127),
	Grey = Color3.fromRGB(20,20,20),
	White = Color3.fromRGB(255,255,255),
	Black = Color3.fromRGB(0,0,0)
}

local tabOrder = {
	"Lobby","Customize","Rolls","Pass","Shop","Settings"
}

local uis = game:GetService("UserInputService")

local function inMenu()
	-- implement logic for specific sections later --
	return false
end

local function updateTab()
	local old = currentTab
	currentTab = tabOrder[current]
	local new = currentTab
	
	local oldButton = buttons[old]
	local oldTab = sections[old]
	local newButton = buttons[new]
	local newTab = sections[new]
	
	--change tab colors
	
	oldButton.BackgroundColor3 = colors.Grey
	oldButton.TextColor3 = colors.White
	oldTab.Visible = false
	
	newButton.BackgroundColor3 = colors.Yellow
	newButton.TextColor3 = colors.Black
	newTab.Visible = true
end

uis.InputBegan:Connect(function(i,e)
	if e then return end
	if inMenu() then return end
	
	for k, v in pairs(leftKeys) do
		if i.KeyCode == v then
			--go left
			current-=1
			if current == 0 then
				current = 6
			end 
			updateTab()
			return
		end
	end
	
	for k, v in pairs(rightKeys) do
		if i.KeyCode == v then
			--go right
			current+=1
			if current == 7 then
				current = 1
			end 
			updateTab()
			return
		end
	end
end)

buttons.Lobby.Activated:Connect(function()
	current = 1
	updateTab()
end)
buttons.Customize.Activated:Connect(function()
	current = 2
	updateTab()
end)
buttons.Shop.Activated:Connect(function()
	current = 5
	updateTab()
end)
buttons.Pass.Activated:Connect(function()
	current = 4
	updateTab()
end)
buttons.Rolls.Activated:Connect(function()
	current = 3
	updateTab()
end)
buttons.Settings.Activated:Connect(function()
	current = 6
	updateTab()
end)
