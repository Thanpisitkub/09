local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Kit = require(ReplicatedStorage.Shared.Kit)

local Windows = {}
local registry = {}

function Windows.Init()
	local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
	local function screen(name, order)
		return Kit.new("ScreenGui", {
			Name = name,
			ResetOnSpawn = false,
			IgnoreGuiInset = true,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			DisplayOrder = order,
			Parent = pg,
		})
	end
	Windows.gui = screen("Windows", 10)
	Windows.overlay = screen("Overlay", 100)
	Windows.toast = Kit.toaster(Windows.overlay)
end

function Windows.create(name, opts)
	opts.Name = name
	opts.Parent = Windows.gui
	local win = Kit.window(opts)
	registry[name] = win
	return win
end

function Windows.toggle(name)
	if registry[name] then
		registry[name].Toggle()
	end
end

function Windows.open(name)
	if registry[name] then
		registry[name].Open()
	end
end

return Windows
