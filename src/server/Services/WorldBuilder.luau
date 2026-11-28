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

-- anime building blocks
function P.torii(f, x, z, k, color)
	k = k or 1
	color = color or c("D7263D")
	cylinder(f, x - 4 * k, 6 * k, z, 12 * k, 1.5 * k, color, Enum.Material.Wood)
	cylinder(f, x + 4 * k, 6 * k, z, 12 * k, 1.5 * k, color, Enum.Material.Wood)
	block(f, x, 12.4 * k, z, 13.5 * k, 1.2 * k, 1.8 * k, c("1E1E1E"))
	block(f, x, 10 * k, z, 10 * k, 0.9 * k, 1.1 * k, color)
end

function P.lantern(f, x, z, glow)
	cylinder(f, x, 1.5, z, 3, 1.2, c("9AA0A6"), Enum.Material.Slate)
	block(f, x, 3.5, z, 2.2, 1.7, 2.2, glow or c("FFD27A"), Enum.Material.Neon)
	block(f, x, 4.7, z, 3.4, 0.6, 3.4, c("6B7075"), Enum.Material.Slate)
end

function P.house(f, x, z, wall, roof)
	block(f, x, 3.5, z, 10, 7, 9, wall, Enum.Material.WoodPlanks)
	block(f, x, 7.9, z, 12.6, 1.6, 11.6, roof, Enum.Material.Slate)
	block(f, x, 2, z + 4.6, 2.4, 4, 0.3, c("3E2723"))
end

function P.sakura(f, x, z)
	local h = rng:NextInteger(8, 12)
	cylinder(f, x, h / 2, z, h, 1.6, c("6D4C41"), Enum.Material.Wood)
	ball(f, x, h + 2, z, 13, 9, 13, jitter(c("FFB7D5"), 0.1), Enum.Material.SmoothPlastic)
	ball(f, x + 4, h, z + 2, 8, 6, 8, jitter(c("FF9EC4"), 0.1))
	ball(f, x - 4, h + 0.5, z - 2, 7, 5, 7, jitter(c("FFC9E0"), 0.1))
end

function P.bamboo(f, x, z)
	for i = -1, 1 do
		local h = rng:NextInteger(14, 20)
		cylinder(f, x + i * 1.7, h / 2, z + rng:NextInteger(-1, 1), h, 0.9, jitter(c("5FAF4F"), 0.15), Enum.Material.Grass)
	end
end

function P.pine(f, x, z)
	cylinder(f, x, 3, z, 6, 1.4, c("5D4037"), Enum.Material.Wood)
	for i = 0, 2 do
		cylinder(f, x, 7 + i * 3.2, z, 1.6, 11 - i * 3, c("2E7D32"), Enum.Material.Grass)
	end
end

function P.tower(f, x, z, wall, roof)
	cylinder(f, x, 10, z, 20, 7, wall, Enum.Material.Marble)
	cylinder(f, x, 21, z, 1.5, 10, roof, Enum.Material.SmoothPlastic)
	cylinder(f, x, 24, z, 4, 6, roof, Enum.Material.SmoothPlastic)
	cylinder(f, x, 27, z, 3, 2.4, roof, Enum.Material.SmoothPlastic)
end

function P.crystal(f, x, z, color, h)
	h = h or rng:NextInteger(6, 12)
	block(f, x, h / 2, z, 2.4, h, 2.4, color, Enum.Material.Neon, CFrame.Angles(math.rad(rng:NextInteger(-12, 12)), math.rad(rng:NextInteger(0, 90)), math.rad(rng:NextInteger(-12, 12))))
end

function P.skyscraper(f, x, z, color, neon)
	local h = rng:NextInteger(22, 46)
	local w = rng:NextInteger(9, 15)
	block(f, x, h / 2, z, w, h, w, color, Enum.Material.Concrete)
	block(f, x, h * 0.35, z + w / 2 + 0.1, w * 0.8, 1, 0.3, neon, Enum.Material.Neon).CanCollide = false
	block(f, x, h * 0.7, z + w / 2 + 0.1, w * 0.8, 1, 0.3, neon, Enum.Material.Neon).CanCollide = false
	block(f, x, h + 0.6, z, w * 0.5, 1.2, w * 0.5, neon, Enum.Material.Neon).CanCollide = false
end

function P.sign(f, x, z, text, color)
	local post = part(f, { Size = Vector3.new(0.8, 10, 0.8), Position = Vector3.new(x, 5, z), Color = c("2B2B3A"), CanCollide = false })
	local board = block(f, x, 11, z, 8, 3.2, 0.6, c("141224"), Enum.Material.Neon)
	board.CanCollide = false
	billboard(board, text, UDim2.fromOffset(150, 60), color, 160, 0)
	post.Name = "SignPost"
