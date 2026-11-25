local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Shared = ReplicatedStorage.Shared
local Kit, Theme = require(Shared.Kit), require(Shared.Theme)
local Windows = require(script.Parent.Windows)
local C, F = Theme.Color, Theme.Font

local Settings = {}
Settings.Values = { Marker = true } -- read by the throw controller

local function group(name)
	local g = SoundService:FindFirstChild(name)
	if not g then
		g = Instance.new("SoundGroup")
		g.Name = name
		g.Volume = 0.7
		g.Parent = SoundService
	end
	return g
end

function Settings.Init()
	local win = Windows.create("Settings", {
		Title = "Settings",
		Icon = Theme.Icons.Settings,
		Accent = Color3.fromHex("6C7A89"),
		Size = UDim2.fromScale(0.5, 0.6),
		MaxSize = Vector2.new(520, 400),
	})
	local y = 4
	local function row(text)
		Kit.label({
			Parent = win.Content,
			Position = UDim2.fromOffset(0, y),
			Size = UDim2.new(0.42, 0, 0, 40),
			Text = text,
			Font = F.Display,
			TextSize = 20,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		local slot = Kit.new("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0.46, 0, 0, y),
			Size = UDim2.new(0.54, -8, 0, 40),
			Parent = win.Content,
		})
		y += 56
		return slot
	end

	for _, name in { "Music", "SFX" } do
		local g = group(name)
		local slot = row(name == "Music" and "Music volume" or "Sound effects")
		Kit.slider({
			Parent = slot,
			Position = UDim2.new(0, 0, 0.5, -7),
			Size = UDim2.new(1, -16, 0, 14),
			Value = g.Volume,
			OnChange = function(v)
				g.Volume = v
			end,
		})
	end

	local slot = row("Landing marker")
	local toggle
	toggle = Kit.button({
		Parent = slot,
		Size = UDim2.fromOffset(110, 44),
		Text = "ON",
		Style = "good",
		OnClick = function()
			Settings.Values.Marker = not Settings.Values.Marker
			toggle.SetText(Settings.Values.Marker and "ON" or "OFF")
			toggle.SetStyle(Settings.Values.Marker and "good" or "locked")
		end,
	})
end

return Settings
