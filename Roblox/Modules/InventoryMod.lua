local InventoryModule = {}
InventoryModule.__index = InventoryModule

local saveEvent = game.ReplicatedStorage.Events.DataManagement.SaveInventory

function InventoryModule:new(player, data)
	local self = setmetatable({}, InventoryModule)
	self.items = {}
	self.Player = player
	self.Cash = 0
	
	spawn(function()
		self:Load(data)
		self:AutoSave()
	end)
	
	return self
end

function InventoryModule:Load(data)
	self.items = data.items or {}
	self.Cash = data.Cash or 0
	game.ReplicatedStorage.Events.Server.MoneyChanged:FireServer(self.Cash)
end

function InventoryModule:AutoSave()
	while true do
		wait(30)
		-- Check if the character is destroyed or missing, stop autosaving if so
		if not self.Character or not self.Character.Parent then
			print("Character is no longer available, stopping auto save.")
			break
		end
		self:Save()
	end
end

function InventoryModule:Save()
	local data = {
		items = self.items,
		Cash = self.Cash
	}
	saveEvent:FireServer(data)
end

function InventoryModule:isFull()
	return false -- change logic if we want to limit inventory space
end

function InventoryModule:AddItem(item)
	if not item then return true end
	if item.Stackable then
		-- Try to find an existing stack
		for _, existingItem in ipairs(self.items) do
			if existingItem.Id == item.Id then
				if existingItem.Quantity < existingItem.MaxQuantity then
					existingItem.Quantity += 1
				end
				return true
			end
		end
	end

	-- Otherwise, insert as a new entry
	table.insert(self.items, item)
	return true
end

function InventoryModule:GetMoney()
	return self.Cash
end

function InventoryModule:ChangeMoney(amount:IntValue)
	self.Cash += math.max(amount, 0) --can be positive or negative, can never result in negative money
	game.ReplicatedStorage.Events.Server.MoneyChanged:FireServer(self.Cash)
end

function InventoryModule:RemoveItem(item)
	for index, value in ipairs(self.items) do
		if value == item then
			table.remove(self.items, index)
			break
		end
	end
end

return InventoryModule
