-- Builds the whole map in code (no Studio needed): one long runway of 12 zones, a hub with 10 player plots,
-- distance signs, boundary walls and lighting. Everything lives in Workspace/World.
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config, Catalog = require(Shared.Config), require(Shared.Catalog)
local ThrowMath, ZoneLook = require(Shared.ThrowMath), require(Shared.ZoneLook)

local W = Config.World
local WorldBuilder = {}
WorldBuilder.Plots = {} -- [slot] = { Model, Spawn, SignLabel, Pen = Vector3, PenHalf = Vector2 }

local WIDTH = W.Slots * W.SlotSpacing + W.WidthPadding
local TRACK_END = W.ZoneStarts[#W.ZoneStarts] + W.LastZoneLength
local rng = Random.new(20261122)

local function c(h)
	return Color3.fromHex(h)
end

local function part(parent, o)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	p.Size = o.Size or Vector3.one
	for k, v in o do
		if k ~= "Size" then
			p[k] = v
		end
	end
	p.Parent = parent
	return p
end

local UP = CFrame.Angles(0, 0, math.pi / 2) -- turns a cylinder (axis = X) upright

local function cylinder(parent, x, y, z, height, diameter, color, mat)
	return part(parent, {
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(height, diameter, diameter),
		CFrame = CFrame.new(x, y, z) * UP,
		Color = color,
		Material = mat or Enum.Material.SmoothPlastic,
	})
end

local function ball(parent, x, y, z, dx, dy, dz, color, mat, collide)
	return part(parent, {
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(dx, dy or dx, dz or dx),
		Position = Vector3.new(x, y, z),
		Color = color,
		Material = mat or Enum.Material.SmoothPlastic,
		CanCollide = collide ~= false,
	})
end

local function block(parent, x, y, z, sx, sy, sz, color, mat, rot)
	return part(parent, {
		Size = Vector3.new(sx, sy, sz),
		CFrame = CFrame.new(x, y, z) * (rot or CFrame.new()),
		Color = color,
		Material = mat or Enum.Material.SmoothPlastic,
	})
end

local function billboard(adornee, text, size, color, maxDistance, offsetY)
	local gui = Instance.new("BillboardGui")
	gui.Size = size
	gui.StudsOffset = Vector3.new(0, offsetY or 0, 0)
	gui.MaxDistance = maxDistance or 300
	gui.LightInfluence = 0
	gui.Parent = adornee
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = c("14363B")
	stroke.Parent = label
	return label
end

local function pick(list)
	return list[rng:NextInteger(1, #list)]
end

local function jitter(color, amount)
	local h, s, v = color:ToHSV()
	return Color3.fromHSV(h, s, math.clamp(v + (rng:NextNumber() - 0.5) * amount, 0, 1))
end

-------------------------------------------------------------------------------- scenery per zone
-- Each generator places ONE prop at (x, z). Props are scenery only.
local P = {}

function P.tree(f, x, z, trunk, leaves, h, d)
	cylinder(f, x, h / 2, z, h, 1.6, trunk, Enum.Material.Wood)
	ball(f, x, h + d * 0.3, z, d, d * 0.85, d, jitter(leaves, 0.12), Enum.Material.Grass)
end

local ZONE_PROPS = {
	function(f, x, z) -- 1 Green Meadow
		local r = rng:NextNumber()
		if r < 0.3 then
			P.tree(f, x, z, c("7A5230"), c("3FA34D"), rng:NextInteger(6, 9), rng:NextInteger(7, 10))
		elseif r < 0.6 then
			ball(f, x, 1.4, z, 3.5, 2.8, 3.5, jitter(c("4FB85C"), 0.15), Enum.Material.Grass)
		else
			ball(f, x, 0.6, z, 1.3, 1.3, 1.3, pick({ c("FF7BAC"), c("FFE066"), c("FFFFFF"), c("9AD1FF") }), nil, false)
		end
	end,
	function(f, x, z) -- 2 Sunny Farm
		local r = rng:NextNumber()
		if r < 0.35 then
			local hay = cylinder(f, x, 1.8, z, 5, 3.6, c("E6C45A"), Enum.Material.Fabric)
			hay.CFrame = CFrame.new(x, 1.8, z) * CFrame.Angles(math.pi / 2, 0, 0) * UP
		elseif r < 0.8 then
			for i = -1, 1 do
				block(f, x + i * 4, 1.6, z, 0.7, 3.2, 0.7, c("8B5A2B"), Enum.Material.Wood)
			end
			block(f, x, 2.4, z, 9, 0.5, 0.4, c("A56B35"), Enum.Material.Wood)
			block(f, x, 1.2, z, 9, 0.5, 0.4, c("A56B35"), Enum.Material.Wood)
		else
			block(f, x, 5, z, 14, 10, 12, c("C0392B"), Enum.Material.WoodPlanks)
			block(f, x, 10.6, z, 16, 1.4, 14, c("5A2D1F"), Enum.Material.Wood)
			block(f, x, 2.6, z + 6.05, 5, 5.2, 0.3, c("FFF4DC"), Enum.Material.Wood)
		end
	end,
	function(f, x, z) -- 3 Tropical Jungle
		if rng:NextNumber() < 0.6 then
			local h = rng:NextInteger(14, 20)
			cylinder(f, x, h / 2, z, h, 2.2, c("5A3A22"), Enum.Material.Wood)
			ball(f, x, h + 3, z, 13, 8, 13, jitter(c("1F7A3A"), 0.12), Enum.Material.Grass)
			ball(f, x + 3, h + 1, z - 2, 8, 5, 8, jitter(c("2E9B4E"), 0.12), Enum.Material.Grass)
		else
			ball(f, x, 1, z, 6, 2.4, 6, jitter(c("2FB05A"), 0.15), Enum.Material.Grass)
		end
	end,
	function(f, x, z) -- 4 Desert Kingdom
		local r = rng:NextNumber()
		if r < 0.4 then
			local h = rng:NextInteger(6, 10)
			cylinder(f, x, h / 2, z, h, 1.8, c("3F8F4E"), Enum.Material.Grass)
			cylinder(f, x + 2.2, h * 0.55, z, 3, 1.1, c("3F8F4E"), Enum.Material.Grass)
			ball(f, x, h, z, 1.8, 1.8, 1.8, c("3F8F4E"), Enum.Material.Grass)
		elseif r < 0.75 then
			ball(f, x, 1.5, z, 5, 3, 4, jitter(c("A68B6A"), 0.15), Enum.Material.Rock)
		else
			ball(f, x, 1.5, z, rng:NextInteger(24, 36), 7, rng:NextInteger(18, 26), c("E6BE70"), Enum.Material.Sand)
		end
	end,
	function(f, x, z) -- 5 Frozen Mountains
		local r = rng:NextNumber()
		if r < 0.4 then
			local h = rng:NextInteger(8, 16)
			block(f, x, h / 2, z, 2.6, h, 2.6, c("BFE8FF"), Enum.Material.Ice, CFrame.Angles(0, math.rad(rng:NextInteger(0, 90)), math.rad(rng:NextInteger(-8, 8))))
		elseif r < 0.75 then
			ball(f, x, 1.5, z, rng:NextInteger(10, 18), 5, rng:NextInteger(8, 14), c("FFFFFF"), Enum.Material.Snow)
		else
			ball(f, x, 2, z, 4, 4, 4, c("FFFFFF"), Enum.Material.Snow)
			ball(f, x, 5, z, 3, 3, 3, c("FFFFFF"), Enum.Material.Snow)
			ball(f, x, 7.4, z, 2.2, 2.2, 2.2, c("FFFFFF"), Enum.Material.Snow)
			ball(f, x, 7.4, z - 1.1, 0.5, 0.5, 1.2, c("FF8F2B"))
		end
	end,
	function(f, x, z) -- 6 Deep Ocean
		local r = rng:NextNumber()
		if r < 0.35 then
			ball(f, x, 1.2, z, 4, 3, 4, pick({ c("FF6F91"), c("FFB347"), c("B28DFF") }), Enum.Material.SmoothPlastic)
			ball(f, x + 2, 1.8, z + 1, 3, 4, 3, pick({ c("FF6F91"), c("FFB347"), c("B28DFF") }))
		elseif r < 0.65 then
			cylinder(f, x, 1.6, z, 3.2, 2.4, c("E63946"))
			cylinder(f, x, 3.4, z, 0.5, 2.5, c("FFFFFF"))
		else
			ball(f, x, 0.5, z, 20, 3, 16, c("F2D99B"), Enum.Material.Sand)
			cylinder(f, x, 5, z, 8, 1, c("7A5230"), Enum.Material.Wood)
			ball(f, x, 9.5, z, 7, 2, 7, c("2FB05A"), Enum.Material.Grass)
		end
	end,
	function(f, x, z) -- 7 Volcanic Island
		local r = rng:NextNumber()
		if r < 0.35 then
			cylinder(f, x, 0.35, z, 0.5, rng:NextInteger(8, 16), c("FF5A1F"), Enum.Material.Neon)
		elseif r < 0.8 then
			block(f, x, 5, z, 3, 10, 3, c("1E1515"), Enum.Material.Basalt, CFrame.Angles(math.rad(rng:NextInteger(-10, 10)), math.rad(rng:NextInteger(0, 90)), math.rad(rng:NextInteger(-10, 10))))
		else
			cylinder(f, x, 4, z, 8, 22, c("4A2E28"), Enum.Material.Basalt)
			cylinder(f, x, 10, z, 6, 13, c("3A2420"), Enum.Material.Basalt)
			cylinder(f, x, 13.2, z, 0.6, 7, c("FF5A1F"), Enum.Material.Neon)
		end
	end,
	function(f, x, z) -- 8 Mystical Forest
		local r = rng:NextNumber()
		local glow = pick({ c("B28DFF"), c("5CF2E6"), c("FF8AD8") })
		if r < 0.4 then
			cylinder(f, x, 2, z, 4, 1, c("F4EEFF"))
			local cap = ball(f, x, 4.4, z, 5, 3, 5, glow, Enum.Material.Neon)
			if rng:NextNumber() < 0.2 then
				local light = Instance.new("PointLight")
				light.Color, light.Range, light.Brightness = glow, 14, 1.2
				light.Parent = cap
			end
		elseif r < 0.7 then
			block(f, x, 4, z, 2, 8, 2, glow, Enum.Material.Neon, CFrame.Angles(math.rad(rng:NextInteger(-15, 15)), math.rad(rng:NextInteger(0, 90)), math.rad(rng:NextInteger(-15, 15))))
		else
			P.tree(f, x, z, c("4B2E5E"), c("9B6BE0"), rng:NextInteger(8, 12), rng:NextInteger(9, 12))
		end
	end,
	function(f, x, z) -- 9 Sky Kingdom
		local r = rng:NextNumber()
		if r < 0.55 then
			for i = 1, 4 do
				ball(f, x + (i - 2.5) * 3, 2 + (i % 2), z + rng:NextInteger(-2, 2), 6, 5, 6, c("FFFFFF"))
			end
		elseif r < 0.8 then
			cylinder(f, x, 7, z, 14, 3, c("F5FBFF"), Enum.Material.Marble)
			block(f, x, 14.4, z, 5, 1.2, 5, c("FFE066"), Enum.Material.Marble)
		else
			ball(f, x, rng:NextInteger(14, 28), z, 2.5, 2.5, 2.5, c("FFE066"), Enum.Material.Neon, false)
		end
	end,
	function(f, x, z) -- 10 Ancient Kingdom
		local r = rng:NextNumber()
		if r < 0.4 then
			local h = rng:NextInteger(12, 16)
			cylinder(f, x, h / 2, z, h, 3, c("E3C98A"), Enum.Material.Sandstone)
			block(f, x, h + 0.6, z, 4.4, 1.2, 4.4, c("C9A24A"), Enum.Material.Sandstone)
		elseif r < 0.7 then
			block(f, x, 2, z, rng:NextInteger(8, 14), 4, 2, c("CDB27A"), Enum.Material.Sandstone)
		else
			block(f, x, 3, z, 5, 6, 5, c("D4AF37"), Enum.Material.Metal)
			ball(f, x, 7.2, z, 4, 4, 4, c("D4AF37"), Enum.Material.Metal)
		end
	end,
	function(f, x, z) -- 11 Galaxy World
		local r = rng:NextNumber()
		if r < 0.5 then
			ball(f, x, rng:NextInteger(6, 40), z, 1.4, 1.4, 1.4, c("FFFFFF"), Enum.Material.Neon, false)
		elseif r < 0.8 then
			local col = pick({ c("FF6FB5"), c("5CF2E6"), c("FFB347"), c("8F7BFF") })
			local y = rng:NextInteger(28, 55)
			ball(f, x, y, z, 14, 14, 14, col, Enum.Material.Neon, false)
			cylinder(f, x, y, z, 0.6, 26, col, Enum.Material.Neon).CanCollide = false
		else
			ball(f, x, 3, z, 7, 5, 6, c("3B3B7A"), Enum.Material.Slate)
		end
	end,
	function(f, x, z) -- 12 Divine Realm
		local r = rng:NextNumber()
		if r < 0.45 then
			local h = rng:NextInteger(16, 24)
			cylinder(f, x, h / 2, z, h, 3, c("FFFBE0"), Enum.Material.Marble)
			ball(f, x, h + 1, z, 3, 3, 3, c("FFE066"), Enum.Material.Neon)
		elseif r < 0.75 then
			cylinder(f, x, rng:NextInteger(20, 36), z, 0.7, 16, c("FFE066"), Enum.Material.Neon).CanCollide = false
		else
			ball(f, x, rng:NextInteger(3, 18), z, 2, 2, 2, c("FFFFFF"), Enum.Material.Neon, false)
		end
	end,
}

-------------------------------------------------------------------------------- track
local function buildTrack(root)
	local ground = Instance.new("Folder")
	ground.Name = "Ground"
	ground.Parent = root

	for i, area in Catalog.Areas do
		local look = ZoneLook[i]
		local z0 = -area.StartDist
		local z1 = -(Catalog.Areas[i + 1] and Catalog.Areas[i + 1].StartDist or (area.StartDist + W.LastZoneLength))
		local length = z0 - z1
		part(ground, {
			Name = "Zone" .. i,
			Size = Vector3.new(WIDTH, 4, length),
			Position = Vector3.new(0, -2, (z0 + z1) / 2),
			Color = look.Ground,
			Material = look.Material,
			Transparency = i == 6 and 0.15 or 0,
		})
		if i == 6 then -- water needs a floor under the glass
			part(ground, { Name = "SeaBed", Size = Vector3.new(WIDTH, 2, length), Position = Vector3.new(0, -5, (z0 + z1) / 2), Color = c("E9D8A6"), Material = Enum.Material.Sand })
		end

		local props = Instance.new("Folder")
		props.Name = "Props" .. i
		props.Parent = root
		local count = math.clamp(math.floor(length / 5), 24, 70)
		for _ = 1, count do
			local x = (rng:NextNumber() - 0.5) * (WIDTH - 24)
			local z = z1 + 14 + rng:NextNumber() * (length - 28)
			ZONE_PROPS[i](props, x, z)
		end

		-- zone gate: stripe, two pillars, banners
		if i > 1 then
			part(root, { Name = "Stripe" .. i, Size = Vector3.new(WIDTH, 0.3, 1.5), Position = Vector3.new(0, 0.15, z0), Color = area.Color, Material = Enum.Material.Neon, CanCollide = false })
			for _, sx in { -1, 1 } do
				local pillar = cylinder(root, sx * (WIDTH / 2 - 14), 14, z0, 28, 5, area.Color, Enum.Material.SmoothPlastic)
				ball(root, sx * (WIDTH / 2 - 14), 29, z0, 6, 6, 6, c("FFE066"), Enum.Material.Neon, false)
				pillar.Name = "GatePillar"
			end
		end
		for _, bx in { -WIDTH / 4, 0, WIDTH / 4 } do
			local sign = part(root, { Name = "ZoneSign", Size = Vector3.one, Position = Vector3.new(bx, 20, z0 - 2), Transparency = 1, CanCollide = false })
			local label = billboard(sign, `{area.Name}\n{area.StartDist} studs`, UDim2.fromOffset(420, 120), area.Color, 600, 0)
			label.Parent.Size = UDim2.fromOffset(420, 120)
			label.Parent.Name = "ZoneBanner"
		end
	end

	-- distance rulers along both edges
	for d = 100, TRACK_END, 100 do
		for _, sx in { -1, 1 } do
			local post = part(root, { Name = "Ruler", Size = Vector3.new(1, 6, 1), Position = Vector3.new(sx * (WIDTH / 2 - 6), 3, -d), Color = c("14363B"), CanCollide = false })
			billboard(post, `{d}`, UDim2.fromOffset(90, 40), c("FFF4DC"), 250, 4)
		end
	end
end

local function buildHub(root)
	local hub = Instance.new("Folder")
	hub.Name = "Hub"
	hub.Parent = root
	part(hub, { Name = "HubGround", Size = Vector3.new(WIDTH, 4, W.HubDepth), Position = Vector3.new(0, -2, W.HubDepth / 2), Color = c("6FCF5A"), Material = Enum.Material.Grass })
	-- path along the start line
	part(hub, { Name = "StartLine", Size = Vector3.new(WIDTH, 0.2, 3), Position = Vector3.new(0, 0.1, 0), Color = c("FFF4DC"), CanCollide = false })
	for _ = 1, 60 do
		local x = (rng:NextNumber() - 0.5) * (WIDTH - 20)
		local z = W.PlotDepth + 12 + rng:NextNumber() * (W.HubDepth - W.PlotDepth - 20)
		if rng:NextNumber() < 0.5 then
			P.tree(hub, x, z, c("7A5230"), c("3FA34D"), rng:NextInteger(7, 11), rng:NextInteger(8, 11))
		else
			ball(hub, x, 0.6, z, 1.3, 1.3, 1.3, pick({ c("FF7BAC"), c("FFE066"), c("FFFFFF") }), nil, false)
		end
	end
end

-------------------------------------------------------------------------------- plots
local ACCENTS = { c("FF8F2B"), c("52C1F5"), c("4CCB5E"), c("F2546E"), c("FFD43B"), c("A66BFF"), c("5CF2E6"), c("FF7BAC"), c("8BC34A"), c("FF6B6B") }

local function prompt(parent, action, object, window)
	local p = Instance.new("ProximityPrompt")
	p.ActionText, p.ObjectText = action, object
	p.HoldDuration = 0
	p.MaxActivationDistance = 12
	p.RequiresLineOfSight = false
	p:SetAttribute("Window", window) -- the client opens the matching window
	p.Parent = parent
end

local function rail(parent, x1, z1, x2, z2, color)
	local dx, dz = x2 - x1, z2 - z1
	local len = math.sqrt(dx * dx + dz * dz)
	local rot = CFrame.lookAt(Vector3.zero, Vector3.new(dx, 0, dz))
	local mx, mz = (x1 + x2) / 2, (z1 + z2) / 2
	for _, y in { 1.4, 2.7 } do
		part(parent, { Size = Vector3.new(0.5, 0.5, len), CFrame = CFrame.new(mx, y, mz) * rot, Color = color, Material = Enum.Material.Wood })
	end
	local posts = math.max(2, math.floor(len / 4) + 1)
	for k = 0, posts - 1 do
		local t = k / (posts - 1)
		part(parent, { Size = Vector3.new(0.8, 3.4, 0.8), Position = Vector3.new(x1 + dx * t, 1.7, z1 + dz * t), Color = color, Material = Enum.Material.Wood })
	end
end

local function buildPlot(root, slot)
	local x = ThrowMath.slotX(slot)
	local accent = ACCENTS[(slot - 1) % #ACCENTS + 1]
	local model = Instance.new("Model")
	model.Name = "Plot" .. slot
	model.Parent = root
	local z0, z1 = 4, 4 + W.PlotDepth
	local zc = (z0 + z1) / 2

	part(model, { Name = "Floor", Size = Vector3.new(48, 0.5, W.PlotDepth), Position = Vector3.new(x, 0.25, zc), Color = c("8FE06B"), Material = Enum.Material.Grass })
	part(model, { Name = "Path", Size = Vector3.new(8, 0.6, W.PlotDepth - 8), Position = Vector3.new(x, 0.3, zc), Color = c("F1DDB0"), Material = Enum.Material.Cobblestone, CanCollide = false })

	local wood = c("8B5A2B")
	rail(model, x - 24, z0, x - 24, z1, wood)
	rail(model, x + 24, z0, x + 24, z1, wood)
	rail(model, x - 24, z1, x + 24, z1, wood)
	rail(model, x - 24, z0, x - 8, z0, wood)
	rail(model, x + 8, z0, x + 24, z0, wood)

	-- animal pen (rear half)
	local penCenter = Vector3.new(x, 0.5, 54)
	local penHalf = Vector2.new(17, 15)
	part(model, { Name = "PenFloor", Size = Vector3.new(36, 0.2, 32), Position = Vector3.new(x, 0.6, 54), Color = c("B7E87A"), Material = Enum.Material.Grass, CanCollide = false })
	rail(model, x - 18, 38, x + 18, 38, c("C98B4A"))
	rail(model, x - 18, 70, x + 18, 70, c("C98B4A"))
	rail(model, x - 18, 38, x - 18, 70, c("C98B4A"))
	rail(model, x + 18, 38, x + 18, 70, c("C98B4A"))
	local penSign = part(model, { Name = "PenSign", Size = Vector3.one, Position = Vector3.new(x, 8, 38), Transparency = 1, CanCollide = false })
	billboard(penSign, "🐾 ANIMAL PEN", UDim2.fromOffset(240, 60), accent, 90, 0)

	-- throw spot
	local spot = ThrowMath.spot(slot)
	local ring = cylinder(model, spot.X, 0.7, spot.Z, 0.3, 9, accent, Enum.Material.Neon)
	ring.CanCollide = false
	ring.Name = "ThrowSpot"
	local ringLabel = part(model, { Size = Vector3.one, Position = spot + Vector3.new(0, 6, 0), Transparency = 1, CanCollide = false })
	billboard(ringLabel, "THROW HERE", UDim2.fromOffset(220, 50), c("FFFFFF"), 120, 0)

	-- pull-up bar (training)
	local bx, bz = x - 16, 20
	cylinder(model, bx - 5, 5, bz, 10, 1, c("6C7A89"), Enum.Material.Metal)
	cylinder(model, bx + 5, 5, bz, 10, 1, c("6C7A89"), Enum.Material.Metal)
	local bar = part(model, { Name = "PullUpBar", Shape = Enum.PartType.Cylinder, Size = Vector3.new(10.6, 0.8, 0.8), CFrame = CFrame.new(bx, 9.5, bz), Color = accent, Material = Enum.Material.Metal })
	local trainPad = part(model, { Name = "TrainPad", Size = Vector3.new(12, 0.3, 6), Position = Vector3.new(bx, 0.65, bz), Color = c("2C5B61"), CanCollide = false })
	prompt(trainPad, "Train", "Pull-up bar", "Upgrades")
	local barLabel = part(model, { Size = Vector3.one, Position = Vector3.new(bx, 13.5, bz), Transparency = 1, CanCollide = false })
	billboard(barLabel, "💪 TRAIN", UDim2.fromOffset(160, 44), c("FFD43B"), 90, 0)

	-- food shop stand
	local sx, sz = x + 16, 20
	block(model, sx, 1.8, sz, 10, 3.2, 4, c("FFF4DC"), Enum.Material.WoodPlanks)
	block(model, sx, 8, sz - 1.2, 11, 0.8, 6.5, accent, Enum.Material.Fabric, CFrame.Angles(math.rad(-10), 0, 0))
	for _, dx in { -4.6, 4.6 } do
		cylinder(model, sx + dx, 4.4, sz + 1.8, 8.8, 0.6, c("8B5A2B"), Enum.Material.Wood)
	end
	local shopPad = part(model, { Name = "ShopPad", Size = Vector3.new(12, 0.3, 5), Position = Vector3.new(sx, 0.65, sz - 4.5), Color = c("2C5B61"), CanCollide = false })
	prompt(shopPad, "Open", "Food Shop", "Shop")
	local shopLabel = part(model, { Size = Vector3.one, Position = Vector3.new(sx, 11.5, sz), Transparency = 1, CanCollide = false })
	billboard(shopLabel, "🛒 FOOD SHOP", UDim2.fromOffset(200, 44), c("52C1F5"), 90, 0)

	-- animals board + map board
	local ax, az = x + 16, 34
	block(model, ax, 2.6, az, 8, 5, 1, c("6C4B2A"), Enum.Material.Wood)
	local animalsPad = part(model, { Name = "AnimalsPad", Size = Vector3.new(8, 0.3, 4), Position = Vector3.new(ax, 0.65, az - 3), Color = c("2C5B61"), CanCollide = false })
	prompt(animalsPad, "Open", "My Animals", "Animals")
	local animalsLabel = part(model, { Size = Vector3.one, Position = Vector3.new(ax, 7.2, az), Transparency = 1, CanCollide = false })
	billboard(animalsLabel, "🐾 ANIMALS", UDim2.fromOffset(180, 40), c("4CCB5E"), 80, 0)

	local mx, mz = x - 16, 34
	block(model, mx, 2.6, mz, 8, 5, 1, c("6C4B2A"), Enum.Material.Wood)
	local mapPad = part(model, { Name = "MapPad", Size = Vector3.new(8, 0.3, 4), Position = Vector3.new(mx, 0.65, mz - 3), Color = c("2C5B61"), CanCollide = false })
	prompt(mapPad, "Read", "World map", "Areas")
	local mapLabel = part(model, { Size = Vector3.one, Position = Vector3.new(mx, 7.2, mz), Transparency = 1, CanCollide = false })
	billboard(mapLabel, "🗺️ WORLD MAP", UDim2.fromOffset(200, 40), c("FF8F2B"), 80, 0)

	-- owner sign
	local signPost = part(model, { Name = "SignPost", Size = Vector3.new(1, 9, 1), Position = Vector3.new(x - 21, 4.5, 12), Color = c("6C4B2A"), Material = Enum.Material.Wood })
	local board = part(model, { Name = "SignBoard", Size = Vector3.new(14, 4.5, 0.8), Position = Vector3.new(x - 21, 10, 12), Color = accent })
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizeStudsPerPixel = 0.06
	gui.Parent = board
	local signLabel = Instance.new("TextLabel")
	signLabel.Size = UDim2.fromScale(1, 1)
	signLabel.BackgroundTransparency = 1
	signLabel.Font = Enum.Font.FredokaOne
	signLabel.TextScaled = true
	signLabel.TextColor3 = Color3.new(1, 1, 1)
	signLabel.Text = `PLOT {slot}\nFree`
	signLabel.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = c("14363B")
	stroke.Parent = signLabel

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.CanCollide = false
	spawn.Transparency = 1
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.Position = Vector3.new(x, 0.5, 14)
	spawn.Parent = model

	WorldBuilder.Plots[slot] = { Model = model, Spawn = spawn, SignLabel = signLabel, Pen = penCenter, PenHalf = penHalf, Accent = accent }
end

local function buildWalls(root)
	local total = TRACK_END + W.HubDepth
	local zc = (W.HubDepth - TRACK_END) / 2
	local function wall(size, pos)
		part(root, { Name = "Wall", Size = size, Position = pos, Transparency = 1, CanCollide = true, CanQuery = false })
	end
	wall(Vector3.new(2, 300, total), Vector3.new(-WIDTH / 2, 150, zc))
	wall(Vector3.new(2, 300, total), Vector3.new(WIDTH / 2, 150, zc))
	wall(Vector3.new(WIDTH, 300, 2), Vector3.new(0, 150, W.HubDepth))
	wall(Vector3.new(WIDTH, 300, 2), Vector3.new(0, 150, -TRACK_END))
end

local function buildLighting()
	Lighting.ClockTime = 14
	Lighting.Brightness = 2.6
	Lighting.GlobalShadows = true
	Lighting.EnvironmentDiffuseScale = 0.5
	for _, class in { "Atmosphere", "BloomEffect", "ColorCorrectionEffect", "SunRaysEffect", "Sky" } do
		local old = Lighting:FindFirstChildOfClass(class)
		if old then
			old:Destroy()
		end
	end
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Name = "ZoneAtmosphere"
	atmosphere.Density, atmosphere.Offset = 0.28, 0.25
	atmosphere.Color, atmosphere.Decay = ZoneLook[1].Fog, ZoneLook[1].Fog
	atmosphere.Glare, atmosphere.Haze = 0.15, 1.2
	atmosphere.Parent = Lighting
	local bloom = Instance.new("BloomEffect")
	bloom.Intensity, bloom.Size, bloom.Threshold = 0.35, 24, 1.6
	bloom.Parent = Lighting
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Saturation, cc.Contrast = 0.18, 0.06
	cc.Parent = Lighting
	local rays = Instance.new("SunRaysEffect")
	rays.Intensity, rays.Spread = 0.06, 0.6
	rays.Parent = Lighting
end

function WorldBuilder.Init()
	local old = Workspace:FindFirstChild("World")
	if old then
		old:Destroy()
	end
	local root = Instance.new("Folder")
	root.Name = "World"
	buildTrack(root)
	buildHub(root)
	for slot = 1, W.Slots do
		buildPlot(root, slot)
	end
	buildWalls(root)
	root.Parent = Workspace
	buildLighting()
end

return WorldBuilder
