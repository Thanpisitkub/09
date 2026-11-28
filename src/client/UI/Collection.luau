local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Kit, Theme, Catalog = require(Shared.Kit), require(Shared.Theme), require(Shared.Catalog)
local Util = require(Shared.Util)
local State = require(script.Parent.Parent.State)
local Windows = require(script.Parent.Windows)
local C, F = Theme.Color, Theme.Font

local Collection = {}

function Collection.Init()
	local win, grid, progress

	local function rebuild()
		for _, child in grid:GetChildren() do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
		local found = 0
		for i, animal in Catalog.AnimalList do
			local seen = State.Inv.Discovered[animal.Id] == true
			if seen then
				found += 1
			end
			local area = Catalog.Areas[animal.Area]
			local tile = Kit.tile({
				Parent = grid,
				LayoutOrder = i,
				Emoji = seen and animal.Emoji or "❔",
				Icon = seen and animal.Icon or nil,
				Title = seen and animal.Name or "???",
				Rarity = seen and animal.Rarity or nil,
				Sub = seen and `{area.Name} · {Util.fmt(animal.BaseIncome)}/s` or area.Name,
			})
			tile.Action:Destroy()
			tile.Frame.BackgroundColor3 = seen and Color3.fromHex("FFFBF0") or C.PaperDark
		end
		progress.Set(found / #Catalog.AnimalList, `Discovered {found} / {#Catalog.AnimalList}`)
	end

	win = Windows.create("Collection", {
		Title = "Character Index",
		Icon = Theme.Icons.Collection,
		Accent = Color3.fromHex("A66BFF"),
		OnOpen = rebuild,
	})
	progress = Kit.bar({
		Parent = win.Content,
		Size = UDim2.new(1, 0, 0, 24),
		Color = Color3.fromHex("A66BFF"),
		TextSize = 15,
	})
	grid = Kit.scroll({
		Parent = win.Content,
		Position = UDim2.fromOffset(0, 32),
		Size = UDim2.new(1, 0, 1, -32),
		Cell = Vector2.new(150, 140),
	})
	State.Changed:Connect(function(key)
		if win.IsOpen and key == "Inventory" then
			rebuild()
		end
	end)
end

return Collection
