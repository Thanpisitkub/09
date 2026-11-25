-- Admin Panel (client). This Script is stored in ServerStorage and the server clones it into the PlayerGui
-- of authorized players only; everyone else never receives this code or any of its UI.
-- The server still re-checks every request, so this file is presentation only.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Kit = require(Shared.Kit)
local Theme = require(Shared.Theme)
local Catalog = require(Shared.Catalog)
local Util = require(Shared.Util)
local Net = require(Shared.Net)

local A = Theme.Admin
local F = Theme.Font
local player = Players.LocalPlayer
local new = Kit.new

local init = Net.func("AdminInit"):InvokeServer()
if not init then
	script:Destroy()
	return
end

local gui = new("ScreenGui", {
	Name = "AdminPanel",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 60,
	Parent = player:WaitForChild("PlayerGui"),
})
script.Destroying:Connect(function()
	gui:Destroy()
end)
Net.event("AdminStatus").OnClientEvent:Connect(function(status)
	if not status or not status.role then
		script:Destroy()
	end
end)

local PALETTE = { Card = A.Panel, Text = A.Text, Line = A.Line, Dim = Color3.new(0, 0, 0) }
local YES = { Text = "YES", Color = A.Good, Lip = Color3.fromHex("1E9E6A") }
local NO = { Text = "NO", Color = A.Bad, Lip = Color3.fromHex("B83A55") }

local function text(props)
	props.Font = props.Font or F.Body
	props.TextColor3 = props.TextColor3 or A.Text
	return Kit.label(props)
end

local thumbs = {}
local function avatar(parent, userId, size)
	local img = new("ImageLabel", {
		Size = UDim2.fromOffset(size, size),
		BackgroundColor3 = A.Raised,
		Image = thumbs[userId] or "",
		Parent = parent,
	})
	Kit.corner(img, size / 2)
	if not thumbs[userId] then
		task.spawn(function()
			local ok, url = pcall(function()
				return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
			end)
			if ok then
				thumbs[userId] = url
				if img.Parent then
					img.Image = url
				end
			end
		end)
	end
	return img
end

-------------------------------------------------------------------------------- shell
local openBtn = Kit.button({
	Parent = gui,
	Name = "AdminOpen",
	Color = A.Accent,
	Lip = A.AccentLip,
	Text = Theme.Icons.Admin,
	TextSize = 26,
	Size = UDim2.fromOffset(56, 56),
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 12, 1, -12),
})

local root = new("Frame", {
	Name = "Panel",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.86, 0.86),
	BackgroundColor3 = A.Bg,
	Visible = false,
	Active = true,
	Parent = gui,
})
new("UISizeConstraint", { MinSize = Vector2.new(420, 300), MaxSize = Vector2.new(940, 580), Parent = root })
Kit.corner(root, 14)
Kit.stroke(root, A.Line, 2)
local panelScale = new("UIScale", { Parent = root })

local function setOpen(open)
	if open then
		root.Visible = true
		panelScale.Scale = 0.9
		Kit.tween(panelScale, 0.2, { Scale = 1 }, Enum.EasingStyle.Back)
	else
		Kit.tween(panelScale, 0.12, { Scale = 0.94 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.delay(0.12, function()
			root.Visible = false
		end)
	end
end
openBtn.Face.Activated:Connect(function()
	setOpen(not root.Visible)
end)

local sidebar = new("Frame", { Size = UDim2.new(0, 168, 1, 0), BackgroundColor3 = A.Panel, Parent = root })
Kit.corner(sidebar, 14)
new("Frame", { Position = UDim2.new(1, -14, 0, 0), Size = UDim2.new(0, 14, 1, 0), BackgroundColor3 = A.Panel, BorderSizePixel = 0, Parent = sidebar })
text({
	Parent = sidebar,
	Position = UDim2.fromOffset(14, 10),
	Size = UDim2.new(1, -28, 0, 26),
	Text = "ADMIN",
	Font = F.Display,
	TextSize = 22,
	TextXAlignment = Enum.TextXAlignment.Left,
})
text({
	Parent = sidebar,
	Position = UDim2.fromOffset(14, 34),
	Size = UDim2.new(1, -28, 0, 16),
	Text = init.isCreator and "Creator" or "Approved admin",
	Font = F.Bold,
	TextSize = 13,
	TextColor3 = init.isCreator and A.Good or A.Muted,
	TextXAlignment = Enum.TextXAlignment.Left,
})
local nav = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(8, 62), Size = UDim2.new(1, -16, 1, -70), Parent = sidebar })
new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = nav })

