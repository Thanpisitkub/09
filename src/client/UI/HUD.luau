local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Kit, Theme, Catalog = require(Shared.Kit), require(Shared.Theme), require(Shared.Catalog)
local Util = require(Shared.Util)
local State = require(script.Parent.Parent.State)
local Windows = require(script.Parent.Windows)
local C, F, I = Theme.Color, Theme.Font, Theme.Icons

local HUD = {}

local function rich(icon, text, iconSize, textSize)
	return `<font size="{iconSize}">{icon}</font>\n<font size="{textSize}">{text}</font>`
end

function HUD.Init()
	local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
	local gui = Kit.new("ScreenGui", {
		Name = "MainHUD",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 1,
		Parent = pg,
	})
	local function cluster(name, anchor, position, size, designWidth)
		local f = Kit.new("Frame", {
			Name = name,
			BackgroundTransparency = 1,
			AnchorPoint = anchor,
			Position = position,
			Size = size,
			Parent = gui,
		})
		Kit.autoscale(f, 600, designWidth)
		return f
	end

	-- Top: money / level / power / luck + XP bar
	local top = cluster("TopBar", Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 6), UDim2.fromOffset(560, 72), 580)
	local row = Kit.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 44), Parent = top })
	Kit.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 8),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = row,
	})
	local money = Kit.pill({ Parent = row, Icon = I.Money, Accent = C.Butter, LayoutOrder = 1 })
	local level = Kit.pill({ Parent = row, Icon = I.Level, Accent = C.Pumpkin, LayoutOrder = 2 })
	local power = Kit.pill({ Parent = row, Icon = I.Power, Accent = C.Berry, LayoutOrder = 3 })
	local luck = Kit.pill({ Parent = row, Icon = I.Luck, Accent = C.Leaf, LayoutOrder = 4 })
	local xp = Kit.bar({
		Parent = top,
		Position = UDim2.fromOffset(0, 52),
		Size = UDim2.new(1, 0, 0, 18),
		Color = C.Sky,
		TextSize = 12,
	})

	-- Left: area chip + income + collect
	local left = cluster("Income", Vector2.new(0, 0.5), UDim2.new(0, 10, 0.5, 0), UDim2.fromOffset(160, 130), nil)
	local areaChip = Kit.new("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = C.Paper, Parent = left })
	Kit.corner(areaChip, 17)
	Kit.stroke(areaChip, C.Ink, 3)
	local areaLabel = Kit.label({ Parent = areaChip, Font = F.Display, TextSize = 15, TextTruncate = Enum.TextTruncate.AtEnd })
	local incomeLabel = Kit.label({
		Parent = left,
		Position = UDim2.fromOffset(0, 38),
		Size = UDim2.new(1, 0, 0, 20),
		Font = F.Display,
		TextSize = 16,
		TextColor3 = C.White,
		Stroke = C.Ink,
		StrokeThickness = 3,
	})
	local collect = Kit.button({
		Parent = left,
		Position = UDim2.fromOffset(0, 62),
		Size = UDim2.new(1, 0, 0, 66),
		Style = "good",
		TextSize = 16,
		RichText = true,
		OnClick = function()
			require(ReplicatedStorage.Shared.Net).event("CollectAll"):FireServer()
		end,
	})

	-- Right: menus
	local right = cluster("Menu", Vector2.new(1, 0.5), UDim2.new(1, -10, 0.5, 0), UDim2.fromOffset(66, 288), nil)
	Kit.new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = right })
	local menus = {
		{ "Areas", I.Areas, "Areas", "primary" },
		{ "Upgrades", I.Upgrades, "Upgrades", "danger" },
		{ "Collection", I.Collection, "Book", "info" },
		{ "Settings", I.Settings, "Settings", "locked" },
	}
	for i, m in menus do
		Kit.button({
			Parent = right,
			LayoutOrder = i,
			Size = UDim2.fromOffset(66, 66),
			Style = m[4],
			RichText = true,
			TextSize = 11,
			Text = rich(m[2], m[3], 24, 11),
			OnClick = function()
				Windows.toggle(m[1])
			end,
		})
	end

	-- Bottom: shop / animals / THROW / food
	local bottom = cluster("Actions", Vector2.new(0.5, 1), UDim2.new(0.5, 0, 1, -10), UDim2.fromOffset(500, 120), 520)
	local bar = Kit.new("Frame", {
		Size = UDim2.new(1, 0, 0, 72),
		Position = UDim2.new(0, 0, 1, 0),
		AnchorPoint = Vector2.new(0, 1),
		BackgroundTransparency = 1,
		Parent = bottom,
	})
	Kit.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 8),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = bar,
	})
	local function small(order, style, icon, text, window)
		return Kit.button({
			Parent = bar,
			LayoutOrder = order,
			Size = UDim2.fromOffset(88, 66),
			Style = style,
			RichText = true,
			TextSize = 12,
			Text = icon and rich(icon, text, 26, 12) or "",
			OnClick = function()
				Windows.toggle(window)
			end,
		})
	end
	small(1, "info", I.Shop, "Shop", "Shop")
	small(2, "good", I.Animals, "Animals", "Animals")
	local throw = Kit.button({
		Parent = bar,
		LayoutOrder = 3,
		Size = UDim2.fromOffset(190, 72),
		Style = "primary",
		Text = "THROW",
		TextSize = 30,
	})
	local foodChip = small(4, "gold", nil, nil, "FoodBag")

	local meterFrame = Kit.new("Frame", {
		Name = "PowerMeter",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -86),
		Size = UDim2.fromOffset(250, 44),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = bottom,
	})
	local distLabel = Kit.label({
		Parent = meterFrame,
		Size = UDim2.new(1, 0, 0, 20),
		Font = F.Display,
		TextSize = 17,
		TextColor3 = C.White,
		Stroke = C.Ink,
		StrokeThickness = 3,
	})
	local meter = Kit.bar({
		Parent = meterFrame,
		Position = UDim2.fromOffset(0, 24),
		Size = UDim2.new(1, 0, 0, 20),
		Color = C.Leaf,
	})

	HUD.Throw = throw
	HUD.MeterFrame = meterFrame
	HUD.Meter = meter
	HUD.DistLabel = distLabel

	function HUD.refresh()
		money.Set(Util.fmt(State.get("Money")))
		level.Set("Lv " .. State.get("Level"))
		power.Set(Util.fmt(State.get("Strength")))
		luck.Set(Util.fmt(State.get("Luck")))
		local xpNow, xpNeed = State.get("XP"), math.max(1, State.get("XPNext"))
		xp.Set(xpNow / xpNeed, `XP {Util.fmt(xpNow)} / {Util.fmt(xpNeed)}`)

		local area = Catalog.Areas[math.max(1, State.get("Zone"))]
		areaLabel.Text = `📍 {area.Name}`
		incomeLabel.Text = `+{Util.fmt(State.get("Income"))}/s`
		collect.SetText(rich("COLLECT", `{I.Money} {Util.fmt(State.get("Pending"))}`, 17, 16))

		local eq = State.Inv.Equipped
		local food = Catalog.Foods[eq]
		local count = food and State.foodCount(eq) or 0
		foodChip.SetText(food and rich(food.Emoji, `x{count}`, 26, 14) or rich(I.Food, "none", 26, 12))
		throw.SetStyle(count > 0 and "primary" or "locked")
		throw.SetText(count > 0 and "THROW" or "NO FOOD")
	end
	State.Changed:Connect(HUD.refresh)
	HUD.refresh()
end

return HUD
