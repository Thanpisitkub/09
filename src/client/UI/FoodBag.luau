local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Kit, Theme, Catalog = require(Shared.Kit), require(Shared.Theme), require(Shared.Catalog)
local Net = require(Shared.Net)
local State = require(script.Parent.Parent.State)
local Windows = require(script.Parent.Windows)
local C, F = Theme.Color, Theme.Font

local FoodBag = {}

function FoodBag.Init()
	local win
	local grid
	local empty

	local function rebuild()
		for _, child in grid:GetChildren() do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
		local owned = {}
		for id, count in State.Inv.Foods do
			table.insert(owned, { food = Catalog.Foods[id], count = count })
		end
		table.sort(owned, function(a, b)
			if a.food.Tier ~= b.food.Tier then
				return a.food.Tier > b.food.Tier
			end
			return a.food.Name < b.food.Name
		end)
		empty.Visible = #owned == 0
		for i, item in owned do
			local f = item.food
			local equipped = State.Inv.Equipped == f.Id
			local tile = Kit.tile({
				Parent = grid,
				LayoutOrder = i,
				Emoji = f.Emoji,
				Title = f.Name,
				Rarity = f.Tier,
				Sub = `x{item.count}`,
			})
			Kit.button({
				Parent = tile.Action,
				Size = UDim2.fromScale(1, 1),
				Text = equipped and "Equipped" or "Equip",
				TextSize = 17,
				Style = equipped and "good" or "info",
				OnClick = function()
					if not equipped then
						Net.event("EquipFood"):FireServer(f.Id)
					end
				end,
			})
		end
	end

	win = Windows.create("FoodBag", {
		Title = "Food Inventory",
		Icon = Theme.Icons.Food,
		Accent = C.Leaf,
		OnOpen = rebuild,
	})
	grid = Kit.scroll({ Parent = win.Content, Cell = Vector2.new(150, 196) })
	empty = Kit.label({
		Parent = win.Content,
		Text = "Your bag is empty.\nBuy food in the Shop, then equip it here.",
		Font = F.Display,
		TextSize = 20,
		TextColor3 = C.InkSoft,
		TextWrapped = true,
		Visible = false,
	})
	State.Changed:Connect(function(key)
		if key == "Inventory" and win.IsOpen then
			rebuild()
		end
	end)
end

return FoodBag
