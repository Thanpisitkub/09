-- Client mirror of server state: numbers arrive as Player attributes, tables via the Inventory event.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.Shared.Net)

local player = Players.LocalPlayer
local changed = Instance.new("BindableEvent")

local State = {}
State.Changed = changed.Event -- fires (key)
State.Inv = { Foods = {}, Equipped = "", Animals = {}, Discovered = {}, Upgrades = {} }

local ATTRS = {
	"Money", "Strength", "Luck", "Level", "XP", "XPNext", "Pending", "Income",
	"Slots", "Placed", "AreaMax", "SelectedArea", "TotalThrows", "TotalAnimals", "Slot", "Zone",
}

function State.get(name)
	return player:GetAttribute(name) or 0
end

function State.foodCount(id)
	return State.Inv.Foods[id] or 0
end

function State.Init()
	for _, key in ATTRS do
		player:GetAttributeChangedSignal(key):Connect(function()
			changed:Fire(key)
		end)
	end
	Net.event("Inventory").OnClientEvent:Connect(function(inv)
		State.Inv = inv
		changed:Fire("Inventory")
	end)
end

function State.request()
	Net.event("RequestState"):FireServer()
end

return State