local closeBtn = new("TextButton", {
	Text = "✕",
	Font = F.Bold,
	TextSize = 18,
	TextColor3 = A.Muted,
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -8, 0, 8),
	Size = UDim2.fromOffset(34, 34),
	Parent = root,
})
closeBtn.Activated:Connect(function()
	setOpen(false)
end)

local stage = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(180, 12), Size = UDim2.new(1, -228, 1, -56), Parent = root })
local status = text({
	Parent = root,
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 180, 1, -10),
	Size = UDim2.new(1, -200, 0, 28),
	Text = "",
	Font = F.Bold,
	TextSize = 15,
	TextXAlignment = Enum.TextXAlignment.Left,
})
local statusToken = 0
local function say(ok, msg)
	statusToken += 1
	local mine = statusToken
	status.Text = (ok and "✔  " or "✖  ") .. msg
	status.TextColor3 = ok and A.Good or A.Bad
	task.delay(5, function()
		if statusToken == mine then
			status.Text = ""
		end
	end)
end

local pages, navButtons, order = {}, {}, 0
local function showPage(name)
	for n, page in pages do
		page.Frame.Visible = n == name
		navButtons[n].BackgroundColor3 = n == name and A.Accent or A.Panel
	end
	if pages[name].OnShow then
		task.spawn(pages[name].OnShow)
	end
end
local function addPage(name, label, onShow)
	order += 1
	local btn = new("TextButton", {
		Name = name,
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundColor3 = A.Panel,
		AutoButtonColor = false,
		Text = "  " .. label,
		Font = F.Bold,
		TextSize = 15,
		TextColor3 = A.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = nav,
	})
	Kit.corner(btn, 8)
	local frame = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, Parent = stage })
	pages[name] = { Frame = frame, OnShow = onShow }
	navButtons[name] = btn
	btn.Activated:Connect(function()
		showPage(name)
	end)
	return frame
end

-------------------------------------------------------------------------------- widgets
local function inputBox(parent, placeholder, position, size)
	local box = new("Frame", { Position = position, Size = size, BackgroundColor3 = A.Raised, Parent = parent })
	Kit.corner(box, 8)
	Kit.stroke(box, A.Line, 1)
	local tb = new("TextBox", {
		Size = UDim2.new(1, -20, 1, 0),
		Position = UDim2.fromOffset(10, 0),
		BackgroundTransparency = 1,
		PlaceholderText = placeholder,
		PlaceholderColor3 = A.Muted,
		Text = "",
		ClearTextOnFocus = false,
		Font = F.Body,
		TextSize = 16,
		TextColor3 = A.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = box,
	})
	return tb
end

local function adminButton(parent, label, position, size, danger)
	return Kit.button({
		Parent = parent,
		Text = label,
		TextSize = 17,
		Color = danger and A.Bad or A.Accent,
		Lip = danger and Color3.fromHex("B83A55") or A.AccentLip,
		Position = position,
		Size = size,
		Radius = 10,
	})
end

