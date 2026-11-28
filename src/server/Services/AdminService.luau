-- Admin Panel backend. Every request is re-authorized on the server; the client UI is only a convenience.
-- Flow for anything that changes data:  AdminRequest (validate + create pending tx)
--                                    -> AdminConfirm (YES/NO; re-verify role, target and tx, then execute once)
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Catalog = require(Shared.Catalog)
local Config = require(Shared.Config)
local Net = require(Shared.Net)
local Util = require(Shared.Util)

local Services = script.Parent
local Perms = require(Services.AdminPermissions)
local Security = require(Services.AdminSecurity)
local AdminLog = require(Services.AdminLog)
local Economy = require(Services.Economy)
local PlayerData = require(Services.PlayerData)

local AdminService = {}

local GIVE = { Strength = true, Luck = true, Money = true, Animal = true }
local PERM = { GrantAdmin = true, RevokeAdmin = true }
local pending = {} -- [txId] = tx
local pendingCount = {} -- [userId] = number
local nameCache = {} -- [userId] = name

local function fail(msg)
	return { ok = false, err = msg }
end

local function nameFor(userId)
	local online = Players:GetPlayerByUserId(userId)
	if online then
		return online.Name, online.DisplayName
	end
	local cached = nameCache[userId]
	if not cached then
		local ok, name = pcall(function()
			return Players:GetNameFromUserIdAsync(userId)
		end)
		cached = ok and name or ("User " .. userId)
		nameCache[userId] = cached
	end
	return cached, cached
end

-- Gives or removes the client-side panel (the code is only ever sent to authorized players).
local function refreshPlayer(player)
	local role = Perms.roleOf(player.UserId)
	local gui = player:FindFirstChildOfClass("PlayerGui")
	if not gui then
		return
	end
	local existing = gui:FindFirstChild("AdminClient")
	if role then
		if not existing then
			local clone = ServerStorage.AdminClient:Clone()
			clone.Name = "AdminClient"
			clone.Parent = gui
		end
		Net.event("AdminStatus"):FireClient(player, { role = role })
	elseif existing then
		Net.event("AdminStatus"):FireClient(player, { role = nil })
		task.delay(0.5, function()
			if existing.Parent then
				existing:Destroy()
			end
		end)
	end
end

local function notifyAdminsPlayersChanged()
	for _, p in Players:GetPlayers() do
		if Perms.roleOf(p.UserId) then
			Net.event("AdminPlayersChanged"):FireClient(p)
		end
	end
end

local function release(tx)
	pending[tx.id] = nil
	pendingCount[tx.adminId] = math.max(0, (pendingCount[tx.adminId] or 1) - 1)
end

local function logAction(category, player, tx, detail, result)
	AdminLog.add({
		category = category,
		adminId = player.UserId,
		adminName = player.Name,
		targetId = tx.targetId,
		targetName = tx.targetName,
		kind = tx.kind,
		detail = detail,
		result = result,
	})
end

local function request(player, kind, targetUserId, value)
	if not Security.rateLimit(player) then
		return fail("Slow down")
	end
	if typeof(kind) ~= "string" or not (GIVE[kind] or PERM[kind]) then
		return fail("Invalid request")
	end
	if not Security.role(player, PERM[kind] and "Creator" or "Admin") then
		return fail("Not authorized")
	end
	if not Util.isFinite(targetUserId) then
		return fail("Invalid target")
	end
	targetUserId = math.floor(targetUserId)
	if (pendingCount[player.UserId] or 0) >= Config.Admin.MaxPendingPerAdmin then
		return fail("Too many pending requests")
	end

	local tx = {
		id = HttpService:GenerateGUID(false),
		adminId = player.UserId,
		kind = kind,
		targetId = targetUserId,
		expires = os.clock() + Config.Admin.PendingTtl,
		state = "pending",
	}
	local target = Players:GetPlayerByUserId(targetUserId)
	local summary = { ok = true, txId = tx.id, kind = kind }

	if kind == "RevokeAdmin" then
		if targetUserId == Perms.creatorId() then
			return fail("The creator's permissions cannot be changed")
		end
		if Perms.roleOf(targetUserId) ~= "Admin" then
			return fail("That player is not an admin")
		end
	else
		if not target then
			return fail("That player is no longer in the server")
		end
		if kind == "GrantAdmin" then
			if Perms.roleOf(targetUserId) then
				return fail("That player already has admin access")
			end
		elseif kind == "Animal" then
			local animal = typeof(value) == "string" and Catalog.Animals[value]
			if not animal then
				return fail("Unknown character")
			end
			tx.animalId = animal.Id
			summary.animalName = animal.Name
			summary.rarity = Catalog.Rarities[animal.Rarity].Name
		else
			local amount = Util.amount(value, Config.Admin.Max[kind])
			if not amount then
				return fail("Enter a whole number between 1 and " .. Util.commas(Config.Admin.Max[kind]))
			end
			tx.amount = amount
			summary.amount = amount
		end
	end

	tx.targetName, tx.targetDisplay = nameFor(targetUserId)
	summary.targetName, summary.targetDisplay = tx.targetName, tx.targetDisplay
	pending[tx.id] = tx
	pendingCount[player.UserId] = (pendingCount[player.UserId] or 0) + 1
	return summary
end

