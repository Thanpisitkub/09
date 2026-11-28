-- Design tokens. "Feed-tag" look: warm paper panels, deep-teal ink outlines, chunky lipped buttons.
local function hex(h)
	return Color3.fromHex(h)
end

local Theme = {}

Theme.Color = {
	Ink = hex("251B4A"),
	InkSoft = hex("5B4B8A"),
	Paper = hex("FFF3F8"),
	PaperDark = hex("F6DDEA"),
	White = hex("FFFFFF"),
	Pumpkin = hex("FF5C9A"), PumpkinLip = hex("C93A74"),
	Leaf = hex("4CCB5E"), LeafLip = hex("2C9440"),
	Berry = hex("F2445E"), BerryLip = hex("B02040"),
	Sky = hex("4DB8FF"), SkyLip = hex("2A86CC"),
	Butter = hex("FFD43B"), ButterLip = hex("D1A100"),
	Stone = hex("B0A8C8"), StoneLip = hex("857DA0"),
}

Theme.Font = {
	Display = Enum.Font.FredokaOne,
	Body = Enum.Font.BuilderSansMedium,
	Bold = Enum.Font.BuilderSansBold,
}

Theme.Radius = { Sm = 10, Md = 16, Lg = 24 }

-- Icon KEYS (see Icons.luau). Kit renders the uploaded image, or an emoji if no asset id exists yet.
Theme.Icons = {
	Money = "Coin", Level = "Star", Power = "Arm", Luck = "Clover",
	Shop = "Shop", Animals = "Paw", Food = "Backpack", Areas = "Planet",
	Upgrades = "Upgrade", Collection = "Book", Settings = "Settings", Throw = "Arm",
	Lock = "Lock", Admin = "🛡️",
}

-- Admin tooling is deliberately a different visual language: calm, dark, dense.
Theme.Admin = {
	Bg = hex("0E1120"),
	Panel = hex("171B2E"),
	Raised = hex("20253C"),
	Line = hex("2E3556"),
	Text = hex("E8EAF6"),
	Muted = hex("8E94B8"),
	Accent = hex("7C6BFF"),
	AccentLip = hex("5444D6"),
	Good = hex("3DDC97"),
	Bad = hex("FF5C7A"),
}

return Theme
