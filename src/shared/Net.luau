-- Remotes are created in code by the server; clients wait for them.
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EVENTS = {
	"RequestState", "Inventory", "Notify", "ThrowFood", "ThrowResult",
	"BuyFood", "EquipFood", "UpgradeStat", "TrainRep",
	"PlaceAnimal", "RemoveAnimal", "SellAnimal", "EquipBest", "CollectAll",
	"AdminStatus", "AdminPlayersChanged",
}
local FUNCTIONS = { "AdminInit", "AdminPlayers", "AdminRequest", "AdminConfirm", "AdminPermList", "AdminLogs" }

local Net = {}
local folder

function Net.init()
	assert(RunService:IsServer(), "Net.init is server-only")
	folder = Instance.new("Folder")
	folder.Name = "Remotes"
	for _, name in EVENTS do
		local r = Instance.new("RemoteEvent")
		r.Name = name
		r.Parent = folder
	end
	for _, name in FUNCTIONS do
		local r = Instance.new("RemoteFunction")
		r.Name = name
		r.Parent = folder
	end
	folder.Parent = ReplicatedStorage
end

local function get()
	if not folder then
		folder = ReplicatedStorage:WaitForChild("Remotes")
	end
	return folder
end

function Net.event(name)
	return get():WaitForChild(name)
end

Net.func = Net.event

return Net
