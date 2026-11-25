local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Kit, Theme, Catalog = require(Shared.Kit), require(Shared.Theme), require(Shared.Catalog)
local Net, Util = require(Shared.Net), require(Shared.Util)
local State = require(script.Parent.Parent.State)
local Windows = require(script.Parent.Windows)
local C, F = Theme.Color, Theme.Font

local MAX_TILES = 150

local Animals = {}

function Animals.Init()
	local win, grid, info, empty

	local function rebuild()
		for _, child in grid:GetChildren() do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
		local list = table.clone(State.Inv.Animals)
		table.sort(list, function(a, b)
			return Catalog.income(a.id, a.size) > Catalog.income(b.id, b.size)
		end)
		empty.Visible = #list == 0
		info.Text = `{Theme.Icons.Money} {Util.fmt(State.get("Income"))}/s   ·   Habitat {State.get("Placed")}/{State.get("Slots")}   ·   {#list} animals`
		for i = 1, math.min(#list, MAX_TILES) do
			local a = list[i]
			local animal = Catalog.Animals[a.id]
			local size = Catalog.SizeByName[a.size]
			local tile = Kit.tile({
				Parent = grid,
				LayoutOrder = i,
				Emoji = animal.Emoji,
				Title = animal.Name,
				Rarity = animal.Rarity,
				Sub = `<font color="#{size.Color:ToHex()}">{size.Name}</font> · {Util.fmt(Catalog.income(a.id, a.size))}/s`,
			})
			Kit.button({
				Parent = tile.Action,
				Size = UDim2.fromScale(1, 1),
				Text = a.placed and "Remove" or "Place",
				TextSize = 17,
				Style = a.placed and "danger" or "good",
				OnClick = function()
					Net.event(a.placed and "RemoveAnimal" or "PlaceAnimal"):FireServer(a.uid)
				end,
			})
		end
	end

	win = Windows.create("Animals", {
		Title = "My Animals",
		Icon = Theme.Icons.Animals,
		Accent = C.Leaf,
		OnOpen = rebuild,
	})
	info = Kit.label({
		Parent = win.Content,
		Size = UDim2.new(1, -250, 0, 44),
		Font = F.Bold,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
	})
	Kit.button({
		Parent = win.Content,
		Text = "Equip Best",
		TextSize = 16,
		Style = "good",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -112, 0, 0),
		Size = UDim2.fromOffset(124, 44),
		OnClick = function()
			Net.event("EquipBest"):FireServer()
		end,
	})
	Kit.button({
		Parent = win.Content,
		Text = "Collect",
		TextSize = 16,
		Style = "gold",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.fromOffset(104, 44),
		OnClick = function()
			Net.event("CollectAll"):FireServer()
		end,
	})
	grid = Kit.scroll({
		Parent = win.Content,
		Position = UDim2.fromOffset(0, 52),
		Size = UDim2.new(1, 0, 1, -52),
		Cell = Vector2.new(150, 196),
	})
	empty = Kit.label({
		Parent = win.Content,
		Position = UDim2.fromOffset(0, 52),
		Size = UDim2.new(1, 0, 1, -52),
		Text = "No animals yet.\nThrow some food to attract your first one!",
		Font = F.Display,
		TextSize = 20,
		TextColor3 = C.InkSoft,
		TextWrapped = true,
		Visible = false,
	})
	State.Changed:Connect(function(key)
		if win.IsOpen and (key == "Inventory" or key == "Income" or key == "Slots") then
			rebuild()
		end
	end)
end

return Animals