-- Searchable, selectable list of people. o.Fetch() -> entries { userId, name, display, ... }
local function entryList(parent, o)
	local obj = { Selected = nil }
	local frame = new("Frame", { BackgroundTransparency = 1, Position = o.Position or UDim2.new(), Size = o.Size, Parent = parent })
	obj.Frame = frame
	local search = inputBox(frame, "Search players…", UDim2.new(), UDim2.new(1, 0, 0, 36))
	local scroll = Kit.scroll({ Parent = frame, Position = UDim2.fromOffset(0, 44), Size = UDim2.new(1, 0, 1, -44), Pad = 6, BarColor = A.Muted })
	local entries = {}

	local function render()
		for _, child in scroll:GetChildren() do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end
		local q = search.Text:lower()
		for i, e in entries do
			if q == "" or e.name:lower():find(q, 1, true) or e.display:lower():find(q, 1, true) or tostring(e.userId):find(q, 1, true) then
				local selected = obj.Selected and obj.Selected.userId == e.userId
				local row = new("TextButton", {
					LayoutOrder = i,
					Size = UDim2.new(1, 0, 0, o.Detailed and 62 or 50),
					BackgroundColor3 = selected and A.Raised or A.Panel,
					AutoButtonColor = false,
					Text = "",
					Parent = scroll,
				})
				Kit.corner(row, 10)
				Kit.stroke(row, selected and A.Accent or A.Line, selected and 2 or 1)
				local av = avatar(row, e.userId, 36)
				av.Position = UDim2.fromOffset(8, (row.Size.Y.Offset - 36) / 2)
				text({
					Parent = row,
					Position = UDim2.fromOffset(52, 6),
					Size = UDim2.new(1, -60, 0, 20),
					Text = e.display,
					Font = F.Bold,
					TextSize = 15,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
				})
				text({
					Parent = row,
					Position = UDim2.fromOffset(52, 26),
					Size = UDim2.new(1, -60, 0, 16),
					Text = `@{e.name} · {e.userId}`,
					TextSize = 12,
					TextColor3 = A.Muted,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
				})
				if o.Detailed then
					local when = e.grantedAt and e.grantedAt > 0 and os.date("%Y-%m-%d", e.grantedAt) or "-"
					text({
						Parent = row,
						Position = UDim2.fromOffset(52, 42),
						Size = UDim2.new(1, -60, 0, 16),
						Text = `{e.role} · Active · granted {when}`,
						TextSize = 12,
						TextColor3 = e.role == "Creator" and A.Good or A.Accent,
						TextXAlignment = Enum.TextXAlignment.Left,
					})
				else
					new("Frame", {
						AnchorPoint = Vector2.new(1, 0.5),
						Position = UDim2.new(1, -10, 0.5, 0),
						Size = UDim2.fromOffset(8, 8),
						BackgroundColor3 = A.Good,
						Parent = row,
					}).Name = "Online"
					Kit.corner(row.Online, 4)
				end
				row.Activated:Connect(function()
					obj.Selected = e
					render()
					if o.OnSelect then
						o.OnSelect(e)
					end
				end)
			end
		end
	end

	function obj.Refresh()
		local list = o.Fetch()
		if not list then
			return
		end
		entries = list
		if obj.Selected then
			local still
			for _, e in entries do
				if e.userId == obj.Selected.userId then
					still = e
				end
			end
			obj.Selected = still
			if not still and o.OnSelect then
				o.OnSelect(nil)
			end
		end
		render()
	end
	search:GetPropertyChangedSignal("Text"):Connect(render)
	return obj
end

local function fetchPlayers()
	local res = Net.func("AdminPlayers"):InvokeServer()
	if res and res.ok then
		return res.list
	end
	say(false, res and res.err or "Could not load players")
end

local function fetchAdmins()
	local res = Net.func("AdminPermList"):InvokeServer()
	if res and res.ok then
		return res.list
	end
	say(false, res and res.err or "Could not load admins")
end

