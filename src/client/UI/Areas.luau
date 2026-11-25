-- World map: zones run down the runway; you reach them by throwing farther (more Throw Power).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Kit, Theme, Catalog = require(Shared.Kit), require(Shared.Theme), require(Shared.Catalog)
local ThrowMath, Util = require(Shared.ThrowMath), require(Shared.Util)
local State = require(script.Parent.Parent.State)
local Windows = require(script.Parent.Windows)
local C, F = Theme.Color, Theme.Font

local Areas = {}

function Areas.Init()
	local win = Windows.create("Areas", { Title = "World Map", Icon = Theme.Icons.Areas, Accent = C.Pumpkin })
	local header = Kit.label({
		Parent = win.Content,
		Size = UDim2.new(1, 0, 0, 26),
		Font = F.Display,
		TextSize = 17,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local list = Kit.scroll({
		Parent = win.Content,
		Position = UDim2.fromOffset(0, 32),
		Size = UDim2.new(1, 0, 1, -32),
		Pad = 10,
	})
	local rows = {}

	for _, area in Catalog.Areas do
		local row = Kit.new("Frame", {
			Name = "Area" .. area.Index,
			Size = UDim2.new(1, 0, 0, 84),
			BackgroundColor3 = C.PaperDark,
			LayoutOrder = area.Index,
			Parent = list,
		})
		Kit.corner(row, 16)
		Kit.stroke(row, C.Ink, 3)
		local badge = Kit.new("Frame", {
			Position = UDim2.fromOffset(8, 8),
			Size = UDim2.fromOffset(68, 68),
			BackgroundColor3 = area.Color,
			Parent = row,
		})
		Kit.corner(badge, 14)
		Kit.stroke(badge, C.Ink, 3)
		Kit.label({
			Parent = badge,
			Text = tostring(area.Index),
			Font = F.Display,
			TextSize = 34,
			TextColor3 = C.White,
			Stroke = C.Ink,
			StrokeThickness = 3,
		})
		Kit.label({
			Parent = row,
			Position = UDim2.fromOffset(88, 8),
			Size = UDim2.new(1, -250, 0, 24),
			Text = area.Name,
			Font = F.Display,
			TextSize = 21,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		Kit.label({
			Parent = row,
			Position = UDim2.fromOffset(88, 32),
			Size = UDim2.new(1, -250, 0, 16),
			Text = area.StartDist == 0 and "Start of the runway" or `Starts {Util.fmt(area.StartDist)} studs out`,
			Font = F.Bold,
			TextSize = 13,
			TextColor3 = C.InkSoft,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		local emojis = {}
		for _, id in area.Animals do
			table.insert(emojis, Catalog.Animals[id].Emoji)
		end
		Kit.label({
			Parent = row,
			Position = UDim2.fromOffset(88, 50),
			Size = UDim2.new(1, -250, 0, 26),
			Text = table.concat(emojis, " "),
			TextSize = 19,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		local chip = Kit.new("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.fromOffset(142, 56),
			BackgroundColor3 = C.Stone,
			Parent = row,
		})
		Kit.corner(chip, 14)
		Kit.stroke(chip, C.Ink, 3)
		local chipLabel = Kit.label({
			Parent = chip,
			Font = F.Display,
			TextSize = 15,
			TextColor3 = C.White,
			RichText = true,
			TextWrapped = true,
			Stroke = C.Ink,
		})
		rows[area.Index] = { area = area, chip = chip, label = chipLabel }
	end

	local function update()
		local reach = ThrowMath.reach(State.get("Strength"))
		local best = Catalog.Areas[math.max(1, State.get("AreaMax"))]
		header.Text = `Your reach: {Util.fmt(reach)} studs  ·  Furthest zone: {best.Name}`
		for index, row in rows do
			local area = row.area
			if State.get("AreaMax") >= index then
				row.chip.BackgroundColor3 = C.Leaf
				row.label.Text = "✔ Reached"
			elseif reach >= area.StartDist then
				row.chip.BackgroundColor3 = C.Butter
				row.label.Text = "In range!\nThrow farther"
			else
				row.chip.BackgroundColor3 = C.Stone
				row.label.Text = `Needs\n{Util.fmt(ThrowMath.strengthFor(area.StartDist))} Power`
			end
		end
	end
	State.Changed:Connect(update)
	update()
end

return Areas
