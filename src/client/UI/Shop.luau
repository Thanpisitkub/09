local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Kit, Theme, Catalog = require(Shared.Kit), require(Shared.Theme), require(Shared.Catalog)
local Net, Util = require(Shared.Net), require(Shared.Util)
local State = require(script.Parent.Parent.State)
local Windows = require(script.Parent.Windows)
local C, F = Theme.Color, Theme.Font

local Shop = {}

function Shop.Init()
	local win = Windows.create("Shop", { Title = "Food Shop", Icon = Theme.Icons.Shop, Accent = C.Sky })
	local money = Kit.label({
		Parent = win.Content,
		Size = UDim2.new(1, 0, 0, 26),
		Font = F.Display,
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Right,
	})
	Kit.label({
		Parent = win.Content,
		Size = UDim2.new(1, -160, 0, 26),
		Text = "Better food summons rarer characters",
		Font = F.Bold,
		TextSize = 15,
		TextColor3 = C.InkSoft,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	local grid = Kit.scroll({
		Parent = win.Content,
		Position = UDim2.fromOffset(0, 32),
		Size = UDim2.new(1, 0, 1, -32),
		Cell = Vector2.new(150, 196),
	})

	local rows = {}
	for i, food in Catalog.FoodList do
		local tile = Kit.tile({
			Parent = grid,
			LayoutOrder = i,
			Emoji = food.Emoji,
			Icon = food.Icon,
			Title = food.Name,
			Rarity = food.Tier,
		})
		local btn = Kit.button({
			Parent = tile.Action,
			Size = UDim2.fromScale(1, 1),
			TextSize = 17,
			OnClick = function()
				Net.event("BuyFood"):FireServer(food.Id, 1)
			end,
		})
		rows[food.Id] = { food = food, tile = tile, btn = btn }
	end

	local function update()
		local m, level = State.get("Money"), State.get("Level")
		money.Text = `Money: ${Util.fmt(m)}`
		for id, row in rows do
			local f = row.food
			local owned = State.foodCount(id)
			row.tile.Sub.Text = owned > 0 and `Lv {f.RequiredLevel}+ · owned {owned}` or `Lv {f.RequiredLevel}+`
			if level < f.RequiredLevel then
				row.btn.SetStyle("locked")
				row.btn.SetText(`Lv {f.RequiredLevel}`)
			else
				row.btn.SetStyle(m >= f.Price and "good" or "gold")
				row.btn.SetText(`${Util.fmt(f.Price)}`)
			end
		end
	end
	State.Changed:Connect(update)
	update()
end

return Shop
