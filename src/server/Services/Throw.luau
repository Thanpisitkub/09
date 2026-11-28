-- Server-authoritative throwing. Food always starts at the owner's throw spot and flies down the runway;
-- WHERE it lands (distance) decides the zone, the food tier + Luck decide which animal comes.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Catalog = require(Shared.Catalog)
local Config = require(Shared.Config)
local Net = require(Shared.Net)
local ThrowMath = require(Shared.ThrowMath)
local Util = require(Shared.Util)
local PlayerData = require(script.Parent.PlayerData)
local Economy = require(script.Parent.Economy)
local Plots = require(script.Parent.Plots)

local Throw = {}
local last = {} -- [Player] = os.clock() of last accepted throw
local rng = Random.new()
local MAX_FROM_SPOT = 28

local function weightedPick(items, weightOf)
	local total = 0
	for _, item in items do
		total += weightOf(item)
	end
	local roll = rng:NextNumber() * total
	for _, item in items do
		roll -= weightOf(item)
		if roll <= 0 then
			return item
		end
	end
	return items[#items]
end

local function rollAnimal(area, food, luck)
	local candidates = {}
	for _, id in area.Animals do
		table.insert(candidates, Catalog.Animals[id])
	end
	return weightedPick(candidates, function(a)
		local r = a.Rarity
		local luckMult = 1 + (luck - 1) * 0.02 * (r - 1)
		return Catalog.RarityWeight[r] * food.Boost ^ (r - 1) * luckMult
	end)
end

local function rollSize(luck)
	return weightedPick(Catalog.Sizes, function(s)
		return s.Weight * math.max(0.05, 1 + (luck - 1) * 0.005 * (s.Index - 3))
	end)
end

function Throw.Init()
	Players.PlayerRemoving:Connect(function(player)
		last[player] = nil
	end)

	Net.event("ThrowFood").OnServerEvent:Connect(function(player, foodId, look, power)
		local p = PlayerData.get(player)
		if not p or typeof(foodId) ~= "string" or typeof(look) ~= "Vector3" or not Util.isFinite(power) then
			return
		end
		if look.X ~= look.X or look.Y ~= look.Y or look.Z ~= look.Z then
			return
		end
		local now = os.clock()
		if last[player] and now - last[player] < Config.ThrowCooldown * 0.9 then
			return
		end

		local slot = Plots.slotOf(player)
		local food = Catalog.Foods[foodId]
		if not slot then
			return
		end
		if not food or (p.Foods[foodId] or 0) < 1 then
			return Economy.notify(player, "error", "You have no food equipped")
		end
		if #p.Animals >= Config.MaxAnimals then
			return Economy.notify(player, "error", "Team storage is full")
		end
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not root or not humanoid or humanoid.Health <= 0 then
			return
		end
		local spot = ThrowMath.spot(slot)
		local offset = (root.Position - spot) * Vector3.new(1, 0, 1)
		if offset.Magnitude > MAX_FROM_SPOT then
			return Economy.notify(player, "info", "Walk to your glowing THROW SPOT first")
		end
		last[player] = now

		local dir = ThrowMath.aim(look)
		local from = spot + Vector3.new(0, 3, 0)
		local target, dist = ThrowMath.target(from, dir, p.Strength, power)
		local to = Vector3.new(target.X, 0.6, target.Z)
		local trackDist = math.max(0, ThrowMath.trackDistance(to))
		local zone = Catalog.zoneAt(trackDist)

		p.Foods[foodId] -= 1
		if p.Foods[foodId] <= 0 then
			p.Foods[foodId] = nil
			if p.Equipped == foodId then
				p.Equipped = next(p.Foods) or ""
			end
		end
		p.TotalThrows += 1
		p.SelectedArea = zone
		p.AreaMax = math.max(p.AreaMax, zone)

		-- Throwing farther raises Luck a little (up to +50% at the end of the runway).
		local lastStart = Catalog.Areas[#Catalog.Areas].StartDist
		local effectiveLuck = p.Luck * (1 + 0.5 * math.min(1, trackDist / lastStart))

		local animal = rollAnimal(Catalog.Areas[zone], food, effectiveLuck)
		local size = rollSize(effectiveLuck)
		local uid, isNew = Economy.giveAnimal(player, animal.Id, size.Name)
		local xp = 8 + food.Tier * 4 + animal.Rarity * 3 + zone * 2
		Economy.addXP(player, xp)

		Net.event("ThrowResult"):FireClient(player, {
			Food = foodId,
			From = from,
			To = to,
			Dist = dist,
			Zone = zone,
			Animal = animal.Id,
			Size = size.Name,
			Uid = uid,
			New = isNew == true,
			Xp = xp,
		})
	end)
end

return Throw
