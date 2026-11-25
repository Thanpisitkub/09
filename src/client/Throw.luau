-- Hold THROW (or E / right trigger) to charge, release to throw toward the camera direction.
-- The client only previews and animates; the server decides what actually lands.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.Shared
local Config, Catalog, Theme = require(Shared.Config), require(Shared.Catalog), require(Shared.Theme)
local Net, ThrowMath, Kit = require(Shared.Net), require(Shared.ThrowMath), require(Shared.Kit)
local State = require(script.Parent.State)
local Windows = require(script.Parent.UI.Windows)
local HUD = require(script.Parent.UI.HUD)
local Reveal = require(script.Parent.UI.Reveal)
local Settings = require(script.Parent.UI.Settings)
local C = Theme.Color

local Throw = {}

local function makeMarker()
	local part = Instance.new("Part")
	part.Name = "LandingMarker"
	part.Shape = Enum.PartType.Cylinder
	part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch, part.CastShadow = true, false, false, false, false
	part.Material = Enum.Material.Neon
	part.Color = C.Pumpkin
	part.Transparency = 0.35
	part.Size = Vector3.new(0.3, 6, 6)
	return part
end

local function landingEffect(position, color)
	local ring = Instance.new("Part")
	ring.Anchored, ring.CanCollide, ring.CanQuery, ring.CanTouch, ring.CastShadow = true, false, false, false, false
	ring.Shape = Enum.PartType.Cylinder
	ring.Material = Enum.Material.Neon
	ring.Color = color
	ring.Transparency = 0.2
	ring.Size = Vector3.new(0.3, 2, 2)
	ring.CFrame = CFrame.new(position + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	ring.Parent = Workspace
	Kit.tween(ring, 0.6, { Size = Vector3.new(0.3, 14, 14), Transparency = 1 })

	local burst = Instance.new("Part")
	burst.Anchored, burst.CanCollide, burst.CanQuery, burst.CanTouch = true, false, false, false
	burst.Transparency = 1
	burst.Size = Vector3.one
	burst.Position = position + Vector3.new(0, 1, 0)
	burst.Parent = Workspace
	local emitter = Instance.new("ParticleEmitter")
	emitter.Rate = 0
	emitter.Speed = NumberRange.new(14, 26)
	emitter.Lifetime = NumberRange.new(0.5, 0.9)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Size = NumberSequence.new(0.9, 0)
	emitter.Color = ColorSequence.new(color)
	emitter.LightEmission = 1
	emitter.Acceleration = Vector3.new(0, -40, 0)
	emitter.Parent = burst
	emitter:Emit(32)
	task.delay(1.2, function()
		ring:Destroy()
		burst:Destroy()
	end)
end

local function fly(result)
	local food = Catalog.Foods[result.Food]
	local animal = Catalog.Animals[result.Animal]
	local flat = (result.To - result.From) * Vector3.new(1, 0, 1)
	local dist = flat.Magnitude
	local duration = ThrowMath.flightTime(dist)

	local ball = Instance.new("Part")
	ball.Anchored, ball.CanCollide, ball.CanQuery, ball.CanTouch, ball.CastShadow = true, false, false, false, false
	ball.Transparency = 1
	ball.Size = Vector3.one * 1.5
	ball.Position = result.From
	ball.Parent = Workspace
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(64, 64)
	billboard.AlwaysOnTop = true
	billboard.Parent = ball
	local face = Kit.label({ Parent = billboard, Text = food and food.Emoji or "🍎", TextSize = 46 })

	local t = 0
	while t < 1 do
		t += RunService.RenderStepped:Wait() / duration
		local a = math.min(t, 1)
		ball.Position = ThrowMath.arc(result.From, result.To, a, dist)
		face.Rotation = a * 720
	end
	ball:Destroy()
	landingEffect(result.To, Catalog.Rarities[animal.Rarity].Color)

	-- the attracted animal hops out at the landing spot
	local critter = Instance.new("Part")
	critter.Anchored, critter.CanCollide, critter.CanQuery, critter.CanTouch = true, false, false, false
	critter.Transparency = 1
	critter.Size = Vector3.one
	critter.Position = result.To + Vector3.new(0, 3, 0)
	critter.Parent = Workspace
	local cg = Instance.new("BillboardGui")
	cg.Size = UDim2.fromOffset(90, 90)
	cg.StudsOffset = Vector3.new(0, 0, 0)
	cg.AlwaysOnTop = true
	cg.Parent = critter
	Kit.label({ Parent = cg, Text = animal.Emoji, TextSize = 70 })
	for _ = 1, 3 do
		Kit.tween(critter, 0.22, { Position = result.To + Vector3.new(0, 7, 0) }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		task.wait(0.22)
		Kit.tween(critter, 0.22, { Position = result.To + Vector3.new(0, 3, 0) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.wait(0.22)
	end
	critter:Destroy()
	Reveal.show(result)
end

function Throw.Init()
	local player = Players.LocalPlayer
	local charging, startedAt, lastThrow = false, 0, 0
	local marker = makeMarker()

	local function power()
		local x = ((os.clock() - startedAt) / 1.3) % 2
		return math.max(0.1, x < 1 and x or 2 - x)
	end
	local function origin()
		local slot = State.get("Slot")
		if slot == 0 then
			return nil
		end
		return ThrowMath.spot(slot) + Vector3.new(0, 3, 0)
	end
	local function nearSpot()
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local o = origin()
		return root ~= nil and o ~= nil and ((root.Position - o) * Vector3.new(1, 0, 1)).Magnitude <= 26
	end

	local function stopCharging()
		charging = false
		HUD.MeterFrame.Visible = false
		marker.Parent = nil
	end

	local function begin()
		if charging or os.clock() - lastThrow < Config.ThrowCooldown then
			return
		end
		local inv = State.Inv
		if inv.Equipped == "" or (inv.Foods[inv.Equipped] or 0) < 1 then
			Windows.toast("error", "No food equipped. Buy some in the Shop!")
			return
		end
		if not nearSpot() then
			Windows.toast("info", "Walk to your glowing THROW SPOT first")
			return
		end
		charging, startedAt = true, os.clock()
		HUD.MeterFrame.Visible = true
	end

	local function release()
		if not charging then
			return
		end
		local p = power()
		stopCharging()
		if not origin() then
			return
		end
		lastThrow = os.clock()
		Net.event("ThrowFood"):FireServer(State.Inv.Equipped, Workspace.CurrentCamera.CFrame.LookVector, p)
		HUD.Throw.SetStyle("locked")
		task.delay(Config.ThrowCooldown, HUD.refresh)
	end

	HUD.Throw.Face.MouseButton1Down:Connect(begin)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			release()
		end
	end)
	ContextActionService:BindAction("TFFA_Throw", function(_, state)
		if state == Enum.UserInputState.Begin then
			begin()
		elseif state == Enum.UserInputState.End then
			release()
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.E, Enum.KeyCode.ButtonR2)

	RunService.RenderStepped:Connect(function()
		if not charging then
			return
		end
		local o = origin()
		if not o then
			return stopCharging()
		end
		local p = power()
		local look = Workspace.CurrentCamera.CFrame.LookVector
		local target, dist = ThrowMath.target(o, ThrowMath.aim(look), State.get("Strength"), p)
		local zone = Catalog.zoneAt(math.max(0, ThrowMath.trackDistance(target)))
		HUD.Meter.Fill.Size = UDim2.fromScale(p, 1)
		HUD.Meter.Fill.BackgroundColor3 = C.Leaf:Lerp(C.Berry, p)
		HUD.DistLabel.Text = string.format("%d studs · %s", dist, Catalog.Areas[zone].Name)

		if Settings.Values.Marker then
			local pulse = 5 + math.sin(os.clock() * 8) * 0.6
			marker.Color = Catalog.Areas[zone].Color
			marker.Size = Vector3.new(0.3, pulse * 2, pulse * 2)
			marker.CFrame = CFrame.new(target.X, 0.3, target.Z) * CFrame.Angles(0, 0, math.pi / 2)
			marker.Parent = Workspace
		else
			marker.Parent = nil
		end
	end)

	Net.event("ThrowResult").OnClientEvent:Connect(function(result)
		task.spawn(fly, result)
	end)
end

return Throw
