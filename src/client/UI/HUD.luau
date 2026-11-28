local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Kit, Theme, Catalog = require(Shared.Kit), require(Shared.Theme), require(Shared.Catalog)
local Util, Net = require(Shared.Util), require(Shared.Net)
local State = require(script.Parent.Parent.State)
local Windows = require(script.Parent.Windows)
local C, F, I = Theme.Color, Theme.Font, Theme.Icons

local HUD = {}

function HUD.Init()
	local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
	local gui = Kit.safe(Kit.new("ScreenGui", {
		Name = "MainHUD",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 1,
		Parent = pg,
	}))
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

	-- Left edge: Index / Map / Upgrades / Settings (icon over caption)
	local left = cluster("Menu", Vector2.new(0, 0.5), UDim2.new(0, 10, 0.5, 0), UDim2.fromOffset(70, 304), nil)
	Kit.new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = left })
	local menus = {
		{ "Collection", I.Collection, "Index", "info" },
		{ "Areas", I.Areas, "Map", "primary" },
		{ "Upgrades", I.Upgrades, "Train", "good" },
		{ "Settings", I.Settings, "Settings", "locked" },
	}
	for i, m in menus do
		Kit.button({
			Parent = left,
			LayoutOrder = i,
			Size = UDim2.fromOffset(70, 70),
			Style = m[4],
			Icon = m[2],
			Text = m[3],
			TextSize = 12,
			OnClick = function()
				Windows.toggle(m[1])
			end,
		})
	end

	-- Right edge: where you are, income, collect
	local right = cluster("Income", Vector2.new(1, 0.5), UDim2.new(1, -10, 0.5, 0), UDim2.fromOffset(160, 130), nil)
	local areaChip = Kit.new("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = C.Paper,
		Parent = right,
	})
	Kit.corner(areaChip, 17)
	Kit.stroke(areaChip, C.Ink, 3)
	local areaLabel = Kit.label({ Parent = areaChip, Font = F.Display, TextSize = 14, TextTruncate = Enum.TextTruncate.AtEnd })
	local incomeLabel = Kit.label({
		Parent = right,
		Position = UDim2.fromOffset(0, 38),
		Size = UDim2.new(1, 0, 0, 20),
		Font = F.Display,
		TextSize = 16,
		TextColor3 = C.White,
		Stroke = C.Ink,
		StrokeThickness = 3,
	})
	local collect = Kit.button({
		Parent = right,
		Position = UDim2.fromOffset(0, 62),
		Size = UDim2.new(1, 0, 0, 66),
		Style = "good",
		TextSize = 17,
		RichText = true,
		OnClick = function()
			Net.event("CollectAll"):FireServer()
		end,
	})

	-- Bottom: shop / animals / THROW / food
	local bottom = cluster("Actions", Vector2.new(0.5, 1), UDim2.new(0.5, 0, 1, -10), UDim2.fromOffset(500, 76), 520)
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
			Icon = icon,
			Text = text,
			TextSize = 12,
			OnClick = function()
				Windows.toggle(window)
			end,
		})
	end
	small(1, "info", I.Shop, "Shop", "Shop")
	small(2, "good", I.Animals, "Team", "Animals")
	local throw = Kit.button({
		Parent = bar,
		LayoutOrder = 3,
		Size = UDim2.fromOffset(190, 72),
		Style = "primary",
		Text = "THROW",
		TextSize = 30,
	})
	local foodChip = small(4, "gold", nil, "none", "FoodBag")
	local chipIcon, chipKey

	HUD.Throw = throw

	function HUD.refresh()
		money.Set("$" .. Util.fmt(State.get("Money")))
		level.Set("Lv " .. State.get("Level"))
		power.Set(Util.fmt(State.get("Strength")))
		luck.Set(Util.fmt(State.get("Luck")))
		local xpNow, xpNeed = State.get("XP"), math.max(1, State.get("XPNext"))
		xp.Set(xpNow / xpNeed, `XP {Util.fmt(xpNow)} / {Util.fmt(xpNeed)}`)

		local area = Catalog.Areas[math.max(1, State.get("Zone"))]
		areaLabel.Text = area.Name
		incomeLabel.Text = `+${Util.fmt(State.get("Income"))}/s`
		collect.SetText(`COLLECT\n<font size="15">${Util.fmt(State.get("Pending"))}</font>`)

		local eq = State.Inv.Equipped
		local food = Catalog.Foods[eq]
		local count = food and State.foodCount(eq) or 0
		if chipKey ~= eq then
			chipKey = eq
			if chipIcon then
				chipIcon:Destroy()
			end
			chipIcon = Kit.icon({
				Parent = foodChip.Face,
				Key = food and food.Icon or I.Food,
				Emoji = food and food.Emoji or nil,
				Size = UDim2.fromScale(0.6, 0.6),
				Position = UDim2.fromScale(0.5, 0.04),
				AnchorPoint = Vector2.new(0.5, 0),
				TextSize = 26,
			})
			Kit.new("UIAspectRatioConstraint", { Parent = chipIcon })
			foodChip.Label.Position = UDim2.fromScale(0, 0.64)
			foodChip.Label.Size = UDim2.fromScale(1, 0.34)
		end
		foodChip.SetText(food and `x{count}` or "none")
		throw.SetStyle(count > 0 and "primary" or "locked")
		throw.SetText(count > 0 and "THROW" or "NO FOOD")
	end
	State.Changed:Connect(HUD.refresh)
	HUD.refresh()
end

return HUD