local function confirm(player, txId, yes)
	local tx = typeof(txId) == "string" and pending[txId]
	if not tx or tx.adminId ~= player.UserId then
		return fail("Request not found")
	end
	if tx.state ~= "pending" then
		return fail("Already processed") -- double-click guard
	end
	tx.state = "processing"

	if yes ~= true then
		release(tx)
		return { ok = true, cancelled = true }
	end
	if os.clock() > tx.expires then
		release(tx)
		return fail("Request expired")
	end

	-- Independent re-authorization, straight from the DataStore.
	local role = Perms.fresh(player.UserId)
	local category = PERM[tx.kind] and "permission" or "action"
	if not role or (PERM[tx.kind] and role ~= "Creator") then
		release(tx)
		logAction(category, player, tx, "", "Denied: not authorized")
		return fail("Not authorized")
	end

	local detail, message = "", ""
	if tx.kind == "GrantAdmin" or tx.kind == "RevokeAdmin" then
		local ok, err
		if tx.kind == "GrantAdmin" then
			local target = Players:GetPlayerByUserId(tx.targetId)
			if not target then
				release(tx)
				logAction(category, player, tx, "", "Failed: target left")
				return fail("That player left the server")
			end
			ok, err = Perms.grant(player.UserId, tx.targetId)
			message = `{tx.targetName} is now an admin`
		else
			ok, err = Perms.revoke(player.UserId, tx.targetId)
			message = `{tx.targetName} is no longer an admin`
		end
		release(tx)
		if not ok then
			logAction(category, player, tx, "", "Failed: " .. tostring(err))
			return fail("Could not save the change. Try again.")
		end
		logAction(category, player, tx, "", "Success")
		return { ok = true, message = message }
	end

	local target = Players:GetPlayerByUserId(tx.targetId)
	if not target or not PlayerData.get(target) then
		release(tx)
		logAction(category, player, tx, "", "Failed: target left")
		return fail("That player left the server")
	end

	if tx.kind == "Strength" then
		Economy.addStrength(target, tx.amount)
		detail = Util.commas(tx.amount) .. " Strength"
	elseif tx.kind == "Luck" then
		Economy.addLuck(target, tx.amount)
		detail = Util.commas(tx.amount) .. " Luck"
	elseif tx.kind == "Money" then
		Economy.addMoney(target, tx.amount)
		detail = Util.commas(tx.amount) .. " Money"
	else
		local uid, err = Economy.giveAnimal(target, tx.animalId, "Normal")
		if not uid then
			release(tx)
			logAction(category, player, tx, tx.animalId, "Failed: " .. tostring(err))
			return fail(tostring(err))
		end
		detail = Catalog.Animals[tx.animalId].Name
	end
	release(tx)
	Economy.notify(target, "reward", `You received {detail} from an admin`)
	logAction(category, player, tx, detail, "Success")
	return { ok = true, message = `Gave {detail} to {tx.targetName}` }
end

local function permList(player)
	if not Security.role(player, "Creator") then
		return fail("Not authorized")
	end
	local out = {}
	local creator = Perms.creatorId()
	if creator then
		local name, display = nameFor(creator)
		table.insert(out, { userId = creator, name = name, display = display, role = "Creator", grantedAt = 0, grantedBy = 0, online = Players:GetPlayerByUserId(creator) ~= nil })
	end
	for _, entry in Perms.list() do
		local name, display = nameFor(entry.userId)
		entry.name, entry.display = name, display
		entry.online = Players:GetPlayerByUserId(entry.userId) ~= nil
		table.insert(out, entry)
	end
	return { ok = true, list = out }
end

local function guarded(label, fn)
	return function(player, ...)
		local ok, result = pcall(fn, player, ...)
		if ok then
			return result
		end
		warn(`[Admin] {label} error: {result}`)
		return fail("Server error")
	end
end

function AdminService.Init()
	Perms.Changed:Connect(function(userId)
		local player = Players:GetPlayerByUserId(userId)
		if player then
			refreshPlayer(player)
		end
	end)

	Net.func("AdminInit").OnServerInvoke = guarded("init", function(player)
		local role = Security.role(player, "Admin")
		if not role then
			return nil
		end
		return { role = role, isCreator = role == "Creator", max = Config.Admin.Max }
	end)

	Net.func("AdminPlayers").OnServerInvoke = guarded("players", function(player)
		if not Security.role(player, "Admin") then
			return fail("Not authorized")
		end
		local list = {}
		for _, p in Players:GetPlayers() do
			table.insert(list, { userId = p.UserId, name = p.Name, display = p.DisplayName })
		end
		return { ok = true, list = list }
	end)

	Net.func("AdminRequest").OnServerInvoke = guarded("request", request)
	Net.func("AdminConfirm").OnServerInvoke = guarded("confirm", confirm)
	Net.func("AdminPermList").OnServerInvoke = guarded("permList", permList)

	Net.func("AdminLogs").OnServerInvoke = guarded("logs", function(player, category)
		if category ~= "action" and category ~= "permission" then
			return fail("Invalid log")
		end
		if not Security.role(player, category == "permission" and "Creator" or "Admin") then
			return fail("Not authorized")
		end
		return { ok = true, list = AdminLog.list(category) }
	end)

	Players.PlayerAdded:Connect(function(player)
		task.spawn(function()
			if not player:WaitForChild("PlayerGui", 20) then
				return
			end
			Perms.fresh(player.UserId)
			if player.Parent then
				refreshPlayer(player)
			end
			notifyAdminsPlayersChanged()
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		Security.forget(player)
		pendingCount[player.UserId] = nil
		for id, tx in pending do
			if tx.adminId == player.UserId then
				pending[id] = nil
			end
		end
		task.defer(notifyAdminsPlayersChanged)
	end)
end

function AdminService.Start()
	for _, player in Players:GetPlayers() do
		task.spawn(function()
			Perms.fresh(player.UserId)
			refreshPlayer(player)
		end)
	end
end

return AdminService