-- Header card for the selected target.
local function targetCard(parent, position)
	local card = new("Frame", { Position = position, Size = UDim2.new(1, 0, 0, 72), BackgroundColor3 = A.Panel, Parent = parent })
	Kit.corner(card, 10)
	Kit.stroke(card, A.Line, 1)
	local av = avatar(card, 1, 52)
	av.Position = UDim2.fromOffset(10, 10)
	local name = text({ Parent = card, Position = UDim2.fromOffset(72, 12), Size = UDim2.new(1, -80, 0, 24), Text = "No player selected", Font = F.Display, TextSize = 20, TextXAlignment = Enum.TextXAlignment.Left })
	local sub = text({ Parent = card, Position = UDim2.fromOffset(72, 38), Size = UDim2.new(1, -80, 0, 18), Text = "Pick someone from the list", TextSize = 13, TextColor3 = A.Muted, TextXAlignment = Enum.TextXAlignment.Left })
	return {
		Set = function(e)
			if not e then
				av.Image, name.Text, sub.Text = "", "No player selected", "Pick someone from the list"
				return
			end
			av.Image = thumbs[e.userId] or ""
			task.spawn(function()
				local ok, url = pcall(function()
					return Players:GetUserThumbnailAsync(e.userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
				end)
				if ok and name.Text == e.display then
					av.Image = url
				end
			end)
			name.Text, sub.Text = e.display, `@{e.name} · UserId {e.userId}`
		end,
	}
end

-- Server-validated transaction with a YES / NO dialog.
local function transact(kind, target, value)
	local res = Net.func("AdminRequest"):InvokeServer(kind, target.userId, value)
	if not res or not res.ok then
		return say(false, res and res.err or "Request failed")
	end
	local who = `<b>{res.targetDisplay}</b> (@{res.targetName})`
	local body, title
	if kind == "Animal" then
		title = "Give animal"
		body = `Selected Player: <b>{res.targetDisplay}</b>\nSelected Animal: <b>{res.animalName}</b>\nAnimal Rarity: <b>{res.rarity}</b>`
	elseif kind == "GrantAdmin" then
		title = "Grant admin access"
		body = `Are you sure you want to grant Admin access to {who}?`
	elseif kind == "RevokeAdmin" then
		title = "Revoke admin access"
		body = `Are you sure you want to revoke Admin access from {who}?`
	else
		title = "Give " .. kind
		body = `Are you sure you want to give <b>{Util.commas(res.amount)}</b> {kind} to {who}?`
	end
	Kit.confirm(gui, {
		Title = title,
		Body = body,
		Palette = PALETTE,
		Radius = 12,
		Yes = YES,
		No = NO,
		OnYes = function()
			local r = Net.func("AdminConfirm"):InvokeServer(res.txId, true)
			say(r and r.ok, r and (r.message or r.err) or "No response")
		end,
		OnNo = function()
			Net.func("AdminConfirm"):InvokeServer(res.txId, false)
			say(true, "Cancelled")
		end,
	})
end

-------------------------------------------------------------------------------- pages
local playerLists = {}

local function givePage(kind, label)
	local page = addPage(kind, label)
	local card
	local list = entryList(page, {
		Size = UDim2.new(0, 220, 1, 0),
		Fetch = fetchPlayers,
		OnSelect = function(e)
			card.Set(e)
		end,
	})
	table.insert(playerLists, list)
	pages[kind].OnShow = list.Refresh
	local right = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(232, 0), Size = UDim2.new(1, -232, 1, 0), Parent = page })
	card = targetCard(right, UDim2.new())

	if kind == "Animal" then
		local search = inputBox(right, "Search animals, areas or rarity…", UDim2.fromOffset(0, 82), UDim2.new(1, 0, 0, 36))
		local grid = Kit.scroll({ Parent = right, Position = UDim2.fromOffset(0, 126), Size = UDim2.new(1, 0, 1, -126), Cell = Vector2.new(104, 112), Pad = 8, BarColor = A.Muted })
		local function build()
			for _, c in grid:GetChildren() do
				if c:IsA("TextButton") then
					c:Destroy()
				end
			end
			local q = search.Text:lower()
			for i, animal in Catalog.AnimalList do
				local rarity = Catalog.Rarities[animal.Rarity]
				local area = Catalog.Areas[animal.Area]
				if q == "" or animal.Name:lower():find(q, 1, true) or rarity.Name:lower():find(q, 1, true) or area.Name:lower():find(q, 1, true) then
					local cell = new("TextButton", { LayoutOrder = i, BackgroundColor3 = A.Panel, AutoButtonColor = false, Text = "", Parent = grid })
					Kit.corner(cell, 10)
					Kit.stroke(cell, rarity.Color, 2)
					text({ Parent = cell, Position = UDim2.fromOffset(0, 8), Size = UDim2.new(1, 0, 0, 44), Text = animal.Emoji, TextSize = 32 })
					text({ Parent = cell, Position = UDim2.fromOffset(2, 54), Size = UDim2.new(1, -4, 0, 18), Text = animal.Name, Font = F.Bold, TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd })
					text({ Parent = cell, Position = UDim2.fromOffset(2, 72), Size = UDim2.new(1, -4, 0, 14), Text = rarity.Name, TextSize = 11, TextColor3 = rarity.Color })
					text({ Parent = cell, Position = UDim2.fromOffset(2, 88), Size = UDim2.new(1, -4, 0, 14), Text = area.Name, TextSize = 10, TextColor3 = A.Muted, TextTruncate = Enum.TextTruncate.AtEnd })
					cell.Activated:Connect(function()
						if not list.Selected then
							return say(false, "Select a player first")
						end
						transact("Animal", list.Selected, animal.Id)
					end)
				end
			end
		end
		search:GetPropertyChangedSignal("Text"):Connect(build)
		build()
	else
		local box = inputBox(right, "Exact amount (whole number)", UDim2.fromOffset(0, 90), UDim2.new(1, 0, 0, 44))
		text({ Parent = right, Position = UDim2.fromOffset(0, 138), Size = UDim2.new(1, 0, 0, 18), Text = `Maximum per action: {Util.commas(init.max[kind])}`, TextSize = 12, TextColor3 = A.Muted, TextXAlignment = Enum.TextXAlignment.Left })
		local give = adminButton(right, "Give", UDim2.fromOffset(0, 168), UDim2.fromOffset(160, 50))
		give.Face.Activated:Connect(function()
			if not list.Selected then
				return say(false, "Select a player first")
			end
			local amount = tonumber((box.Text:gsub("[,%s]", "")))
			if not amount then
				return say(false, "Enter a valid number")
			end
			transact(kind, list.Selected, amount)
		end)
	end
