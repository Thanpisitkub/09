-- Assigns each player a plot, spawns them there, and shows their placed animals wandering in the pen.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config, Catalog = require(Shared.Config), require(Shared.Catalog)
local WorldBuilder = require(script.Parent.WorldBuilder)
local PlayerData = require(script.Parent.PlayerData)
local Economy = require(script.Parent.Economy)

local MAX_PETS = 40
local SIZE_SCALE = { 0.6, 0.8, 1, 1.3, 1.7, 2.2 }

local Plots = {}
local slotOf = {} -- [Player] = slot
local owner = {} -- [slot] = Player
local rebuildToken = {} -- [Player] = number

function Plots.slotOf(player)
	return slotOf[player]
end

local function setSign(slot, text)
	local plot = WorldBuilder.Plots[slot]
	if plot then
		plot.SignLabel.Text = text
	end
end

local function clearPets(slot)
	local plot = WorldBuilder.Plots[slot]
	local folder = plot and plot.Model:FindFirstChild("Pets")
	if folder then
		folder:Destroy()
	end
end

local function wander(pet, plot)
	task.spawn(function()
		while pet.Parent do
			local target = Vector3.new(
				plot.Pen.X + (math.random() * 2 - 1) * plot.PenHalf.X,
				plot.Pen.Y + 1.6,
				plot.Pen.Z + (math.random() * 2 - 1) * plot.PenHalf.Y
			)
			local time = math.max(1, (target - pet.Position).Magnitude / 4)
			local tween = TweenService:Create(pet, TweenInfo.new(time, Enum.EasingStyle.Linear), { Position = target })
			tween:Play()
			task.wait(time + math.random() * 2.5)
		end
	end)
end

local function spawnPet(folder, plot, animalData)
	local animal = Catalog.Animals[animalData.id]
	local size = Catalog.SizeByName[animalData.size]
	local scale = SIZE_SCALE[size.Index]
	local rarity = Catalog.Rarities[animal.Rarity]

	local pet = Instance.new("Part")
	pet.Name = animal.Name
	pet.Anchored, pet.CanCollide, pet.CanQuery, pet.CanTouch = true, false, false, false
	pet.Transparency = 1
	pet.Size = Vector3.one
	pet.Position = Vector3.new(
		plot.Pen.X + (math.random() * 2 - 1) * plot.PenHalf.X,
		plot.Pen.Y + 1.6,
		plot.Pen.Z + (math.random() * 2 - 1) * plot.PenHalf.Y
	)
	pet.Parent = folder

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(3.4 * scale, 3.4 * scale)
	gui.MaxDistance = 140
	gui.LightInfluence = 0
	gui.Parent = pet
	local badge = Instance.new("Frame")
	badge.Size = UDim2.fromScale(1, 1)
	badge.BackgroundColor3 = rarity.Color
	badge.BackgroundTransparency = 0.35
	badge.Parent = gui
	Instance.new("UICorner", badge).CornerRadius = UDim.new(1, 0)
	local ring = Instance.new("UIStroke")
	ring.Color, ring.Thickness = Color3.fromHex("14363B"), 2
	ring.Parent = badge
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Text = animal.Emoji
	label.Parent = badge

	wander(pet, plot)
end

local function rebuildPets(player)
	local slot = slotOf[player]
	local profile = PlayerData.get(player)
	local plot = slot and WorldBuilder.Plots[slot]
	if not plot or not profile then
		return
	end
	rebuildToken[player] = (rebuildToken[player] or 0) + 1
	local mine = rebuildToken[player]
	task.delay(0.3, function() -- debounce bursts of inventory updates
		if rebuildToken[player] ~= mine or slotOf[player] ~= slot or not player.Parent then
			return
		end
		clearPets(slot)
		local folder = Instance.new("Folder")
		folder.Name = "Pets"
		local count = 0
		for _, a in profile.Animals do
			if a.placed and count < MAX_PETS then
				count += 1
				spawnPet(folder, plot, a)
			end
		end
		folder.Parent = plot.Model
	end)
end

local function claim(player)
	if slotOf[player] then
		return
	end
	for slot = 1, Config.World.Slots do
		if not owner[slot] then
			owner[slot] = player
			slotOf[player] = slot
			player:SetAttribute("Slot", slot)
			player.RespawnLocation = WorldBuilder.Plots[slot].Spawn
			setSign(slot, `{player.DisplayName}\nPlot {slot}`)
			rebuildPets(player)
			return
		end
	end
	warn(`[Plots] no free plot for {player.Name}`)
end

local function release(player)
	local slot = slotOf[player]
	if slot then
		clearPets(slot)
		setSign(slot, `PLOT {slot}\nFree`)
		owner[slot] = nil
	end
	slotOf[player] = nil
	rebuildToken[player] = nil
end

function Plots.Init()
	Players.PlayerAdded:Connect(claim)
	Players.PlayerRemoving:Connect(release)
	PlayerData.Loaded:Connect(rebuildPets)
	Economy.InventoryChanged:Connect(rebuildPets)
end

function Plots.Start()
	for _, player in Players:GetPlayers() do
		claim(player)
		if player.Character then
			player:LoadCharacter()
		end
	end
end

return Plots
