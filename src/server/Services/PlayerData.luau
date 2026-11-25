local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Catalog = require(Shared.Catalog)

local store = DataStoreService:GetDataStore("TFFA_PlayerData_v1")

local PlayerData = {}
local profiles = {} -- [Player] = profile table
local noSave = {} -- [Player] = true (Studio fallback after a failed load: never overwrite real data)
local loadedEvent = Instance.new("BindableEvent")
PlayerData.Loaded = loadedEvent.Event

local NUMBERS = { "Money", "Strength", "Luck", "Level", "XP", "Pending", "Slots", "NextUid", "AreaMax", "SelectedArea", "TotalThrows" }

local function defaults()
	return {
		Money = Config.StartMoney,
		Strength = Config.StartStrength,
		Luck = Config.StartLuck,
		Level = 1,
		XP = 0,
		Pending = 0,
		Slots = Config.StartSlots,
		Foods = table.clone(Config.StartFoods),
		Equipped = "Carrot",
		Animals = {},
		NextUid = 1,
		Discovered = {},
		AreaMax = 1,
		SelectedArea = 1,
		Upgrades = {},
		TotalThrows = 0,
	}
end

local function finite(x)
	return typeof(x) == "number" and x == x and x ~= math.huge and x ~= -math.huge and x >= 0
end

-- Never trust stored data: rebuild it field by field.
local function sanitize(raw)
	local d = defaults()
	if typeof(raw) ~= "table" then
		return d
	end
	for _, key in NUMBERS do
		if finite(raw[key]) then
			d[key] = raw[key]
		end
	end
	d.Level = math.max(1, math.floor(d.Level))
	d.AreaMax = math.clamp(math.floor(d.AreaMax), 1, #Catalog.Areas)
	d.SelectedArea = math.clamp(math.floor(d.SelectedArea), 1, d.AreaMax)
	d.Slots = math.max(1, math.floor(d.Slots))

	d.Foods = {}
	if typeof(raw.Foods) == "table" then
		for id, n in raw.Foods do
			if Catalog.Foods[id] and finite(n) and n >= 1 then
				d.Foods[id] = math.floor(n)
			end
		end
	end
	d.Equipped = (typeof(raw.Equipped) == "string" and d.Foods[raw.Equipped]) and raw.Equipped or (next(d.Foods) or "")

	d.Animals = {}
	if typeof(raw.Animals) == "table" then
		for _, a in raw.Animals do
			if
				typeof(a) == "table"
				and typeof(a.uid) == "string"
				and Catalog.Animals[a.id]
				and Catalog.SizeByName[a.size]
				and #d.Animals < Config.MaxAnimals
			then
				table.insert(d.Animals, { uid = a.uid, id = a.id, size = a.size, placed = a.placed == true })
			end
		end
	end

	d.Discovered = {}
	if typeof(raw.Discovered) == "table" then
		for id in raw.Discovered do
			if Catalog.Animals[id] then
				d.Discovered[id] = true
			end
		end
	end
	for _, a in d.Animals do
		d.Discovered[a.id] = true
	end

	d.Upgrades = {}
	if typeof(raw.Upgrades) == "table" then
		for kind, n in raw.Upgrades do
			if Catalog.Upgrades[kind] and finite(n) then
				d.Upgrades[kind] = math.min(math.floor(n), Catalog.Upgrades[kind].Max)
			end
		end
	end
	return d
end

local function retry(fn, tries)
	local err
	for i = 1, tries do
		local ok, res = pcall(fn)
		if ok then
			return true, res
		end
		err = res
		task.wait(math.min(2 ^ i, 8))
	end
	return false, err
end

function PlayerData.get(player)
	return profiles[player]
end

function PlayerData.save(player)
	local profile = profiles[player]
	if not profile or noSave[player] then
		return
	end
	local ok, err = retry(function()
		store:UpdateAsync(tostring(player.UserId), function()
			return profile
		end)
	end, 4)
	if not ok then
		warn(`[PlayerData] save failed for {player.Name}: {err}`)
	end
end

local function onAdded(player)
	if profiles[player] then
		return
	end
	local ok, raw = retry(function()
		return store:GetAsync(tostring(player.UserId))
	end, 4)
	if player.Parent ~= Players then
		return
	end
	if not ok then
		if RunService:IsStudio() then
			warn("[PlayerData] DataStore unavailable in Studio (enable Studio Access to API Services). Using a temporary profile that will NOT be saved.")
			noSave[player] = true
			raw = nil
		else
			player:Kick("Your data could not be loaded. Please rejoin in a moment.")
			return
		end
	end
	profiles[player] = sanitize(raw)
	loadedEvent:Fire(player)
end

local function onRemoving(player)
	PlayerData.save(player)
	profiles[player] = nil
	noSave[player] = nil
end

function PlayerData.Init()
	Players.PlayerAdded:Connect(function(player)
		task.spawn(onAdded, player)
	end)
	Players.PlayerRemoving:Connect(onRemoving)
end

function PlayerData.Start()
	for _, player in Players:GetPlayers() do
		task.spawn(onAdded, player)
	end
	task.spawn(function()
		while true do
			task.wait(Config.AutosaveSeconds)
			for _, player in Players:GetPlayers() do
				task.spawn(PlayerData.save, player)
			end
		end
	end)
	game:BindToClose(function()
		if RunService:IsStudio() then
			return
		end
		local pending = 0
		for _, player in Players:GetPlayers() do
			pending += 1
			task.spawn(function()
				PlayerData.save(player)
				pending -= 1
			end)
		end
		local deadline = os.clock() + 25
		while pending > 0 and os.clock() < deadline do
			task.wait(0.2)
		end
	end)
end

return PlayerData