end

local NEON = { c("FF4FA3"), c("29E0FF"), c("B26BFF"), c("FFE14D"), c("5CFF9D") }
local SIGNS = { "RAMEN", "GAME", "IDOL", "24H", "NEON", "MANGA" }

local ZONE_PROPS = {
	function(f, x, z) -- 1 Sakura Village
		local r = rng:NextNumber()
		if r < 0.42 then
			P.sakura(f, x, z)
		elseif r < 0.55 then
			P.lantern(f, x, z)
		elseif r < 0.67 then
			P.house(f, x, z, c("F3E6CF"), c("B24A4A"))
		elseif r < 0.75 then
			P.torii(f, x, z, 0.7)
		else
			ball(f, x, 0.5, z, 1.4, 0.6, 1.4, pick({ c("FFB7D5"), c("FFFFFF"), c("FF9EC4") }), nil, false)
		end
	end,
	function(f, x, z) -- 2 Ninja Dojo Hills
		local r = rng:NextNumber()
		if r < 0.42 then
			P.bamboo(f, x, z)
		elseif r < 0.62 then
			cylinder(f, x, 3.5, z, 7, 1.6, c("8D6E63"), Enum.Material.Wood)
			ball(f, x, 5.5, z + 1.2, 2.6, 3.4, 2.6, c("D7B98E"), Enum.Material.Fabric)
		elseif r < 0.78 then
			P.house(f, x, z, c("6D4C41"), c("2E7D32"))
		else
			ball(f, x, 1.5, z, 5, 3, 4, jitter(c("8A8F94"), 0.15), Enum.Material.Rock)
		end
	end,
	function(f, x, z) -- 3 Samurai Castle
		local r = rng:NextNumber()
		if r < 0.28 then
			P.pine(f, x, z)
		elseif r < 0.5 then
			block(f, x, 3.5, z, 16, 7, 3, c("B9B2A3"), Enum.Material.Slate)
			for i = -2, 2 do
				block(f, x + i * 3.4, 7.8, z, 1.8, 1.6, 3, c("B9B2A3"), Enum.Material.Slate)
			end
		elseif r < 0.68 then
			cylinder(f, x, 7, z, 14, 0.8, c("3E2723"), Enum.Material.Wood)
			block(f, x + 2.6, 11, z, 5, 3.4, 0.3, c("C62828"), Enum.Material.Fabric)
		elseif r < 0.82 then
			P.lantern(f, x, z)
		else
			for i = 0, 2 do
				block(f, x, 3 + i * 5, z, 12 - i * 2.4, 3, 12 - i * 2.4, c("F3E6CF"), Enum.Material.WoodPlanks)
				block(f, x, 5.2 + i * 5, z, 15 - i * 2.4, 0.9, 15 - i * 2.4, c("37474F"), Enum.Material.Slate)
			end
		end
	end,
	function(f, x, z) -- 4 Magic Academy
		local r = rng:NextNumber()
		if r < 0.28 then
			P.tower(f, x, z, c("E8E0FF"), c("6A3FD0"))
		elseif r < 0.55 then
			P.crystal(f, x, z, pick({ c("B28DFF"), c("5CF2E6"), c("FF8AD8") }))
			P.crystal(f, x + 2.4, z + 1, pick({ c("B28DFF"), c("5CF2E6") }), 5)
		elseif r < 0.78 then
			local book = block(f, x, rng:NextInteger(7, 16), z, 4, 0.7, 3, pick({ c("5CF2E6"), c("FFE14D") }), Enum.Material.Neon, CFrame.Angles(math.rad(rng:NextInteger(-20, 20)), math.rad(rng:NextInteger(0, 90)), 0))
			book.CanCollide = false
		else
			ball(f, x, rng:NextInteger(5, 14), z, 2.4, 2.4, 2.4, c("FFE14D"), Enum.Material.Neon, false)
		end
	end,
	function(f, x, z) -- 5 Spirit Shrine
		local r = rng:NextNumber()
		if r < 0.32 then
			P.torii(f, x, z, 0.85)
		elseif r < 0.5 then
			P.lantern(f, x, z, c("7FDBFF"))
		elseif r < 0.7 then
			block(f, x, 2.4, z, 4, 4.8, 3, c("F5F5F5"), Enum.Material.Marble)
			block(f, x - 1.2, 5.6, z, 1, 1.8, 1, c("F5F5F5"), Enum.Material.Marble)
			block(f, x + 1.2, 5.6, z, 1, 1.8, 1, c("F5F5F5"), Enum.Material.Marble)
			block(f, x, 3.4, z + 1.55, 3.2, 1.2, 0.2, c("D7263D"), Enum.Material.Fabric)
		else
			local wisp = ball(f, x, rng:NextInteger(4, 12), z, 2.2, 2.2, 2.2, c("7FDBFF"), Enum.Material.Neon, false)
			if rng:NextNumber() < 0.25 then
				local light = Instance.new("PointLight")
				light.Color, light.Range, light.Brightness = c("7FDBFF"), 14, 1.2
				light.Parent = wisp
			end
		end
	end,
	function(f, x, z) -- 6 Pirate Seas
		local r = rng:NextNumber()
		if r < 0.3 then
			block(f, x, 2.5, z, 9, 4, 24, c("6D4C41"), Enum.Material.WoodPlanks)
			cylinder(f, x, 11, z, 14, 0.9, c("3E2723"), Enum.Material.Wood)
			block(f, x, 11.5, z + 0.2, 0.4, 9, 8, c("FFF8E7"), Enum.Material.Fabric)
			block(f, x, 18.4, z, 0.3, 2, 3, c("111111"), Enum.Material.Fabric)
		elseif r < 0.55 then
			for i = 0, 2 do
				cylinder(f, x + i * 2.2, 1.4, z + (i % 2) * 1.6, 2.8, 2.2, c("8D6E63"), Enum.Material.Wood)
			end
		elseif r < 0.75 then
			cylinder(f, x, 1.6, z, 3.2, 2.4, c("E63946"))
			cylinder(f, x, 3.4, z, 0.5, 2.5, c("FFFFFF"))
		else
			for i = 0, 2 do
				block(f, x, 0.5, z + i * 3.2, 7, 0.6, 2.8, c("A1887F"), Enum.Material.WoodPlanks)
			end
		end
	end,
	function(f, x, z) -- 7 Neon Tokyo
		local r = rng:NextNumber()
		if r < 0.45 then
			P.skyscraper(f, x, z, c("1F1B3A"), pick(NEON))
		elseif r < 0.65 then
			P.sign(f, x, z, pick(SIGNS), pick(NEON))
		elseif r < 0.82 then
			block(f, x, 3, z, 4, 6, 3, pick({ c("E53935"), c("1E88E5"), c("FDD835") }), Enum.Material.SmoothPlastic)
			block(f, x, 3.6, z + 1.55, 3, 3.4, 0.2, c("B9F6FF"), Enum.Material.Neon).CanCollide = false
		else
			cylinder(f, x, 5, z, 10, 0.6, c("2B2B3A"))
			ball(f, x, 10.4, z, 1.8, 1.8, 1.8, pick(NEON), Enum.Material.Neon, false)
		end
	end,
	function(f, x, z) -- 8 Mecha Wasteland
		local r = rng:NextNumber()
		if r < 0.28 then
			block(f, x, 6, z, 4, 12, 4, c("8FA1AC"), Enum.Material.Metal, CFrame.Angles(0, math.rad(rng:NextInteger(0, 90)), math.rad(rng:NextInteger(-18, 18))))
			block(f, x + 1, 13, z, 6, 3, 5, c("FF7043"), Enum.Material.Metal)
		elseif r < 0.55 then
			for _ = 1, 3 do
				block(f, x + rng:NextInteger(-3, 3), 1.5, z + rng:NextInteger(-3, 3), rng:NextInteger(3, 6), rng:NextInteger(2, 4), rng:NextInteger(3, 6), jitter(c("7B6B63"), 0.2), Enum.Material.CorrodedMetal, CFrame.Angles(0, math.rad(rng:NextInteger(0, 90)), 0))
			end
		elseif r < 0.72 then
			ball(f, x, 8, z, 11, 10, 11, c("B0BEC5"), Enum.Material.Metal)
			block(f, x, 8.6, z + 5.2, 8, 2.2, 0.8, c("FF5A1F"), Enum.Material.Neon).CanCollide = false
		else
			cylinder(f, x, 10, z, 20, 0.8, c("90A4AE"), Enum.Material.Metal)
			ball(f, x, 20.5, z, 1.8, 1.8, 1.8, c("FF5A1F"), Enum.Material.Neon, false)
		end
	end,
	function(f, x, z) -- 9 Demon Hunt Forest
		local r = rng:NextNumber()
		if r < 0.38 then
			cylinder(f, x, 6, z, 12, 1.8, c("2A1F2D"), Enum.Material.Wood)
			block(f, x + 2, 10, z, 6, 0.8, 0.8, c("2A1F2D"), Enum.Material.Wood, CFrame.Angles(0, 0, math.rad(25)))
			block(f, x - 2, 9, z, 6, 0.8, 0.8, c("2A1F2D"), Enum.Material.Wood, CFrame.Angles(0, 0, math.rad(-25)))
		elseif r < 0.65 then
			for _ = 1, 3 do
				ball(f, x + rng:NextInteger(-2, 2), 0.7, z + rng:NextInteger(-2, 2), 1.1, 1.1, 1.1, c("FF1744"), Enum.Material.Neon, false)
			end
		elseif r < 0.82 then
			block(f, x, 2, z, 2.4, 4, 0.8, c("6B6B7A"), Enum.Material.Slate)
		else
			P.lantern(f, x, z, c("FF5252"))
		end
	end,
	function(f, x, z) -- 10 Isekai Kingdom
		local r = rng:NextNumber()
		if r < 0.28 then
			P.tower(f, x, z, c("F1F1F1"), c("2D9CDB"))
		elseif r < 0.52 then
			P.crystal(f, x, z, pick({ c("5CF2E6"), c("FFE14D"), c("FF8AD8") }), rng:NextInteger(10, 18))
		elseif r < 0.74 then
			local ring = part(f, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.8, 12, 12), Position = Vector3.new(x, 8, z), Color = pick({ c("B28DFF"), c("5CF2E6") }), Material = Enum.Material.Neon, CanCollide = false })
			ring.Name = "Portal"
		else
			P.tree(f, x, z, c("6D4C41"), c("5CC96B"), rng:NextInteger(8, 12), rng:NextInteger(9, 13))
		end
	end,
	function(f, x, z) -- 11 Hero Academy City
		local r = rng:NextNumber()
		if r < 0.45 then
			P.skyscraper(f, x, z, c("7FA6D6"), c("FFFFFF"))
		elseif r < 0.68 then
			block(f, x, 4, z, 4, 8, 3, c("FFC107"), Enum.Material.Metal)
			ball(f, x, 9.6, z, 3, 3, 3, c("FFC107"), Enum.Material.Metal)
			block(f, x, 5, z - 1.8, 5, 8, 0.4, c("E53935"), Enum.Material.Fabric)
		elseif r < 0.84 then
			P.sign(f, x, z, "HERO", c("FFD43B"))
		else
			cylinder(f, x, 5, z, 10, 0.6, c("37474F"))
			ball(f, x, 10.4, z, 1.8, 1.8, 1.8, c("FFFFFF"), Enum.Material.Neon, false)
		end
	end,
	function(f, x, z) -- 12 Celestial Heaven
		local r = rng:NextNumber()
		if r < 0.3 then
			local h = rng:NextInteger(16, 24)
			cylinder(f, x, h / 2, z, h, 3, c("FFFBE0"), Enum.Material.Marble)
			ball(f, x, h + 1, z, 3, 3, 3, c("FFE066"), Enum.Material.Neon)
		elseif r < 0.55 then
			cylinder(f, x, rng:NextInteger(18, 36), z, 0.7, 16, c("FFE066"), Enum.Material.Neon).CanCollide = false
		elseif r < 0.78 then
			for i = 1, 3 do
				ball(f, x + (i - 2) * 3.4, 2 + (i % 2), z, 6, 4.5, 6, c("FFFFFF"))
			end
		else
			ball(f, x, rng:NextInteger(6, 22), z, 2.2, 2.2, 2.2, c("FFF59D"), Enum.Material.Neon, false)
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
		local count = math.clamp(math.floor(length / 6), 22, 56)
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
	part(hub, { Name = "HubGround", Size = Vector3.new(WIDTH, 4, W.HubDepth), Position = Vector3.new(0, -2, W.HubDepth / 2), Color = c("BFE8A8"), Material = Enum.Material.Grass })
	P.torii(hub, 0, 2, 1.8, c("E53935")) -- grand entrance gate
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

	local wood = c("B03A2E")
	rail(model, x - 24, z0, x - 24, z1, wood)
	rail(model, x + 24, z0, x + 24, z1, wood)
	rail(model, x - 24, z1, x + 24, z1, wood)
	rail(model, x - 24, z0, x - 8, z0, wood)
	rail(model, x + 8, z0, x + 24, z0, wood)

	-- animal pen (rear half)
	local penCenter = Vector3.new(x, 0.5, 54)
	local penHalf = Vector2.new(17, 15)
	part(model, { Name = "PenFloor", Size = Vector3.new(36, 0.2, 32), Position = Vector3.new(x, 0.6, 54), Color = c("B7E87A"), Material = Enum.Material.Grass, CanCollide = false })
	rail(model, x - 18, 38, x + 18, 38, c("D9534F"))
	rail(model, x - 18, 70, x + 18, 70, c("D9534F"))
	rail(model, x - 18, 38, x - 18, 70, c("D9534F"))
	rail(model, x + 18, 38, x + 18, 70, c("D9534F"))
	local penSign = part(model, { Name = "PenSign", Size = Vector3.one, Position = Vector3.new(x, 8, 38), Transparency = 1, CanCollide = false })
	billboard(penSign, "🏯 TEAM DOJO", UDim2.fromOffset(240, 60), accent, 90, 0)

	-- checkered launch strip (tap the prompt, or press THROW)
	local spot = ThrowMath.spot(slot)
	for ix = 0, 15 do
		for iz = 0, 1 do
			part(model, {
				Name = "Checker",
				Size = Vector3.new(2, 0.3, 2),
				Position = Vector3.new(spot.X - 15 + ix * 2, 0.65, spot.Z - 1 + iz * 2),
				Color = (ix + iz) % 2 == 0 and c("14363B") or c("FFFFFF"),
				CanCollide = false,
			})
		end
	end
	local launch = part(model, { Name = "LaunchPad", Size = Vector3.new(32, 0.3, 4), Position = Vector3.new(spot.X, 0.7, spot.Z), Transparency = 1, CanCollide = false })
	local launchPrompt = Instance.new("ProximityPrompt")
	launchPrompt.ActionText, launchPrompt.ObjectText = "TAP TO THROW!", "Launch strip"
	launchPrompt.HoldDuration = 0
	launchPrompt.MaxActivationDistance = 14
	launchPrompt.RequiresLineOfSight = false
	launchPrompt:SetAttribute("Action", "Throw")
	launchPrompt.Parent = launch
	local stripLabel = part(model, { Size = Vector3.one, Position = spot + Vector3.new(0, 6, 0), Transparency = 1, CanCollide = false })
	billboard(stripLabel, "TAP TO THROW!", UDim2.fromOffset(240, 50), c("FFD43B"), 120, 0)

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
	for k = 0, 7 do -- blue and white striped awning
		block(model, sx - 5.25 + k * 1.5, 8, sz - 1.2, 1.5, 0.8, 6.5, k % 2 == 0 and c("E53935") or c("FFFFFF"), Enum.Material.Fabric, CFrame.Angles(math.rad(-10), 0, 0))
	end
	for _, dx in { -4.6, 4.6 } do
		cylinder(model, sx + dx, 4.4, sz + 1.8, 8.8, 0.6, c("8B5A2B"), Enum.Material.Wood)
	end
	local shopPad = cylinder(model, sx, 0.7, sz - 4.5, 0.3, 9, c("FF5C9A"), Enum.Material.Neon) -- glowing entrance circle
	shopPad.Name, shopPad.CanCollide = "ShopPad", false
	prompt(shopPad, "Open", "Food Shop", "Shop")
	local shopLabel = part(model, { Size = Vector3.one, Position = Vector3.new(sx, 11.5, sz), Transparency = 1, CanCollide = false })
	billboard(shopLabel, "🛒 FOOD SHOP", UDim2.fromOffset(200, 44), c("52C1F5"), 90, 0)

	-- animals board + map board
	local ax, az = x + 16, 34
	block(model, ax, 2.6, az, 8, 5, 1, c("6C4B2A"), Enum.Material.Wood)
	local animalsPad = part(model, { Name = "AnimalsPad", Size = Vector3.new(8, 0.3, 4), Position = Vector3.new(ax, 0.65, az - 3), Color = c("2C5B61"), CanCollide = false })
	prompt(animalsPad, "Open", "My Team", "Animals")
	local animalsLabel = part(model, { Size = Vector3.one, Position = Vector3.new(ax, 7.2, az), Transparency = 1, CanCollide = false })
	billboard(animalsLabel, "🎴 TEAM", UDim2.fromOffset(180, 40), c("4CCB5E"), 80, 0)

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
	Lighting.ClockTime = 17.3
	Lighting.Brightness = 2.3
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
	bloom.Intensity, bloom.Size, bloom.Threshold = 0.5, 28, 1.4
	bloom.Parent = Lighting
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Saturation, cc.Contrast = 0.28, 0.08
	cc.TintColor = c("FFF0F6")
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
