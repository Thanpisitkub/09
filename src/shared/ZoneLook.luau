-- Per-zone palette. The server paints the ground with it, the client tints fog and ambient light.
local function hex(h)
	return Color3.fromHex(h)
end

return {
	{ Ground = hex("F4C6D8"), Material = Enum.Material.Grass, Fog = hex("FFD9E8"), Ambient = hex("B59AA8") }, -- Sakura Village
	{ Ground = hex("8BCB72"), Material = Enum.Material.Grass, Fog = hex("D7F2B8"), Ambient = hex("8EA37C") }, -- Ninja Dojo Hills
	{ Ground = hex("B8A98A"), Material = Enum.Material.Slate, Fog = hex("F2C9A0"), Ambient = hex("A8927C") }, -- Samurai Castle
	{ Ground = hex("6F5BC4"), Material = Enum.Material.Grass, Fog = hex("D6C4FF"), Ambient = hex("8F7EC0") }, -- Magic Academy
	{ Ground = hex("3E6F8E"), Material = Enum.Material.Slate, Fog = hex("A9E4FF"), Ambient = hex("6C94B0") }, -- Spirit Shrine
	{ Ground = hex("2E9CE0"), Material = Enum.Material.Glass, Fog = hex("9ADCFF"), Ambient = hex("6C9EC0") }, -- Pirate Seas
	{ Ground = hex("1A1636"), Material = Enum.Material.SmoothPlastic, Fog = hex("7A3FBF"), Ambient = hex("6A4FA8") }, -- Neon Tokyo
	{ Ground = hex("6B5B52"), Material = Enum.Material.Metal, Fog = hex("FFA36B"), Ambient = hex("A07A62") }, -- Mecha Wasteland
	{ Ground = hex("2D1B3F"), Material = Enum.Material.Grass, Fog = hex("8E5AA8"), Ambient = hex("6C4F80") }, -- Demon Hunt Forest
	{ Ground = hex("7FD18B"), Material = Enum.Material.Grass, Fog = hex("C8F5D0"), Ambient = hex("86AE90") }, -- Isekai Kingdom
	{ Ground = hex("A9C7E8"), Material = Enum.Material.Concrete, Fog = hex("D6ECFF"), Ambient = hex("94A8C0") }, -- Hero Academy City
	{ Ground = hex("FFF3C4"), Material = Enum.Material.Marble, Fog = hex("FFF6D8"), Ambient = hex("C8BC96") }, -- Celestial Heaven
}
