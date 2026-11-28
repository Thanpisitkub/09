-- Client side of the map: proximity prompts open windows, and fog / ambient light follow the zone you are in.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage.Shared
local Catalog, ThrowMath, ZoneLook = require(Shared.Catalog), require(Shared.ThrowMath), require(Shared.ZoneLook)
local Windows = require(script.Parent.UI.Windows)

local WorldClient = {}

function WorldClient.Init()
	local player = Players.LocalPlayer

	ProximityPromptService.PromptTriggered:Connect(function(prompt)
		if prompt:GetAttribute("Action") == "Throw" then
			require(script.Parent.Throw).throwNow()
			return
		end
		local window = prompt:GetAttribute("Window")
		if window then
			Windows.toggle(window)
		end
	end)

	local atmosphere = Lighting:WaitForChild("ZoneAtmosphere", 15)
	local current = 0
	local clock = 0
	RunService.Heartbeat:Connect(function(dt)
		clock += dt
		if clock < 0.25 then
			return
		end
		clock = 0
		local cam = Workspace.CurrentCamera
		if not cam then
			return
		end
		local zone = Catalog.zoneAt(math.max(0, ThrowMath.trackDistance(cam.CFrame.Position)))
		if zone == current then
			return
		end
		current = zone
		player:SetAttribute("Zone", zone)
		local look = ZoneLook[zone]
		local info = TweenInfo.new(1.6, Enum.EasingStyle.Sine)
		TweenService:Create(Lighting, info, { OutdoorAmbient = look.Ambient, Ambient = look.Ambient }):Play()
		if atmosphere then
			TweenService:Create(atmosphere, info, { Color = look.Fog, Decay = look.Fog }):Play()
		end
	end)
end

return WorldClient
