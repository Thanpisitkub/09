-- Client-side UI toolkit: every screen in the game is assembled from these parts,
-- so the whole interface shares one look (see Theme).
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Theme = require(script.Parent.Theme)
local Catalog = require(script.Parent.Catalog)
local Icons = require(script.Parent.Icons)
local GuiService = game:GetService("GuiService")
local C, F = Theme.Color, Theme.Font

local Kit = {}

function Kit.new(class, props, children)
	local inst = Instance.new(class)
	local parent
	for k, v in props or {} do
		if k == "Parent" then
			parent = v
		else
			inst[k] = v
		end
	end
	for _, child in children or {} do
		child.Parent = inst
	end
	inst.Parent = parent
	return inst
end
local new = Kit.new

function Kit.corner(inst, r)
	return new("UICorner", { CornerRadius = UDim.new(0, r or Theme.Radius.Md), Parent = inst })
end

function Kit.stroke(inst, color, thickness)
	return new("UIStroke", {
		Color = color or C.Ink,
		Thickness = thickness or 3,
		LineJoinMode = Enum.LineJoinMode.Round,
		Parent = inst,
	})
end

function Kit.tween(inst, time, props, style, dir)
	local t = TweenService:Create(
		inst,
		TweenInfo.new(time, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
		props
	)
	t:Play()
	return t
end

function Kit.label(o)
	local props = {
		BackgroundTransparency = 1,
		Font = F.Body,
		TextColor3 = C.Ink,
		TextSize = 16,
		Text = "",
		Size = UDim2.fromScale(1, 1),
	}
	for k, v in o do
		if k ~= "Stroke" and k ~= "StrokeThickness" then
			props[k] = v
		end
	end
	local l = new("TextLabel", props)
	if o.Stroke then
		Kit.stroke(l, o.Stroke, o.StrokeThickness or 2)
	end
	return l
end

-- Image icon (or emoji fallback) sized by the caller.
function Kit.icon(o)
	local id = Icons.image(o.Key)
	if id then
		return new("ImageLabel", {
			Name = o.Name or "Icon",
			BackgroundTransparency = 1,
			Image = id,
			ScaleType = Enum.ScaleType.Fit,
			Size = o.Size or UDim2.fromScale(1, 1),
			Position = o.Position or UDim2.new(),
			AnchorPoint = o.AnchorPoint or Vector2.zero,
			LayoutOrder = o.LayoutOrder or 0,
			Parent = o.Parent,
		})
	end
	return Kit.label({
		Name = o.Name or "Icon",
		Parent = o.Parent,
		Size = o.Size or UDim2.fromScale(1, 1),
		Position = o.Position or UDim2.new(),
		AnchorPoint = o.AnchorPoint or Vector2.zero,
		LayoutOrder = o.LayoutOrder or 0,
		Text = o.Emoji or Icons.emoji(o.Key) or "",
		TextSize = o.TextSize or 24,
	})
end

-- Round icon button (close, small actions) that pops on hover/press.
function Kit.iconButton(o)
	local id = Icons.image(o.Key)
	local common = {
		Name = o.Name or "IconButton",
		AutoButtonColor = false,
		Size = o.Size or UDim2.fromOffset(44, 44),
		Position = o.Position or UDim2.new(),
		AnchorPoint = o.AnchorPoint or Vector2.zero,
		Parent = o.Parent,
	}
	local btn
	if id then
		common.BackgroundTransparency = 1
		common.Image = id
		common.ScaleType = Enum.ScaleType.Fit
		btn = new("ImageButton", common)
	else
		common.BackgroundColor3 = C.Berry
		common.Text = Icons.emoji(o.Key) or ""
		common.Font = F.Display
		common.TextSize = 22
		common.TextColor3 = C.White
		btn = new("TextButton", common)
		Kit.corner(btn, 12)
		Kit.stroke(btn, C.Ink, 3)
	end
	local scale = new("UIScale", { Parent = btn })
	btn.MouseEnter:Connect(function()
		Kit.tween(scale, 0.1, { Scale = 1.1 })
	end)
	btn.MouseLeave:Connect(function()
		Kit.tween(scale, 0.1, { Scale = 1 })
	end)
	btn.MouseButton1Down:Connect(function()
		Kit.tween(scale, 0.06, { Scale = 0.9 })
	end)
	btn.MouseButton1Up:Connect(function()
		Kit.tween(scale, 0.1, { Scale = 1.1 })
	end)
	btn.Activated:Connect(function()
		if o.OnClick then
			o.OnClick()
		end
	end)
	return btn
end

-- Phones get a relatively bigger HUD than desktops; the cluster also never overflows a narrow screen.
function Kit.isTouch()
	local UIS = game:GetService("UserInputService")
	return UIS.TouchEnabled and not UIS.KeyboardEnabled
end

-- Make a ScreenGui respect notches and rounded corners.
function Kit.safe(gui)
	pcall(function()
		gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
	end)
	return gui
end

-- Scales an edge-anchored cluster so touch targets stay big on phones and
-- the cluster never overflows a narrow portrait screen.
function Kit.autoscale(frame, baseHeight, designWidth)
	local scale = new("UIScale", { Parent = frame })
	local cam = Workspace.CurrentCamera or Workspace:WaitForChild("Camera")
	local function update()
		local vp = cam.ViewportSize
		local base = Kit.isTouch() and baseHeight * 0.86 or baseHeight * 1.12
		local s = math.clamp(vp.Y / base, 0.66, 1.3)
		if designWidth then
			s = math.min(s, (vp.X * 0.98) / designWidth)
		end
		scale.Scale = s
	end
	update()
	cam:GetPropertyChangedSignal("ViewportSize"):Connect(update)
	return scale
end

local STYLES = {
	primary = { C.Pumpkin, C.PumpkinLip },
	good = { C.Leaf, C.LeafLip },
	danger = { C.Berry, C.BerryLip },
	info = { C.Sky, C.SkyLip },
	gold = { C.Butter, C.ButterLip },
	locked = { C.Stone, C.StoneLip },
}
Kit.Styles = STYLES

-- Chunky button with a "lip" that squashes when pressed.
-- Returns { Holder, Face, Label, Enabled, SetText, SetStyle, SetColors }.
function Kit.button(o)
	local pair = STYLES[o.Style or "primary"]
	local color, lip = o.Color or pair[1], o.Lip or pair[2]
	local radius = o.Radius or 14

	local holder = new("Frame", {
		Name = o.Name or "Button",
		BackgroundTransparency = 1,
		Size = o.Size or UDim2.fromOffset(140, 52),
		Position = o.Position or UDim2.new(),
		AnchorPoint = o.AnchorPoint or Vector2.zero,
		LayoutOrder = o.LayoutOrder or 0,
		Parent = o.Parent,
	})
	local base = new("Frame", { Name = "Lip", Size = UDim2.fromScale(1, 1), BackgroundColor3 = lip, Parent = holder })
	Kit.corner(base, radius)
	Kit.stroke(base, C.Ink, 3)

	local face = new("TextButton", {
		Name = "Face",
		Size = UDim2.new(1, 0, 1, -6),
		BackgroundColor3 = color,
		AutoButtonColor = false,
		Text = "",
		Parent = holder,
	})
	Kit.corner(face, radius)
	local faceStroke = Kit.stroke(face, C.Ink, 3)
	faceStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	new("UIGradient", {
		Color = ColorSequence.new(C.White, Color3.fromRGB(205, 205, 205)),
		Rotation = 90,
		Parent = face,
	})

	local label = Kit.label({
		Name = "Label",
		Parent = face,
		Text = o.Text or "",
		Font = F.Display,
		TextColor3 = C.White,
		TextSize = o.TextSize or 22,
		RichText = o.RichText == true,
		Stroke = lip,
	})
	if o.Icon then -- icon on top, caption underneath
		label.Position = UDim2.fromScale(0, 0.64)
		label.Size = UDim2.fromScale(1, 0.34)
		local icon = Kit.icon({
			Parent = face,
			Key = o.Icon,
			Size = UDim2.fromScale(0.6, 0.6),
			Position = UDim2.fromScale(0.5, 0.04),
			AnchorPoint = Vector2.new(0.5, 0),
			TextSize = 26,
		})
		new("UIAspectRatioConstraint", { Parent = icon })
	end

	local obj = { Holder = holder, Face = face, Label = label, Enabled = true }
	local pressed, hover = false, false
	local textStroke = label:FindFirstChildOfClass("UIStroke")

	local function paint()
		local c = hover and obj.Enabled and color:Lerp(C.White, 0.15) or color
		Kit.tween(face, 0.08, { BackgroundColor3 = c })
	end
	local function setPressed(p)
		pressed = p
		Kit.tween(face, 0.07, { Position = p and UDim2.fromOffset(0, 4) or UDim2.new() })
	end

	face.MouseButton1Down:Connect(function()
		if obj.Enabled then
			setPressed(true)
		end
	end)
	face.MouseButton1Up:Connect(function()
		setPressed(false)
	end)
	face.MouseEnter:Connect(function()
		hover = true
		paint()
	end)
	face.MouseLeave:Connect(function()
		hover = false
		paint()
		if pressed then
			setPressed(false)
		end
	end)
	face.Activated:Connect(function()
		if obj.Enabled and o.OnClick then
			o.OnClick()
		end
	end)

	function obj.SetText(t)
		label.Text = t
	end
	function obj.SetColors(c, l)
		color = c
		base.BackgroundColor3 = l
		textStroke.Color = l
		paint()
	end
	function obj.SetStyle(name)
		obj.SetColors(STYLES[name][1], STYLES[name][2])
	end
	function obj.SetEnabled(on, offStyle)
		obj.Enabled = on
		if not on then
			obj.SetStyle(offStyle or "locked")
		end
	end
	return obj
end

-- Stat pill for the HUD: round badge + number that bumps when it changes.
function Kit.pill(o)
	local frame = new("Frame", {
		Name = o.Name or "Pill",
		Size = o.Size or UDim2.fromOffset(130, 44),
		BackgroundColor3 = C.Paper,
		LayoutOrder = o.LayoutOrder or 0,
		Parent = o.Parent,
	})
	Kit.corner(frame, 22)
	Kit.stroke(frame, C.Ink, 3)
	local badge = new("Frame", {
		Name = "Badge",
		Size = UDim2.fromOffset(34, 34),
		Position = UDim2.fromOffset(5, 5),
		BackgroundColor3 = o.Accent or C.Butter,
		Parent = frame,
	})
	Kit.corner(badge, 17)
	Kit.stroke(badge, C.Ink, 2)
	Kit.icon({
		Parent = badge,
		Key = o.Icon,
		Size = UDim2.fromScale(0.86, 0.86),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		TextSize = 19,
	})
	local value = Kit.label({
		Name = "Value",
		Parent = frame,
		Position = UDim2.fromOffset(42, 0),
		Size = UDim2.new(1, -52, 1, 0),
		Text = o.Text or "0",
		Font = F.Display,
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local scale = new("UIScale", { Parent = frame })
	local obj = { Frame = frame, Value = value }
	function obj.Set(text)
		if value.Text ~= text then
			value.Text = text
			scale.Scale = 1.12
			Kit.tween(scale, 0.22, { Scale = 1 }, Enum.EasingStyle.Back)
		end
	end
	return obj
end

function Kit.bar(o)
	local track = new("Frame", {
		Name = o.Name or "Bar",
		Size = o.Size or UDim2.new(1, 0, 0, 14),
		Position = o.Position or UDim2.new(),
		AnchorPoint = o.AnchorPoint or Vector2.zero,
		BackgroundColor3 = C.Ink,
		BackgroundTransparency = 0.25,
		Parent = o.Parent,
	})
	Kit.corner(track, 8)
	Kit.stroke(track, C.Ink, 2)
	local fill = new("Frame", {
		Name = "Fill",
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = o.Color or C.Leaf,
		Parent = track,
	})
	Kit.corner(fill, 8)
	local label = Kit.label({
		Parent = track,
		Font = F.Bold,
		TextSize = o.TextSize or 12,
		TextColor3 = C.White,
		Stroke = C.Ink,
		Text = "",
	})
	local obj = { Track = track, Fill = fill, Label = label }
	function obj.Set(alpha, text)
		Kit.tween(fill, 0.25, { Size = UDim2.fromScale(math.clamp(alpha, 0, 1), 1) })
		if text then
			label.Text = text
		end
	end
	return obj
end

function Kit.rarityStroke(stroke, rarity)
	local r = Catalog.Rarities[rarity]
	if r.Gradient then
		stroke.Color = C.White
		new("UIGradient", { Color = r.Gradient, Rotation = 45, Parent = stroke })
	else
		stroke.Color = r.Color
	end
end

local openWindows = {}

-- Paper window with a colored header. Opening one closes the others.
function Kit.window(o)
	local accent = o.Accent or C.Pumpkin
	local root = new("Frame", {
		Name = o.Name,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = o.Size or UDim2.fromScale(0.64, 0.8),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = o.Parent,
	})
	new("UISizeConstraint", {
		MinSize = o.MinSize or Vector2.new(330, 270),
		MaxSize = o.MaxSize or Vector2.new(800, 560),
		Parent = root,
	})
	local scale = new("UIScale", { Parent = root })

	local shadow = new("Frame", {
		Name = "Shadow",
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromOffset(0, 8),
		BackgroundColor3 = C.Ink,
		BackgroundTransparency = 0.55,
		Parent = root,
	})
	Kit.corner(shadow, 26)

	local body = new("Frame", {
		Name = "Body",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = C.Paper,
		Active = true,
		Parent = root,
	})
	Kit.corner(body, 24)
	Kit.stroke(body, C.Ink, 4)

	local header = new("Frame", { Name = "Header", Size = UDim2.new(1, 0, 0, 54), BackgroundColor3 = accent, Parent = body })
	Kit.corner(header, 22)
	new("Frame", {
		Name = "HeaderFill",
		Position = UDim2.fromOffset(0, 28),
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundColor3 = accent,
		BorderSizePixel = 0,
		Parent = header,
	})
	new("Frame", {
		Name = "HeaderLine",
		Position = UDim2.new(0, 0, 1, -3),
		Size = UDim2.new(1, 0, 0, 3),
		BackgroundColor3 = C.Ink,
		BorderSizePixel = 0,
		Parent = header,
	})
	if o.Icon then
		Kit.icon({
			Parent = header,
			Key = o.Icon,
			Size = UDim2.fromOffset(42, 42),
			Position = UDim2.fromOffset(12, 5),
			TextSize = 28,
		})
	end
	Kit.label({
		Name = "Title",
		Parent = header,
		Position = UDim2.fromOffset(o.Icon and 62 or 18, 0),
		Size = UDim2.new(1, -120, 1, -3),
		Text = o.Title,
		Font = F.Display,
		TextSize = 26,
		TextColor3 = C.White,
		TextXAlignment = Enum.TextXAlignment.Left,
		Stroke = C.Ink,
		StrokeThickness = 3,
	})

	local win = { Root = root, Name = o.Name, IsOpen = false }
	function win.Open()
		if win.IsOpen then
			return
		end
		for other in openWindows do
			if other ~= win then
				other.Close()
			end
		end
		win.IsOpen = true
		openWindows[win] = true
		root.Visible = true
		scale.Scale = 0.82
		Kit.tween(scale, 0.22, { Scale = 1 }, Enum.EasingStyle.Back)
		if o.OnOpen then
			o.OnOpen()
		end
	end
	function win.Close()
		if not win.IsOpen then
			return
		end
		win.IsOpen = false
		openWindows[win] = nil
		Kit.tween(scale, 0.12, { Scale = 0.9 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.delay(0.12, function()
			if not win.IsOpen then
				root.Visible = false
			end
		end)
		if o.OnClose then
			o.OnClose()
		end
	end
	function win.Toggle()
		if win.IsOpen then
			win.Close()
		else
			win.Open()
		end
	end

	Kit.iconButton({
		Name = "Close",
		Parent = header,
		Key = "Close",
		Size = UDim2.fromOffset(46, 46),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0, 25),
		OnClick = win.Close,
	})

	win.Content = new("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 66),
		Size = UDim2.new(1, -28, 1, -80),
		Parent = body,
	})
	return win
end

function Kit.scroll(o)
	local sf = new("ScrollingFrame", {
		Name = o.Name or "Scroll",
		Size = o.Size or UDim2.fromScale(1, 1),
		Position = o.Position or UDim2.new(),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = o.BarColor or C.Ink,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Parent = o.Parent,
	})
	if o.Cell then
		local pad = o.Pad or 10
		local grid = new("UIGridLayout", {
			CellSize = UDim2.fromOffset(o.Cell.X, o.Cell.Y),
			CellPadding = UDim2.fromOffset(pad, pad),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = sf,
		})
		-- stretch cells so whole columns fill the width (1 column on a narrow phone, 4+ on a monitor)
		local function fit()
			local width = sf.AbsoluteSize.X - 24
			if width <= 0 then
				return
			end
			local cols = math.max(1, math.floor((width + pad) / (o.Cell.X + pad)))
			local w = math.floor((width - pad * (cols - 1)) / cols)
			grid.CellSize = UDim2.fromOffset(w, o.Cell.Y)
		end
		sf:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
		task.defer(fit)
	else
		new("UIListLayout", { Padding = UDim.new(0, o.Pad or 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = sf })
	end
	new("UIPadding", {
		PaddingTop = UDim.new(0, 6),
		PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 6),
		PaddingRight = UDim.new(0, 10),
		Parent = sf,
	})
	return sf
end

-- 150 x 190 card: rarity-colored outline, emoji, name, sub-line and an action slot.
function Kit.tile(o)
	local frame = new("Frame", {
		Name = o.Name or "Tile",
		BackgroundColor3 = Color3.fromHex("FFFBF0"),
		LayoutOrder = o.LayoutOrder or 0,
		Parent = o.Parent,
	})
	Kit.corner(frame, 16)
	local stroke = Kit.stroke(frame, C.Ink, 4)
	if o.Rarity then
		Kit.rarityStroke(stroke, o.Rarity)
	end
	local emoji = Kit.icon({
		Name = "Emoji",
		Parent = frame,
		Key = o.Icon,
		Emoji = o.Emoji,
		Position = UDim2.new(0.5, 0, 0, 14),
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.fromOffset(68, 68),
		TextSize = 50,
	})
	local name = Kit.label({
		Name = "ItemName",
		Parent = frame,
		Position = UDim2.fromOffset(4, 84),
		Size = UDim2.new(1, -8, 0, 24),
		Text = o.Title or "",
		Font = F.Display,
		TextSize = 16,
		TextScaled = true,
	})
	new("UITextSizeConstraint", { MaxTextSize = 17, MinTextSize = 10, Parent = name })
	local sub = Kit.label({
		Name = "Sub",
		Parent = frame,
		Position = UDim2.fromOffset(4, 108),
		Size = UDim2.new(1, -8, 0, 18),
		Text = o.Sub or "",
		Font = F.Bold,
		TextSize = 13,
		TextColor3 = C.InkSoft,
		RichText = true,
	})
	local chip
	if o.Rarity then
		local r = Catalog.Rarities[o.Rarity]
		chip = new("Frame", {
			Name = "RarityChip",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, -2),
			Size = UDim2.fromOffset(84, 18),
			BackgroundColor3 = r.Color,
			Parent = frame,
		})
		Kit.corner(chip, 9)
		Kit.stroke(chip, C.Ink, 2)
		if r.Gradient then
			new("UIGradient", { Color = r.Gradient, Parent = chip })
		end
		Kit.label({ Parent = chip, Text = r.Name, Font = F.Bold, TextSize = 11, TextColor3 = C.Ink })
	end
	local action = new("Frame", {
		Name = "Action",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 10, 1, -52),
		Size = UDim2.new(1, -20, 0, 44),
		Parent = frame,
	})
	return { Frame = frame, Emoji = emoji, Name = name, Sub = sub, Action = action, Stroke = stroke, Chip = chip }
end

-- Toast stack. Returns push(kind, text) where kind = success | error | info | reward.
function Kit.toaster(gui)
	local holder = new("Frame", {
		Name = "Toasts",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 84),
		Size = UDim2.fromOffset(440, 300),
		Parent = gui,
	})
	new("UIListLayout", {
		Padding = UDim.new(0, 6),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = holder,
	})
	local colors = { success = C.Leaf, error = C.Berry, info = C.Sky, reward = C.Butter }
	local n = 0
	return function(kind, text)
		n += 1
		local toast = new("Frame", {
			Size = UDim2.fromOffset(0, 40),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = C.Paper,
			LayoutOrder = n,
			Parent = holder,
		})
		Kit.corner(toast, 20)
		Kit.stroke(toast, C.Ink, 3)
		new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = toast,
		})
		new("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 18), Parent = toast })
		local dot = new("Frame", {
			Size = UDim2.fromOffset(14, 14),
			BackgroundColor3 = colors[kind] or C.Sky,
			LayoutOrder = 1,
			Parent = toast,
		})
		Kit.corner(dot, 7)
		Kit.stroke(dot, C.Ink, 2)
		Kit.label({
			Parent = toast,
			Size = UDim2.fromScale(0, 1),
			AutomaticSize = Enum.AutomaticSize.X,
			Text = text,
			Font = F.Bold,
			TextSize = 16,
			LayoutOrder = 2,
		})
		local scale = new("UIScale", { Scale = 0.6, Parent = toast })
		Kit.tween(scale, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
		task.delay(3.2, function()
			if toast.Parent then
				Kit.tween(scale, 0.18, { Scale = 0 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				task.wait(0.2)
				toast:Destroy()
			end
		end)
	end
end

-- Modal YES / NO. o = { Title, Body (rich text), Yes = {Text,Style|Color,Lip}, No = {...}, OnYes, OnNo, Palette }
-- OnYes may yield (e.g. a server call); the dialog closes when it returns.
function Kit.confirm(gui, o)
	local p = o.Palette or { Card = C.Paper, Text = C.Ink, Line = C.Ink, Dim = C.Ink }
	local dim = new("TextButton", {
		Name = "ConfirmDim",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = p.Dim,
		BackgroundTransparency = 0.4,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 10,
		Parent = gui,
	})
	local card = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(400, 214),
		BackgroundColor3 = p.Card,
		Parent = dim,
	})
	new("UISizeConstraint", { MaxSize = Vector2.new(400, 260), Parent = card })
	Kit.corner(card, o.Radius or 22)
	Kit.stroke(card, p.Line, o.Radius and 2 or 4)
	local scale = new("UIScale", { Scale = 0.8, Parent = card })
	Kit.tween(scale, 0.2, { Scale = 1 }, Enum.EasingStyle.Back)

	Kit.label({
		Parent = card,
		Position = UDim2.fromOffset(16, 12),
		Size = UDim2.new(1, -32, 0, 30),
		Text = o.Title or "Are you sure?",
		Font = F.Display,
		TextSize = 24,
		TextColor3 = p.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	Kit.label({
		Parent = card,
		Position = UDim2.fromOffset(16, 48),
		Size = UDim2.new(1, -32, 0, 90),
		Text = o.Body or "",
		Font = F.Body,
		TextSize = 17,
		TextColor3 = p.Text,
		TextWrapped = true,
		RichText = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
	})

	local function close()
		if dim.Parent then
			dim:Destroy()
		end
	end
	local yes, no
	local busy = false
	local function make(spec, default, pos, handler)
		spec = spec or {}
		return Kit.button({
			Parent = card,
			Text = spec.Text or default,
			Style = spec.Style,
			Color = spec.Color,
			Lip = spec.Lip,
			Radius = o.Radius,
			Size = UDim2.new(0.5, -22, 0, 52),
			AnchorPoint = Vector2.new(0, 1),
			Position = pos,
			OnClick = handler,
		})
	end
	yes = make(o.Yes or { Style = "good" }, "YES", UDim2.new(0, 16, 1, -14), function()
		if busy then
			return
		end
		busy = true
		yes.SetEnabled(false)
		no.SetEnabled(false)
		task.spawn(function()
			if o.OnYes then
				o.OnYes()
			end
			close()
		end)
	end)
	no = make(o.No or { Style = "danger" }, "NO", UDim2.new(0.5, 6, 1, -14), function()
		if busy then
			return
		end
		busy = true
		task.spawn(function()
			if o.OnNo then
				o.OnNo()
			end
			close()
		end)
	end)
	return close
end

-- Anime-style speed lines flying outward from the screen centre.
function Kit.speedLines(parent, color, duration)
	local holder = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = parent })
	for i = 1, 20 do
		local a = (i / 20) * math.pi * 2 + math.random() * 0.2
		local line = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(math.random(110, 260), 3),
			Position = UDim2.fromScale(0.5 + math.cos(a) * 0.34, 0.5 + math.sin(a) * 0.34),
			Rotation = math.deg(a),
			BackgroundColor3 = color or C.White,
			BackgroundTransparency = 0.3,
			BorderSizePixel = 0,
			Parent = holder,
		})
		Kit.tween(line, duration or 0.5, {
			Position = UDim2.fromScale(0.5 + math.cos(a) * 0.62, 0.5 + math.sin(a) * 0.62),
			BackgroundTransparency = 1,
		})
	end
	task.delay((duration or 0.5) + 0.1, function()
		holder:Destroy()
	end)