end

givePage("Strength", "Give Strength")
givePage("Luck", "Give Luck")
givePage("Money", "Give Money")
givePage("Animal", "Give Animals")

-- Action log (+ permission history for the creator)
local logPage = addPage("Log", "Action Log")
local logCategory = "action"
local logScroll = Kit.scroll({ Parent = logPage, Position = UDim2.fromOffset(0, init.isCreator and 44 or 0), Size = UDim2.new(1, 0, 1, init.isCreator and -44 or 0), Pad = 6, BarColor = A.Muted })
local function loadLog()
	for _, c in logScroll:GetChildren() do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end
	local res = Net.func("AdminLogs"):InvokeServer(logCategory)
	if not res or not res.ok then
		return say(false, res and res.err or "Could not load log")
	end
	if #res.list == 0 then
		say(true, "No entries yet")
	end
	for i, e in res.list do
		local row = new("Frame", { LayoutOrder = i, Size = UDim2.new(1, 0, 0, 58), BackgroundColor3 = A.Panel, Parent = logScroll })
		Kit.corner(row, 8)
		local good = tostring(e.result):sub(1, 7) == "Success"
		text({ Parent = row, Position = UDim2.fromOffset(10, 6), Size = UDim2.new(1, -20, 0, 18), Text = `{os.date("%Y-%m-%d %H:%M", e.t)}  ·  {e.adminName} ({e.adminId})`, Font = F.Bold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd })
		text({ Parent = row, Position = UDim2.fromOffset(10, 24), Size = UDim2.new(1, -20, 0, 16), Text = `{e.kind} {e.detail or ""} → {e.targetName or "?"} ({e.targetId or 0})`, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd })
		text({ Parent = row, Position = UDim2.fromOffset(10, 40), Size = UDim2.new(1, -20, 0, 14), Text = tostring(e.result), TextSize = 12, TextColor3 = good and A.Good or A.Bad, TextXAlignment = Enum.TextXAlignment.Left })
	end
