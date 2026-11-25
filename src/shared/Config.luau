return {
	Version = 1,
	StartMoney = 150,
	StartStrength = 10,
	StartLuck = 1,
	StartSlots = 4,
	MaxAnimals = 500,
	StartFoods = { Carrot = 5 },
	ThrowCooldown = 0.9,
	AutosaveSeconds = 60,

	-- The world is one long runway. Plots sit behind the start line (z >= 0); zones run down -Z.
	World = {
		Slots = 10,
		SlotSpacing = 56,
		TrackZ = 0, -- zone distance is measured from here
		ThrowZ = 8, -- every throw spot sits this far behind the start line
		PlotDepth = 72,
		HubDepth = 150,
		LastZoneLength = 400,
		WidthPadding = 160,
		ZoneStarts = { 0, 70, 150, 250, 370, 510, 670, 850, 1050, 1270, 1510, 1770 },
	},

	Admin = {
		-- Unpublished places report CreatorId 0. To test the creator-only menu in Studio,
		-- put YOUR UserId here. Ignored in live servers.
		StudioCreatorUserId = 0,
		RequestCooldown = 0.35,
		PendingTtl = 60,
		MaxPendingPerAdmin = 5,
		Max = { Strength = 1e12, Luck = 1e6, Money = 1e15 },
		LogLimit = 300,
	},
}
