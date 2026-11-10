--!nocheck
--[[
	Blossom UI Library (single file)

	local Blossom = loadstring(readfile("Blossom.luau"))()      -- executor
	local Blossom = require(path.to.Blossom)                    -- Studio

	local Window = Blossom.new({ Title = "Blossom", Script = "blossom.lua", Build = "operation one" })
	Window:Category("Combat")
	local Rage = Window:Tab({ Name = "Rage", Icon = "target" })
	local Main = Rage:Section({ Name = "Main", Icon = "robot", Side = 1 })
	Main:Toggle({ Name = "Enabled", Default = true, Keybind = Enum.KeyCode.C, Callback = print })

	Elements: Toggle, Slider, RangeSlider, Dropdown, Colorpicker, Keybind, Button,
	          Textbox, Label, Divider, Listbox.
	Toggle and Label also accept Keybind = and Color = for inline controls.
	Every element returns an object with .Value and :Set(value, silent).

	Options for Blossom.new: Title, Script, Build, Theme, MenuKey, Font (a font family string),
	Size and MinSize (Vector2), Resizable (default true). Window:SetSize(width, height) resizes from code.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Blossom = {}

local INTER = "rbxassetid://12187365364"
local Vec2, Dim2 = Vector2.new, UDim2.new
local Offset = UDim2.fromOffset
local RGB = Color3.fromRGB
local floor, round = math.floor, math.round
local FULL = 99

-- Spacing rule: Pad around every surface, Gap between stacked items. Sizes are even so centring stays on whole pixels.
local Metrics = {
	Pad = 10, Gap = 6, SectionGap = 10,
	Radius = 3, SmallRadius = 2, CardRadius = 4, PillRadius = 5, PopupRadius = 5, FloatRadius = 6, WindowRadius = 6,
	WindowW = 586, WindowH = 466, MinWindowW = 520, MinWindowH = 380, SidebarW = 141, ContentX = 142, ColumnW = 207,
	TabW = 121, TabH = 28, TabPitch = 32, CategoryToTab = 25, TabToCategory = 25, FirstCategory = 56, SearchH = 28,
	Row = 16, HeaderH = 24, HeaderDescH = 40,
	DividerH = 9, SliderH = 33, DropdownH = 47, InputH = 26, ButtonH = 28, ListRowH = 24,
	ToggleW = 28, ToggleH = 16, ToggleKnob = 10, Knob = 11, PickerKnob = 8, TrackH = 9, TrackY = 24, TrackInset = 5,
	ChipH = 16, ValueChipH = 17, Swatch = 14, ChipGap = 2,
}

local Themes = {
	Blossom = {
		Background = RGB(42, 44, 52), Tab = RGB(48, 50, 58), Outline = RGB(65, 68, 80), Inline = RGB(56, 58, 68),
		Text = RGB(232, 234, 245), InactiveText = RGB(126, 130, 148), Accent = RGB(113, 159, 226), Element = RGB(54, 57, 68),
		Gradient = RGB(172, 187, 209), Shadow = RGB(0, 0, 0), HoveredElement = RGB(72, 77, 90),
	},
	Afterglow = {
		Background = RGB(34, 28, 25), Tab = RGB(30, 23, 20), Outline = RGB(60, 46, 38), Inline = RGB(42, 33, 29),
		Text = RGB(240, 232, 226), InactiveText = RGB(140, 122, 110), Accent = RGB(255, 145, 60), Element = RGB(49, 34, 27),
		Gradient = RGB(172, 167, 163), Shadow = RGB(0, 0, 0), HoveredElement = RGB(70, 51, 42),
	},
	Frostbite = {
		Background = RGB(22, 30, 38), Tab = RGB(16, 25, 32), Outline = RGB(42, 58, 72), Inline = RGB(27, 38, 47),
		Text = RGB(228, 240, 248), InactiveText = RGB(114, 136, 152), Accent = RGB(86, 219, 255), Element = RGB(28, 39, 52),
		Gradient = RGB(164, 172, 178), Shadow = RGB(0, 0, 0), HoveredElement = RGB(44, 60, 74),
	},
	Volt = {
		Background = RGB(24, 24, 20), Tab = RGB(18, 18, 14), Outline = RGB(54, 54, 40), Inline = RGB(32, 32, 26),
		Text = RGB(242, 242, 226), InactiveText = RGB(134, 134, 112), Accent = RGB(255, 250, 76), Element = RGB(32, 32, 26),
		Gradient = RGB(170, 170, 158), Shadow = RGB(0, 0, 0), HoveredElement = RGB(58, 58, 44),
	},
	Obsidian = {
		Background = RGB(16, 16, 18), Tab = RGB(12, 11, 14), Outline = RGB(44, 42, 52), Inline = RGB(24, 24, 29),
		Text = RGB(234, 232, 244), InactiveText = RGB(118, 114, 134), Accent = RGB(159, 109, 255), Element = RGB(24, 23, 31),
		Gradient = RGB(166, 164, 175), Shadow = RGB(0, 0, 0), HoveredElement = RGB(236, 240, 248),
	},
	["Sakura Drift"] = {
		Background = RGB(38, 28, 34), Tab = RGB(32, 23, 29), Outline = RGB(70, 50, 62), Inline = RGB(48, 35, 43),
		Text = RGB(248, 234, 242), InactiveText = RGB(150, 122, 138), Accent = RGB(255, 155, 205), Element = RGB(44, 46, 48),
		Gradient = RGB(176, 166, 172), Shadow = RGB(0, 0, 0), HoveredElement = RGB(77, 53, 67),
	},
	["Neon Mirage"] = {
		Background = RGB(22, 16, 34), Tab = RGB(17, 12, 28), Outline = RGB(54, 40, 82), Inline = RGB(32, 23, 48),
		Text = RGB(238, 232, 252), InactiveText = RGB(128, 114, 160), Accent = RGB(255, 86, 255), Element = RGB(30, 21, 46),
		Gradient = RGB(144, 163, 182), Shadow = RGB(0, 0, 0), HoveredElement = RGB(56, 39, 84),
	},
	["Copper Dust"] = {
		Background = RGB(39, 30, 25), Tab = RGB(34, 25, 20), Outline = RGB(72, 54, 42), Inline = RGB(49, 36, 28),
		Text = RGB(244, 232, 220), InactiveText = RGB(148, 124, 104), Accent = RGB(243, 152, 86), Element = RGB(51, 34, 22),
		Gradient = RGB(173, 164, 155), Shadow = RGB(0, 0, 0), HoveredElement = RGB(77, 56, 42),
	},
	Abyss = {
		Background = RGB(12, 20, 28), Tab = RGB(8, 15, 22), Outline = RGB(30, 48, 62), Inline = RGB(18, 30, 40),
		Text = RGB(222, 236, 246), InactiveText = RGB(100, 128, 148), Accent = RGB(52, 176, 238), Element = RGB(16, 28, 38),
		Gradient = RGB(158, 169, 176), Shadow = RGB(0, 0, 0), HoveredElement = RGB(32, 51, 67),
	},
	Porcelain = {
		Background = RGB(250, 248, 244), Tab = RGB(236, 234, 230), Outline = RGB(214, 212, 208), Inline = RGB(255, 255, 255),
		Text = RGB(44, 46, 54), InactiveText = RGB(140, 142, 150), Accent = RGB(133, 176, 255), Element = RGB(255, 255, 255),
		Gradient = RGB(214, 218, 226), Shadow = RGB(120, 120, 120), HoveredElement = RGB(255, 255, 255),
	},
	Graphite = {
		Background = RGB(32, 30, 30), Tab = RGB(40, 40, 40), Outline = RGB(58, 60, 62), Inline = RGB(42, 45, 46),
		Text = RGB(236, 236, 250), InactiveText = RGB(128, 128, 134), Accent = RGB(105, 159, 237), Element = RGB(44, 46, 46),
		Gradient = RGB(190, 190, 190), Shadow = RGB(0, 0, 0), HoveredElement = RGB(67, 70, 72),
	},
}
local ThemeOrder = { "Blossom", "Afterglow", "Frostbite", "Volt", "Obsidian", "Sakura Drift", "Neon Mirage", "Copper Dust", "Abyss", "Porcelain", "Graphite" }
local ThemeKeys = {
	{ "Background", "Background" }, { "Tab", "Tab" }, { "Outline", "Outline" }, { "Inline", "Inline" },
	{ "Text", "Text" }, { "Inactive Text", "InactiveText" }, { "Accent", "Accent" }, { "Element", "Element" },
	{ "Gradient", "Gradient" }, { "Shadow", "Shadow" }, { "Hovered Element", "HoveredElement" },
}
local Casings = { "Normal", "Lower Case", "Upper Case", "Bold Case" }
local Fonts = {
	Inter = INTER,
	["Builder Sans"] = "rbxasset://fonts/families/BuilderSans.json",
	Roboto = "rbxasset://fonts/families/Roboto.json",
	Montserrat = "rbxasset://fonts/families/Montserrat.json",
	["Source Sans Pro"] = "rbxasset://fonts/families/SourceSansPro.json",
	Ubuntu = "rbxasset://fonts/families/Ubuntu.json",
	Nunito = "rbxasset://fonts/families/Nunito.json",
	Arimo = "rbxasset://fonts/families/Arimo.json",
}
local FontOrder = { "Inter", "Builder Sans", "Roboto", "Montserrat", "Source Sans Pro", "Ubuntu", "Nunito", "Arimo" }
local WeightOrder = { "Regular", "Medium", "SemiBold", "Bold" }

local Current = table.clone(Themes.Blossom)
local Casing = "Normal"
local FontFamily = INTER
local BodyWeight = Enum.FontWeight.SemiBold

Blossom.Themes = Themes
Blossom.ThemeOrder = ThemeOrder
Blossom.Metrics = Metrics
Blossom.Fonts = Fonts

-------------------------------------------------------------------------------
-- Animator: one render-step loop driving springs. Retargeting keeps velocity,
-- so interrupted motion stays continuous, and it costs far less than TweenService.
-------------------------------------------------------------------------------

local Presets = {
	Fast = { W = 42, Z = 1 },      -- hover and colour feedback
	Knob = { W = 44, Z = 0.86 },   -- toggles and slider knobs
	Follow = { W = 34, Z = 1 },    -- things attached to the pointer
	Smooth = { W = 26, Z = 1 },    -- layout and popups
	Soft = { W = 19, Z = 1 },      -- page transitions, theme morphs
	Settle = { W = 24, Z = 0.8 },  -- small overshoot for reflow
}

local Active, Tracks, Jobs = {}, {}, {}
local EPS = { number = 0.0015, Color3 = 0.003, UDim2 = 0.4, Vector2 = 0.4 }

local function encode(v)
	local kind = typeof(v)
	if kind == "number" then return { v } end
	if kind == "Color3" then return { v.R, v.G, v.B } end
	if kind == "UDim2" then return { v.X.Scale, v.X.Offset, v.Y.Scale, v.Y.Offset } end
	if kind == "Vector2" then return { v.X, v.Y } end
	error("cannot animate " .. kind)
end

local function decode(kind, x)
	if kind == "number" then return x[1] end
	if kind == "Color3" then return Color3.new(math.clamp(x[1], 0, 1), math.clamp(x[2], 0, 1), math.clamp(x[3], 0, 1)) end
	if kind == "UDim2" then return Dim2(x[1], round(x[2]), x[3], round(x[4])) end
	return Vec2(round(x[1]), round(x[2]))
end

local function untrack(entry)
	entry.Dead = true
	local map = Tracks[entry.Target]
	if map and map[entry.Prop] == entry then
		map[entry.Prop] = nil
		if next(map) == nil then Tracks[entry.Target] = nil end
	end
end

local function animate(target, prop, goal, preset, opts)
	local map = Tracks[target]
	if not map then map = {}; Tracks[target] = map end
	local entry = map[prop]
	if not entry then
		local from = encode(target[prop])
		local vel = {}
		for i = 1, #from do vel[i] = 0 end
		entry = { Target = target, Prop = prop, Kind = typeof(goal), X = from, V = vel }
		map[prop] = entry
		table.insert(Active, entry)
	end
	entry.G, entry.Goal = encode(goal), goal
	entry.P = Presets[preset or "Smooth"]
	entry.Done = opts and opts.Done or nil
	entry.Step = opts and opts.Step or nil
end

local function snap(target, prop, value)
	local map = Tracks[target]
	local entry = map and map[prop]
	if entry then untrack(entry) end
	target[prop] = value
end

local function place(target, prop, value, animated, preset)
	if animated then animate(target, prop, value, preset) else snap(target, prop, value) end
end

local function stepAnimator(dt)
	dt = math.min(dt, 1 / 20)
	local cache = {}
	local i = 1
	while i <= #Active do
		local e = Active[i]
		if e.Dead then
			Active[i] = Active[#Active]
			Active[#Active] = nil
		else
			local c = cache[e.P]
			if not c then
				local w, z = e.P.W, e.P.Z
				local t = dt
				if z >= 1 then
					local k = math.exp(-w * t)
					c = { k * (1 + w * t), k * t, -k * w * w * t, k * (1 - w * t) }
				else
					local wd = w * math.sqrt(1 - z * z)
					local k, co, si = math.exp(-z * w * t), math.cos(wd * t), math.sin(wd * t)
					c = { k * (co + z * w * si / wd), k * si / wd, -k * w * w * si / wd, k * (co - z * w * si / wd) }
				end
				cache[e.P] = c
			end
			local x, v, g = e.X, e.V, e.G
			local eps, settled = EPS[e.Kind], true
			local velEps = eps * e.P.W
			for n = 1, #x do
				local d = x[n] - g[n]
				local nv = c[3] * d + c[4] * v[n]
				local nd = c[1] * d + c[2] * v[n]
				x[n], v[n] = g[n] + nd, nv
				local channelEps = (e.Kind == "UDim2" and n % 2 == 1) and 0.0005 or eps
				if math.abs(nd) > channelEps or math.abs(nv) > velEps then settled = false end
			end
			if settled then
				e.Target[e.Prop] = e.Goal
				if e.Step then e.Step(e.Goal) end
				local done = e.Done
				untrack(e)
				Active[i] = Active[#Active]
				Active[#Active] = nil
				if done then task.spawn(done) end
			else
				local value = decode(e.Kind, x)
				if value ~= e.Last then
					e.Last = value
					e.Target[e.Prop] = value
					if e.Step then e.Step(value) end
				end
				i += 1
			end
		end
	end
end

local FrameConnection
local sweepHover
local function ensureLoop()
	if FrameConnection then return end
	FrameConnection = RunService.RenderStepped:Connect(function(dt)
		stepAnimator(dt)
		local currentJobs = {}
		for job in Jobs do table.insert(currentJobs, job) end
		for _, job in currentJobs do
			if Jobs[job] then job(dt) end
		end
		sweepHover()
	end)
end

-------------------------------------------------------------------------------
-- Theme, casing and font registries
-------------------------------------------------------------------------------

local Bound, ByKey, Dynamic, Cased, NoFade = {}, {}, {}, {}, {}

local function resolve(source)
	if type(source) == "function" then return source() end
	return Current[source]
end

local function forget(inst)
	local bindings = Bound[inst]
	if bindings then
		for prop, source in bindings do
			if type(source) == "string" then
				local set = ByKey[source]
				if set then set[inst] = nil end
			end
		end
	end
	Bound[inst], Dynamic[inst], Cased[inst], Tracks[inst], NoFade[inst] = nil, nil, nil, nil, nil
end

local function bind(inst, prop, source)
	local bindings = Bound[inst]
	if not bindings then
		bindings = {}
		Bound[inst] = bindings
		inst.Destroying:Once(function() forget(inst) end)
	end
	bindings[prop] = source
	if type(source) == "string" then
		local set = ByKey[source]
		if not set then set = {}; ByKey[source] = set end
		set[inst] = prop
	else
		Dynamic[inst] = true
	end
	inst[prop] = resolve(source)
end

local function refresh(inst, preset)
	local bindings = Bound[inst]
	if not bindings then return end
	for prop, source in bindings do
		local value = resolve(source)
		if preset == false or typeof(value) == "ColorSequence" then
			snap(inst, prop, value)
		else
			animate(inst, prop, value, preset or "Fast")
		end
	end
end

local function applyCase(text)
	if Casing == "Lower Case" then return string.lower(text) end
	if Casing == "Upper Case" or Casing == "Bold Case" then return string.upper(text) end
	return text
end

local function fontOf(weight)
	if Casing == "Bold Case" then weight = Enum.FontWeight.Bold end
	return Font.new(FontFamily, weight or BodyWeight, Enum.FontStyle.Normal)
end

local function setText(inst, text, prop)
	prop = prop or "Text"
	local entry = Cased[inst]
	if not entry then entry = {}; Cased[inst] = entry end
	entry[prop] = text
	inst[prop] = applyCase(text)
end

local function applyTextSettings()
	for inst, entry in Cased do
		for prop, raw in entry do
			if prop == "Text" or prop == "PlaceholderText" then inst[prop] = applyCase(raw) end
		end
		inst.FontFace = fontOf(entry.Weight)
	end
end

local TEXT_CLASSES = { TextLabel = true, TextButton = true, TextBox = true }

local function new(class, props, parent)
	local inst = Instance.new(class)
	if inst:IsA("GuiObject") then
		inst.BorderSizePixel = 0
		inst.BackgroundTransparency = 1
	end
	if class == "TextButton" then
		inst.AutoButtonColor = false
		inst.Text = ""
	end
	if TEXT_CLASSES[class] then
		if class ~= "TextButton" then Cased[inst] = {} end
		inst.FontFace = fontOf(nil)
		inst.TextSize = 13
		inst.TextXAlignment = Enum.TextXAlignment.Left
		inst.TextYAlignment = Enum.TextYAlignment.Top
	end
	local bg, fg, radius, border
	if props then
		for key, value in props do
			if key == "Bg" then bg = value
			elseif key == "Fg" then fg = value
			elseif key == "Radius" then radius = value
			elseif key == "Border" then border = value
			elseif key == "Weight" then
				if not Cased[inst] then Cased[inst] = {} end
				Cased[inst].Weight = value
				inst.FontFace = fontOf(value)
			elseif (key == "Text" and class ~= "TextBox" or key == "PlaceholderText") and TEXT_CLASSES[class] then
				setText(inst, value, key)
			else
				inst[key] = value
			end
		end
	end
	if bg then
		if not (props and props.BackgroundTransparency) then inst.BackgroundTransparency = 0 end
		bind(inst, "BackgroundColor3", bg)
	end
	if fg then bind(inst, "TextColor3", fg) end
	if radius then
		local corner = Instance.new("UICorner")
		corner.CornerRadius = radius >= FULL and UDim.new(0.5, 0) or UDim.new(0, radius)
		corner.Parent = inst
	end
	if border then
		local stroke = Instance.new("UIStroke")
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Thickness = 1
		bind(stroke, "Color", border)
		stroke.Parent = inst
	end
	if parent then inst.Parent = parent end
	return inst
end

-- Top-aligned text at a computed whole-pixel offset.
local function capOffset(rowH, size)
	local capHeight = round(size * 0.7)
	return math.ceil((rowH - capHeight) / 2 - round(size * 0.16))
end

local function label(parent, o)
	local size, rowH = o.TextSize or 12, o.RowH or Metrics.Row
	local x = o.X or 0
	return new("TextLabel", {
		Fg = o.Fg or "Text", Text = o.Text or "", TextSize = size, Weight = o.Weight, TextTruncate = o.Truncate,
		TextTransparency = o.TextTransparency, ZIndex = o.ZIndex,
		Position = Offset(x, (o.Y or 0) + capOffset(rowH, size)),
		Size = o.W and Offset(o.W, rowH) or Dim2(1, -x - (o.Right or 0), 0, rowH),
	}, parent)
end

-- Centres text inside a fixed width using its measured bounds, floored to a whole pixel.
local function centeredLabel(parent, width, o)
	o.Truncate = Enum.TextTruncate.AtEnd
	local text = label(parent, o)
	local y, rowH = text.Position.Y.Offset, o.RowH or Metrics.Row
	local function fit()
		text.Size = Offset(width - 12, rowH)
		text.Position = Offset(floor((width - math.min(math.ceil(text.TextBounds.X), width - 12)) / 2), y)
	end
	text:GetPropertyChangedSignal("TextBounds"):Connect(fit)
	fit()
	return text, function(newWidth)
		width = newWidth
		fit()
	end
end

local function addGradient(inst)
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	bind(gradient, "Color", function() return ColorSequence.new(Color3.new(1, 1, 1), Current.Gradient) end)
	gradient.Parent = inst
	return gradient
end

local Shadows = {
	Large = { Blur = 10, Spread = 0, Transparency = 0.3 },
	PickerKnob = { Blur = 6, Spread = 6, Transparency = 0.5 },
}

local ShadowsAvailable = pcall(function()
	local shadow = Instance.new("UIShadow")
	shadow.BlurRadius = UDim.new(0, 10)
	shadow.Spread = Offset(0, 0)
	shadow.Transparency = 0.3
	shadow.Color = Color3.new(0, 0, 0)
	shadow:Destroy()
end)

local function addShadow(inst, style)
	if not ShadowsAvailable then return nil end
	local ok, shadow = pcall(function()
		local preset = Shadows[style]
		local s = Instance.new("UIShadow")
		s.BlurRadius = UDim.new(0, preset.Blur)
		s.Spread = Offset(preset.Spread, preset.Spread)
		s.Transparency = preset.Transparency
		bind(s, "Color", "Shadow")
		s.Parent = inst
		return s
	end)
	return ok and shadow or nil
end

local function fire(callback, ...)
	if callback then task.spawn(callback, ...) end
end

local function clamp01(n) return math.clamp(n, 0, 1) end

local function isClick(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

local ScreenRef

local function mousePos()
	local location = UserInputService:GetMouseLocation()
	if ScreenRef then return location + ScreenRef.AbsolutePosition end
	return location
end

local function toLayer(point)
	return ScreenRef and point - ScreenRef.AbsolutePosition or point
end

local function inside(frame, point, margin)
	margin = margin or 0
	local p, s = frame.AbsolutePosition, frame.AbsoluteSize
	return point.X >= p.X - margin and point.X <= p.X + s.X + margin and point.Y >= p.Y - margin and point.Y <= p.Y + s.Y + margin
end

local function beginDrag(onMove, onEnd, onFrame)
	local last
	local function job(dt)
		local point = mousePos()
		if not last or point ~= last then
			last = point
			if onMove then onMove(point) end
		end
		if onFrame then onFrame(point, dt) end
	end
	Jobs[job] = true
	local ended
	ended = UserInputService.InputEnded:Connect(function(input)
		if isClick(input) then
			ended:Disconnect()
			Jobs[job] = nil
			local point = mousePos()
			if onMove and point ~= last then onMove(point) end
			if onEnd then onEnd(point) end
		end
	end)
end

local Focus
local HoverSet = {}

local function isShown(inst)
	local node = inst
	while node and node:IsA("GuiObject") do
		if not node.Visible then return false end
		node = node.Parent
	end
	return true
end

local function covered(inst, point)
	local win = Focus
	if not win then return false end
	local dropdown = win.OpenDropdown
	if dropdown then
		if inst:IsDescendantOf(dropdown.Panel) then return false end
		if inside(dropdown.Panel, point) then return true end
	end
	local popup = win.ActivePopup
	if popup and inside(popup.Frame, point) and not inst:IsDescendantOf(popup.Frame) then return true end
	if win.Search and win.Search.Open and not inst:IsDescendantOf(win.Search.Overlay) then return true end
	return false
end

local function hoverable(inst, onEnter, onLeave)
	local entered = false
	local function leave()
		if not entered then return end
		entered = false
		HoverSet[inst] = nil
		onLeave()
	end
	inst.MouseEnter:Connect(function()
		if entered or covered(inst, mousePos()) then return end
		entered = true
		HoverSet[inst] = leave
		onEnter()
	end)
	inst.MouseLeave:Connect(leave)
	inst.Destroying:Once(function() HoverSet[inst] = nil end)
end

function sweepHover()
	if next(HoverSet) == nil then return end
	local point = mousePos()
	local toLeave = {}
	for inst, leave in HoverSet do
		if not inside(inst, point) or not isShown(inst) or covered(inst, point) then
			table.insert(toLeave, leave)
		end
	end
	for _, leave in toLeave do leave() end
end

-------------------------------------------------------------------------------
-- Fader: one animated alpha drives every transparency beneath a root
-------------------------------------------------------------------------------

local Fader = {}
Fader.__index = Fader

local function newFader(root)
	return setmetatable({ Root = root, Alpha = 1, Entries = nil }, Fader)
end

local function captureFade(root)
	local entries = {}
	local function add(inst, prop)
		if NoFade[inst] or (Tracks[inst] and Tracks[inst][prop]) then return end
		local base = inst[prop]
		if base < 1 then table.insert(entries, { inst, prop, base }) end
	end
	local function visit(inst)
		if inst:IsA("GuiObject") then
			if inst ~= root and not inst.Visible then return end
			add(inst, "BackgroundTransparency")
			if TEXT_CLASSES[inst.ClassName] then add(inst, "TextTransparency") end
			if inst:IsA("ImageLabel") then add(inst, "ImageTransparency") end
		elseif inst:IsA("UIStroke") or inst.ClassName == "UIShadow" then
			add(inst, "Transparency")
		end
		for _, child in inst:GetChildren() do visit(child) end
	end
	visit(root)
	return entries
end

function Fader:_apply(alpha)
	local entries = self.Entries
	if not entries then return end
	for _, e in entries do
		e[1][e[2]] = 1 - (1 - e[3]) * alpha
	end
end

function Fader:Show(onDone, preset)
	if not self.Entries then
		self.Entries = captureFade(self.Root)
		self.Alpha = 0
		self:_apply(0)
	end
	self.Root.Visible = true
	animate(self, "Alpha", 1, preset or "Smooth", {
		Step = function(value) self:_apply(value) end,
		Done = function()
			self.Entries = nil
			if onDone then onDone() end
		end,
	})
end

function Fader:Hide(onDone, preset)
	if not self.Entries then
		self.Entries = captureFade(self.Root)
		self.Alpha = 1
	end
	animate(self, "Alpha", 0, preset or "Fast", {
		Step = function(value) self:_apply(value) end,
		Done = function()
			self.Root.Visible = false
			self:_apply(1)
			self.Entries = nil
			if onDone then onDone() end
		end,
	})
end

-------------------------------------------------------------------------------
-- Icons: drawn from frames on a 16x16 grid, so no decals have to be uploaded
-------------------------------------------------------------------------------

local Icons = {
	target = { { "f", 0.5, 0.5, 15, 15, FULL }, { "h", 3, 3, 10, 10, FULL }, { "f", 4.8, 4.8, 6.4, 6.4, FULL } },
	bullet = { { "f", 1, 4, 3, 8, 1 }, { "f", 5, 4, 6, 8, 1 }, { "f", 8.2, 5.2, 5.6, 5.6, 1, 45 } },
	smile = {
		{ "f", 1, 1, 14, 14, FULL }, { "h", 4.4, 5, 2.6, 2.6, FULL }, { "h", 9, 5, 2.6, 2.6, FULL },
		{ "h", 4.6, 9.8, 6.8, 2, FULL },
	},
	globe = {
		{ "f", 1, 1, 14, 14, FULL }, { "h", 3, 3.2, 4.4, 3, FULL, -20 }, { "h", 8.2, 8, 4.6, 3.8, FULL, 20 },
		{ "h", 9.8, 2.8, 2.6, 2, FULL }, { "h", 3.4, 9.6, 2.6, 2.6, FULL },
	},
	bomb = { { "f", 1, 4, 11, 11, FULL }, { "f", 9.2, 2.8, 4, 3, 0.5, 45 }, { "f", 12.8, 0.8, 2.4, 2.4, FULL } },
	file = {
		{ "f", 3, 1, 10, 14, 1.5 }, { "h", 10.6, -0.8, 4.2, 4.2, 0, 45 }, { "h", 5.5, 7.5, 5, 1.1, 0 },
		{ "h", 5.5, 10.3, 5, 1.1, 0 },
	},
	gear = {
		{ "f", 6.5, 0.8, 3, 14.4, 0.6, 0 }, { "f", 6.5, 0.8, 3, 14.4, 0.6, 45 }, { "f", 6.5, 0.8, 3, 14.4, 0.6, 90 },
		{ "f", 6.5, 0.8, 3, 14.4, 0.6, 135 }, { "f", 2.6, 2.6, 10.8, 10.8, FULL }, { "h", 5.6, 5.6, 4.8, 4.8, FULL },
	},
	robot = {
		{ "f", 7.2, 2, 1.6, 3.5, 0 }, { "f", 6.4, 0.5, 3.2, 3.2, FULL }, { "f", 2.2, 5, 11.6, 9.4, 2 },
		{ "f", 0.2, 8, 1.4, 4, 0.5 }, { "f", 14.4, 8, 1.4, 4, 0.5 }, { "h", 4.6, 7.6, 2.5, 2.5, FULL },
		{ "h", 8.9, 7.6, 2.5, 2.5, FULL }, { "h", 5.4, 11.4, 5.2, 1.1, 0 },
	},
	wrench = {
		{ "f", 5.6, 4.2, 3.8, 12.6, 1.4, 45 }, { "f", 8.8, 0.8, 6.6, 6.6, FULL },
		{ "h", 11.4, -1.2, 3.2, 5.8, 0, 45 },
	},
	cube = {
		{ "f", 4, 1.1, 8, 13.8, 0, 0 }, { "f", 4, 1.1, 8, 13.8, 0, 60 }, { "f", 4, 1.1, 8, 13.8, 0, 120 },
		{ "h", 7.5, 8, 1, 6.6, 0, 0 }, { "h", 4.6, 2.6, 1, 6.8, 0, 120 }, { "h", 10.4, 2.6, 1, 6.8, 0, 60 },
	},
	search = { { "r", 2, 2, 9, 9, FULL, 0, 1.7 }, { "f", 9.6, 11.2, 5.6, 2, FULL, 45 } },
	user = { { "f", 5, 1, 6, 6, FULL }, { "f", 2.5, 8.5, 11, 6.5, 3 } },
	key = {
		{ "f", 1, 8.5, 7, 7, FULL }, { "f", 6.2, 5, 9, 2.2, 0.6, -45 }, { "f", 11.2, 4.6, 3.4, 2, 0.4, 45 },
		{ "h", 3.1, 10.6, 2.8, 2.8, FULL },
	},
	grip = { { "f", 5.5, 11.3, 11, 1.5, FULL, -45 }, { "f", 10.2, 12.7, 5.6, 1.5, FULL, -45 } },
	check = { { "f", 2, 8.4, 6.2, 2, FULL, 45 }, { "f", 5.2, 6.8, 10, 2, FULL, -45 } },
	layout = { { "f", 0.5, 1, 15, 4.5, 1 }, { "f", 0.5, 6.5, 7, 8.5, 1 }, { "f", 8.5, 6.5, 7, 8.5, 1 } },
	reset = { { "r", 2.6, 2.6, 10.8, 10.8, FULL, 0, 1.8 }, { "h", 9.5, 0.5, 6, 5.5, 0 }, { "f", 9.2, 1.2, 4.6, 4.6, 0.5, 45 } },
	logo = (function()
		local parts = { { "f", 0.6, 0.6, 14.8, 14.8, FULL } }
		for arm = 0, 2 do
			for step = 0, 3 do
				local degrees = arm * 120 + step * 42
				local angle, radius = math.rad(degrees), 6.3 - step * 1.45
				local cx, cy = 8 + math.cos(angle) * radius, 8 + math.sin(angle) * radius
				table.insert(parts, { "h", cx - 2, cy - 0.6, 4, 1.2, FULL, degrees + 118 })
			end
		end
		table.insert(parts, { "h", 7, 7, 2, 2, FULL })
		return parts
	end)(),
}

local function makeIcon(parent, name, size, color, hole, props)
	props = props or {}
	local root = new("Frame", { Name = "Icon", Size = Offset(size, size), Position = props.Position, AnchorPoint = props.AnchorPoint, ZIndex = props.ZIndex }, parent)
	local icon = { Root = root, Parts = {} }
	if type(name) == "string" and string.find(name, "rbxasset", 1, true) then
		local image = new("ImageLabel", { Size = Dim2(1, 0, 1, 0), Image = name }, root)
		bind(image, "ImageColor3", color)
		table.insert(icon.Parts, image)
	else
		local scale = size / 16
		for _, part in Icons[name] or Icons.cube do
			local kind, x, y, w, h, radius, rotation, thickness = table.unpack(part, 1, 8)
			local frame = new("Frame", {
				Position = UDim2.fromScale(x / 16, y / 16), Size = UDim2.fromScale(w / 16, h / 16),
				Rotation = rotation or 0, Radius = radius and radius > 0 and (radius >= FULL and FULL or math.max(1, round(radius * scale))) or nil,
			}, root)
			if kind == "r" then
				local stroke = new("UIStroke", { Thickness = (thickness or 1.5) * scale }, frame)
				bind(stroke, "Color", color)
				table.insert(icon.Parts, stroke)
			else
				frame.BackgroundTransparency = 0
				bind(frame, "BackgroundColor3", kind == "h" and hole or color)
				table.insert(icon.Parts, frame)
			end
		end
	end
	function icon.Update(preset)
		for _, part in icon.Parts do refresh(part, preset) end
	end
	return icon
end

local function interactive(target, base, hover, press, handle)
	local state = { Hover = false, Press = false }
	local source = handle or target
	bind(target, "BackgroundColor3", function()
		if state.Press and press then return Current[press] end
		if state.Hover then return Current[hover or "HoveredElement"] end
		return Current[base]
	end)
	hoverable(source, function() state.Hover = true; refresh(target) end, function() state.Hover, state.Press = false, false; refresh(target) end)
	if source:IsA("GuiButton") then
		source.MouseButton1Down:Connect(function() state.Press = true; refresh(target) end)
		source.MouseButton1Up:Connect(function() state.Press = false; refresh(target) end)
	end
	return state
end

-------------------------------------------------------------------------------
-- Classes
-------------------------------------------------------------------------------

local Window, Tab, Section, Column = {}, {}, {}, {}
Window.__index, Tab.__index, Section.__index, Column.__index = Window, Tab, Section, Column

local function formatNumber(value, decimals)
	if decimals and decimals > 0 then return string.format("%." .. decimals .. "f", value) end
	return tostring(floor(value + 0.5))
end

local function keyName(key)
	if key == nil then return "-" end
	local name = typeof(key) == "EnumItem" and key.Name or tostring(key)
	local short = {
		LeftShift = "LS", RightShift = "RS", LeftControl = "LC", RightControl = "RC", LeftAlt = "LA", RightAlt = "RA",
		MouseButton1 = "M1", MouseButton2 = "M2", MouseButton3 = "M3", Return = "Ent", Backspace = "Bk",
		One = "1", Two = "2", Three = "3", Four = "4", Five = "5", Six = "6", Seven = "7", Eight = "8", Nine = "9", Zero = "0",
	}
	return short[name] or name
end

local function makeChip(parent, text, anchorRight, outerHeight)
	local height = (outerHeight or Metrics.ChipH) - 2
	local chip = new("Frame", {
		Bg = "Element", Radius = Metrics.Radius, Border = "Outline", Size = Offset(16, height),
		AnchorPoint = anchorRight and Vec2(1, 0) or nil,
	}, parent)
	addGradient(chip)
	local caption = label(chip, { Fg = "InactiveText", Text = text, TextSize = 11, X = 4, RowH = height })
	return chip, caption
end

local function fitChip(chip, text, minimum, onFit)
	local height = chip.Size.Y.Offset
	local function apply(bounds)
		local width = math.max((minimum or 2) - 2, bounds + 8)
		chip.Size = Offset(width, height)
		text.Position = Offset(floor((width - bounds) / 2), text.Position.Y.Offset)
		if onFit then onFit(width + 2) end
		return width
	end
	local function fit() apply(math.ceil(text.TextBounds.X)) end
	text:GetPropertyChangedSignal("TextBounds"):Connect(fit)
	fit()
	return apply, fit
end

local function makeEditable(chip, text, read, write, apply, fit)
	local height = chip.Size.Y.Offset
	local hit = new("TextButton", { Size = Dim2(1, 0, 1, 0), ZIndex = 2 }, chip)
	interactive(chip, "Element", nil, nil, hit)
	local editing = false
	local stroke = chip:FindFirstChildOfClass("UIStroke")
	bind(stroke, "Color", function() return editing and Current.Accent or Current.Outline end)
	local box = new("TextBox", {
		Fg = "Text", TextSize = 11, Visible = false, ZIndex = 3, ClearTextOnFocus = false,
		Position = Offset(4, capOffset(height, 11)), Size = Dim2(1, -8, 0, height),
	}, chip)
	box:GetPropertyChangedSignal("Text"):Connect(function()
		if editing then apply(math.ceil(box.TextBounds.X)) end
	end)
	hit.MouseButton1Click:Connect(function()
		editing = true
		refresh(stroke)
		box.Text = read()
		text.Visible, box.Visible = false, true
		box:CaptureFocus()
		box.CursorPosition = #box.Text + 1
		box.SelectionStart = 1
	end)
	box.FocusLost:Connect(function()
		if not editing then return end
		editing = false
		refresh(stroke)
		local number = tonumber(string.match(box.Text, "%-?%d*%.?%d+") or "")
		box.Visible, text.Visible = false, true
		if number then write(number) end
		fit()
	end)
end

-------------------------------------------------------------------------------
-- Column
-------------------------------------------------------------------------------

function Column:Layout(animated)
	local y = 0
	for _, section in self.Sections do
		section.Y = y
		if not section.Dragging and not section.Dropping then
			place(section.Root, "Position", Offset(0, y), animated, "Settle")
		end
		y += section.TotalH + Metrics.SectionGap
	end
	self.ContentH = math.max(0, y - Metrics.SectionGap)
	self.Scroll.CanvasSize = Offset(0, self.ContentH)
	self:ClampScroll()
end

function Column:ClampScroll()
	self.Target = math.clamp(self.Target, 0, math.max(0, self.ContentH - (self.Tab.Window.Height - Metrics.Pad * 2)))
end

function Column:ScrollTo(y)
	self.Target = y
	self:ClampScroll()
	animate(self.Scroll, "CanvasPosition", Vec2(0, self.Target), "Soft")
end

-------------------------------------------------------------------------------
-- Section
-------------------------------------------------------------------------------

function Section:Layout(animated)
	local y, any = Metrics.Pad, false
	for _, item in self.Items do
		if item.Visible then
			item.Y, any = y, true
			place(item.Frame, "Position", Offset(0, y), animated)
			y += item.Height + Metrics.Gap
		end
	end
	if any then y -= Metrics.Gap end
	self.CardH = y + Metrics.Pad
	self.TotalH = self.HeaderH + self.CardH
	place(self.Card, "Size", Dim2(1, -2, 0, self.CardH - 2), animated)
	if not self.Dragging then place(self.Root, "Size", Dim2(1, 0, 0, self.TotalH), animated) end
	if self.Column then self.Column:Layout(animated) end
end

function Section:_item(height, kind, name, indexed)
	local frame = new("Frame", { Size = Dim2(1, 0, 0, height) }, self.Body)
	local item = { Frame = frame, Height = height, Kind = kind, Name = name, Section = self, Slots = {}, Visible = true, Y = 0 }
	table.insert(self.Items, item)
	if name and indexed ~= false then table.insert(self.Window.Index, item) end
	self:Layout(false)
	return item
end

local function layoutSlots(item)
	local x = 0
	for _, slot in item.Slots do
		x += slot.Gap
		slot.Frame.Position = Dim2(1, -x - 1, 0, floor((Metrics.Row - slot.Height) / 2) + 1)
		x += slot.Width
	end
	if item.Label then item.Label.Size = Dim2(1, -(x + Metrics.Gap), 0, Metrics.Row) end
end

local function addSlot(item, frame, width, height, gap)
	local slot = { Frame = frame, Width = width, Height = height, Gap = #item.Slots == 0 and 0 or gap }
	frame.AnchorPoint = Vec2(1, 0)
	table.insert(item.Slots, slot)
	layoutSlots(item)
	return slot
end

local function attachKeybind(section, item, options)
	local win = section.Window
	local object = {
		Key = options.Key, Mode = options.Mode or "Toggle", Listening = false,
		OnPress = options.OnPress, OnRelease = options.OnRelease, Name = options.Name,
	}
	local chip, text = makeChip(item.Frame, keyName(object.Key))
	local button = new("TextButton", { Size = Dim2(1, 0, 1, 0), ZIndex = 2 }, chip)
	local slot = addSlot(item, chip, 18, Metrics.ChipH, Metrics.Gap + 2)
	fitChip(chip, text, 18, function(width)
		slot.Width = width
		layoutSlots(item)
	end)
	interactive(chip, "Element", nil, nil, button)
	bind(text, "TextColor3", function()
		if object.Listening then return Current.Accent end
		return Current.InactiveText
	end)
	function object.Refresh()
		setText(text, object.Listening and "..." or keyName(object.Key))
		refresh(text)
		if object.OnKeyChanged then object.OnKeyChanged() end
	end
	function object:Set(key)
		object.Key = key
		object.Refresh()
	end
	button.MouseButton1Click:Connect(function()
		object.Listening = true
		win.Listening = object
		object.Refresh()
	end)
	button.MouseButton2Click:Connect(function() win:OpenKeybindMenu(chip, object) end)
	object.Chip, object.Label = chip, text
	table.insert(win.Binds, object)
	return object
end

local function attachColor(section, item, options)
	local win = section.Window
	local color = {
		Value = options.Default or Color3.new(1, 1, 1), Alpha = options.Alpha or 0, Animation = "None",
		Callback = options.Callback, Flag = options.Flag,
	}
	local swatch = new("TextButton", {
		Size = Offset(Metrics.Swatch - 2, Metrics.Swatch - 2), Radius = Metrics.Radius, BackgroundTransparency = 0,
		BackgroundColor3 = color.Value, Border = "Outline",
	}, item.Frame)
	addSlot(item, swatch, Metrics.Swatch, Metrics.Swatch, Metrics.Gap + 2)
	color.Swatch = swatch
	function color:Set(value, alpha, silent)
		color.Value = value
		if alpha ~= nil then color.Alpha = alpha end
		swatch.BackgroundColor3 = value
		if win.Picker.Target == color and not win.Picker.Dragging then win.Picker.Sync() end
		if not silent then fire(color.Callback, value, color.Alpha) end
	end
	swatch.MouseButton1Click:Connect(function() win:OpenPicker(swatch, color) end)
	table.insert(win.Colors, color)
	return color
end

local function addInlineControls(section, item, options, name)
	local keybind, color
	if options.Color then
		color = attachColor(section, item, { Default = options.Color, Alpha = options.ColorAlpha, Callback = options.ColorCallback })
	end
	if options.Keybind ~= nil then
		keybind = attachKeybind(section, item, { Key = options.Keybind, Mode = options.KeybindMode, Name = options.KeybindName or name })
	end
	return keybind, color
end

local function register(section, object, options, item)
	local win = section.Window
	win.FlagOwners[item] = object
	if options.NoSave then return nil end
	local base = options.Flag or (section.Tab.Name .. "/" .. section.Name .. "/" .. tostring(options.Name or item.Kind))
	local flag, count = base, 1
	while win.Flags[flag] do
		count += 1
		flag = base .. "#" .. count
	end
	win.Flags[flag] = object
	object.Flag = flag
	return flag
end

function Section:Toggle(options)
	local win, name = self.Window, options.Name
	local item = self:_item(Metrics.Row, "Toggle", name)
	local toggle = { Value = options.Default == true, Item = item, Callback = options.Callback }
	local hit = new("TextButton", { Position = Offset(0, -3), Size = Dim2(1, 0, 1, 6) }, item.Frame)
	local hovering = false
	local text = label(item.Frame, {
		Text = name, Truncate = Enum.TextTruncate.AtEnd,
		Fg = function()
			if toggle.Value then return Current.Text end
			return hovering and Current.InactiveText:Lerp(Current.Text, 0.45) or Current.InactiveText
		end,
	})
	item.Label = text
	local track = new("Frame", {
		Bg = function() return toggle.Value and Current.Accent or Current.Element end,
		Size = Offset(Metrics.ToggleW - 2, Metrics.ToggleH - 2), Radius = FULL, Border = "Outline",
	}, item.Frame)
	addGradient(track)
	local knob = new("Frame", {
		Bg = function() return toggle.Value and Current.Text or Current.InactiveText end,
		Size = Offset(Metrics.ToggleKnob, Metrics.ToggleKnob), Radius = FULL,
	}, track)
	addSlot(item, track, Metrics.ToggleW, Metrics.ToggleH, 0)

	local function render(animated)
		local x = toggle.Value and Metrics.ToggleW - 2 - Metrics.ToggleKnob - 2 or 2
		place(knob, "Position", Offset(x, 2), animated, "Knob")
		local preset = animated and "Fast" or false
		refresh(track, preset); refresh(knob, preset); refresh(text, preset)
	end
	local function syncHotkey()
		if toggle.Keybind then win:SetHotkeyActive(toggle.Keybind, toggle.Value) end
	end

	function toggle:Set(value, silent)
		value = value == true
		if value == toggle.Value then return end
		toggle.Value = value
		render(true)
		syncHotkey()
		if not silent then fire(toggle.Callback, value) end
	end

	hoverable(hit, function()
		hovering = true
		refresh(text)
	end, function()
		hovering = false
		refresh(text)
	end)
	hit.MouseButton1Click:Connect(function() toggle:Set(not toggle.Value) end)

	local hotkeyName = options.KeybindName or (name == "Enabled" and self.Name) or name
	options.KeybindName = hotkeyName
	toggle.Keybind, toggle.Color = addInlineControls(self, item, options, hotkeyName)
	if toggle.Keybind then
		toggle.Keybind.OnPress = function()
			if toggle.Keybind.Mode == "Hold" then toggle:Set(true) else toggle:Set(not toggle.Value) end
		end
		toggle.Keybind.OnRelease = function()
			if toggle.Keybind.Mode == "Hold" then toggle:Set(false) end
		end
		toggle.Keybind.OnKeyChanged = syncHotkey
	end
	render(false)
	syncHotkey()
	local flag = register(self, toggle, options, item)
	if flag and toggle.Keybind then win.Flags[flag .. "/Key"] = toggle.Keybind end
	if flag and toggle.Color then win.Flags[flag .. "/Color"] = toggle.Color end
	return toggle
end

function Section:Label(options)
	local name = options.Name or options.Text
	local item = self:_item(Metrics.Row, "Label", name, false)
	local text = label(item.Frame, { Text = name, Truncate = Enum.TextTruncate.AtEnd })
	item.Label = text
	local object = { Item = item, Instance = text }
	function object:Set(value) setText(text, value) end
	object.Keybind, object.Color = addInlineControls(self, item, options, name)
	return object
end

function Section:Divider()
	local item = self:_item(Metrics.DividerH, "Divider", nil, false)
	new("Frame", { Bg = "Element", Position = Offset(1, 1), Size = Dim2(1, -2, 1, -2), Radius = FULL, Border = "Outline" }, item.Frame)
	return item
end

function Section:Keybind(options)
	local item = self:_item(Metrics.Row, "Keybind", options.Name)
	item.Label = label(item.Frame, { Text = options.Name, Truncate = Enum.TextTruncate.AtEnd })
	local object = attachKeybind(self, item, { Key = options.Default, Mode = options.Mode, Name = options.Name, OnPress = options.Callback })
	object.Item = item
	register(self, object, options, item)
	return object
end

function Section:Colorpicker(options)
	local item = self:_item(Metrics.Row, "Colorpicker", options.Name, options.Indexed)
	item.Label = label(item.Frame, { Text = options.Name, Truncate = Enum.TextTruncate.AtEnd })
	local object = attachColor(self, item, options)
	object.Item = item
	register(self, object, options, item)
	return object
end

local function trackWidth(win)
	return win.ColumnW - Metrics.Pad * 2 - 2
end

local function makeTrack(parent)
	local track = new("Frame", {
		Bg = "Element", Position = Offset(1, Metrics.TrackY + 1), Size = Dim2(1, -2, 0, Metrics.TrackH - 2),
		Radius = FULL, Border = "Outline",
	}, parent)
	addGradient(track)
	local fill = new("Frame", { Name = "Fill", Bg = "Accent", Radius = FULL, Size = Dim2(0, 0, 1, 0) }, track)
	addGradient(fill)
	local hit = new("TextButton", { Position = Offset(-4, Metrics.Row), Size = Dim2(1, 8, 0, Metrics.Row + 1), ZIndex = 4 }, parent)
	return track, fill, hit
end

local function makeKnob(track)
	return new("Frame", { Name = "Knob", Bg = "Text", Size = Offset(Metrics.Knob, Metrics.Knob), Radius = FULL, ZIndex = 3 }, track)
end

local function knobPixels(alpha, width)
	return round(Metrics.TrackInset + alpha * (width - Metrics.TrackInset * 2))
end

local function placeKnob(knob, pixels, animated)
	place(knob, "Position", Offset(pixels - floor(Metrics.Knob / 2), floor((Metrics.TrackH - 2 - Metrics.Knob) / 2)), animated, "Follow")
end

local function alphaAt(track, point)
	local inset = Metrics.TrackInset
	return clamp01((point.X - track.AbsolutePosition.X - inset) / (track.AbsoluteSize.X - inset * 2))
end

function Section:Slider(options)
	local item = self:_item(Metrics.SliderH, "Slider", options.Name)
	local caption = label(item.Frame, { Text = options.Name, Truncate = Enum.TextTruncate.AtEnd })
	local minimum, maximum = options.Min or 0, options.Max or 100
	local decimals, suffix = options.Decimals or 0, options.Suffix or ""
	local slider = { Value = minimum, Item = item, Callback = options.Callback }
	local chip, chipText = makeChip(item.Frame, "", true, Metrics.ValueChipH)
	chip.Position = Dim2(1, -1, 0, 0)
	local apply, fit = fitChip(chip, chipText, 24, function(width) caption.Size = Dim2(1, -(width + Metrics.Gap), 0, Metrics.Row) end)
	local track, fill, hit = makeTrack(item.Frame)
	local knob = makeKnob(track)

	local function render(animated)
		local alpha = maximum == minimum and 0 or (slider.Value - minimum) / (maximum - minimum)
		local pixels = knobPixels(alpha, trackWidth(self.Window))
		placeKnob(knob, pixels, animated)
		place(fill, "Size", Dim2(0, pixels, 1, 0), animated, "Follow")
	end

	function slider:Set(value, silent, animated)
		local step = 10 ^ -decimals
		value = math.clamp(floor(value / step + 0.5) * step, minimum, maximum)
		local changed = value ~= slider.Value
		slider.Value = value
		setText(chipText, formatNumber(value, decimals) .. suffix)
		render(animated ~= false)
		if changed and not silent then fire(slider.Callback, value) end
	end

	makeEditable(chip, chipText, function() return formatNumber(slider.Value, decimals) end, function(number) slider:Set(number) end, apply, fit)

	local function fromMouse(point)
		slider:Set(minimum + (maximum - minimum) * alphaAt(track, point))
	end
	hit.InputBegan:Connect(function(input)
		if not isClick(input) then return end
		fromMouse(mousePos())
		beginDrag(fromMouse)
	end)

	table.insert(self.Window.ResizeJobs, function() render(false) end)
	slider:Set(options.Default or minimum, true, false)
	register(self, slider, options, item)
	return slider
end

function Section:RangeSlider(options)
	local item = self:_item(Metrics.SliderH, "Range Slider", options.Name)
	local caption = label(item.Frame, { Text = options.Name, Truncate = Enum.TextTruncate.AtEnd })
	local minimum, maximum = options.Min or 0, options.Max or 100
	local decimals, suffix = options.Decimals or 0, options.Suffix or ""
	local default = options.Default or { minimum, maximum }
	local range = { Value = { default[1], default[2] }, Item = item, Callback = options.Callback }
	local highChip, highText = makeChip(item.Frame, "", true, Metrics.ValueChipH)
	local lowChip, lowText = makeChip(item.Frame, "", true, Metrics.ValueChipH)
	highChip.Position = Dim2(1, -1, 0, 0)
	local highWidth, lowWidth = 24, 24
	local function layoutChips()
		lowChip.Position = Dim2(1, -(highWidth + Metrics.ChipGap + 1), 0, 0)
		caption.Size = Dim2(1, -(highWidth + lowWidth + Metrics.ChipGap + Metrics.Gap), 0, Metrics.Row)
	end
	local applyHigh, fitHigh = fitChip(highChip, highText, 24, function(width) highWidth = width; layoutChips() end)
	local applyLow, fitLow = fitChip(lowChip, lowText, 24, function(width) lowWidth = width; layoutChips() end)
	local track, fill, hit = makeTrack(item.Frame)
	local lowKnob, highKnob = makeKnob(track), makeKnob(track)

	local function alphaOf(value) return (value - minimum) / (maximum - minimum) end

	local function render(animated)
		local width = trackWidth(self.Window)
		local low, high = knobPixels(alphaOf(range.Value[1]), width), knobPixels(alphaOf(range.Value[2]), width)
		placeKnob(lowKnob, low, animated)
		placeKnob(highKnob, high, animated)
		place(fill, "Position", Dim2(0, low, 0, 0), animated, "Follow")
		place(fill, "Size", Dim2(0, high - low, 1, 0), animated, "Follow")
	end

	function range:Set(value, silent, animated)
		range.Value = { math.min(value[1], value[2]), math.max(value[1], value[2]) }
		setText(lowText, formatNumber(range.Value[1], decimals) .. suffix)
		setText(highText, formatNumber(range.Value[2], decimals) .. suffix)
		render(animated ~= false)
		if not silent then fire(range.Callback, range.Value) end
	end

	local function snapped(value)
		local step = 10 ^ -decimals
		return math.clamp(floor(value / step + 0.5) * step, minimum, maximum)
	end

	makeEditable(lowChip, lowText, function() return formatNumber(range.Value[1], decimals) end, function(number)
		range:Set({ math.min(snapped(number), range.Value[2]), range.Value[2] })
	end, applyLow, fitLow)
	makeEditable(highChip, highText, function() return formatNumber(range.Value[2], decimals) end, function(number)
		range:Set({ range.Value[1], math.max(snapped(number), range.Value[1]) })
	end, applyHigh, fitHigh)

	local active = 1
	local function valueAt(point)
		return snapped(minimum + (maximum - minimum) * alphaAt(track, point))
	end
	local function fromMouse(point)
		local value, nextValue = valueAt(point), { range.Value[1], range.Value[2] }
		if active == 1 then
			nextValue[1] = math.min(value, nextValue[2])
		else
			nextValue[2] = math.max(value, nextValue[1])
		end
		range:Set(nextValue)
	end
	hit.InputBegan:Connect(function(input)
		if not isClick(input) then return end
		local point = mousePos()
		local value = valueAt(point)
		active = math.abs(value - range.Value[1]) <= math.abs(value - range.Value[2]) and 1 or 2
		fromMouse(point)
		beginDrag(fromMouse)
	end)

	table.insert(self.Window.ResizeJobs, function() render(false) end)
	range:Set(range.Value, true, false)
	register(self, range, options, item)
	return range
end

local function buildDropdown(win, parent, options)
	local dropdown = {
		Options = options.Options or {}, Multi = options.Multi == true, Open = false,
		Value = options.Multi and {} or options.Default, Callback = options.Callback,
	}
	if options.Multi and options.Default then
		if type(options.Default) == "table" then
			for k, v in options.Default do
				if type(k) == "number" then
					dropdown.Value[v] = true
				elseif v == true then
					dropdown.Value[k] = true
				end
			end
		end
	end

	local input = new("TextButton", {
		Position = Offset(1, (options.Y or 0) + 1), Size = Dim2(1, -2, 0, Metrics.InputH - 2), Radius = Metrics.Radius, BackgroundTransparency = 0,
	}, parent)
	interactive(input, "Element")
	addGradient(input)
	local stroke = new("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Thickness = 1 }, input)
	bind(stroke, "Color", function() return dropdown.Open and Current.Accent or Current.Outline end)
	local value = label(input, { Fg = "InactiveText", TextSize = 13, X = 7, RowH = Metrics.InputH - 2, Right = 28, Truncate = Enum.TextTruncate.AtEnd })
	makeIcon(input, "layout", 14, "InactiveText", "Element", { AnchorPoint = Vec2(1, 0), Position = Dim2(1, -5, 0, 5) })

	local panel = new("TextButton", { Bg = "Background", BackgroundTransparency = 1, Radius = Metrics.Radius, Visible = false, Size = Offset(10, 0) }, win.Dropdowns)
	local panelStroke = new("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Thickness = 1, Transparency = 1 }, panel)
	bind(panelStroke, "Color", "Outline")
	local list = new("ScrollingFrame", { Size = Dim2(1, 0, 1, 0), ScrollBarThickness = 0, CanvasSize = Offset(0, 0) }, panel)
	local rows, panelH, flipped = {}, 0, false
	local emptyText = label(panel, { Fg = "InactiveText", Text = options.Empty or "No options", TextSize = 13, X = 9, RowH = Metrics.ListRowH, Right = 8, TextTransparency = 1 })
	dropdown.Reveal = 0

	local function isSelected(option)
		if dropdown.Multi then return dropdown.Value[option] == true end
		return dropdown.Value == option
	end

	local function caption()
		if not dropdown.Multi then return dropdown.Value and tostring(dropdown.Value) or "None" end
		local names = {}
		for _, option in dropdown.Options do
			if dropdown.Value[option] then table.insert(names, tostring(option)) end
		end
		return #names > 0 and table.concat(names, ", ") or "None"
	end

	local function applyRow(row)
		local reveal = dropdown.Reveal
		row.Button.BackgroundTransparency = 1 - math.max(row.Sel, row.Hov) * reveal
		row.Bar.BackgroundTransparency = 1 - row.Sel * reveal
		row.Text.TextTransparency = 1 - reveal
	end

	local function applyReveal()
		local reveal = dropdown.Reveal
		panel.BackgroundTransparency = 1 - reveal
		panelStroke.Transparency = 1 - reveal
		emptyText.TextTransparency = 1 - reveal
		for _, row in rows do applyRow(row) end
	end

	local function paint(animated)
		local preset = animated and "Fast" or false
		for _, row in rows do
			local selected = isSelected(row.Option)
			if animated then
				animate(row, "Sel", selected and 1 or 0, "Fast", { Step = function() applyRow(row) end })
			else
				snap(row, "Sel", selected and 1 or 0)
				applyRow(row)
			end
			place(row.Text, "Position", Offset(selected and 17 or 8, row.TextY), animated, "Smooth")
			refresh(row.Text, preset)
			refresh(row.Button, preset)
		end
		setText(value, caption())
	end

	local function rebuild()
		for _, row in rows do row.Button:Destroy() end
		rows = {}
		local count = #dropdown.Options
		for index, option in dropdown.Options do
			local row = { Option = option, Sel = 0, Hov = 0, Hovering = false }
			row.Button = new("TextButton", {
				Bg = function() return row.Hovering and Current.Inline or Current.Tab end,
				BackgroundTransparency = 1, Position = Offset(0, (index - 1) * Metrics.ListRowH), Size = Dim2(1, 0, 0, Metrics.ListRowH),
				Radius = (index == 1 or index == count) and Metrics.Radius or nil,
			}, list)
			row.Bar = new("Frame", { Bg = "Accent", BackgroundTransparency = 1, Position = Offset(7, 6), Size = Offset(2, 12) }, row.Button)
			row.Text = label(row.Button, {
				Text = tostring(option), X = 8, TextSize = 13, RowH = Metrics.ListRowH, Right = 18, Truncate = Enum.TextTruncate.AtEnd, TextTransparency = 1,
				Fg = function() return isSelected(option) and Current.Text or Current.InactiveText end,
			})
			row.TextY = row.Text.Position.Y.Offset
			local function step() applyRow(row) end
			hoverable(row.Button, function()
				row.Hovering = true
				refresh(row.Button)
				animate(row, "Hov", 1, "Fast", { Step = step })
			end, function()
				row.Hovering = false
				refresh(row.Button)
				animate(row, "Hov", 0, "Fast", { Step = step })
			end)
			row.Button.MouseButton1Click:Connect(function()
				if dropdown.Multi then
					dropdown.Value[option] = not dropdown.Value[option] or nil
					paint(true)
					fire(dropdown.Callback, dropdown.Value)
				else
					dropdown:Set(option)
					dropdown:Toggle(false)
				end
			end)
			table.insert(rows, row)
		end
		list.CanvasSize = Offset(0, count * Metrics.ListRowH)
		emptyText.Visible = count == 0
		paint(false)
	end

	local function measure()
		panelH = math.clamp(#dropdown.Options, 1, options.MaxRows or 10) * Metrics.ListRowH
	end

	local function follow()
		local p, s = input.AbsolutePosition, input.AbsoluteSize
		local screen = win.Screen.AbsolutePosition.Y + win.Screen.AbsoluteSize.Y
		flipped = p.Y + s.Y + 6 + panelH > screen - 8 and p.Y - 6 - panelH > win.Screen.AbsolutePosition.Y + 8
		local goal = toLayer(Vec2(p.X, flipped and p.Y - 6 or p.Y + s.Y + 6))
		panel.AnchorPoint = flipped and Vec2(0, 1) or Vec2(0, 0)
		panel.Position = Offset(goal.X, goal.Y)
	end
	dropdown.Follow = follow

	function dropdown:Toggle(open)
		if open == nil then open = not dropdown.Open end
		if open == dropdown.Open then return end
		dropdown.Open = open
		refresh(stroke)
		local width = input.AbsoluteSize.X
		if open then
			if win.OpenDropdown and win.OpenDropdown ~= dropdown then win.OpenDropdown:Toggle(false) end
			win.OpenDropdown = dropdown
			measure()
			follow()
			panel.Visible = true
			panel.Size = Offset(width, panelH)
			animate(dropdown, "Reveal", 1, "Fast", { Step = applyReveal })
			local selectedIndex = not dropdown.Multi and table.find(dropdown.Options, dropdown.Value)
			local furthest = math.max(0, #dropdown.Options * Metrics.ListRowH - panelH)
			list.CanvasPosition = Vec2(0, selectedIndex and math.clamp(floor((selectedIndex - 1) * Metrics.ListRowH - (panelH - Metrics.ListRowH) / 2), 0, furthest) or 0)
			for index, row in rows do
				local y = (index - 1) * Metrics.ListRowH
				row.Button.Position = Offset(0, y + 6)
				task.delay(math.min(index, 10) * 0.012, function()
					if row.Button.Parent then place(row.Button, "Position", Offset(0, y), dropdown.Open, "Smooth") end
				end)
			end
		else
			if win.OpenDropdown == dropdown then win.OpenDropdown = nil end
			animate(dropdown, "Reveal", 0, "Fast", {
				Step = applyReveal,
				Done = function() panel.Visible = false end,
			})
		end
	end

	function dropdown:Set(newValue, silent)
		if dropdown.Multi then
			dropdown.Value = {}
			if type(newValue) == "table" then
				for k, v in newValue do
					if type(k) == "number" then
						dropdown.Value[v] = true
					elseif v == true then
						dropdown.Value[k] = true
					end
				end
			end
		else
			dropdown.Value = newValue
		end
		paint(true)
		if not silent then fire(dropdown.Callback, dropdown.Multi and dropdown.Value or newValue) end
	end

	function dropdown:SetOptions(newOptions)
		dropdown.Options = newOptions
		rebuild()
		if dropdown.Open then
			measure()
			panel.Size = Offset(input.AbsoluteSize.X, panelH)
		end
	end

	dropdown.Input, dropdown.Panel = input, panel
	input.MouseButton1Click:Connect(function()
		if win.DropdownClosedBy == input and os.clock() - win.DropdownClosedAt < 0.25 then return end
		dropdown:Toggle()
	end)
	rebuild()
	return dropdown
end

function Section:Dropdown(options)
	local item = self:_item(Metrics.DropdownH, "Dropdown", options.Name)
	label(item.Frame, { Text = options.Name, Truncate = Enum.TextTruncate.AtEnd })
	options.Y = Metrics.DropdownH - Metrics.InputH
	local dropdown = buildDropdown(self.Window, item.Frame, options)
	dropdown.Item = item
	register(self, dropdown, options, item)
	return dropdown
end

function Section:Button(options)
	local item = self:_item(Metrics.ButtonH, "Button", options.Name)
	local win = self.Window
	local button = new("TextButton", { Position = Offset(1, 1), Size = Dim2(1, -2, 0, Metrics.ButtonH - 2), Radius = Metrics.Radius, Border = "Outline", BackgroundTransparency = 0 }, item.Frame)
	interactive(button, "Element", "HoveredElement", "Inline")
	addGradient(button)
	local _, setWidth = centeredLabel(button, trackWidth(win), { Text = options.Name, TextSize = 13, RowH = Metrics.ButtonH - 2 })
	table.insert(win.ResizeJobs, function() setWidth(trackWidth(win)) end)
	local object = { Item = item, Instance = button, Callback = options.Callback }
	button.MouseButton1Click:Connect(function() fire(object.Callback) end)
	return object
end

function Section:Textbox(options)
	local item = self:_item(Metrics.InputH, "Textbox", options.Name or options.Placeholder)
	local frame = new("Frame", { Bg = "Element", Position = Offset(1, 1), Size = Dim2(1, -2, 0, Metrics.InputH - 2), Radius = Metrics.Radius, Border = "Outline" }, item.Frame)
	addGradient(frame)
	local box = new("TextBox", {
		Fg = "Text", PlaceholderText = options.Placeholder or options.Name or "", Text = options.Default or "", TextSize = 13,
		Position = Offset(7, capOffset(Metrics.InputH - 2, 13)), Size = Dim2(1, -14, 0, 18), ClearTextOnFocus = false,
	}, frame)
	bind(box, "PlaceholderColor3", "InactiveText")
	local object = { Item = item, Instance = box, Value = box.Text, Callback = options.Callback }
	function object:Set(text, silent)
		box.Text = text
		object.Value = text
		if not silent then fire(object.Callback, text) end
	end
	local stroke = frame:FindFirstChildOfClass("UIStroke")
	local focused = false
	bind(stroke, "Color", function() return focused and Current.Accent or Current.Outline end)
	box.Focused:Connect(function() focused = true; refresh(stroke) end)
	box.FocusLost:Connect(function()
		focused = false
		refresh(stroke)
		object:Set(box.Text)
	end)
	register(self, object, options, item)
	return object
end

function Section:Listbox(options)
	local height = options.Height or 177
	local item = self:_item(height, "Listbox", options.Name, false)
	local frame = new("ScrollingFrame", {
		Bg = "Inline", Position = Offset(1, 1), Size = Dim2(1, -2, 0, height - 2), Radius = Metrics.Radius, Border = "Outline",
		ScrollBarThickness = 0, CanvasSize = Offset(0, 0),
	}, item.Frame)
	local listbox = { Options = {}, Value = nil, Item = item, Callback = options.Callback }
	local rows = {}
	local emptyText = label(frame, { Fg = "InactiveText", Text = options.Empty or "Nothing here yet", TextSize = 13, X = 10, Y = 2, RowH = Metrics.ListRowH, Right = 8 })

	local function paint(animated)
		local preset = animated and "Fast" or false
		for _, row in rows do
			local selected = listbox.Value == row.Option
			refresh(row.Text, preset)
			place(row.Text, "Position", Offset(selected and 17 or 8, row.TextY), animated, "Smooth")
			place(row.Bar, "BackgroundTransparency", selected and 0 or 1, animated, "Fast")
		end
	end

	function listbox:Set(value, silent)
		listbox.Value = value
		paint(true)
		if not silent then fire(listbox.Callback, value) end
	end

	function listbox:SetOptions(optionsList)
		for _, row in rows do row.Button:Destroy() end
		rows, listbox.Options = {}, optionsList
		for index, option in optionsList do
			local row = { Option = option }
			row.Button = new("TextButton", {
				Bg = "HoveredElement", BackgroundTransparency = 1, Position = Offset(2, 2 + (index - 1) * Metrics.ListRowH),
				Size = Dim2(1, -4, 0, Metrics.ListRowH), Radius = Metrics.SmallRadius,
			}, frame)
			NoFade[row.Button] = true
			row.Bar = new("Frame", { Bg = "Accent", BackgroundTransparency = 1, Position = Offset(6, 6), Size = Offset(2, 12) }, row.Button)
			row.Text = label(row.Button, {
				Text = option, X = 8, TextSize = 13, RowH = Metrics.ListRowH, Right = 18, Truncate = Enum.TextTruncate.AtEnd,
				Fg = function() return listbox.Value == option and Current.Text or Current.InactiveText end,
			})
			row.TextY = row.Text.Position.Y.Offset
			hoverable(row.Button, function() animate(row.Button, "BackgroundTransparency", 0, "Fast") end, function() animate(row.Button, "BackgroundTransparency", 1, "Fast") end)
			row.Button.MouseButton1Click:Connect(function() listbox:Set(option) end)
			table.insert(rows, row)
		end
		frame.CanvasSize = Offset(0, 4 + #optionsList * Metrics.ListRowH)
		emptyText.Visible = #optionsList == 0
		paint(false)
	end

	listbox:SetOptions(options.Options or {})
	return listbox
end

function Section:_beginDrag()
	if self.Dropping then return end
	local win, start = self.Window, mousePos()
	local grab = start - self.Root.AbsolutePosition
	local stroke = self.Card:FindFirstChildOfClass("UIStroke")
	local lifted, ghost, ghostFader = false, nil, nil

	local function slotPosition(column)
		return column.Scroll.AbsolutePosition + Vec2(0, self.Y - column.Scroll.CanvasPosition.Y)
	end

	local function targetFor(point)
		local page = self.Tab
		local left, right = page.Columns[1], page.Columns[2]
		local boundary = (left.Scroll.AbsolutePosition.X + left.Scroll.AbsoluteSize.X + right.Scroll.AbsolutePosition.X) / 2
		local column = point.X < boundary and left or right
		local current = table.find(column.Sections, self)
		local index = 1
		for position, other in column.Sections do
			if other ~= self then
				local middle = column.Scroll.AbsolutePosition.Y - column.Scroll.CanvasPosition.Y + other.Y + other.TotalH / 2
				local bias = (current and position < current) and -14 or 14
				if point.Y > middle + bias then index += 1 end
			end
		end
		return column, index
	end

	local function lift()
		lifted = true
		self.Dragging = true
		win:CloseFloating()
		local absolute, size = self.Root.AbsolutePosition, self.Root.AbsoluteSize
		local layer = toLayer(absolute)
		self.Root.Parent = win.DragLayer
		self.Root.Size = Offset(size.X, self.TotalH)
		self.Root.Position = Offset(layer.X, layer.Y)
		refresh(stroke)
		ghost = new("Frame", {
			Bg = "Accent", BackgroundTransparency = 0.92, Radius = Metrics.CardRadius, Border = "Accent",
			Position = Offset(layer.X, layer.Y), Size = Offset(size.X, self.TotalH), ZIndex = -1,
		}, win.DragLayer)
		ghostFader = newFader(ghost)
		ghost.Visible = false
		ghostFader:Show(nil, "Fast")
	end

	local function move(point)
		if not lifted then
			if (point - start).Magnitude < 5 then return end
			lift()
		end
		local goal = toLayer(point - grab)
		animate(self.Root, "Position", Offset(goal.X, goal.Y), "Follow")
		local column, index = targetFor(point)
		local current = table.find(column.Sections, self)
		if column ~= self.Column or current ~= index then
			local previous = self.Column
			table.remove(previous.Sections, table.find(previous.Sections, self))
			table.insert(column.Sections, math.min(index, #column.Sections + 1), self)
			self.Column = column
			if previous ~= column then previous:Layout(true) end
			column:Layout(true)
		end
	end

	local function frame(point)
		if not lifted then return end
		local column = self.Column
		local scroll = column.Scroll
		local top, bottom = scroll.AbsolutePosition.Y, scroll.AbsolutePosition.Y + scroll.AbsoluteSize.Y
		if point.X >= scroll.AbsolutePosition.X and point.X <= scroll.AbsolutePosition.X + scroll.AbsoluteSize.X then
			if point.Y < top + 36 then column:ScrollTo(column.Target - 8)
			elseif point.Y > bottom - 36 then column:ScrollTo(column.Target + 8) end
		end
		local slot = toLayer(slotPosition(column))
		animate(ghost, "Position", Offset(slot.X, slot.Y), "Smooth")
	end

	beginDrag(move, function()
		if not lifted then return end
		local column = self.Column
		column:Layout(true)
		self.Dragging = false
		self.Dropping = true
		refresh(stroke)
		local goal = toLayer(slotPosition(column))
		local doomed = ghost
		ghostFader:Hide(function() doomed:Destroy() end)
		animate(self.Root, "Position", Offset(goal.X, goal.Y), "Smooth", {
			Done = function()
				self.Dropping = false
				self.Root.Parent = column.Scroll
				self.Root.Size = Dim2(1, 0, 0, self.TotalH)
				self.Root.Position = Offset(0, self.Y)
			end,
		})
	end, frame)
end

-------------------------------------------------------------------------------
-- Tab
-------------------------------------------------------------------------------

function Tab:Section(options)
	local win = self.Window
	local column = self.Columns[options.Side or 1]
	local headerH = options.Description and Metrics.HeaderDescH or Metrics.HeaderH
	local root = new("Frame", { Name = options.Name, Size = Dim2(1, 0, 0, headerH) }, column.Scroll)
	local header = new("TextButton", { Size = Dim2(1, 0, 0, headerH - 8) }, root)
	local hovering = false
	local titleColor = function() return hovering and Current.Text or Current.InactiveText end
	local icon = makeIcon(header, options.Icon or "cube", 16, titleColor, "Tab")
	local title = label(header, { Text = options.Name, X = 27, Fg = titleColor, Truncate = Enum.TextTruncate.AtEnd })
	if options.Description then
		label(header, { Fg = "InactiveText", Text = options.Description, TextSize = 11, RowH = 14, Y = 18, Truncate = Enum.TextTruncate.AtEnd })
	end
	local section
	local card = new("Frame", {
		Bg = "Inline", Active = true, Position = Offset(1, headerH + 1), Size = Dim2(1, -2, 0, 0),
		Radius = Metrics.CardRadius,
	}, root)
	local stroke = new("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Thickness = 1 }, card)
	bind(stroke, "Color", function() return section and section.Dragging and Current.Accent or Current.Outline end)
	local body = new("Frame", { Position = Offset(Metrics.Pad - 1, -1), Size = Dim2(1, -(Metrics.Pad - 1) * 2, 1, 2) }, card)
	section = setmetatable({
		Window = win, Tab = self, Column = column, Name = options.Name, Root = root, Card = card, Body = body,
		Items = {}, HeaderH = headerH, TotalH = headerH, CardH = 0, Y = 0, Dragging = false, Dropping = false, Title = title,
	}, Section)
	table.insert(column.Sections, section)
	table.insert(win.Sections, section)
	hoverable(header, function() hovering = true; icon.Update(); refresh(title) end, function() hovering = false; icon.Update(); refresh(title) end)
	header.MouseButton1Down:Connect(function() section:_beginDrag() end)
	section:Layout(false)
	return section
end

-------------------------------------------------------------------------------
-- Window
-------------------------------------------------------------------------------

local function guiParent(screen)
	if typeof(gethui) == "function" then
		pcall(function()
			local hui = gethui()
			if hui then screen.Parent = hui end
		end)
	end
	if not screen.Parent then
		if typeof(syn) == "table" and typeof(syn.protect_gui) == "function" then
			pcall(syn.protect_gui, screen)
		elseif typeof(protectgui) == "function" then
			pcall(protectgui, screen)
		end
		pcall(function() screen.Parent = game:GetService("CoreGui") end)
	end
	if not screen.Parent then
		local lp = Players.LocalPlayer
		if not lp then
			Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
			lp = Players.LocalPlayer
		end
		if lp then
			screen.Parent = lp:WaitForChild("PlayerGui")
		end
	end
end

function Window:Category(name)
	local y = self.SidebarY + (self.SidebarHasTabs and Metrics.TabToCategory or 0)
	label(self.Sidebar, { Fg = "InactiveText", Text = name, TextSize = 9, X = Metrics.Pad, RowH = 12, Y = y - 6, W = 120 })
	self.SidebarY = y
	self.SidebarAfterCategory = true
end

function Window:Tab(options)
	local y = self.SidebarY + (self.SidebarAfterCategory and Metrics.CategoryToTab or Metrics.TabPitch)
	self.SidebarAfterCategory, self.SidebarHasTabs = false, true
	self.SidebarY = y

	local tab = setmetatable({ Window = self, Name = options.Name, Y = y - Metrics.TabH / 2 }, Tab)
	local button = new("TextButton", { Position = Offset(Metrics.Pad, tab.Y), Size = Offset(Metrics.TabW, Metrics.TabH), ZIndex = 2 }, self.Sidebar)
	tab.Button = button
	local hovering = false
	local isActive = function() return self.CurrentTab == tab end
	local color = function() return (isActive() or hovering) and Current.Text or Current.InactiveText end
	local hole = function() return isActive() and Current.Inline or Current.Background end
	tab.Icon = makeIcon(button, options.Icon or "cube", 16, color, hole, { Position = Offset(6, 6) })
	tab.Label = label(button, { Text = options.Name, X = 33, TextSize = 13, RowH = Metrics.TabH, Fg = color, Right = 6, Truncate = Enum.TextTruncate.AtEnd })
	tab.LabelY = tab.Label.Position.Y.Offset

	tab.Page = new("Frame", { Name = options.Name, Size = Dim2(1, 0, 1, 0), Visible = false }, self.Pages)
	tab.Columns = {}
	for index = 1, 2 do
		local scroll = new("ScrollingFrame", {
			Position = Offset(Metrics.Pad + (index - 1) * (self.ColumnW + Metrics.Pad), 0),
			Size = Dim2(0, self.ColumnW, 1, 0), ScrollBarThickness = 0, CanvasSize = Offset(0, 0),
			ScrollingEnabled = not UserInputService.MouseEnabled, ClipsDescendants = true,
		}, tab.Page)
		local column = setmetatable({ Scroll = scroll, Sections = {}, Target = 0, ContentH = 0, Tab = tab, ShowTop = false, ShowBottom = false }, Column)
		local function edge(position, rotation)
			local frame = new("Frame", { Bg = "Tab", BackgroundTransparency = 1, Position = position, Size = Offset(self.ColumnW, 14), ZIndex = 4 }, tab.Page)
			new("UIGradient", { Rotation = rotation, Transparency = NumberSequence.new(1, 0) }, frame)
			return frame
		end
		local edgeX = Metrics.Pad + (index - 1) * (self.ColumnW + Metrics.Pad)
		column.FadeTop, column.FadeBottom = edge(Offset(edgeX, 0), 270), edge(Dim2(0, edgeX, 1, -14), 90)
		table.insert(self.Columns, column)
		tab.Columns[index] = column
	end

	local function paint()
		tab.Icon.Update()
		refresh(tab.Label)
		animate(tab.Label, "Position", Offset(hovering and not isActive() and 35 or 33, tab.LabelY), "Smooth")
	end
	tab.Paint = paint
	hoverable(button, function() hovering = true; paint() end, function() hovering = false; paint() end)
	button.MouseButton1Click:Connect(function() self:SelectTab(tab) end)
	table.insert(self.Tabs, tab)
	if not self.CurrentTab then self:SelectTab(tab, true) end
	return tab
end

function Window:SelectTab(tab, instant)
	if self.CurrentTab == tab then return end
	local previous = self.CurrentTab
	self.CurrentTab = tab
	self:CloseFloating()
	if previous then
		previous.Page.Visible = false
		previous.Paint()
	end
	tab.Page.Visible = true
	tab.Paint()
	self.Indicator.Visible = true
	place(self.Indicator, "Position", Offset(Metrics.Pad + 1, tab.Y + 1), not instant, "Soft")
	if not instant then
		self.Veil.BackgroundTransparency = 0
		animate(self.Veil, "BackgroundTransparency", 1, "Soft")
		tab.Page.Position = Offset(0, 10)
		animate(tab.Page, "Position", Offset(0, 0), "Soft")
	end
end

function Window:SetHotkeyActive(object, active)
	local entry = self.HotkeyEntries[object]
	local shouldShow = active and object.Key ~= nil
	if shouldShow and not entry then
		local frame = new("Frame", { Bg = "Background", Size = Offset(40, 24), Radius = Metrics.FloatRadius, Border = "Outline", Visible = false }, self.Hotkeys)
		new("Frame", { Bg = "Accent", Position = Offset(1, 5), Size = Offset(2, 14), Radius = Metrics.SmallRadius }, frame)
		local text = label(frame, { TextSize = 12, X = Metrics.Pad, RowH = 24, Weight = Enum.FontWeight.SemiBold })
		entry = { Frame = frame, Label = text, Fader = newFader(frame) }
		self.HotkeyEntries[object] = entry
		table.insert(self.HotkeyOrder, object)
		text:GetPropertyChangedSignal("TextBounds"):Connect(function()
			frame.Size = Offset(math.ceil(text.TextBounds.X) + Metrics.Pad * 2, 24)
		end)
		setText(text, (object.Name or "Key") .. " - " .. keyName(object.Key))
		frame.Size = Offset(math.ceil(text.TextBounds.X) + Metrics.Pad * 2, 24)
		frame.Position = Offset(-14, 33 * #self.HotkeyOrder + 1)
		entry.Fader:Show()
	elseif entry and shouldShow then
		setText(entry.Label, (object.Name or "Key") .. " - " .. keyName(object.Key))
		return
	elseif entry then
		self.HotkeyEntries[object] = nil
		table.remove(self.HotkeyOrder, table.find(self.HotkeyOrder, object))
		animate(entry.Frame, "Position", Offset(-14, entry.Frame.Position.Y.Offset), "Smooth")
		entry.Fader:Hide(function() entry.Frame:Destroy() end)
	else
		return
	end
	for index, key in self.HotkeyOrder do
		animate(self.HotkeyEntries[key].Frame, "Position", Offset(1, 33 * index + 1), "Settle")
	end
end

function Window:Notify(options)
	if type(options) == "string" then options = { Text = options } end
	local frame = new("Frame", { Bg = "Background", Size = Offset(60, 28), Radius = Metrics.FloatRadius, Border = "Outline", Visible = false }, self.Notifications)
	makeIcon(frame, options.Icon or "check", 14, function() return RGB(112, 205, 132) end, "Background", { Position = Offset(8, 7) })
	local text = label(frame, { Text = options.Text, TextSize = 12, X = 28, RowH = 28, W = 340, Truncate = Enum.TextTruncate.AtEnd })
	local entry = { Frame = frame, Fader = newFader(frame) }
	local function fit() frame.Size = Offset(math.min(math.ceil(text.TextBounds.X), 340) + 38, 28) end
	text:GetPropertyChangedSignal("TextBounds"):Connect(fit)
	fit()
	table.insert(self.NotifyStack, 1, entry)
	local function stack()
		local count = #self.NotifyStack
		for index, item in self.NotifyStack do
			local y = (count - index) * 36
			if not item.Placed then
				item.Placed = true
				item.Frame.Position = Offset(-36, y)
			end
			animate(item.Frame, "Position", Offset(0, y), "Settle")
		end
	end
	function entry.Dismiss()
		if entry.Gone then return end
		entry.Gone = true
		table.remove(self.NotifyStack, table.find(self.NotifyStack, entry))
		animate(frame, "Position", Offset(-36, frame.Position.Y.Offset), "Smooth")
		entry.Fader:Hide(function() frame:Destroy() end)
		stack()
	end
	stack()
	entry.Fader:Show()
	if #self.NotifyStack > 6 then self.NotifyStack[#self.NotifyStack].Dismiss() end
	task.delay(options.Duration or 3, entry.Dismiss)
end

function Window:ApplyTheme(name, silent)
	local theme = Themes[name]
	if not theme then return end
	for key, value in theme do Current[key] = value end
	self.ThemeName = name
	local hidden = {}
	for _, tab in self.Tabs do
		if tab ~= self.CurrentTab then
			for _, inst in tab.Page:GetDescendants() do hidden[inst] = true end
		end
	end
	for inst in Bound do refresh(inst, not hidden[inst] and "Soft" or false) end
	for _, row in self.ThemeRows do row.Color:Set(Current[row.Key], nil, true) end
	if not silent then self:Notify(('Applied "%s" theme.'):format(name)) end
end

function Window:SetThemeColor(key, color)
	Current[key] = color
	self.PendingThemeKeys[key] = true
end

function Window:_flushThemeColors(dt)
	self.ThemeClock += dt
	if next(self.PendingThemeKeys) == nil or self.ThemeClock < 1 / 30 then return end
	self.ThemeClock = 0
	local keys = {}
	for key in self.PendingThemeKeys do table.insert(keys, key) end
	for _, key in keys do
		local set = ByKey[key]
		if set then
			for inst, prop in set do snap(inst, prop, Current[key]) end
		end
		self.PendingThemeKeys[key] = nil
	end
	for inst in Dynamic do refresh(inst, false) end
end

function Window:SetCasing(name, silent)
	Casing = name
	applyTextSettings()
	if not silent then self:Notify(('Set casing to "%s".'):format(name)) end
end

function Window:SetFont(name)
	FontFamily = Fonts[name] or name
	applyTextSettings()
end

function Window:SetTextWeight(name)
	BodyWeight = Enum.FontWeight[name]
	applyTextSettings()
end

function Window:CloseFloating()
	if self.OpenDropdown then self.OpenDropdown:Toggle(false) end
	self:ClosePopup()
end

function Window:ClosePopup()
	local popup = self.ActivePopup
	if not popup then return end
	self.ActivePopup = nil
	self.LastPopupAnchor, self.LastPopupTime = popup.Anchor, os.clock()
	if popup.OnClose then popup.OnClose() end
	local position = popup.Frame.Position
	animate(popup.Frame, "Position", Offset(position.X.Offset, position.Y.Offset - 4), "Fast")
	popup.Fader:Hide()
end

function Window:_openPopup(popup, anchor, absolute)
	if self.LastPopupAnchor == anchor and os.clock() - self.LastPopupTime < 0.2 then return false end
	self:ClosePopup()
	local point = toLayer(absolute)
	local viewport, size = self.Screen.AbsoluteSize, popup.Frame.Size
	local x = math.clamp(floor(point.X), 8, math.max(8, viewport.X - size.X.Offset - 8))
	local y = math.clamp(floor(point.Y), 8, math.max(8, viewport.Y - size.Y.Offset - 8))
	popup.Anchor = anchor
	popup.Frame.Position = Offset(x, y - 6)
	animate(popup.Frame, "Position", Offset(x, y), "Settle")
	popup.Fader:Show()
	self.ActivePopup = popup
	return true
end

function Window:OpenKeybindMenu(chip, object)
	local menu = self.KeybindMenu
	menu.Target = object
	menu.Paint(false)
	local p, s = chip.AbsolutePosition, chip.AbsoluteSize
	self:_openPopup(menu, chip, Vec2(p.X, p.Y + s.Y + Metrics.Gap))
end

function Window:OpenPicker(swatch, color)
	local picker = self.Picker
	if self.LastPopupAnchor == swatch and os.clock() - self.LastPopupTime < 0.2 then return end
	local p, s = swatch.AbsolutePosition, swatch.AbsoluteSize
	picker.Target = color
	picker.Sync()
	self:_openPopup(picker, swatch, Vec2(p.X - 8, p.Y + s.Y + Metrics.Pad))
end

function Window:_clamped(target, x, y)
	local screen, size, anchor = self.Screen.AbsoluteSize, target.AbsoluteSize, target.AnchorPoint
	local keep = math.min(60, size.X)
	local left = math.clamp(x - anchor.X * size.X, keep - size.X, math.max(keep - size.X, screen.X - keep))
	local top = math.clamp(y - anchor.Y * size.Y, 0, math.max(0, screen.Y - 30))
	return Offset(round(left + anchor.X * size.X), round(top + anchor.Y * size.Y))
end

function Window:_modalPosition(offsetY)
	return Offset(floor((self.Width - 420) / 2), floor((self.Height - 340) / 2) + offsetY)
end

local function evenClamp(value, minimum, maximum)
	local clamped = math.clamp(floor(value), minimum, math.max(minimum, maximum))
	return clamped - clamped % 2
end

function Window:_minHeight()
	local needed = math.ceil(self.SidebarY + Metrics.TabH / 2 + Metrics.Gap + Metrics.SearchH + Metrics.Pad)
	return evenClamp(math.max(self.MinSize.Y, needed + needed % 2), 0, math.huge)
end

function Window:_applySize(width, height)
	self.Width, self.Height = width, height
	self.ColumnW = (width - Metrics.ContentX - Metrics.Pad * 3) / 2
	self.Holder.Size = Offset(width, height)
	for _, tab in self.Tabs do
		for index, column in tab.Columns do
			local x = Metrics.Pad + (index - 1) * (self.ColumnW + Metrics.Pad)
			column.Scroll.Position = Offset(x, 0)
			column.Scroll.Size = Dim2(0, self.ColumnW, 1, 0)
			column.FadeTop.Position, column.FadeTop.Size = Offset(x, 0), Offset(self.ColumnW, 14)
			column.FadeBottom.Position, column.FadeBottom.Size = Dim2(0, x, 1, -14), Offset(self.ColumnW, 14)
			column:ClampScroll()
			if column.Scroll.CanvasPosition.Y > column.Target then
				snap(column.Scroll, "CanvasPosition", Vec2(0, column.Target))
			end
		end
	end
	for _, job in self.ResizeJobs do job() end
	if self.Search and not self.Search.Open then self.Search.Modal.Position = self:_modalPosition(0) end
end

function Window:SetSize(width, height)
	width = evenClamp(width, self.MinSize.X, math.huge)
	height = evenClamp(height, self:_minHeight(), math.huge)
	local position = self.Holder.Position
	snap(self.Holder, "Position", Offset(position.X.Offset + (width - self.Width) / 2, position.Y.Offset + (height - self.Height) / 2))
	self.Moved[self.Holder] = true
	self:_applySize(width, height)
end

function Window:_beginResize(axisX, axisY, onEnd)
	if self.Search.Open then return end
	self:CloseFloating()
	local start, startW, startH = mousePos(), self.Width, self.Height
	local minHeight = self:_minHeight()
	local position = self.Holder.Position
	local left, top = position.X.Offset - startW / 2, position.Y.Offset - startH / 2
	beginDrag(function(point)
		local delta, screen = point - start, self.Screen.AbsoluteSize
		local width = axisX == 1 and evenClamp(startW + delta.X, self.MinSize.X, screen.X - left - 4) or startW
		local height = axisY == 1 and evenClamp(startH + delta.Y, minHeight, screen.Y - top - 4) or startH
		if width == self.Width and height == self.Height then return end
		self.Moved[self.Holder] = true
		snap(self.Holder, "Position", Offset(left + width / 2, top + height / 2))
		self:_applySize(width, height)
	end, onEnd)
end

function Window:_buildResize()
	local hovering, resizing = 0, false
	local color = function() return (hovering > 0 or resizing) and Current.InactiveText or Current.Outline end
	local grip = makeIcon(self.Root, "grip", 12, color, "Tab", { AnchorPoint = Vec2(1, 1), Position = Dim2(1, -2, 1, -2), ZIndex = 15 })
	local function handle(name, position, size, anchor, axisX, axisY)
		local button = new("TextButton", { Name = name, AnchorPoint = anchor, Position = position, Size = size, ZIndex = 16 }, self.Root)
		hoverable(button, function() hovering += 1; grip.Update() end, function() hovering -= 1; grip.Update() end)
		button.MouseButton1Down:Connect(function()
			resizing = true
			grip.Update()
			self:_beginResize(axisX, axisY, function()
				resizing = false
				grip.Update()
			end)
		end)
		table.insert(self.ResizeHandles, button)
	end
	handle("ResizeRight", Dim2(1, 3, 0, 12), Dim2(0, 6, 1, -30), Vec2(1, 0), 1, 0)
	handle("ResizeBottom", Dim2(0, 12, 1, 3), Dim2(1, -30, 0, 6), Vec2(0, 1), 0, 1)
	handle("ResizeCorner", Dim2(1, 3, 1, 3), Offset(18, 18), Vec2(1, 1), 1, 1)
end

function Window:_makeDraggable(handle, target, allowed)
	handle.InputBegan:Connect(function(input)
		if not isClick(input) then return end
		local start, origin = mousePos(), target.Position
		if allowed and not allowed(start) then return end
		beginDrag(function(point)
			local delta = point - start
			if delta.Magnitude < 1 and not self.Moved[target] then return end
			self.Moved[target] = true
			animate(target, "Position", self:_clamped(target, origin.X.Offset + delta.X, origin.Y.Offset + delta.Y), "Follow")
		end)
	end)
end

function Window:_overControl(point)
	if self.Search.Open then return true end
	if self.OpenDropdown and inside(self.OpenDropdown.Panel, point) then return true end
	if self.ActivePopup and inside(self.ActivePopup.Frame, point) then return true end
	if inside(self.SearchButton, point) then return true end
	for _, handle in self.ResizeHandles do
		if inside(handle, point) then return true end
	end
	for _, tab in self.Tabs do
		if inside(tab.Button, point) then return true end
	end
	if self.CurrentTab then
		for _, column in self.CurrentTab.Columns do
			if inside(column.Scroll, point) then
				for _, section in column.Sections do
					if inside(section.Root, point) then return true end
				end
			end
		end
	end
	return false
end

function Window:_popupFrame(width, height)
	local wrapper = new("Frame", { Size = Offset(width, height), Visible = false, Active = true }, self.Popups)
	local body = new("TextButton", { Bg = "Background", Size = Dim2(1, 0, 1, 0), Radius = Metrics.PopupRadius, Border = "Outline" }, wrapper)
	addShadow(body, "Large")
	local controls = {}
	self:_makeDraggable(body, wrapper, function(point)
		for _, control in controls do
			if inside(control, point, 6) then return false end
		end
		return true
	end)
	return wrapper, body, controls
end

function Window:_buildKeybindMenu()
	local pad, gap, rowH = Metrics.Pad, Metrics.Gap, Metrics.InputH
	local width = 202
	local inner = width - pad * 2
	local half = (inner - gap) / 2
	local frame, body, controls = self:_popupFrame(width, pad * 2 + rowH * 2 + gap)
	local menu = { Frame = frame, Fader = newFader(frame), Target = nil }
	local pill = new("Frame", { Bg = "Accent", Size = Offset(half - 2, rowH - 2), Position = Offset(pad + half + gap + 1, pad + 1), Radius = Metrics.Radius, Border = "Outline" }, body)
	addGradient(pill)
	local onToggle = new("TextButton", { Position = Offset(pad, pad), Size = Offset(half, rowH), ZIndex = 2 }, body)
	centeredLabel(onToggle, half, { Text = "On Toggle", RowH = rowH })
	local onHold = new("TextButton", { Position = Offset(pad + half + gap, pad), Size = Offset(half, rowH), ZIndex = 2 }, body)
	centeredLabel(onHold, half, { Text = "On Hold", RowH = rowH })
	local reset = new("TextButton", { Position = Offset(pad + 1, pad + rowH + gap + 1), Size = Offset(inner - 2, rowH - 2), Radius = Metrics.Radius, Border = "Outline", BackgroundTransparency = 0 }, body)
	interactive(reset, "Element")
	addGradient(reset)
	table.insert(controls, onToggle)
	table.insert(controls, onHold)
	table.insert(controls, reset)
	local center = floor(inner / 2)
	makeIcon(reset, "reset", 14, "Text", "Element", { Position = Offset(center - 32, 5) })
	label(reset, { Text = "Reset", X = center - 12, RowH = rowH - 2, W = 50 })

	function menu.Paint(animated)
		local target = menu.Target
		if not target then return end
		local x = target.Mode == "Hold" and pad + half + gap or pad
		place(pill, "Position", Offset(x + 1, pad + 1), animated, "Knob")
	end
	onToggle.MouseButton1Click:Connect(function()
		if menu.Target then menu.Target.Mode = "Toggle"; menu.Paint(true) end
	end)
	onHold.MouseButton1Click:Connect(function()
		if menu.Target then menu.Target.Mode = "Hold"; menu.Paint(true) end
	end)
	reset.MouseButton1Click:Connect(function()
		if menu.Target then menu.Target:Set(nil) end
		self:ClosePopup()
	end)
	self.KeybindMenu = menu
end

function Window:_buildPicker()
	local pad, gap = Metrics.Pad, Metrics.Gap
	local width = 216
	local svW, svH, barW = width - pad * 3 - 12, 168, 12
	local alphaY = pad + svH + pad
	local labelY = alphaY + barW + pad
	local inputY = labelY + Metrics.Row + gap
	local frame, body, controls = self:_popupFrame(width, inputY + Metrics.InputH + pad)
	local picker = { Frame = frame, Fader = newFader(frame), Target = nil, H = 0, S = 0, V = 1, Alpha = 0, Dragging = false }

	local sv = new("Frame", { BackgroundTransparency = 0, Position = Offset(pad + 1, pad + 1), Size = Offset(svW - 2, svH - 2), Radius = Metrics.Radius, Border = "Outline" }, body)
	local white = new("Frame", { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), Size = Dim2(1, 0, 1, 0), Radius = Metrics.Radius }, sv)
	new("UIGradient", { Transparency = NumberSequence.new(0, 1) }, white)
	local black = new("Frame", { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(0, 0, 0), Size = Dim2(1, 0, 1, 0), Radius = Metrics.Radius }, sv)
	new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0) }, black)

	local function ringKnob(parent)
		local size = Metrics.PickerKnob
		local knob = new("Frame", { Name = "Knob", BackgroundTransparency = 0, AnchorPoint = Vec2(0.5, 0.5), Size = Offset(size, size), Radius = FULL, ZIndex = 3 }, parent)
		local ring = new("UIStroke", { Thickness = 2 }, knob)
		bind(ring, "Color", "Text")
		addShadow(knob, "PickerKnob")
		return knob
	end
	local svKnob = ringKnob(sv)
	picker.SVKnob = svKnob
	local INSET = (Metrics.PickerKnob + 4) / 2 - 1
	local function along(scale) return round(INSET - INSET * 2 * scale) end
	local function fromPointer(position, origin, length)
		return clamp01((position - origin - INSET) / (length - INSET * 2))
	end

	local hue = new("Frame", { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), Position = Offset(pad * 2 + svW + 1, pad + 1), Size = Offset(barW - 2, svH - 2), Radius = Metrics.Radius, Border = "Outline" }, body)
	local keys = {}
	for index = 0, 6 do
		table.insert(keys, ColorSequenceKeypoint.new(index / 6, Color3.fromHSV((index / 6) % 1, 1, 1)))
	end
	new("UIGradient", { Rotation = 90, Color = ColorSequence.new(keys) }, hue)
	local hueKnob = ringKnob(hue)

	local alphaBar = new("Frame", { Bg = "Background", Position = Offset(pad + 1, alphaY + 1), Size = Offset(width - pad * 2 - 2, barW - 2), Radius = Metrics.Radius, Border = "Outline" }, body)
	local alphaClip = new("CanvasGroup", { Name = "AlphaClip", BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), Size = Dim2(1, 0, 1, 0), Radius = Metrics.Radius }, alphaBar)
	for column = 0, 48 do
		for row = 0, 2 do
			if (column + row) % 2 == 1 then
				new("Frame", { BackgroundTransparency = 0, BackgroundColor3 = RGB(190, 190, 190), Position = Offset(column * 4, row * 4), Size = Offset(4, 4) }, alphaClip)
			end
		end
	end
	local alphaFill = new("Frame", { BackgroundTransparency = 0, Size = Dim2(1, 0, 1, 0) }, alphaClip)
	new("UIGradient", { Transparency = NumberSequence.new(0, 1) }, alphaFill)
	local alphaKnob = ringKnob(alphaBar)

	label(body, { Text = "Animations", X = pad, Y = labelY })
	local holder = new("Frame", { Position = Offset(pad, inputY), Size = Offset(width - pad * 2, Metrics.InputH) }, body)
	for _, control in { sv, hue, alphaBar, holder } do table.insert(controls, control) end

	local function paint()
		local color = Color3.fromHSV(picker.H, picker.S, picker.V)
		local pure = Color3.fromHSV(picker.H, 1, 1)
		sv.BackgroundColor3 = pure
		svKnob.BackgroundColor3 = color
		svKnob.Position = Dim2(picker.S, along(picker.S), 1 - picker.V, along(1 - picker.V))
		hueKnob.Position = Dim2(0.5, 0, picker.H, along(picker.H))
		hueKnob.BackgroundColor3 = pure
		alphaFill.BackgroundColor3 = color
		alphaKnob.Position = Dim2(picker.Alpha, along(picker.Alpha), 0.5, 0)
		alphaKnob.BackgroundColor3 = color
	end

	local function commit()
		paint()
		if picker.Target then picker.Target:Set(Color3.fromHSV(picker.H, picker.S, picker.V), picker.Alpha) end
	end

	function picker.Sync()
		local target = picker.Target
		if not target then return end
		local h, s, v = target.Value:ToHSV()
		if s > 0 and v > 0 then picker.H = h end
		picker.S, picker.V, picker.Alpha = s, v, target.Alpha or 0
		paint()
		if picker.Animation then picker.Animation:Set(target.Animation or "None", true) end
	end

	local function dragArea(area, knob, update)
		local hit = new("TextButton", { Position = Offset(-6, -6), Size = Dim2(1, 12, 1, 12), ZIndex = 5 }, area)
		hit.InputBegan:Connect(function(input)
			if not isClick(input) then return end
			picker.Dragging = true
			update(mousePos())
			beginDrag(update, function() picker.Dragging = false end)
		end)
	end
	dragArea(sv, svKnob, function(point)
		picker.S = fromPointer(point.X, sv.AbsolutePosition.X, sv.AbsoluteSize.X)
		picker.V = 1 - fromPointer(point.Y, sv.AbsolutePosition.Y, sv.AbsoluteSize.Y)
		commit()
	end)
	dragArea(hue, hueKnob, function(point)
		picker.H = math.min(fromPointer(point.Y, hue.AbsolutePosition.Y, hue.AbsoluteSize.Y), 0.9999)
		commit()
	end)
	dragArea(alphaBar, alphaKnob, function(point)
		picker.Alpha = fromPointer(point.X, alphaBar.AbsolutePosition.X, alphaBar.AbsoluteSize.X)
		commit()
	end)

	self.Picker = picker
	picker.Animation = buildDropdown(self, holder, {
		Options = { "None", "Rainbow", "Pulse" }, Default = "None", MaxRows = 3,
		Callback = function(value)
			if picker.Target then picker.Target.Animation = value end
		end,
	})
	picker.OnClose = function() picker.Animation:Toggle(false) end
end

function Window:_buildSearch()
	local width, height, pad = 420, 340, Metrics.Pad
	local overlay = new("TextButton", {
		BackgroundTransparency = 0.45, BackgroundColor3 = Color3.new(0, 0, 0), Size = Dim2(1, 0, 1, 0), Visible = false,
		ZIndex = 20, Radius = Metrics.WindowRadius,
	}, self.Root)
	local modal = new("TextButton", {
		Bg = "Background", Position = self:_modalPosition(0), Size = Offset(width, height), Radius = Metrics.WindowRadius, Border = "Outline",
	}, overlay)
	local title = label(modal, { Text = "Search", TextSize = 14, Weight = Enum.FontWeight.SemiBold, X = pad * 2, Y = pad + 2, RowH = 20 })
	local field = new("Frame", { Bg = "Inline", Position = Offset(pad * 2 + 1, 43), Size = Offset(width - pad * 4 - 2, 34), Radius = Metrics.PillRadius, Border = "Outline" }, modal)
	makeIcon(field, "search", 14, "InactiveText", "Inline", { Position = Offset(10, 10) })
	local box = new("TextBox", {
		Fg = "Text", PlaceholderText = "Type to search...", Position = Offset(34, capOffset(34, 13)), Size = Dim2(1, -45, 0, 20), ClearTextOnFocus = false,
	}, field)
	bind(box, "PlaceholderColor3", "InactiveText")
	local results = new("ScrollingFrame", {
		Position = Offset(pad * 2, 88), Size = Offset(width - pad * 4 + 6, height - 88 - pad), CanvasSize = Offset(0, 0),
		ScrollBarThickness = 2, ScrollBarImageTransparency = 0,
	}, modal)
	bind(results, "ScrollBarImageColor3", "Accent")

	local noResults = centeredLabel(modal, width, { Fg = "InactiveText", Text = "No results", Y = 170 })
	noResults.Visible = false
	local search = { Overlay = overlay, Modal = modal, Fader = newFader(overlay), Open = false, Rows = {}, Dirty = false, Box = box, Order = {} }

	local function goTo(entry)
		self:CloseSearch()
		local section = entry.Section or entry
		self:SelectTab(section.Tab)
		section.Column:ScrollTo(section.Y + (entry.Section and section.HeaderH + entry.Y or 0) - 40)
		if entry.Frame then
			local flash = new("Frame", {
				Bg = "Accent", BackgroundTransparency = 0.7, Position = Offset(-6, -3), Size = Dim2(1, 12, 1, 6), Radius = Metrics.Radius, ZIndex = 0,
			}, entry.Frame)
			task.delay(0.2, function()
				animate(flash, "BackgroundTransparency", 1, "Soft", { Done = function() flash:Destroy() end })
			end)
		end
	end

	local function retire(row)
		row.Retired = true
		row.Frame:Destroy()
	end

	local function makeRow(entry, name, sub, y)
		local frame = new("TextButton", {
			Bg = "HoveredElement", BackgroundTransparency = 1, Position = Offset(10, y), Size = Offset(width - pad * 4, 44), Radius = Metrics.Radius,
		}, results)
		NoFade[frame] = true
		local row = { Frame = frame, Y = y, Retired = false }
		row.Bar = new("Frame", { Bg = "Accent", BackgroundTransparency = 1, Position = Offset(4, 8), Size = Offset(3, 28), Radius = Metrics.SmallRadius }, frame)
		row.Name = label(frame, { Text = name, TextSize = 13, X = 14, Y = 5, RowH = 18, TextTransparency = 1, Right = 10, Truncate = Enum.TextTruncate.AtEnd })
		row.Sub = label(frame, { Fg = "InactiveText", Text = sub, TextSize = 11, X = 14, Y = 22, RowH = 16, TextTransparency = 1, Right = 10, Truncate = Enum.TextTruncate.AtEnd })
		hoverable(frame, function() animate(frame, "BackgroundTransparency", 0.4, "Fast") end, function() animate(frame, "BackgroundTransparency", 1, "Fast") end)
		frame.MouseButton1Click:Connect(function() goTo(entry) end)
		return row
	end

	local function sync()
		local text = box.Text
		setText(title, text ~= "" and text or "Search")
		setText(self.SearchLabel, text ~= "" and text or "Search...")
		local wanted, order = {}, {}
		if text ~= "" then
			local needle = string.lower(text)
			local function add(entry, name, sub)
				if #order < 30 and name and string.find(string.lower(name), needle, 1, true) then
					wanted[entry] = true
					table.insert(order, { entry, name, sub })
				end
			end
			for _, section in self.Sections do
				add(section, section.Name, section.Tab.Name .. " / " .. section.Name .. "  \194\183  Section")
			end
			for _, item in self.Index do
				add(item, item.Name, item.Section.Tab.Name .. " / " .. item.Section.Name .. "  \194\183  " .. item.Kind)
			end
		end
		local toRemove = {}
		for entry, row in search.Rows do
			if not wanted[entry] then
				table.insert(toRemove, { entry = entry, row = row })
			end
		end
		for _, item in toRemove do
			search.Rows[item.entry] = nil
			retire(item.row)
		end
		local fresh = 0
		for index, data in order do
			local entry, y = data[1], (index - 1) * 48
			local row = search.Rows[entry]
			if row then
				row.Y = y
				animate(row.Frame, "Position", Offset(0, y), "Smooth")
			else
				row = makeRow(entry, data[2], data[3], y)
				search.Rows[entry] = row
				fresh += 1
				task.delay(math.min(fresh, 8) * 0.025, function()
					if row.Retired then return end
					animate(row.Frame, "Position", Offset(0, row.Y), "Smooth")
					animate(row.Bar, "BackgroundTransparency", 0, "Smooth")
					animate(row.Name, "TextTransparency", 0, "Smooth")
					animate(row.Sub, "TextTransparency", 0, "Smooth")
				end)
			end
		end
		results.CanvasSize = Offset(0, #order * 48)
		search.Order = order
		noResults.Visible = text ~= "" and #order == 0
	end

	box:GetPropertyChangedSignal("Text"):Connect(function() search.Dirty = true end)
	box.FocusLost:Connect(function(enterPressed)
		if UserInputService:IsKeyDown(Enum.KeyCode.Escape) then
			self:CloseSearch()
		elseif enterPressed then
			if search.Dirty then
				search.Dirty = false
				sync()
			end
			if search.Order[1] then goTo(search.Order[1][1]) end
		end
	end)
	overlay.MouseButton1Click:Connect(function() self:CloseSearch() end)
	search.Sync = sync
	self.Search = search
end

function Window:OpenSearch()
	local search = self.Search
	if search.Open then return end
	search.Open = true
	self:CloseFloating()
	search.Modal.Position = self:_modalPosition(10)
	animate(search.Modal, "Position", self:_modalPosition(0), "Smooth")
	search.Fader:Show()
	search.Box:CaptureFocus()
end

function Window:CloseSearch()
	local search = self.Search
	if not search.Open then return end
	search.Open = false
	search.Box:ReleaseFocus()
	animate(search.Modal, "Position", self:_modalPosition(7), "Fast")
	search.Fader:Hide()
end

function Window:SetVisible(visible)
	if self.Visible == visible then return end
	self.Visible = visible
	self:CloseFloating()
	self.ModalButton.Visible = visible
	if not self.Scale.Parent then
		if not visible then self.Scale.Scale = 1 end
		self.Scale.Parent = self.Holder
	end
	if visible then
		animate(self.Scale, "Scale", 1, "Smooth", {
			Done = function()
				if self.Visible then self.Scale.Parent = nil end
			end,
		})
		self.Fader:Show()
	else
		animate(self.Scale, "Scale", 0.97, "Fast")
		self.Fader:Hide()
	end
end

function Window:Toggle()
	self:SetVisible(not self.Visible)
end

local ConfigMemory = {}
local function configPath(name) return "Blossom/" .. name .. ".json" end

function Window:_serialize()
	local data = {}
	for flag, object in self.Flags do
		local value = object.Value
		if object.Swatch then
			value = { Color = object.Value:ToHex(), Alpha = object.Alpha }
		elseif object.Chip then
			value = { Key = object.Key and (typeof(object.Key) == "EnumItem" and object.Key.Name or tostring(object.Key)) or false, Mode = object.Mode }
		elseif object.Multi then
			local list = {}
			for option, enabled in object.Value do
				if enabled then table.insert(list, option) end
			end
			value = list
		end
		if value ~= nil then data[flag] = value end
	end
	return HttpService:JSONEncode(data)
end

function Window:_deserialize(json)
	local ok, data = pcall(function() return HttpService:JSONDecode(json) end)
	if not ok or type(data) ~= "table" then return false end
	for flag, value in data do
		local object = self.Flags[flag]
		if object then
			if object.Swatch then
				if type(value) == "table" and value.Color then
					pcall(function() object:Set(Color3.fromHex(value.Color), value.Alpha) end)
				end
			elseif object.Chip then
				if type(value) == "table" then
					object.Mode = value.Mode or object.Mode
					local key = nil
					if value.Key then
						local k = string.find(value.Key, "MouseButton", 1, true) and Enum.UserInputType[value.Key] or Enum.KeyCode[value.Key]
						key = k
					end
					object:Set(key)
				end
			else
				object:Set(value)
			end
		end
	end
	return true
end

function Window:ListConfigs()
	local names = {}
	local listed = false
	if typeof(listfiles) == "function" and typeof(isfolder) == "function" then
		local ok, hasFolder = pcall(isfolder, "Blossom")
		if ok and hasFolder then
			local okFiles, files = pcall(listfiles, "Blossom")
			if okFiles and type(files) == "table" then
				listed = true
				for _, path in files do
					local name = string.match(path, "([^/\\]+)%.json$")
					if name then table.insert(names, name) end
				end
			end
		end
	end
	if not listed then
		for name in ConfigMemory do table.insert(names, name) end
	end
	table.sort(names)
	return names
end

function Window:SaveConfig(name)
	local json = self:_serialize()
	if typeof(writefile) == "function" then
		if typeof(isfolder) == "function" and typeof(makefolder) == "function" then
			local ok, exists = pcall(isfolder, "Blossom")
			if ok and not exists then pcall(makefolder, "Blossom") end
		end
		if pcall(writefile, configPath(name), json) then return end
	end
	ConfigMemory[name] = json
end

function Window:LoadConfig(name)
	local json
	if typeof(readfile) == "function" and typeof(isfile) == "function" then
		local ok, exists = pcall(isfile, configPath(name))
		if ok and exists then
			local okRead, content = pcall(readfile, configPath(name))
			if okRead then json = content end
		end
	end
	if not json then json = ConfigMemory[name] end
	if json then return self:_deserialize(json) end
	return false
end

function Window:DeleteConfig(name)
	if typeof(delfile) == "function" and typeof(isfile) == "function" then
		local ok, exists = pcall(isfile, configPath(name))
		if ok and exists then pcall(delfile, configPath(name)) end
	end
	ConfigMemory[name] = nil
end

local AUTOLOAD_PATH = "Blossom/autoload.txt"
local AutoloadMemory

local function readAutoload()
	if typeof(readfile) == "function" and typeof(isfile) == "function" then
		local ok, exists = pcall(isfile, AUTOLOAD_PATH)
		if ok and exists then
			local okRead, content = pcall(readfile, AUTOLOAD_PATH)
			if okRead then return content end
		end
		return nil
	end
	return AutoloadMemory
end

local function writeAutoload(name)
	if typeof(writefile) ~= "function" then
		AutoloadMemory = name
	elseif name then
		if typeof(isfolder) == "function" and typeof(makefolder) == "function" then
			local ok, exists = pcall(isfolder, "Blossom")
			if ok and not exists then pcall(makefolder, "Blossom") end
		end
		if not pcall(writefile, AUTOLOAD_PATH, name) then
			AutoloadMemory = name
		end
	elseif typeof(delfile) == "function" and typeof(isfile) == "function" then
		local ok, exists = pcall(isfile, AUTOLOAD_PATH)
		if ok and exists then pcall(delfile, AUTOLOAD_PATH) end
	end
end

function Window:BuildSettings(tab)
	local selected
	local saved = readAutoload()
	local autoloadOn, autoloadName = saved ~= nil, saved
	local autoloadList
	local profiles = tab:Section({ Name = "Profiles", Icon = "cube", Side = 1 })
	profiles:Label({ Name = "Configs" })
	local listbox = profiles:Listbox({ Height = 177, Empty = "No configs yet", Options = self:ListConfigs(), Callback = function(value) selected = value end })
	local nameBox = profiles:Textbox({ Placeholder = "Config name", NoSave = true })
	local function refreshList()
		local names = self:ListConfigs()
		listbox:SetOptions(names)
		autoloadList:SetOptions(names)
	end
	profiles:Button({ Name = "Create", Callback = function()
		local name = nameBox.Instance.Text
		if name == "" then self:Notify({ Text = "Enter a config name first." }); return end
		self:SaveConfig(name)
		refreshList()
		self:Notify(('Created "%s".'):format(name))
	end })
	profiles:Button({ Name = "Load", Callback = function()
		if selected and self:LoadConfig(selected) then self:Notify(('Loaded "%s".'):format(selected)) end
	end })
	profiles:Button({ Name = "Delete", Callback = function()
		if selected then
			self:DeleteConfig(selected)
			self:Notify(('Deleted "%s".'):format(selected))
			selected = nil
			refreshList()
		end
	end })
	profiles:Button({ Name = "Overwrite", Callback = function()
		if selected then
			self:SaveConfig(selected)
			self:Notify(('Overwrote "%s".'):format(selected))
		end
	end })

	local function storeAutoload() writeAutoload(autoloadOn and autoloadName or nil) end
	local autoload = tab:Section({ Name = "Autoload", Icon = "cube", Side = 1 })
	autoload:Toggle({ Name = "Load on start", Default = autoloadOn, NoSave = true, Callback = function(value)
		autoloadOn = value
		storeAutoload()
	end })
	autoloadList = autoload:Dropdown({ Name = "Config", Options = self:ListConfigs(), Default = saved, Empty = "No configs yet", NoSave = true, Callback = function(value)
		autoloadName = value
		storeAutoload()
	end })

	local theming = tab:Section({ Name = "Theming", Icon = "cube", Side = 2 })
	theming:Dropdown({ Name = "Theme", Options = ThemeOrder, Default = self.ThemeName, MaxRows = 11, NoSave = true, Callback = function(value) self:ApplyTheme(value) end })
	theming:Dropdown({ Name = "Casing", Options = Casings, Default = "Normal", NoSave = true, Callback = function(value) self:SetCasing(value) end })
	theming:Divider()
	for _, pair in ThemeKeys do
		local key = pair[2]
		local color = theming:Colorpicker({ Name = pair[1], Default = Current[key], NoSave = true, Callback = function(value) self:SetThemeColor(key, value) end })
		table.insert(self.ThemeRows, { Key = key, Color = color })
	end

	local menu = tab:Section({ Name = "Menu", Icon = "cube", Side = 2 })
	local menuBind = menu:Keybind({ Name = "Menu Key", Default = self.MenuKey, NoSave = true })
	menuBind.OnKeyChanged = function() self.MenuKey = menuBind.Key end
	menu:Toggle({ Name = "Watermark", Default = true, NoSave = true, Callback = function(value) self.Watermark.Visible = value end })
	menu:Toggle({ Name = "Hotkey List", Default = true, NoSave = true, Callback = function(value) self.Hotkeys.Visible = value end })
	menu:Dropdown({ Name = "Font", Options = FontOrder, Default = "Inter", NoSave = true, Callback = function(value) self:SetFont(value) end })
	menu:Dropdown({ Name = "Text Weight", Options = WeightOrder, Default = BodyWeight.Name, NoSave = true, Callback = function(value) self:SetTextWeight(value) end })

	if saved then
		task.defer(function()
			if self:LoadConfig(saved) then self:Notify(('Autoloaded "%s".'):format(saved)) end
		end)
	end
end

function Window:_buildWatermark(options)
	local player = Players.LocalPlayer or { DisplayName = "User", Name = "User" }
	local frame = new("Frame", { Bg = "Background", Size = Offset(298, 28), Radius = Metrics.FloatRadius, Border = "Outline", Active = true }, self.Screen)
	makeIcon(frame, "logo", 16, "Accent", "Background", { Position = Offset(8, 6) })
	local function text(value, size, weight)
		return label(frame, { Text = value, TextSize = size, Weight = weight, RowH = 28, W = 10 })
	end
	local function sep()
		return new("Frame", { Bg = "Outline", Position = Offset(0, 7), Size = Offset(1, 14) }, frame)
	end
	local first, firstSep = text(options.Script or "blossom.lua", 12, Enum.FontWeight.Medium), sep()
	local second, secondSep = text(options.Build or "release", 12, Enum.FontWeight.SemiBold), sep()
	local userIcon = makeIcon(frame, "user", 13, "Text", "Background")
	local third = text(("%s (@%s)"):format(player.DisplayName or "User", player.Name or "User"), 11, Enum.FontWeight.SemiBold)
	local function layout()
		local x = 31
		for _, entry in { { first, firstSep }, { second, secondSep } } do
			local width = math.ceil(entry[1].TextBounds.X)
			entry[1].Size = Offset(width + 1, 28)
			entry[1].Position = Offset(x, entry[1].Position.Y.Offset)
			x += width + 8
			entry[2].Position = Offset(x, 7)
			x += 9
		end
		userIcon.Root.Position = Offset(x, 7)
		x += 20
		local width = math.ceil(third.TextBounds.X)
		third.Size = Offset(width + 1, 28)
		third.Position = Offset(x, third.Position.Y.Offset)
		frame.Size = Offset(x + width + Metrics.Pad, 28)
		self:_placeOverlays()
	end
	for _, entry in { first, second, third } do
		entry:GetPropertyChangedSignal("TextBounds"):Connect(layout)
	end
	self.Watermark = frame
	self.WatermarkLayout = layout
	self:_makeDraggable(frame, frame)
end

function Window:_buildHotkeys()
	local holder = new("Frame", { Size = Offset(200, 300) }, self.Screen)
	local head = new("Frame", { Bg = "Background", Position = Offset(1, 1), Size = Offset(88, 25), Radius = Metrics.FloatRadius, Border = "Outline", Active = true }, holder)
	makeIcon(head, "key", 14, "Accent", "Background", { Position = Offset(9, 5) })
	local text = label(head, { Text = "Hotkeys", TextSize = 12, Weight = Enum.FontWeight.SemiBold, X = 31, RowH = 25 })
	local function fit() head.Size = Offset(math.ceil(text.TextBounds.X) + 41, 25) end
	text:GetPropertyChangedSignal("TextBounds"):Connect(fit)
	fit()
	self.Hotkeys = holder
	self:_makeDraggable(head, holder)
end

function Window:_placeOverlays()
	local size = self.Screen.AbsoluteSize
	if size.X <= 0 then return end
	if not self.Moved[self.Holder] then self.Holder.Position = Offset(floor(size.X / 2), floor(size.Y / 2)) end
	if self.Watermark and not self.Moved[self.Watermark] then
		self.Watermark.Position = Offset(floor((size.X - self.Watermark.Size.X.Offset) / 2), size.Y - 44)
	end
	if self.Hotkeys and not self.Moved[self.Hotkeys] then self.Hotkeys.Position = Offset(14, floor((size.Y - 300) / 2)) end
end

function Window:Destroy()
	if self.Connections then
		for _, connection in self.Connections do connection:Disconnect() end
	end
	table.clear(Jobs)
	table.clear(HoverSet)
	for _, entry in Active do entry.Dead = true end
	table.clear(Active)
	table.clear(Tracks)
	if FrameConnection then
		FrameConnection:Disconnect()
		FrameConnection = nil
	end
	if Focus == self then Focus = nil end
	if ScreenRef == self.Screen then ScreenRef = nil end
	if self.Screen then self.Screen:Destroy() end
end

local LastWindow

function Blossom.new(options)
	options = options or {}
	local globalEnv = typeof(getgenv) == "function" and getgenv() or nil
	local previous = LastWindow or (globalEnv and globalEnv.__BlossomWindow)
	if previous then pcall(previous.Destroy, previous) end
	if options.Theme and Themes[options.Theme] then
		for key, value in Themes[options.Theme] do Current[key] = value end
	end
	if options.Font then FontFamily = Fonts[options.Font] or options.Font end
	local minSize = options.MinSize or Vec2(Metrics.MinWindowW, Metrics.MinWindowH)
	minSize = Vec2(minSize.X - minSize.X % 2, minSize.Y - minSize.Y % 2)
	local startSize = options.Size or Vec2(Metrics.WindowW, Metrics.WindowH)
	local startW, startH = evenClamp(startSize.X, minSize.X, math.huge), evenClamp(startSize.Y, minSize.Y, math.huge)
	local win = setmetatable({
		Width = startW, Height = startH, MinSize = minSize, ColumnW = (startW - Metrics.ContentX - Metrics.Pad * 3) / 2,
		ResizeJobs = {}, ResizeHandles = {},
		Title = options.Title or "Blossom", Tabs = {}, Sections = {}, Columns = {}, Index = {}, Binds = {}, Colors = {}, Flags = {},
		ThemeRows = {}, HotkeyEntries = {}, HotkeyOrder = {}, NotifyStack = {}, Connections = {}, Jobs = {}, Moved = {}, PendingThemeKeys = {}, FlagOwners = {},
		ThemeClock = 0, SidebarY = Metrics.FirstCategory, SidebarHasTabs = false, SidebarAfterCategory = false,
		Visible = true, ThemeName = options.Theme or "Blossom", MenuKey = options.MenuKey or Enum.KeyCode.RightShift,
		LastPopupTime = 0, DropdownClosedAt = 0,
	}, Window)
	ensureLoop()
	LastWindow, Focus = win, win
	if globalEnv then globalEnv.__BlossomWindow = win end

	local screen = new("ScreenGui", { Name = "Blossom", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 100 })
	guiParent(screen)
	win.Screen = screen
	ScreenRef = screen

	local holder = new("Frame", {
		Name = "Window", AnchorPoint = Vec2(0.5, 0.5), Size = Offset(win.Width, win.Height), ZIndex = 10,
	}, screen)
	win.Holder = holder
	win.Scale = new("UIScale", { Scale = 0.97 })
	local root = new("Frame", { Bg = "Background", Active = true, Size = Dim2(1, 0, 1, 0), Radius = Metrics.WindowRadius, Border = "Outline" }, holder)
	addShadow(root, "Large")
	win.Root = root
	win.Fader = newFader(holder)
	win.ModalButton = new("TextButton", { Modal = true, Size = Offset(1, 1) }, holder)

	local sidebar = new("Frame", { Size = Dim2(0, Metrics.SidebarW, 1, 0) }, root)
	win.Sidebar = sidebar
	makeIcon(sidebar, "logo", 20, "Accent", "Background", { Position = Offset(Metrics.Pad * 2, 15) })
	label(sidebar, { Text = win.Title, TextSize = 16, Weight = Enum.FontWeight.Bold, X = 51, Y = 11, RowH = 28, W = 85 })
	win.Indicator = new("Frame", { Bg = "Inline", Size = Offset(Metrics.TabW - 2, Metrics.TabH - 2), Radius = Metrics.PillRadius, Border = "Outline", Visible = false }, sidebar)
	local searchButton = new("TextButton", {
		Position = Dim2(0, Metrics.Pad + 1, 1, -(Metrics.Pad + Metrics.SearchH) + 1), Size = Offset(Metrics.TabW - 2, Metrics.SearchH - 2), Radius = Metrics.PillRadius, Border = "Outline", BackgroundTransparency = 0,
	}, sidebar)
	interactive(searchButton, "Inline")
	win.SearchButton = searchButton
	makeIcon(searchButton, "search", 14, "InactiveText", "Inline", { Position = Offset(6, 6) })
	win.SearchLabel = label(searchButton, { Fg = "InactiveText", Text = "Search...", X = 30, RowH = Metrics.SearchH - 2, Right = 6 })
	searchButton.MouseButton1Click:Connect(function() win:OpenSearch() end)

	new("Frame", { Bg = "Outline", Position = Offset(Metrics.SidebarW, 0), Size = Dim2(0, 1, 1, 0) }, root)
	local content = new("Frame", { Bg = "Tab", Position = Offset(Metrics.ContentX, 0), Size = Dim2(1, -Metrics.ContentX, 1, 0), Radius = Metrics.WindowRadius }, root)
	new("Frame", { Name = "CornerPatch", Bg = "Tab", Size = Dim2(0, 12, 1, 0) }, content)
	win.Pages = new("Frame", {
		Name = "Pages", Position = Offset(0, Metrics.Pad), Size = Dim2(1, 0, 1, -Metrics.Pad * 2), ClipsDescendants = true,
	}, content)
	win.Veil = new("Frame", { Bg = "Tab", BackgroundTransparency = 1, Size = Dim2(1, 0, 1, 0), ZIndex = 5 }, win.Pages)

	win.DragLayer = new("Frame", { Name = "Drag", Size = Dim2(1, 0, 1, 0), ZIndex = 30 }, screen)
	win.Popups = new("Frame", { Name = "Popups", Size = Dim2(1, 0, 1, 0), ZIndex = 40 }, screen)
	win.Dropdowns = new("Frame", { Name = "Dropdowns", Size = Dim2(1, 0, 1, 0), ZIndex = 45 }, screen)
	win.Notifications = new("Frame", { Name = "Notifications", Position = Offset(16, 16), Size = Offset(400, 600), ZIndex = 50 }, screen)

	win:_buildWatermark(options)
	win:_buildHotkeys()
	win:_buildKeybindMenu()
	win:_buildPicker()
	win:_buildSearch()
	if options.Resizable ~= false then win:_buildResize() end
	win:_placeOverlays()
	win.WatermarkLayout()
	table.insert(win.Connections, screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() win:_placeOverlays() end))

	win:_makeDraggable(root, holder, function(point) return not win:_overControl(point) end)

	table.insert(win.Connections, UserInputService.InputBegan:Connect(function(input, processed)
		if isClick(input) then
			local point = mousePos()
			local dropdown = win.OpenDropdown
			local overDropdown = dropdown and inside(dropdown.Panel, point)
			if dropdown and not overDropdown then
				if inside(dropdown.Input, point) then
					win.DropdownClosedBy, win.DropdownClosedAt = dropdown.Input, os.clock()
				end
				dropdown:Toggle(false)
			end
			if win.ActivePopup and not overDropdown and not inside(win.ActivePopup.Frame, point, 6) then
				win:ClosePopup()
			end
		end
		local listening = win.Listening
		if listening then
			local isKey = input.UserInputType == Enum.UserInputType.Keyboard
			local isMouse = input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3
			if isKey or isMouse then
				win.Listening = nil
				listening.Listening = false
				if isKey and input.KeyCode == Enum.KeyCode.Escape then
					listening.Key = nil
				else
					listening.Key = isKey and input.KeyCode or input.UserInputType
				end
				listening.Refresh()
			elseif isClick(input) then
				win.Listening = nil
				listening.Listening = false
				listening.Refresh()
			end
			return
		end
		if processed then return end
		if input.KeyCode == win.MenuKey or input.UserInputType == win.MenuKey then win:Toggle() end
		for _, object in win.Binds do
			if object.Key and (object.Key == input.KeyCode or object.Key == input.UserInputType) and object.OnPress then
				object.OnPress()
			end
		end
	end))

	table.insert(win.Connections, UserInputService.InputEnded:Connect(function(input)
		for _, object in win.Binds do
			if object.Key and (object.Key == input.KeyCode or object.Key == input.UserInputType) and object.OnRelease then
				object.OnRelease()
			end
		end
	end))

	table.insert(win.Connections, UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseWheel or not win.Visible or win.Search.Open or not win.CurrentTab then return end
		local point = mousePos()
		local dropdown = win.OpenDropdown
		if dropdown then
			if inside(dropdown.Panel, point) then return end
			dropdown:Toggle(false)
		end
		for _, column in win.CurrentTab.Columns do
			if inside(column.Scroll, point) then
				column:ScrollTo(column.Target - input.Position.Z * 60)
			end
		end
	end))

	local clock, colorClock = 0, 0
	local function perFrame(dt)
		clock += dt
		colorClock += dt
		win:_flushThemeColors(dt)
		if win.OpenDropdown then win.OpenDropdown.Follow() end
		if win.CurrentTab then
			for _, column in win.CurrentTab.Columns do
				local y = column.Scroll.CanvasPosition.Y
				local showTop, showBottom = y > 1, y < column.ContentH - column.Scroll.AbsoluteSize.Y - 1
				if showTop ~= column.ShowTop then
					column.ShowTop = showTop
					animate(column.FadeTop, "BackgroundTransparency", showTop and 0 or 1, "Fast")
				end
				if showBottom ~= column.ShowBottom then
					column.ShowBottom = showBottom
					animate(column.FadeBottom, "BackgroundTransparency", showBottom and 0 or 1, "Fast")
				end
			end
		end
		if win.Search.Dirty then
			win.Search.Dirty = false
			win.Search.Sync()
		end
		if colorClock >= 1 / 30 then
			colorClock = 0
			for _, color in win.Colors do
				if color.Animation == "Rainbow" then
					local _, s, v = color.Value:ToHSV()
					color:Set(Color3.fromHSV((clock * 0.25) % 1, math.max(s, 0.5), math.max(v, 0.6)))
				elseif color.Animation == "Pulse" then
					local h, s = color.Value:ToHSV()
					color:Set(Color3.fromHSV(h, s, 0.65 + math.sin(clock * 4) * 0.35))
				end
			end
		end
	end
	Jobs[perFrame] = true
	table.insert(win.Jobs, perFrame)

	holder.Visible, win.Visible = false, false
	win.Watermark.Visible, win.Hotkeys.Visible = false, false
	task.defer(function()
		if win.Screen.Parent == nil then return end
		win:_placeOverlays()
		win:SetVisible(true)
		newFader(win.Watermark):Show()
		newFader(win.Hotkeys):Show()
	end)

	return win
end

return Blossom
