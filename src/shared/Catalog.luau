-- Single source of truth for areas, animals, foods, rarities, sizes and upgrades.
-- Emoji are placeholder icons: swap `Emoji` for an image/viewport later without touching the UI.
local Config = require(script.Parent.Config)
local Catalog = {}

local function hex(h)
	return Color3.fromHex(h)
end

Catalog.Rarities = {
	{ Name = "Common", Color = hex("B8C2CC") },
	{ Name = "Uncommon", Color = hex("5BD36B") },
	{ Name = "Rare", Color = hex("4DA3FF") },
	{ Name = "Epic", Color = hex("A66BFF") },
	{ Name = "Legendary", Color = hex("FFB020") },
	{ Name = "Mythical", Color = hex("FF4D8D") },
	{ Name = "Divine", Color = hex("FFE066") },
	{ Name = "Celestial", Color = hex("5CF2E6") },
	{
		Name = "Sovereign",
		Color = hex("FF5CF2"),
		Gradient = ColorSequence.new({
			ColorSequenceKeypoint.new(0, hex("FFD43B")),
			ColorSequenceKeypoint.new(0.5, hex("FF5CF2")),
			ColorSequenceKeypoint.new(1, hex("5CF2E6")),
		}),
	},
}
Catalog.RarityWeight = { 100, 55, 28, 12, 5, 2, 0.8, 0.3, 0.1 }

Catalog.Sizes = {
	{ Name = "Tiny", Weight = 4, Mult = 0.5, Color = hex("9AA7A5") },
	{ Name = "Small", Weight = 20, Mult = 0.8, Color = hex("6FCF97") },
	{ Name = "Normal", Weight = 50, Mult = 1, Color = hex("56CCF2") },
	{ Name = "Large", Weight = 18, Mult = 1.5, Color = hex("BB6BD9") },
	{ Name = "Giant", Weight = 6, Mult = 2.5, Color = hex("F2994A") },
	{ Name = "Colossal", Weight = 2, Mult = 5, Color = hex("EB5757") },
}
Catalog.SizeByName = {}
for i, s in Catalog.Sizes do
	s.Index = i
	Catalog.SizeByName[s.Name] = s
end

-- 12 areas x 6 animals = 72 animals.
local areaDefs = {
	{ "Green Meadow", "7ED957", { { "Rabbit", "🐇" }, { "Chicken", "🐔" }, { "Duck", "🦆" }, { "Sheep", "🐑" }, { "Pig", "🐖" }, { "Deer", "🦌" } } },
	{ "Sunny Farm", "F2C94C", { { "Cow", "🐄" }, { "Horse", "🐎" }, { "Goat", "🐐" }, { "Donkey", "🐴" }, { "Turkey", "🦃" }, { "Alpaca", "🦙" } } },
	{ "Tropical Jungle", "27AE60", { { "Monkey", "🐒" }, { "Toucan", "🐦" }, { "Parrot", "🦜" }, { "Jaguar", "🐆" }, { "Sloth", "🦥" }, { "Capybara", "🐹" } } },
	{ "Desert Kingdom", "E2A93B", { { "Camel", "🐪" }, { "Fennec Fox", "🦊" }, { "Meerkat", "🐿️" }, { "Desert Fox", "🦊" }, { "Scorpion", "🦂" }, { "Desert Tortoise", "🐢" } } },
	{ "Frozen Mountains", "9BDDFF", { { "Polar Bear", "🐻" }, { "Arctic Fox", "🦊" }, { "Penguin", "🐧" }, { "Reindeer", "🦌" }, { "Seal", "🦦" }, { "Snow Leopard", "🐆" } } },
	{ "Deep Ocean", "2D9CDB", { { "Dolphin", "🐬" }, { "Shark", "🦈" }, { "Sea Turtle", "🐢" }, { "Octopus", "🐙" }, { "Whale", "🐋" }, { "Seahorse", "🐠" } } },
	{ "Volcanic Island", "EB5757", { { "Fire Salamander", "🦎" }, { "Lava Lizard", "🦎" }, { "Phoenix", "🔥" }, { "Red Dragon", "🐉" }, { "Magma Turtle", "🐢" }, { "Fire Fox", "🦊" } } },
	{ "Mystical Forest", "9B51E0", { { "Unicorn", "🦄" }, { "Fairy Fox", "🦊" }, { "Spirit Deer", "🦌" }, { "Crystal Owl", "🦉" }, { "Moon Rabbit", "🐇" }, { "Magical Wolf", "🐺" } } },
	{ "Sky Kingdom", "74C0FC", { { "Sky Dragon", "🐲" }, { "Cloud Pegasus", "🦄" }, { "Golden Eagle", "🦅" }, { "Storm Phoenix", "🔥" }, { "Celestial Butterfly", "🦋" }, { "Cloud Lion", "🦁" } } },
	{ "Ancient Kingdom", "C9A227", { { "Royal Griffin", "🦅" }, { "Ancient Dragon", "🐉" }, { "Golden Tiger", "🐯" }, { "Royal Lion", "🦁" }, { "Ancient Phoenix", "🔥" }, { "Imperial Elephant", "🐘" } } },
	{ "Galaxy World", "5B4BDB", { { "Galaxy Cat", "🐈" }, { "Cosmic Whale", "🐋" }, { "Alien Fox", "🦊" }, { "Star Dragon", "🐲" }, { "Nebula Rabbit", "🐇" }, { "Space Phoenix", "🔥" } } },
	{ "Divine Realm", "FFE066", { { "Divine Dragon", "🐉" }, { "Celestial Lion", "🦁" }, { "Eternal Phoenix", "🔥" }, { "Heavenly Unicorn", "🦄" }, { "Godly Wolf", "🐺" }, { "Infinity Whale", "🐋" } } },
}
local OFFSETS = { 0, 0, 1, 1, 2, 3 }