end
if init.isCreator then
	local tabs = {}
	for i, def in { { "action", "Actions" }, { "permission", "Permission history" } } do
		local b = new("TextButton", { Position = UDim2.fromOffset((i - 1) * 150, 0), Size = UDim2.fromOffset(142, 34), BackgroundColor3 = A.Panel, AutoButtonColor = false, Text = def[2], Font = F.Bold, TextSize = 14, TextColor3 = A.Text, Parent = logPage })
		Kit.corner(b, 8)
		tabs[def[1]] = b
		b.Activated:Connect(function()
			logCategory = def[1]
			for k, tb in tabs do
				tb.BackgroundColor3 = k == logCategory and A.Accent or A.Panel
			end
			task.spawn(loadLog)
		end)
	end
	tabs.action.BackgroundColor3 = A.Accent
end
pages.Log.OnShow = loadLog

-- Creator-only permission management. The page, its nav button and its code path exist only for the creator.
if init.isCreator then
	local perm = addPage("Perm", "Admin Permissions")
	local mode = "Grant"
	local modeBtns = {}
	local body = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 44), Size = UDim2.new(1, 0, 1, -44), Parent = perm })
	local card
	local actionBtn
	local playersList, adminsList

	local function applyMode()
		for m, b in modeBtns do
			b.BackgroundColor3 = m == mode and A.Accent or A.Panel
		end
		playersList.Frame.Visible = mode == "Grant"
		adminsList.Frame.Visible = mode ~= "Grant"
		actionBtn.Holder.Visible = mode ~= "List"
		actionBtn.SetText(mode == "Grant" and "Grant Admin" or "Revoke Admin")
		actionBtn.SetColors(mode == "Grant" and A.Accent or A.Bad, mode == "Grant" and A.AccentLip or Color3.fromHex("B83A55"))
		card.Set(nil)
		playersList.Selected, adminsList.Selected = nil, nil
		task.spawn(mode == "Grant" and playersList.Refresh or adminsList.Refresh)
	end

	for i, def in { { "Grant", "Grant Admin" }, { "Revoke", "Revoke Admin" }, { "List", "Admin List" } } do
		local b = new("TextButton", { Position = UDim2.fromOffset((i - 1) * 130, 0), Size = UDim2.fromOffset(122, 34), BackgroundColor3 = A.Panel, AutoButtonColor = false, Text = def[2], Font = F.Bold, TextSize = 14, TextColor3 = A.Text, Parent = perm })
		Kit.corner(b, 8)
		modeBtns[def[1]] = b
		b.Activated:Connect(function()
			mode = def[1]
			applyMode()
		end)
	end

	playersList = entryList(body, { Size = UDim2.new(0, 230, 1, 0), Fetch = fetchPlayers, OnSelect = function(e) card.Set(e) end })
	adminsList = entryList(body, { Size = UDim2.new(0, 230, 1, 0), Fetch = fetchAdmins, Detailed = true, OnSelect = function(e) card.Set(e) end })
	table.insert(playerLists, playersList)
	local right = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(242, 0), Size = UDim2.new(1, -242, 1, 0), Parent = body })
	card = targetCard(right, UDim2.new())
	actionBtn = adminButton(right, "Grant Admin", UDim2.fromOffset(0, 90), UDim2.fromOffset(180, 50))
	actionBtn.Face.Activated:Connect(function()
		local list = mode == "Grant" and playersList or adminsList
		if not list.Selected then
			return say(false, "Select a player first")
		end
		if mode == "Revoke" and list.Selected.role == "Creator" then
			return say(false, "The creator's permissions cannot be changed")
		end
		transact(mode == "Grant" and "GrantAdmin" or "RevokeAdmin", list.Selected)
		task.delay(1.5, function()
			(mode == "Grant" and playersList or adminsList).Refresh()
		end)
	end)
	pages.Perm.OnShow = applyMode
	applyMode()
end

Net.event("AdminPlayersChanged").OnClientEvent:Connect(function()
	for _, list in playerLists do
		if list.Frame.Visible and list.Frame.Parent.Visible then
			task.spawn(list.Refresh)
		end
	end
end)

showPage("Strength")
