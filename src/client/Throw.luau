-- Tap THROW (or E / right trigger / the checkered launch strip prompt) to throw at full power.
-- Distance comes from Throw Power; the server decides where it lands and WHO shows up.
-- The visitor stays a mystery silhouette until it reaches your base (anime "who is it?!" reveal).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.Shared
local Config, Catalog, Theme = require(Shared.Config), require(Shared.Catalog), require(Shared.Theme)
local Net, ThrowMath, Kit = require(Shared.Net), require(Shared.ThrowMath), require(Shared.Kit)
local State = require(script.Parent.State)
local Windows = require(script.Parent.UI.Windows)
local HUD = require(script.Parent.UI.HUD)
local Reveal = require(script.Parent.UI.Reveal)
local C, F = Theme.Color, Theme.Font

-- Roblox's own R15 "tool slash" overhead swing: a public animation that reads as a throwing motion
-- and replicates to everyone. (A custom clip would need publishing under your account.)
local SWING = "rbxassetid://522635514"

local Throw = {}
local lastThrow = 0

local function newPart(props)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	for k, v in props do
		p[k] = v
	end
	p.Parent = Workspace
	return p
end

local function playSwing()
	local character = Players.LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		return
	end
	local anim = Instance.new("Animation")
	anim.AnimationId = SWING
	local ok, track = pcall(function()
		return animator:LoadAnimation(anim)
	end)
	if ok and track then
		track.Priority = Enum.AnimationPriority.Action
		track:Play(0.05, 1, 1.5)
	end
end

local function punchCamera()
	local cam = Workspace.CurrentCamera
	if not cam then
		return
	end
	local base = cam.FieldOfView
	Kit.tween(cam, 0.12, { FieldOfView = base + 7 })
	task.delay(0.14, function()
		Kit.tween(cam, 0.35, { FieldOfView = base })
	end)
end

-- Landing burst in neutral pink so the visitor's rarity stays secret.
local function landingEffect(position)
	local ring = newPart({
		Shape = Enum.PartType.Cylinder,
		Material = Enum.Material.Neon,
		Color = C.Pumpkin,
		Transparency = 0.2,
		Size = Vector3.new(0.3, 2, 2),
		CFrame = CFrame.new(position + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.pi / 2),
	})
	Kit.tween(ring, 0.6, { Size = Vector3.new(0.3, 16, 16), Transparency = 1 })

	local burst = newPart({ Transparency = 1, Size = Vector3.one, Position = position + Vector3.new(0, 1, 0) })
	local emitter = Instance.new("ParticleEmitter")
	emitter.Rate = 0
	emitter.Speed = NumberRange.new(14, 28)
	emitter.Lifetime = NumberRange.new(0.5, 1)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Size = NumberSequence.new(1, 0)
	emitter.Color = ColorSequence.new(C.Pumpkin, C.White)
	emitter.LightEmission = 1
	emitter.Acceleration = Vector3.new(0, -40, 0)
	emitter.Parent = burst
	emitter:Emit(36)
	task.delay(1.2, function()
		ring:Destroy()
		burst:Destroy()
	end)
end

-- Spinning magic circle where the food landed. Returns a function that removes it.
local function summonCircle(position)
	local folder = Instance.new("Folder")
	folder.Parent = Workspace
	local function disc(diameter, alpha)
		local d = newPart({
			Shape = Enum.PartType.Cylinder,
			Material = Enum.Material.Neon,
			Color = C.Pumpkin,
			Transparency = alpha,
			Size = Vector3.new(0.25, diameter, diameter),
		})
		d.Parent = folder
		return d
	end
	local outer, inner = disc(12, 0.35), disc(8, 0.2)
	local barA = newPart({ Material = Enum.Material.Neon, Color = C.White, Transparency = 0.25, Size = Vector3.new(16, 0.2, 0.6) })
	local barB = newPart({ Material = Enum.Material.Neon, Color = C.White, Transparency = 0.25, Size = Vector3.new(16, 0.2, 0.6) })
	barA.Parent, barB.Parent = folder, folder
	local t0 = os.clock()
	local conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		local base = CFrame.new(position + Vector3.new(0, 0.4, 0))
		outer.CFrame = base * CFrame.Angles(0, t * 1.4, 0) * CFrame.Angles(0, 0, math.pi / 2)
		inner.CFrame = base * CFrame.Angles(0, -t * 2, 0) * CFrame.Angles(0, 0, math.pi / 2) + Vector3.new(0, 0.05, 0)
		barA.CFrame = base * CFrame.Angles(0, t * 2.4, 0) + Vector3.new(0, 0.1, 0)
		barB.CFrame = base * CFrame.Angles(0, t * 2.4 + math.pi / 2, 0) + Vector3.new(0, 0.1, 0)
	end)
	return function()
		conn:Disconnect()
		folder:Destroy()
	end
