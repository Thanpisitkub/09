-- Server entry point. One Script boots every service in two phases:
--   Init  = set up own state and connect listeners (never yields, never calls other services)
--   Start = begin running (may yield, may call other services)
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)
Net.init()

local Services = ServerScriptService:WaitForChild("Services")
local ORDER = { "PlayerData", "AdminLog", "AdminPermissions", "WorldBuilder", "Economy", "Plots", "Throw", "AdminService" }

local loaded = {}
for _, name in ORDER do
	local ok, mod = pcall(require, Services:FindFirstChild(name))
	if ok then
		loaded[name] = mod
	else
		warn(`[Boot] failed to require {name}: {mod}`)
	end
end

for _, phase in { "Init", "Start" } do
	for _, name in ORDER do
		local mod = loaded[name]
		if mod and mod[phase] then
			local ok, err = pcall(mod[phase])
			if not ok then
				warn(`[Boot] {name}.{phase} failed: {err}`)
			end
		end
	end
end
