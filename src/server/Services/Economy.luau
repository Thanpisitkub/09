-- Owns money, stats, inventory, upgrades, areas, animal placement and passive income.
-- Everything the client sees is a mirror: player attributes for numbers, one Inventory event for tables.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Catalog = require(Shared.Catalog)
local Config = require(Shared.Config)
local Net = require(Shared.Net)
local Util = require(Shared.Util)
local PlayerData = require(script.Parent.PlayerData)

local Economy = {}
local inventoryChanged = Instance.new("BindableEvent")
Economy.InventoryChanged = inventoryChanged.Event -- (player) after any inventory/placement change
local income = {} -- [Player] = money per second from placed animals
local lastCall = {} -- [Player] = { [key] = os.clock() }

function Economy.notify(player, kind, text)
	Net.event("Notify"):FireClient(player, kind, text)
end

local function throttle(player, key, interval)
	local t = lastCall[player]
	if not t then
		t = {}
		lastCall[player] = t
	end
	local now = os.clock()
	if t[key] and now - t[key] < interval then
		return false
	end
	t[key] = now
	return true
end

local function recalc(player)
	local p = PlayerData.get(player)
	if not p then
		return
	end
	local total, placed = 0, 0
	for _, a in p.Animals do
		if a.placed then
			total += Catalog.income(a.id, a.size)
			placed += 1
		end
	end
	income[player] = total
	player:SetAttribute("Income", total)
	player:SetAttribute("Placed", placed)
end

