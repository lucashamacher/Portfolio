--fileName: PregameLobbyService
local Players = game:GetService("Players")
local KickEvent = game.ReplicatedStorage:WaitForChild("KickEvent")
local SetReady = game.ReplicatedStorage:WaitForChild("SetReadyStatus")

local FILL_WINDOW_DURATION = 30 

local Lobby = {
	Id = nil,
	Host = nil,
	MaxPlayers = 3,
	Members = {},
	JoinOrder = {},
	Settings = {
		PrivateLobby = false,
		FriendsAllowed = true,
	},
	State = "Open",    
	AllowedInvites = {},
	Ready = {},
	Filling = false,    

	Bots = {},       
	BotCount = 0,
}

local FillToken = 0

local function addMember(plr)
	if not Lobby.Members[plr.UserId] then
		Lobby.Members[plr.UserId] = plr
		table.insert(Lobby.JoinOrder, plr)
		-- default: not ready
		Lobby.Ready[plr.UserId] = false
	end
end

local function removeMember(plr)
	Lobby.Members[plr.UserId] = nil
	Lobby.Ready[plr.UserId] = nil

	for i, p in ipairs(Lobby.JoinOrder) do
		if p == plr then
			table.remove(Lobby.JoinOrder, i)
			break
		end
	end
end

local function memberCount()
	return #Lobby.JoinOrder -- real players
end 

local function readyCount()
	local n = 0
	for userId, isReady in pairs(Lobby.Ready) do
		if isReady and Lobby.Members[userId] then
			n += 1
		end
	end
	return n
end

local function allReady()
	return memberCount() > 0 and readyCount() == memberCount()
end

-- total slots in the party (players + bots)
local function totalCount()
	return memberCount() + (Lobby.BotCount or 0)
end

local function isFull()
	return totalCount() >= Lobby.MaxPlayers
end

local function setState(newState)
	Lobby.State = newState
	print("Lobby state ->", newState)
end

local function canJoin(plr, tpData)
	-- If lobby not initialized yet, always allow first player
	if not Lobby.Id then
		return true
	end

	-- Basic state guard
	if Lobby.State ~= "Open" then
		return false, "Lobby is locked."
	end

	-- Must match LobbyId from TeleportData
	if tpData.LobbyId ~= Lobby.Id then
		return false, "Wrong lobby."
	end

	-- Max size check
	if isFull() then
		return false, "Lobby is full."
	end

	-- Host always allowed
	if Lobby.Host and plr.UserId == Lobby.Host.UserId then
		return true
	end

	-- Invite whitelist
	if Lobby.AllowedInvites[plr.UserId] then
		return true
	end

	-- Settings-based rules
	if Lobby.Settings.PrivateLobby then
		if Lobby.Settings.FriendsAllowed and Lobby.Host and plr:IsFriendsWith(Lobby.Host.UserId) then
			return true
		end
		return false, "This lobby is private."
	else
		if Lobby.Settings.FriendsAllowed and Lobby.Host and plr:IsFriendsWith(Lobby.Host.UserId) then
			return true
		end
		-- Open to anyone if not private
		return true
	end
end

Players.PlayerAdded:Connect(function(plr)
	local joinData = plr:GetJoinData()
	local tpData = joinData and joinData.TeleportData or {}

	-- First player to join defines the lobby
	if not Lobby.Id then
		Lobby.Id = tpData.LobbyId or ("Adhoc_" .. plr.UserId)
		Lobby.Host = plr

		-- Settings from TeleportData, fallback to defaults
		local incomingSettings = tpData.Settings or {}
		Lobby.Settings.PrivateLobby = incomingSettings.PrivateLobby == true
		Lobby.Settings.FriendsAllowed = incomingSettings.FriendsAllowed ~= false

		addMember(plr)
		print("Pregame lobby created:", Lobby.Id, "Host:", plr.Name)
		return
	end

	-- For additional players, enforce rules
	local ok, reason = canJoin(plr, tpData)
	if not ok then
		warn("Rejecting join for", plr.Name, "-", reason)
		plr:Kick(reason)
		return
	end

	addMember(plr)
	print(plr.Name, "joined pregame lobby", Lobby.Id)

	-- If someone joins while we're in the fill window,
	-- stop filling and lock the lobby. We will wait until all are ready again.
	if Lobby.Filling and Lobby.State == "Open" then
		Lobby.Filling = false
		FillToken += 1 -- cancel any pending fill timer
		setState("Locked")
		print("Player joined during fill window; lobby locked. Waiting for everyone to ready.")
	end
end)

Players.PlayerRemoving:Connect(function(plr)
	removeMember(plr)

	-- If someone leaves while we are filling, cancel that fill attempt
	if Lobby.Filling then
		Lobby.Filling = false
		FillToken += 1
		print("Player left; cancelling fill window.")
	end

	-- If no one is left, "destroy" lobby data
	if memberCount() == 0 then
		print("Lobby is now empty; resetting lobby data.")
		Lobby.Id = nil
		Lobby.Host = nil
		Lobby.Settings = {
			PrivateLobby = false,
			FriendsAllowed = true,
		}
		Lobby.State = "Open"
		Lobby.AllowedInvites = {}
		Lobby.JoinOrder = {}
		Lobby.Members = {}
		Lobby.Ready = {}
		Lobby.Filling = false
		Lobby.Bots = {}
		Lobby.BotCount = 0
		return
	end

	-- If host left but others remain, promote next earliest joined
	if Lobby.Host == plr then
		local newHost = Lobby.JoinOrder[1]
		Lobby.Host = newHost
		print("Host left; new host is", newHost and newHost.Name or "nil")
	end
end)