end

function Kit.burst(parent, color, count)
	count = count or 14
	for i = 1, count do
		local p = new("Frame", {
			Size = UDim2.fromOffset(10, 10),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			BackgroundColor3 = color,
			Rotation = math.random(0, 90),
			Parent = parent,
		})
		Kit.corner(p, 3)
		local a = (i / count) * math.pi * 2 + math.random() * 0.4
		local d = math.random(90, 170)
		Kit.tween(p, 0.7, {
			Position = UDim2.new(0.5, math.cos(a) * d, 0.5, math.sin(a) * d),
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(2, 2),
		})
		task.delay(0.75, function()
			p:Destroy()
		end)
	end
end

function Kit.slider(o)
	local track = new("Frame", {
		Size = o.Size or UDim2.new(1, 0, 0, 14),
		Position = o.Position or UDim2.new(),
		BackgroundColor3 = C.Ink,
		BackgroundTransparency = 0.2,
		Parent = o.Parent,
	})
	Kit.corner(track, 7)
	local v0 = o.Value or 0.5
	local fill = new("Frame", { Size = UDim2.fromScale(v0, 1), BackgroundColor3 = C.Leaf, Parent = track })
	Kit.corner(fill, 7)
	local knob = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(v0, 0, 0.5, 0),
		Size = UDim2.fromOffset(26, 26),
		BackgroundColor3 = C.Paper,
		Parent = track,
	})
	Kit.corner(knob, 13)
	Kit.stroke(knob, C.Ink, 3)
	local hit = new("TextButton", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, 26, 0, 36),
		BackgroundTransparency = 1,
		Text = "",
		Parent = track,
	})
	local dragging = false
	local function setX(x)
		local a = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		fill.Size = UDim2.fromScale(a, 1)
		knob.Position = UDim2.new(a, 0, 0.5, 0)
		if o.OnChange then
			o.OnChange(a)
		end
	end
	local function isPointer(i)
		return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
	end
	hit.InputBegan:Connect(function(i)
		if isPointer(i) then
			dragging = true
			setX(i.Position.X)
		end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			setX(i.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(i)
		if isPointer(i) then
			dragging = false
		end
	end)
	return track
end

return Kit