local function publish(player)
	local p = PlayerData.get(player)
	if not p then
		return
	end
	player:SetAttribute("Money", p.Money)
	player:SetAttribute("Strength", p.Strength)
	player:SetAttribute("Luck", p.Luck)
	player:SetAttribute("Level", p.Level)
	player:SetAttribute("XP", p.XP)
	player:SetAttribute("XPNext", Catalog.xpNeeded(p.Level))
	player:SetAttribute("Pending", p.Pending)
	player:SetAttribute("Slots", p.Slots)
	player:SetAttribute("AreaMax", p.AreaMax)
	player:SetAttribute("SelectedArea", p.SelectedArea)
	player:SetAttribute("TotalThrows", p.TotalThrows)
	player:SetAttribute("TotalAnimals", #p.Animals)

	local stats = player:FindFirstChild("leaderstats")
	if stats then
		stats.Level.Value = p.Level
		stats.Power.Value = p.Strength
		stats.Animals.Value = #p.Animals
	end
end

local function pushInventory(player)
	local p = PlayerData.get(player)
	if not p then
		return
	end
	inventoryChanged:Fire(player)
	Net.event("Inventory"):FireClient(player, {
		Foods = p.Foods,
		Equipped = p.Equipped,
		Animals = p.Animals,
		Discovered = p.Discovered,
		Upgrades = p.Upgrades,
	})
end

Economy.publish = publish
Economy.pushInventory = pushInventory

local function refresh(player)
	recalc(player)
	publish(player)
	pushInventory(player)
end

function Economy.addMoney(player, n)
	local p = PlayerData.get(player)
	if p then
		p.Money += n
		publish(player)
	end
end

function Economy.addStrength(player, n)
	local p = PlayerData.get(player)
	if p then
		p.Strength += n
		publish(player)
	end
end

function Economy.addLuck(player, n)
	local p = PlayerData.get(player)
	if p then
		p.Luck += n
		publish(player)
	end
end

function Economy.addXP(player, n)
	local p = PlayerData.get(player)
	if not p then
		return
	end
	p.XP += n
	local leveled = false
	while p.XP >= Catalog.xpNeeded(p.Level) do
		p.XP -= Catalog.xpNeeded(p.Level)
		p.Level += 1
		leveled = true
	end
	publish(player)
	if leveled then
		Economy.notify(player, "levelup", `Level {p.Level}!`)
	end
end

-- Returns uid, isNewDiscovery  (or nil, reason)
function Economy.giveAnimal(player, animalId, size)
	local p = PlayerData.get(player)
	if not p then
		return nil, "No profile"
	end
	if not Catalog.Animals[animalId] or not Catalog.SizeByName[size] then
		return nil, "Unknown character"
	end
	if #p.Animals >= Config.MaxAnimals then
		return nil, "Team storage is full"
	end
	local uid = "a" .. p.NextUid
	p.NextUid += 1
	table.insert(p.Animals, { uid = uid, id = animalId, size = size, placed = false })
	local isNew = not p.Discovered[animalId]
	p.Discovered[animalId] = true
	publish(player)
	pushInventory(player)
	return uid, isNew
end

local function findAnimal(p, uid)
	for _, a in p.Animals do
		if a.uid == uid then
			return a
		end
	end
	return nil
end

local function placedCount(p)
	local n = 0
	for _, a in p.Animals do
		if a.placed then
			n += 1
		end
	end
	return n
end

function Economy.Init()
	local function onLoaded(player)
		local stats = Instance.new("Folder")
		stats.Name = "leaderstats"
		for _, name in { "Level", "Power", "Animals" } do
			local v = Instance.new("NumberValue")
			v.Name = name
			v.Parent = stats
		end
		stats.Parent = player
		refresh(player)
	end
	PlayerData.Loaded:Connect(onLoaded)

	Players.PlayerRemoving:Connect(function(player)
		income[player] = nil
		lastCall[player] = nil
	end)

	Net.event("RequestState").OnServerEvent:Connect(function(player)
		if PlayerData.get(player) then
			refresh(player)
		end
	end)

	Net.event("BuyFood").OnServerEvent:Connect(function(player, foodId, qty)
		local p = PlayerData.get(player)
		local food = typeof(foodId) == "string" and Catalog.Foods[foodId]
		qty = Util.amount(qty, 99)
		if not p or not food or not qty or not throttle(player, "buy", 0.15) then
			return
		end
		if p.Level < food.RequiredLevel then
			return Economy.notify(player, "error", `Reach level {food.RequiredLevel} to buy {food.Name}`)
		end
		local cost = food.Price * qty
		if p.Money < cost then
			return Economy.notify(player, "error", "Not enough money")
		end
		p.Money -= cost
		p.Foods[foodId] = (p.Foods[foodId] or 0) + qty
		if p.Equipped == "" or not p.Foods[p.Equipped] then
			p.Equipped = foodId
		end
		publish(player)
		pushInventory(player)
		Economy.notify(player, "success", `Bought {qty}x {food.Name}`)
	end)

	Net.event("EquipFood").OnServerEvent:Connect(function(player, foodId)
		local p = PlayerData.get(player)
		if p and typeof(foodId) == "string" and (p.Foods[foodId] or 0) > 0 and throttle(player, "equip", 0.1) then
			p.Equipped = foodId
			pushInventory(player)
		end
	end)

	Net.event("UpgradeStat").OnServerEvent:Connect(function(player, kind)
		local p = PlayerData.get(player)
		local u = typeof(kind) == "string" and Catalog.Upgrades[kind]
		if not p or not u or not throttle(player, "upgrade", 0.2) then
			return
		end
		local owned = p.Upgrades[kind] or 0
		if owned >= u.Max then
			return Economy.notify(player, "info", `{u.Name} is maxed out`)
		end
		local cost = Catalog.upgradeCost(kind, owned)
		if p.Money < cost then
			return Economy.notify(player, "error", "Not enough money")
		end
		p.Money -= cost
		p.Upgrades[kind] = owned + 1
		if kind == "Strength" then
			p.Strength += u.Gain
		elseif kind == "Luck" then
			p.Luck += u.Gain
		else
			p.Slots += u.Gain
		end
		publish(player)
		pushInventory(player)
		Economy.notify(player, "success", `{u.Name}: {u.Desc}`)
	end)

	Net.event("TrainRep").OnServerEvent:Connect(function(player, perfect)
		local p = PlayerData.get(player)
		if not p or not throttle(player, "train", 0.45) then
			return
		end
		local gain = 1 + math.floor(p.Level / 4)
		if perfect == true then
			gain = math.floor(gain * 1.5)
		end
		p.Strength += gain
		publish(player)
		Economy.addXP(player, 2)
		Economy.notify(player, "success", `+{gain} Throw Power`)
	end)

	Net.event("PlaceAnimal").OnServerEvent:Connect(function(player, uid)
		local p = PlayerData.get(player)
		if not p or typeof(uid) ~= "string" or not throttle(player, "place", 0.1) then
			return
		end
		local a = findAnimal(p, uid)
		if not a or a.placed then
			return
		end
		if placedCount(p) >= p.Slots then
			return Economy.notify(player, "error", "All team slots are full")
		end
		a.placed = true
		recalc(player)
		pushInventory(player)
	end)

	Net.event("RemoveAnimal").OnServerEvent:Connect(function(player, uid)
		local p = PlayerData.get(player)
		if not p or typeof(uid) ~= "string" or not throttle(player, "place", 0.1) then
			return
		end
		local a = findAnimal(p, uid)
		if a and a.placed then
			a.placed = false
			recalc(player)
			pushInventory(player)
		end
	end)

	Net.event("SellAnimal").OnServerEvent:Connect(function(player, uid)
		local p = PlayerData.get(player)
		if not p or typeof(uid) ~= "string" or not throttle(player, "sell", 0.2) then
			return
		end
		for i, a in p.Animals do
			if a.uid == uid then
				local price = Catalog.sellPrice(a.id, a.size)
				table.remove(p.Animals, i)
				p.Money += price
				recalc(player)
				publish(player)
				pushInventory(player)
				Economy.notify(player, "reward", `Sold {Catalog.Animals[a.id].Name} for ${Util.fmt(price)}`)
				return
			end
		end
	end)

	Net.event("EquipBest").OnServerEvent:Connect(function(player)
		local p = PlayerData.get(player)
		if not p or not throttle(player, "best", 0.5) then
			return
		end
		local sorted = table.clone(p.Animals)
		table.sort(sorted, function(x, y)
			return Catalog.income(x.id, x.size) > Catalog.income(y.id, y.size)
		end)
		for i, a in sorted do
			a.placed = i <= p.Slots
		end
		recalc(player)
		pushInventory(player)
	end)

	Net.event("CollectAll").OnServerEvent:Connect(function(player)
		local p = PlayerData.get(player)
		if not p or p.Pending < 1 or not throttle(player, "collect", 0.3) then
			return
		end
		local amount = math.floor(p.Pending)
		p.Pending -= amount
		p.Money += amount
		publish(player)
		Economy.notify(player, "reward", `Collected {Util.fmt(amount)} coins`)
	end)
end

function Economy.Start()
	for _, player in Players:GetPlayers() do
		if PlayerData.get(player) then
			refresh(player)
		end
	end
	task.spawn(function()
		while true do
			task.wait(1)
			for player, perSecond in income do
				local p = PlayerData.get(player)
				if p and perSecond > 0 then
					p.Pending += perSecond
					player:SetAttribute("Pending", p.Pending)
				end
			end
		end
	end)
end

return Economy