local function addBots(count)
	if count <= 0 then return end

	for i = 1, count do
		local slotIndex = totalCount() + 1
		table.insert(Lobby.Bots, {
			SlotIndex = slotIndex,
			IsReady = true, -- bots are always ready
		})
	end

	Lobby.BotCount += count
	print("Added", count, "bots. Total bots now:", Lobby.BotCount)
end

KickEvent.OnServerEvent:Connect(function(sender, targetUserId)
	if sender ~= Lobby.Host then
		return
	end

	local target = Lobby.Members[targetUserId]
	if not target or target.Parent ~= Players then
		return
	end

	if target == sender then
		return
	end

	target:Kick("You were removed from the party by the host.")
end)

local TeleportService = game:GetService("TeleportService")

local WAITING_ROOM_PLACE_ID = 122219194965525

local function startMatchmaking()
	print(">>> Matchmaking starting for lobby:", Lobby.Id,
		"players:", memberCount(), "max:", Lobby.MaxPlayers,
		"bots:", Lobby.BotCount)

	-- collect all real players currently in the party
	local playerList = {}
	for _, plr in ipairs(Lobby.JoinOrder) do
		table.insert(playerList, plr)
	end

	if #playerList == 0 then
		warn("No real players left to teleport. Aborting matchmaking.")
		return
	end

	-- TeleportData to send to the waiting room
	local teleportData = {
		LobbyId = Lobby.Id,
		HostUserId = Lobby.Host and Lobby.Host.UserId,

		Members = {},      -- all human players userIds
		Bots = Lobby.Bots, -- bot slot metadata
		BotCount = Lobby.BotCount,

		Settings = Lobby.Settings,
	}

	for _, plr in ipairs(playerList) do
		table.insert(teleportData.Members, plr.UserId)
	end

	local options = Instance.new("TeleportOptions")
	options:SetTeleportData(teleportData)

	-- teleport whole party
	local ok, err = pcall(function()
		TeleportService:TeleportAsync(WAITING_ROOM_PLACE_ID, playerList, options)
	end)

	if not ok then
		warn("Teleport failed:", err)
	else
		print("Teleport started for lobby:", Lobby.Id)
	end
end


local function finalizeAndMatchmake()
	if not isFull() then
		local needed = Lobby.MaxPlayers - totalCount()
		if needed > 0 then
			print("Finalizing lobby. Need to add", needed, "bots.")
			addBots(needed)
		end
	end

	if Lobby.State ~= "Locked" then
		setState("Locked")
	end

	startMatchmaking()
end

local function startFillWindow()
	-- Already filling or lobby not open? do nothing
	if Lobby.Filling or Lobby.State ~= "Open" then
		return
	end

	-- Only start a fill window if *currently* all ready and not full
	if not allReady() or isFull() then
		return
	end

	Lobby.Filling = true
	FillToken += 1
	local myToken = FillToken

	print("Starting fill window for", FILL_WINDOW_DURATION, "seconds...")

	task.delay(FILL_WINDOW_DURATION, function()
		-- If token changed, this fill attempt was cancelled or restarted
		if FillToken ~= myToken then
			return
		end

		Lobby.Filling = false

		if Lobby.State ~= "Open" then
			return
		end

		if not allReady() then
			print("Fill window ended, but not all ready anymore. Doing nothing.")
			return
		end

		-- Still open, still all ready: finalize
		finalizeAndMatchmake()
	end)
end

SetReady.OnServerEvent:Connect(function(plr, isReady)
	if not Lobby.Members[plr.UserId] then
		return
	end

	local flag = isReady and true or false
	Lobby.Ready[plr.UserId] = flag

	print(plr.Name, "ready =", flag, "(", readyCount(), "/", memberCount(), ")")

	local everyoneReady = allReady()

	-- If we were filling and someone toggles to NOT ready, cancel filling immediately
	if Lobby.Filling and not everyoneReady then
		Lobby.Filling = false
		FillToken += 1
		print("Fill window cancelled: not all players ready anymore.")
		return
	end

	if not everyoneReady then
		-- some players not ready; nothing else to do
		return
	end

	-- From here, everyoneReady == true

	if Lobby.State == "Open" then
		if isFull() then
			setState("Locked")
			print("All players ready and lobby full; starting matchmaking now.")
			finalizeAndMatchmake()
		else
			print("All players ready, but lobby not full. Starting fill window...")
			startFillWindow()
		end

	elseif Lobby.State == "Locked" and not Lobby.Filling then
		-- e.g. someone joined during fill, we locked; now everyone is ready
		print("All players ready and lobby locked; finalizing and starting matchmaking.")
		finalizeAndMatchmake()
	end
end)
