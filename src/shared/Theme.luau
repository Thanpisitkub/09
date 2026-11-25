-- Design tokens. "Feed-tag" look: warm paper panels, deep-teal ink outlines, chunky lipped buttons.
local function hex(h)
	return Color3.fromHex(h)
end

local Theme = {}

Theme.Color = {
	Ink = hex("14363B"),
	InkSoft = hex("2C5B61"),
	Paper = hex("FFF4DC"),
	PaperDark = hex("F1DDB0"),
	White = hex("FFFFFF"),
	Pumpkin = hex("FF8F2B"), PumpkinLip = hex("C95F0A"),
	Leaf = hex("4CCB5E"), LeafLip = hex("2C9440"),
	Berry = hex("F2546E"), BerryLip = hex("B82C45"),
	Sky = hex("52C1F5"), SkyLip = hex("2A8DBF"),
	Butter = hex("FFD43B"), ButterLip = hex("D1A100"),
	Stone = hex("A9B4B2"), StoneLip = hex("7C8886"),
}

Theme.Font = {
	Display = Enum.Font.FredokaOne,
	Body = Enum.Font.BuilderSansMedium,
	Bold = Enum.Font.BuilderSansBold,
}

Theme.Radius = { Sm = 10, Md = 16, Lg = 24 }

-- Swap any of these for an image asset id later (Kit reads text only for now).
Theme.Icons = {
	Money = "🪙", Level = "⭐", Power = "💪", Luck = "🍀",
	Shop = "🛒", Animals = "🐾", Food = "🎒", Areas = "🗺️",
	Upgrades = "⚡", Collection = "📖", Settings = "⚙️", Throw = "🎯",
	Lock = "🔒", Admin = "🛡️",
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