end

local function silhouette(position)
	local anchor = newPart({ Transparency = 1, Size = Vector3.one, Position = position + Vector3.new(0, 2, 0) })
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(120, 120)
	gui.AlwaysOnTop = true
	gui.Parent = anchor
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Color3.fromRGB(18, 14, 34)
	frame.Parent = gui
	Kit.corner(frame, 60)
	Kit.stroke(frame, C.White, 5)
	Kit.label({ Parent = frame, Text = "?", Font = F.Display, TextSize = 80, TextColor3 = C.White })
	local pulse = Instance.new("UIScale")
	pulse.Parent = frame
	task.spawn(function()
		while anchor.Parent do
			Kit.tween(pulse, 0.35, { Scale = 1.14 }, Enum.EasingStyle.Sine)
			task.wait(0.35)
			Kit.tween(pulse, 0.35, { Scale = 1 }, Enum.EasingStyle.Sine)
			task.wait(0.35)
		end
	end)
	return anchor
end

local function fly(result)
	task.wait(0.22) -- let the swing wind up before the food leaves the hand
	local food = Catalog.Foods[result.Food]
	local flat = (result.To - result.From) * Vector3.new(1, 0, 1)
	local dist = flat.Magnitude
	local duration = ThrowMath.flightTime(dist)

	local ball = newPart({ Transparency = 1, Size = Vector3.one * 1.5, Position = result.From })
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(70, 70)
	billboard.AlwaysOnTop = true
	billboard.Parent = ball
	local face = Kit.icon({ Parent = billboard, Key = food and food.Icon, Emoji = food and food.Emoji or "🍙", TextSize = 46 })
	Kit.speedLines(Windows.overlay, C.White, 0.35)

	local t = 0
	while t < 1 do
		t += RunService.RenderStepped:Wait() / duration
		local a = math.min(t, 1)
		ball.Position = ThrowMath.arc(result.From, result.To, a, dist)
		face.Rotation = a * 720
	end
	ball:Destroy()
	landingEffect(result.To)

	-- who is it?! a silhouette rises out of the summoning circle...
	local stopCircle = summonCircle(result.To)
	local sil = silhouette(result.To)
	Kit.tween(sil, 0.5, { Position = result.To + Vector3.new(0, 9, 0) }, Enum.EasingStyle.Back)
	task.wait(0.7)

	-- ...and dashes to your base before the reveal
	local slot = State.get("Slot")
	local target = (slot > 0 and ThrowMath.spot(slot) or result.From) + Vector3.new(0, 6, -2)
	local from = sil.Position
	local travel = math.clamp(dist / 60, 1, 2.6)
	local s = 0
	while s < 1 do
		s += RunService.RenderStepped:Wait() / travel
		local a = math.min(s, 1)
		sil.Position = from:Lerp(target, a) + Vector3.new(0, math.sin(a * math.pi * 6) * 0.9, 0)
	end
	sil:Destroy()
	stopCircle()
	Kit.speedLines(Windows.overlay, C.Pumpkin, 0.5)
	Reveal.show(result)
end

function Throw.throwNow()
	local player = Players.LocalPlayer
	local inv = State.Inv
	if inv.Equipped == "" or (inv.Foods[inv.Equipped] or 0) < 1 then
		Windows.toast("error", "No food equipped. Buy some in the Shop!")
		return
	end
	if os.clock() - lastThrow < Config.ThrowCooldown then
		return
	end
	local slot = State.get("Slot")
	if slot == 0 then
		return
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local spot = ThrowMath.spot(slot)
	if not root or ((root.Position - spot) * Vector3.new(1, 0, 1)).Magnitude > 26 then
		Windows.toast("info", "Walk to your checkered launch strip first")
		return
	end
	lastThrow = os.clock()
	playSwing()
	punchCamera()
	Net.event("ThrowFood"):FireServer(inv.Equipped, Workspace.CurrentCamera.CFrame.LookVector, 1)
	HUD.Throw.SetStyle("locked")
	task.delay(Config.ThrowCooldown, HUD.refresh)
end

function Throw.Init()
	HUD.Throw.Face.Activated:Connect(Throw.throwNow)
	ContextActionService:BindAction("TFFA_Throw", function(_, state)
		if state == Enum.UserInputState.Begin then
			Throw.throwNow()
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.E, Enum.KeyCode.ButtonR2)

	Net.event("ThrowResult").OnClientEvent:Connect(function(result)
		task.spawn(fly, result)
	end)
end

return Throw
