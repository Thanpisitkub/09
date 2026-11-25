-- The Admin whitelist. Only the original creator is ever Creator; everyone else on the list is Admin.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local GroupService = game:GetService("GroupService")
local DataStoreService = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local store = DataStoreService:GetDataStore("TFFA_AdminPerms_v1")
local KEY = "Whitelist"
local TOPIC = "TFFA_AdminPerms"

local Perms = {}
local whitelist = {} -- [userId: number] = { role, grantedAt, grantedBy }
local creatorId = nil
local changedEvent = Instance.new("BindableEvent")
Perms.Changed = changedEvent.Event -- (userId, role | nil)

local function resolveCreator()
	if RunService:IsStudio() and Config.Admin.StudioCreatorUserId ~= 0 then
		return Config.Admin.StudioCreatorUserId
	end
	if game.CreatorType == Enum.CreatorType.Group then
		local ok, info = pcall(function()
			return GroupService:GetGroupInfoAsync(game.CreatorId)
		end)
		return ok and info.Owner and info.Owner.Id or nil
	end
	return game.CreatorId ~= 0 and game.CreatorId or nil
end

local function decode(raw)
	local out = {}
	if typeof(raw) == "table" then
		for key, entry in raw do
			local id = tonumber(key)
			if id and typeof(entry) == "table" and id ~= creatorId then
				out[id] = { role = "Admin", grantedAt = entry.grantedAt or 0, grantedBy = entry.grantedBy or 0 }
			end
		end
	end
	return out
end

local function encode(map)
	local out = {}
	for id, entry in map do
		out[tostring(id)] = entry
	end
	return out
end

function Perms.creatorId()
	return creatorId
end

function Perms.roleOf(userId)
	if creatorId and userId == creatorId then
		return "Creator"
	end
	return whitelist[userId] and "Admin" or nil
end

-- Re-reads one user's role from the DataStore (used before privileged work and on join).
function Perms.fresh(userId)
	local ok, raw = pcall(function()
		return store:GetAsync(KEY)
	end)
	if ok then
		local map = decode(raw)
		local entry = map[userId]
		if entry then
			whitelist[userId] = entry
		else
			whitelist[userId] = nil
		end
	end
	return Perms.roleOf(userId)
end

function Perms.reload()
	local ok, raw = pcall(function()
		return store:GetAsync(KEY)
	end)
	if ok then
		whitelist = decode(raw)
	else
		warn("[AdminPermissions] could not load whitelist: " .. tostring(raw))
	end
end

local function publish(userId, role)
	task.spawn(function()
		pcall(function()
			MessagingService:PublishAsync(TOPIC, { userId = userId, role = role, job = game.JobId })
		end)
	end)
end

local function mutate(fn)
	local ok, err = pcall(function()
		store:UpdateAsync(KEY, function(old)
			local map = decode(old)
			fn(map)
			return encode(map)
		end)
	end)
	return ok, err
end

-- Callers must already have verified that `actorId` is the Creator.
function Perms.grant(actorId, targetId)
	if actorId ~= creatorId or targetId == creatorId then
		return false, "Not allowed"
	end
	local entry = { role = "Admin", grantedAt = os.time(), grantedBy = actorId }
	local ok, err = mutate(function(map)
		map[targetId] = map[targetId] or entry
	end)
	if not ok then
		return false, tostring(err)
	end
	whitelist[targetId] = whitelist[targetId] or entry
	changedEvent:Fire(targetId, "Admin")
	publish(targetId, "Admin")
	return true
end

function Perms.revoke(actorId, targetId)
	if actorId ~= creatorId or targetId == creatorId then
		return false, "Not allowed"
	end
	local ok, err = mutate(function(map)
		map[targetId] = nil
	end)
	if not ok then
		return false, tostring(err)
	end
	whitelist[targetId] = nil
	changedEvent:Fire(targetId, nil)
	publish(targetId, nil)
	return true
end

function Perms.list()
	local out = {}
	for id, entry in whitelist do
		table.insert(out, { userId = id, role = entry.role, grantedAt = entry.grantedAt, grantedBy = entry.grantedBy })
	end
	table.sort(out, function(a, b)
		return a.grantedAt < b.grantedAt
	end)
	return out
end

function Perms.Init()
	creatorId = resolveCreator()
	if not creatorId then
		warn("[AdminPermissions] no creator resolved: nobody can use the Admin Panel (see Config.Admin.StudioCreatorUserId)")
	end
end

function Perms.Start()
	Perms.reload()
	task.spawn(function()
		local ok, err = pcall(function()
			MessagingService:SubscribeAsync(TOPIC, function(message)
				local data = message.Data
				if typeof(data) ~= "table" or data.job == game.JobId or typeof(data.userId) ~= "number" then
					return
				end
				if data.userId == creatorId then
					return
				end
				if data.role == "Admin" then
					whitelist[data.userId] = whitelist[data.userId]
						or { role = "Admin", grantedAt = os.time(), grantedBy = creatorId or 0 }
				else
					whitelist[data.userId] = nil
				end
				changedEvent:Fire(data.userId, whitelist[data.userId] and "Admin" or nil)
			end)
		end)
		if not ok then
			warn("[AdminPermissions] cross-server sync unavailable: " .. tostring(err))
		end
	end)
end

return Perms
