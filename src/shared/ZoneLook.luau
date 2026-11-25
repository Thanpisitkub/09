-- Per-zone palette. The server paints the ground with it, the client tints fog and ambient light.
local function hex(h)
	return Color3.fromHex(h)
end

return {
	{ Ground = hex("7ED957"), Material = Enum.Material.Grass, Fog = hex("C8F0FF"), Ambient = hex("8FA88A") },
	{ Ground = hex("D9BE5C"), Material = Enum.Material.Grass, Fog = hex("FFE9B0"), Ambient = hex("A89A78") },
	{ Ground = hex("2E9B55"), Material = Enum.Material.Grass, Fog = hex("A8E6C0"), Ambient = hex("6E9A7E") },
	{ Ground = hex("E8C27A"), Material = Enum.Material.Sand, Fog = hex("FFD9A0"), Ambient = hex("B0987A") },
	{ Ground = hex("EAF4FF"), Material = Enum.Material.Snow, Fog = hex("D6EEFF"), Ambient = hex("94A8BE") },
	{ Ground = hex("2A8DD6"), Material = Enum.Material.Glass, Fog = hex("9AD8FF"), Ambient = hex("6C94B8") },
	{ Ground = hex("3A2C2C"), Material = Enum.Material.Basalt, Fog = hex("FF9A6B"), Ambient = hex("A06A5A") },
	{ Ground = hex("7B4FBF"), Material = Enum.Material.Grass, Fog = hex("D9B8FF"), Ambient = hex("8A72B0") },
	{ Ground = hex("F5FBFF"), Material = Enum.Material.SmoothPlastic, Fog = hex("BFE3FF"), Ambient = hex("9CB4CC") },
	{ Ground = hex("C9A96A"), Material = Enum.Material.Sandstone, Fog = hex("FFE0A0"), Ambient = hex("B09A74") },
	{ Ground = hex("1C1C4E"), Material = Enum.Material.SmoothPlastic, Fog = hex("4A3AA0"), Ambient = hex("6A5AA8") },
	{ Ground = hex("FFF3B0"), Material = Enum.Material.Marble, Fog = hex("FFFBE0"), Ambient = hex("C8BC96") },
}
