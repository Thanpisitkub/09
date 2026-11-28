local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Shared = ReplicatedStorage.Shared
local Kit, Theme, Catalog = require(Shared.Kit), require(Shared.Theme), require(Shared.Catalog)
local Net, Util = require(Shared.Net), require(Shared.Util)
local State = require(script.Parent.Parent.State)
local Windows = require(script.Parent.Windows)
local C, F = Theme.Color, Theme.Font

local Upgrades = {}

function Upgrades.Init()
	local conn
	local zoneStart, zoneSize = 0.4, 0.22
	local marker, zone, train

	local function pingPong()
		local x = (os.clock() * 0.9) % 2
		return x < 1 and x or 2 - x
	end

	local function doTrain()
		local m = pingPong()
		local perfect = m >= zoneStart and m <= zoneStart + zoneSize
		Net.event("TrainRep"):FireServer(perfect)
		zoneStart = 0.05 + math.random() * (0.9 - zoneSize)
		zone.Position = UDim2.fromScale(zoneStart, 0)
		if perfect then
			Kit.burst(zone, C.Butter, 10)
		end
	end

	local win = Windows.create("Upgrades", {
		Title = "Upgrades & Training",
		Icon = Theme.Icons.Upgrades,
		Accent = Color3.fromHex("FF6B6B"),
		OnOpen = function()
			conn = RunService.RenderStepped:Connect(function()
				marker.Position = UDim2.fromScale(pingPong(), 0.5)
			end)
		end,
		OnClose = function()
			if conn then
				conn:Disconnect()
				conn = nil
			end
		end,
	})
	local list = Kit.scroll({ Parent = win.Content, Pad = 10 })

	local rows = {}
	for i, kind in Catalog.UpgradeOrder do
		local u = Catalog.Upgrades[kind]
		local row = Kit.new("Frame", {
			Size = UDim2.new(1, 0, 0, 72),
			BackgroundColor3 = C.PaperDark,
			LayoutOrder = i,
			Parent = list,
		})
		Kit.corner(row, 16)
		Kit.stroke(row, C.Ink, 3)
		Kit.label({ Parent = row, Position = UDim2.fromOffset(6, 0), Size = UDim2.fromOffset(60, 72), Text = u.Icon, TextSize = 38 })
		Kit.label({
			Parent = row,
			Position = UDim2.fromOffset(70, 8),
			Size = UDim2.new(1, -230, 0, 26),
			Text = u.Name,
			Font = F.Display,
			TextSize = 20,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		local sub = Kit.label({
			Parent = row,
			Position = UDim2.fromOffset(70, 36),
			Size = UDim2.new(1, -230, 0, 24),
			Font = F.Bold,
			TextSize = 14,
			TextColor3 = C.InkSoft,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		local btn = Kit.button({
			Parent = row,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.fromOffset(132, 52),
			TextSize = 17,
			OnClick = function()
				Net.event("UpgradeStat"):FireServer(kind)
			end,
		})
		rows[kind] = { sub = sub, btn = btn }
	end

	-- Training yard: stop the marker inside the green zone for a bigger gain.
	local card = Kit.new("Frame", {
		Size = UDim2.new(1, 0, 0, 148),
		BackgroundColor3 = C.PaperDark,
		LayoutOrder = 10,
		Parent = list,
	})
	Kit.corner(card, 16)
	Kit.stroke(card, C.Ink, 3)
	Kit.label({
		Parent = card,
		Position = UDim2.fromOffset(14, 8),
		Size = UDim2.new(1, -28, 0, 28),
		Text = "💪  Training Yard",
		Font = F.Display,
		TextSize = 21,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	local track = Kit.new("Frame", {
		Position = UDim2.fromOffset(14, 46),
		Size = UDim2.new(1, -28, 0, 30),
		BackgroundColor3 = C.Ink,
		Parent = card,
	})
	Kit.corner(track, 15)
	zone = Kit.new("Frame", {
		Position = UDim2.fromScale(zoneStart, 0),
		Size = UDim2.fromScale(zoneSize, 1),
		BackgroundColor3 = C.Leaf,
		Parent = track,
	})
	Kit.corner(zone, 15)
	marker = Kit.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(12, 40),
		BackgroundColor3 = C.White,
		Parent = track,
	})
	Kit.corner(marker, 6)
	Kit.stroke(marker, C.Ink, 2)
	train = Kit.button({
		Parent = card,
		Text = "TRAIN  (Space)",
		TextSize = 20,
		Style = "primary",
		Position = UDim2.new(0.5, -110, 0, 88),
		Size = UDim2.fromOffset(220, 48),
		OnClick = doTrain,
	})
	UserInputService.InputBegan:Connect(function(input, processed)
		if win.IsOpen and not processed and (input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonA) then
			doTrain()
		end
	end)

	local function update()
		local money = State.get("Money")
		for kind, row in rows do
			local u = Catalog.Upgrades[kind]
			local owned = State.Inv.Upgrades[kind] or 0
			row.sub.Text = `{u.Desc}  ·  {owned}/{u.Max}`
			if owned >= u.Max then
				row.btn.SetText("MAX")
				row.btn.SetStyle("locked")
			else
				local cost = Catalog.upgradeCost(kind, owned)
				row.btn.SetText(`${Util.fmt(cost)}`)
				row.btn.SetStyle(money >= cost and "good" or "gold")
			end
		end
	end
	State.Changed:Connect(update)
	update()
end

return Upgrades