Catalog.Areas = {}
Catalog.Animals = {}
Catalog.AnimalList = {}

for ai, def in areaDefs do
	local base = math.clamp(math.floor((ai - 1) * 0.6) + 1, 1, 9)
	local area = {
		Index = ai,
		Name = def[1],
		Color = hex(def[2]),
		StartDist = Config.World.ZoneStarts[ai],
		Animals = {},
	}
	for slot, pair in def[3] do
		local id = (pair[1]:gsub("%s", ""))
		local rarity = math.min(9, base + OFFSETS[slot])
		local income = 1.5 * 1.9 ^ (rarity - 1) * (1 + 0.15 * (ai - 1))
		local animal = {
			Id = id,
			Name = pair[1],
			Emoji = pair[2],
			Area = ai,
			Rarity = rarity,
			BaseIncome = math.max(1, math.floor(income * 10) / 10),
			Description = `A {Catalog.Rarities[rarity].Name:lower()} animal found in the {def[1]}.`,
		}
		Catalog.Animals[id] = animal
		table.insert(Catalog.AnimalList, animal)
		table.insert(area.Animals, id)
	end
	Catalog.Areas[ai] = area
end

-- 30 foods across the 9 rarity tiers.
local foodDefs = {
	{ 1, "Carrot", "🥕" }, { 1, "Apple", "🍎" }, { 1, "Bread", "🍞" }, { 1, "Corn", "🌽" }, { 1, "Wheat", "🌾" },
	{ 2, "Banana", "🍌" }, { 2, "Fish", "🐟" }, { 2, "Cheese", "🧀" }, { 2, "Watermelon", "🍉" },
	{ 3, "Honey", "🍯" }, { 3, "Pineapple", "🍍" }, { 3, "Steak", "🥩" }, { 3, "Mango", "🥭" },
	{ 4, "Golden Apple", "🍏" }, { 4, "Crystal Berry", "💠" }, { 4, "Magic Mushroom", "🍄" }, { 4, "Dragon Fruit", "🍈" },
	{ 5, "Star Fruit", "⭐" }, { 5, "Rainbow Cake", "🍰" }, { 5, "Phoenix Pepper", "🌶️" },
	{ 6, "Moon Peach", "🍑" }, { 6, "Frost Grape", "🍇" }, { 6, "Dragon Egg", "🥚" },
	{ 7, "Divine Fruit", "🍊" }, { 7, "Angel Cookie", "🍪" }, { 7, "Sun Melon", "☀️" },
	{ 8, "Cosmic Berry", "🔮" }, { 8, "Nebula Pie", "🥧" },
	{ 9, "Sovereign Elixir", "🧪" }, { 9, "Infinity Feast", "🍽️" },
}

Catalog.Foods = {}
Catalog.FoodList = {}
local seen = {}
for _, def in foodDefs do
	local tier = def[1]
	seen[tier] = (seen[tier] or 0) + 1
	local k = seen[tier]
	local id = (def[2]:gsub("%s", ""))
	local food = {
		Id = id,
		Name = def[2],
		Emoji = def[3],
		Tier = tier,
		Price = math.floor(8 * 3.2 ^ (tier - 1) * (1 + 0.3 * (k - 1))),
		RequiredLevel = (tier - 1) * 4 + k,
		Boost = 1 + 0.25 * (tier - 1),
		Description = `Draws {Catalog.Rarities[tier].Name} animals and rarer.`,
	}
	Catalog.Foods[id] = food
	table.insert(Catalog.FoodList, food)
end

Catalog.Upgrades = {
	Strength = { Name = "Strength Boost", Icon = "💪", Desc = "+5 Throw Power", Base = 100, Growth = 1.35, Max = 500, Gain = 5 },
	Luck = { Name = "Lucky Charm", Icon = "🍀", Desc = "+1 Luck", Base = 250, Growth = 1.6, Max = 60, Gain = 1 },
	Slots = { Name = "Habitat Slot", Icon = "🏡", Desc = "+1 habitat slot", Base = 500, Growth = 2.1, Max = 24, Gain = 1 },
}
Catalog.UpgradeOrder = { "Strength", "Luck", "Slots" }

-- Which zone a landing distance (studs beyond the start line) belongs to.
function Catalog.zoneAt(dist)
	for i = #Catalog.Areas, 1, -1 do
		if dist >= Catalog.Areas[i].StartDist then
			return i
		end
	end
	return 1
end

function Catalog.upgradeCost(kind, owned)
	local u = Catalog.Upgrades[kind]
	return math.floor(u.Base * u.Growth ^ owned)
end

function Catalog.xpNeeded(level)
	return math.floor(60 * level ^ 1.5)
end

function Catalog.income(animalId, sizeName)
	local a, s = Catalog.Animals[animalId], Catalog.SizeByName[sizeName]
	if not a or not s then
		return 0
	end
	return math.floor(a.BaseIncome * s.Mult * 10) / 10
end

return Catalog
