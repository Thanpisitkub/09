-- Client entry (Script, RunContext = Client, lives in ReplicatedStorage so it runs exactly once).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
player:WaitForChild("PlayerGui")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
Net.event("RequestState") -- wait until the server has built the remotes

local UI = script.Parent:WaitForChild("UI")
local State = require(script.Parent:WaitForChild("State"))
local Windows = require(UI.Windows)
local Reveal = require(UI.Reveal)

local ORDER = {
	State, Windows, Reveal,
	require(UI.Shop), require(UI.FoodBag), require(UI.Animals), require(UI.Collection),
	require(UI.Areas), require(UI.Upgrades), require(UI.Settings),
	require(UI.HUD), require(script.Parent:WaitForChild("WorldClient")), require(script.Parent:WaitForChild("Throw")),
}

for _, mod in ORDER do
	if mod.Init then
		local ok, err = pcall(mod.Init)
		if not ok then
			warn("[Client] init failed: " .. tostring(err))
		end
	end
end

Net.event("Notify").OnClientEvent:Connect(function(kind, text)
	if kind == "levelup" then
		Reveal.levelUp(text)
	else
		Windows.toast(kind, text)
	end
end)

State.request() -- ask for the first snapshot once every listener is connected
