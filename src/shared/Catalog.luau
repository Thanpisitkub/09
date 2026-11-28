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

-- 12 anime zones x 6 characters = 72 ORIGINAL characters (archetypes, not existing anime IP).
-- { name, portrait emoji (fallback), face icon key, hair color }
local areaDefs = {
	{ "Sakura Village", "FF9EC4", { { "Petal Girl", "🌸", "FaceBeam", "FFB7D5" }, { "Village Boy", "🧒", "FaceZany", "7A5230" }, { "Lantern Keeper", "🏮", "FaceShy", "FF8F2B" }, { "Kitsune Maiden", "🦊", "FaceWink", "E8A33B" }, { "Blossom Archer", "🏹", "FaceCool", "FF6FA8" }, { "Cherry Captain", "⚔️", "FaceSalute", "C2185B" } } },
	{ "Ninja Dojo Hills", "6FBF73", { { "Rookie Ninja", "🥋", "FaceBeam", "2F3A4F" }, { "Shadow Scout", "🌑", "FaceSmirk", "1B1B2F" }, { "Shuriken Kid", "⭐", "FaceZany", "3A86FF" }, { "Smoke Master", "💨", "FaceThink", "6C7A89" }, { "Bamboo Blade", "🎋", "FaceCool", "2E7D32" }, { "Grand Sensei", "🧘", "FaceSalute", "E0E0E0" } } },
	{ "Samurai Castle", "C0392B", { { "Foot Soldier", "🛡️", "FaceAngry", "5D4037" }, { "Ronin Wanderer", "🗡️", "FaceSleep", "37474F" }, { "Katana Lady", "🌺", "FaceCool", "880E4F" }, { "Banner Knight", "🚩", "FaceSalute", "B71C1C" }, { "Shogun Heir", "🏯", "FaceSmirk", "311B92" }, { "Iron Shogun", "👺", "FaceAngry", "212121" } } },
	{ "Magic Academy", "7E57C2", { { "Apprentice Mage", "🧙", "FaceNerd", "6A4C93" }, { "Potion Prodigy", "🧪", "FaceZany", "00BFA5" }, { "Rune Scholar", "📚", "FaceThink", "3949AB" }, { "Star Witch", "🌟", "FaceStar", "FFD54F" }, { "Spell Duelist", "🔮", "FaceSmirk", "E91E63" }, { "Archmage Headmaster", "🎓", "FaceBoom", "9E9E9E" } } },
	{ "Spirit Shrine", "4FC3F7", { { "Shrine Maiden", "⛩️", "FaceHalo", "F8BBD0" }, { "Fox Spirit", "🦊", "FaceWink", "FF7043" }, { "Wisp Child", "👻", "FaceBeam", "80DEEA" }, { "Oni Guard", "👹", "FaceAngry", "D32F2F" }, { "Spirit Monk", "🙏", "FaceSleep", "8D6E63" }, { "Moon Kitsune", "🌙", "FaceStar", "CFD8DC" } } },
	{ "Pirate Seas", "29B6F6", { { "Deckhand", "⚓", "FaceBeam", "5D4037" }, { "Cannon Girl", "💥", "FaceBoom", "FF7043" }, { "Navigator", "🧭", "FaceThink", "26A69A" }, { "First Mate", "🏴", "FaceCool", "455A64" }, { "Storm Captain", "⛈️", "FaceSalute", "1A237E" }, { "Treasure Queen", "👑", "FaceSmirk", "FFC107" } } },
	{ "Neon Tokyo", "EC407A", { { "Idol Trainee", "🎤", "FaceBeam", "FF80AB" }, { "Street Racer", "🏎️", "FaceCool", "00E5FF" }, { "Hacker Girl", "💻", "FaceSmirk", "76FF03" }, { "Cyber Samurai", "🤖", "FaceSalute", "651FFF" }, { "Neon DJ", "🎧", "FaceParty", "F50057" }, { "Virtual Idol", "💿", "FaceStar", "18FFFF" } } },
	{ "Mecha Wasteland", "FF7043", { { "Pilot Cadet", "🚀", "FaceBeam", "5D4037" }, { "Mech Mechanic", "🔧", "FaceNerd", "FFA000" }, { "Robo Buddy", "🤖", "FaceZany", "B0BEC5" }, { "Ace Pilot", "🛩️", "FaceCool", "D84315" }, { "Titan Commander", "⚙️", "FaceSalute", "37474F" }, { "Core Guardian", "⚡", "FaceBoom", "FF1744" } } },
	{ "Demon Hunt Forest", "8E44AD", { { "Night Hunter", "🌃", "FaceCool", "311B92" }, { "Blade Novice", "🗡️", "FaceShy", "4E342E" }, { "Crimson Oni", "👹", "FaceDevil", "C62828" }, { "Lily Spirit", "🥀", "FaceHeart", "AD1457" }, { "Twin Fang", "🐺", "FaceAngry", "455A64" }, { "Dawn Captain", "🌅", "FaceSalute", "FF8F00" } } },
	{ "Isekai Kingdom", "66BB6A", { { "Reborn Hero", "✨", "FaceBeam", "42A5F5" }, { "Elf Archer", "🧝", "FaceWink", "9CCC65" }, { "Dwarf Smith", "🔨", "FaceCool", "8D6E63" }, { "Demon Lord", "😈", "FaceDevil", "4A148C" }, { "Hero Princess", "👸", "FaceHeart", "F48FB1" }, { "Goddess Guide", "🌿", "FaceHalo", "80CBC4" } } },
	{ "Hero Academy City", "42A5F5", { { "Rookie Hero", "🦸", "FaceBeam", "66BB6A" }, { "Speed Hero", "💨", "FaceZany", "FFEE58" }, { "Sky Hero", "☁️", "FaceCool", "90CAF9" }, { "Shield Hero", "🛡️", "FaceSalute", "78909C" }, { "Top Pro Hero", "🏅", "FaceSmirk", "EF5350" }, { "Legend Hero", "🌞", "FaceStar", "FFD600" } } },
	{ "Celestial Heaven", "FFD54F", { { "Angel Trainee", "👼", "FaceHalo", "FFF9C4" }, { "Starlight Idol", "🌟", "FaceParty", "FFCA28" }, { "Halo Knight", "⚜️", "FaceSalute", "B0BEC5" }, { "Cosmic Sage", "🪐", "FaceThink", "7E57C2" }, { "Divine Valkyrie", "🔱", "FaceCool", "FFD54F" }, { "Heavenly Emperor", "👑", "FaceBoom", "FFFFFF" } } },
}
local OFFSETS = { 0, 0, 1, 1, 2, 3 }
local FOOD_ICON = {
	Carrot = "Carrot", Apple = "Apple", Wheat = "Wheat", Banana = "Banana", Mango = "Lemon",
	["Crystal Berry"] = "Blueberry", ["Divine Fruit"] = "Orange", ["Golden Apple"] = "GoldenApple",
	["Angel Cookie"] = "Cookie", ["Rainbow Cake"] = "Pancake", ["Nebula Pie"] = "Pizza",
	["Cosmic Berry"] = "Strawberry", ["Infinity Feast"] = "Burger", ["Sovereign Elixir"] = "PurplePotion",
	["Star Fruit"] = "Star",
}

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
			Icon = pair[3],
			Hair = hex(pair[4]),
			Area = ai,
			Rarity = rarity,
			BaseIncome = math.max(1, math.floor(income * 10) / 10),
			Description = `A {Catalog.Rarities[rarity].Name:lower()} character who lives in {def[1]}.`,
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
		Icon = FOOD_ICON[def[2]],
		Tier = tier,
		Price = math.floor(8 * 3.2 ^ (tier - 1) * (1 + 0.3 * (k - 1))),
		RequiredLevel = (tier - 1) * 4 + k,
		Boost = 1 + 0.25 * (tier - 1),
		Description = `Draws {Catalog.Rarities[tier].Name} characters and rarer.`,
	}
	Catalog.Foods[id] = food
	table.insert(Catalog.FoodList, food)
end

Catalog.Upgrades = {
	Strength = { Name = "Strength Boost", Icon = "💪", Desc = "+5 Throw Power", Base = 100, Growth = 1.35, Max = 500, Gain = 5 },
	Luck = { Name = "Lucky Charm", Icon = "🍀", Desc = "+1 Luck", Base = 250, Growth = 1.6, Max = 60, Gain = 1 },
	Slots = { Name = "Team Slot", Icon = "🏯", Desc = "+1 team slot", Base = 500, Growth = 2.1, Max = 24, Gain = 1 },
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

function Catalog.sellPrice(animalId, sizeName)
	return math.max(1, math.floor(Catalog.income(animalId, sizeName) * 45))
end

function Catalog.income(animalId, sizeName)
	local a, s = Catalog.Animals[animalId], Catalog.SizeByName[sizeName]
	if not a or not s then
		return 0
	end
	return math.floor(a.BaseIncome * s.Mult * 10) / 10
end

return Catalog
