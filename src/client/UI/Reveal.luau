-- Animal reveal card and level-up banner.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Shared = ReplicatedStorage.Shared
local Kit, Theme, Catalog = require(Shared.Kit), require(Shared.Theme), require(Shared.Catalog)
local Util = require(Shared.Util)
local Windows = require(script.Parent.Windows)
local C, F = Theme.Color, Theme.Font

local Reveal = {}

function Reveal.show(result)
	local animal = Catalog.Animals[result.Animal]
	local size = Catalog.SizeByName[result.Size]
	if not animal or not size then
		return
	end
	local rarity = Catalog.Rarities[animal.Rarity]

	local dim = Kit.new("TextButton", {
		Name = "Reveal",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = C.Ink,
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Parent = Windows.overlay,
	})
	Kit.tween(dim, 0.25, { BackgroundTransparency = 0.45 })

	local rays = Kit.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(1100, 1100),
		BackgroundTransparency = 1,
		Parent = dim,
	})
	for i = 0, 11 do
		Kit.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(46, 1100),
			Rotation = i * 15,
			BackgroundColor3 = rarity.Color,
			BackgroundTransparency = 0.82,
			BorderSizePixel = 0,
			Parent = rays,
		})
	end
	local spin = RunService.RenderStepped:Connect(function(dt)
		rays.Rotation += dt * 14
	end)

	local card = Kit.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(310, 370),
		BackgroundColor3 = C.Paper,
		Parent = dim,
	})
	Kit.corner(card, 26)
	Kit.rarityStroke(Kit.stroke(card, C.Ink, 6), animal.Rarity)
	local scale = Kit.new("UIScale", { Scale = 0.3, Parent = card })
	Kit.tween(scale, 0.45, { Scale = 1 }, Enum.EasingStyle.Back)

	local ribbon = Kit.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 14),
		Size = UDim2.fromOffset(190, 34),
		BackgroundColor3 = rarity.Color,
		Parent = card,
	})
	Kit.corner(ribbon, 17)
	Kit.stroke(ribbon, C.Ink, 3)
	if rarity.Gradient then
		Kit.new("UIGradient", { Color = rarity.Gradient, Parent = ribbon })
	end
	Kit.label({ Parent = ribbon, Text = rarity.Name, Font = F.Display, TextSize = 22, TextColor3 = C.Ink })

	local emoji = Kit.icon({
		Parent = card,
		Key = animal.Icon,
		Emoji = animal.Emoji,
		Position = UDim2.new(0.5, 0, 0, 58),
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.fromOffset(130, 130),
		TextSize = 104,
	})
	TweenService:Create(emoji, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		Position = UDim2.new(0.5, 0, 0, 46),
	}):Play()

	Kit.label({
		Parent = card,
		Position = UDim2.fromOffset(10, 192),
		Size = UDim2.new(1, -20, 0, 36),
		Text = animal.Name,
		Font = F.Display,
		TextSize = 30,
	})
	Kit.label({
		Parent = card,
		Position = UDim2.fromOffset(10, 230),
		Size = UDim2.new(1, -20, 0, 26),
		Text = `<font color="#{size.Color:ToHex()}">{size.Name}</font>  ·  ${Util.fmt(Catalog.income(animal.Id, size.Name))}/s`,
		Font = F.Bold,
		TextSize = 19,
		RichText = true,
	})
	Kit.label({
		Parent = card,
		Position = UDim2.fromOffset(18, 258),
		Size = UDim2.new(1, -36, 0, 38),
		Text = animal.Description,
		Font = F.Body,
		TextSize = 14,
		TextColor3 = C.InkSoft,
		TextWrapped = true,
	})

	if result.New then
		local tag = Kit.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(1, -30, 0, 64),
			Size = UDim2.fromOffset(78, 30),
			BackgroundColor3 = C.Berry,
			Rotation = 14,
			Parent = card,
		})
		Kit.corner(tag, 15)
		Kit.stroke(tag, C.Ink, 3)
		Kit.label({ Parent = tag, Text = "NEW!", Font = F.Display, TextSize = 18, TextColor3 = C.White })
	end

	local function close()
		spin:Disconnect()
		if dim.Parent then
			dim:Destroy()
		end
	end
	Kit.button({
		Parent = card,
		Text = "Nice!",
		Style = "good",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -16),
		Size = UDim2.fromOffset(180, 54),
		OnClick = close,
	})
	dim.Activated:Connect(close)
	task.delay(10, close)

	task.delay(0.3, function()
		if card.Parent then
			Kit.burst(card, rarity.Color, 10 + animal.Rarity * 3)
		end
	end)
	if animal.Rarity >= 5 then
		local flash = Kit.new("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = C.White,
			BackgroundTransparency = 0.3,
			Parent = dim,
		})
		Kit.tween(flash, 0.7, { BackgroundTransparency = 1 })
		task.delay(0.8, function()
			flash:Destroy()
		end)
	end
end

function Reveal.levelUp(text)
	local banner = Kit.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.3),
		Size = UDim2.fromOffset(300, 84),
		BackgroundColor3 = C.Butter,
		Parent = Windows.overlay,
	})
	Kit.corner(banner, 22)
	Kit.stroke(banner, C.Ink, 5)
	Kit.label({
		Parent = banner,
		Position = UDim2.fromOffset(0, 6),
		Size = UDim2.new(1, 0, 0, 28),
		Text = "LEVEL UP!",
		Font = F.Bold,
		TextSize = 18,
		TextColor3 = C.InkSoft,
	})
	Kit.label({
		Parent = banner,
		Position = UDim2.fromOffset(0, 30),
		Size = UDim2.new(1, 0, 0, 46),
		Text = text,
		Font = F.Display,
		TextSize = 38,
		TextColor3 = C.White,
		Stroke = C.Ink,
		StrokeThickness = 4,
	})
	local scale = Kit.new("UIScale", { Scale = 0.2, Parent = banner })
	Kit.tween(scale, 0.4, { Scale = 1 }, Enum.EasingStyle.Back)
	Kit.burst(banner, C.Pumpkin, 16)
	task.delay(2.4, function()
		Kit.tween(scale, 0.2, { Scale = 0 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.wait(0.22)
		banner:Destroy()
	end)
end

return Reveal
