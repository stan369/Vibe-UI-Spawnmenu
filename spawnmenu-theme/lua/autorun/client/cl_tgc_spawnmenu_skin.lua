--[[--------------------------------------------------------------------------
	TheGmod.Club spawnmenu skin
	A custom derma skin (palette from the website style.css) applied to the
	Q spawnmenu.

	IMPORTANT lesson from earlier crashes ("attempt to index field 'Tab'/'Button'
	a nil value"): panels read colours straight out of skin.Colours.<X>, so the
	skin MUST carry a complete Colours table. Relying on SKIN.Base inheritance was
	leaving it incomplete. So we deep-copy Default's whole Colours table (after
	load, once Default is fully built) and only overlay the few text colours we
	want -- guaranteeing no field is ever missing.

	Can't be tested outside GMod; treat as a first pass to tune from screenshots.
	Set ENABLED to false (or delete the addon) to revert.
----------------------------------------------------------------------------]]

local ENABLED = true
if not ENABLED then return end

--------------------------------------------------------------------- palette
-- Warm charcoal, not near-black -- keeps the brand warmth but is easy on the eyes
-- for a full-screen menu. (Earlier near-black #0b0906 read as "crazy dark".)
local C = {
	bg       = Color(30, 26, 21),       -- window / content base
	panel    = Color(38, 32, 25),       -- surface
	panel2   = Color(48, 40, 31),       -- surface-hover
	header   = Color(24, 20, 16),        -- tabs / section headers (a touch darker)
	border   = Color(64, 52, 39),
	borderL  = Color(84, 68, 50),
	text     = Color(255, 255, 255),    -- white (primary text)
	muted    = Color(230, 226, 221),    -- near-white so secondary labels stay readable
	dim      = Color(188, 179, 168),    -- brighter dim so nothing looks gray/hard to read
	accent   = Color(255, 122, 26),     -- #ff7a1a
	accentL  = Color(255, 157, 77),     -- #ff9d4d
	purple   = Color(122, 58, 168),     -- #7a3aa8
	shadow   = Color(0, 0, 0, 150),
	-- website-style dark gradient for the window background (kept dark so white
	-- text stays readable): warm orange-tinted -> purple-tinted.
	gradA    = Color(62, 37, 21),       -- orange-tinted dark (left)
	gradB    = Color(42, 26, 56),       -- purple-tinted dark (right)
	-- content fills: mostly transparent so the window gradient shows through.
	-- Safe for readability because the frame BEHIND them is opaque (not blur).
	frost    = Color(16, 13, 10, 55),   -- big content areas (grid, tree, forms)
	frostList= Color(16, 13, 10, 100),  -- tool list (a touch more for row contrast)
}

-- horizontal orange -> purple gradient (site signature)
local function hGrad(x, y, w, h, c1, c2)
	local steps = 28
	local sw = w / steps
	for i = 0, steps - 1 do
		local t = i / (steps - 1)
		surface.SetDrawColor(Lerp(t, c1.r, c2.r), Lerp(t, c1.g, c2.g), Lerp(t, c1.b, c2.b), 255)
		surface.DrawRect(x + i * sw, y, sw + 1, h)
	end
end

----------------------------------------------------------------- build skin
local SKIN = {}
SKIN.PrintName    = "TheGmod.Club"
SKIN.Author       = "TheGmod.Club"
SKIN.Base         = "Default"
SKIN.DermaVersion = 1

------------------------------------------------------------- frame / panels
-- horizontal 2-colour gradient fill (opaque), for the window background
local function gradFill(x, y, w, h, c1, c2)
	local steps = 48
	local sw = w / steps
	for i = 0, steps - 1 do
		local t = i / (steps - 1)
		surface.SetDrawColor(Lerp(t, c1.r, c2.r), Lerp(t, c1.g, c2.g), Lerp(t, c1.b, c2.b), 255)
		surface.DrawRect(x + i * sw, y, sw + 1, h)
	end
end

-- OPAQUE gradient for a panel, but mapped across the whole window it lives in,
-- so separate panels (tree, grid, tool list) line up into one continuous
-- orange->purple gradient while each stays solid (readable, no game-world bleed).
local function windowGradPaint(p, w, h)
	local win = p
	local node = p.GetParent and p:GetParent()
	while IsValid(node) do
		if node.GetName and node:GetName() == "DFrame" then win = node break end
		node = node:GetParent()
	end

	local total = win:GetWide()
	if total <= 0 then total = w end
	local px = p:LocalToScreen(0, 0)
	local wx = win:LocalToScreen(0, 0)
	local offset = px - wx

	local steps = 64
	local sw = w / steps
	for i = 0, steps - 1 do
		local t = math.Clamp((offset + (i + 0.5) * sw) / total, 0, 1)
		surface.SetDrawColor(
			Lerp(t, C.gradA.r, C.gradB.r),
			Lerp(t, C.gradA.g, C.gradB.g),
			Lerp(t, C.gradA.b, C.gradB.b), 255)
		surface.DrawRect(i * sw, 0, sw + 1, h)
	end
end

-- Website hero look: a dark base with soft radial orange + purple glows,
-- positioned relative to the whole window so separate panels form one glow.
local glowMat = Material("sprites/light_glow02_add")

local function windowGlowPaint(p, w, h)
	local win = p
	local node = p.GetParent and p:GetParent()
	while IsValid(node) do
		if node.GetName and node:GetName() == "DFrame" then win = node break end
		node = node:GetParent()
	end

	local ww, wh = win:GetSize()
	if ww <= 0 then ww = w end
	if wh <= 0 then wh = h end
	local pxs, pys = p:LocalToScreen(0, 0)
	local wxs, wys = win:LocalToScreen(0, 0)
	local ox, oy = pxs - wxs, pys - wys

	-- dark base
	surface.SetDrawColor(22, 19, 24)
	surface.DrawRect(0, 0, w, h)

	-- faint grid pattern (like the site's .bg-grid), phase-aligned across the window
	local spacing = 44
	surface.SetDrawColor(255, 255, 255, 6)
	for gx = -(ox % spacing), w, spacing do
		surface.DrawRect(gx, 0, 1, h)
	end
	for gy = -(oy % spacing), h, spacing do
		surface.DrawRect(0, gy, w, 1)
	end

	-- single soft purple glow along the bottom (clipped to this panel's slice)
	surface.SetMaterial(glowMat)
	local gs = math.max(ww, wh) * 1.15

	surface.SetDrawColor(122, 58, 168, 42)   -- purple, bottom
	surface.DrawTexturedRect((ww * 0.5 - ox) - gs / 2, (wh * 1.05 - oy) - gs / 2, gs, gs)
end

function SKIN:PaintFrame(panel, w, h)
	draw.RoundedBox(6, 0, 0, w, h, C.border)
	windowGlowPaint(panel, w, h)
end

function SKIN:PaintPanel(panel, w, h)
	if not panel.m_bBackground then return end
	surface.SetDrawColor(C.frost)
	surface.DrawRect(0, 0, w, h)
end

-------------------------------------------------------------------- buttons
function SKIN:PaintButton(panel, w, h)
	-- selected/active tool buttons: paint the gradient even when the button
	-- normally draws no background (m_bBackground == false), which is what the
	-- spawnmenu tool-list rows are -- that's why they kept their default yellow.
	local selected = panel.Depressed
		or (panel.IsSelected and panel:IsSelected())
		or panel.m_bSelected
		or (panel.GetToggle and panel:GetToggle())
	if selected then
		hGrad(0, 0, w, h, C.accent, C.purple)
		return
	end

	if panel.m_bBackground == false then return end
	if panel.Hovered then
		draw.RoundedBox(4, 0, 0, w, h, C.panel2)
	else
		draw.RoundedBox(4, 0, 0, w, h, C.panel)
	end
end

---------------------------------------------------------- property sheet / tabs
function SKIN:PaintPropertySheet(panel, w, h)
	local ah = 0
	if IsValid(panel.m_pActiveButton) then
		ah = panel.m_pActiveButton:GetTall() - 8
	end
	-- glow background (mapped across the window) as the sheet background
	windowGlowPaint(panel, w, h)
end

function SKIN:PaintTab(panel, w, h)
	local sheet = panel.GetPropertySheet and panel:GetPropertySheet()
	local active = IsValid(sheet) and sheet:GetActiveTab() == panel
	surface.SetDrawColor(active and C.panel or C.header)
	surface.DrawRect(0, 0, w, h)
	if active then
		hGrad(0, h - 3, w, 3, C.accent, C.purple)
	end
end

------------------------------------------------------------------- scrollbar
function SKIN:PaintScrollBarGrip(panel, w, h)
	draw.RoundedBox(3, 1, 0, w - 2, h, panel.Hovered and C.accent or C.borderL)
end

function SKIN:PaintVScrollBar(panel, w, h)
	surface.SetDrawColor(C.header)
	surface.DrawRect(0, 0, w, h)
end

------------------------------------------------------------- category / tree
function SKIN:PaintCollapsibleCategory(panel, w, h)
	surface.SetDrawColor(C.header)
	surface.DrawRect(0, 0, w, h)
end

function SKIN:PaintCategoryHeader(panel, w, h)
	surface.SetDrawColor(C.panel2)
	surface.DrawRect(0, 0, w, h)
	hGrad(0, h - 2, w, 2, C.accent, C.purple)
end

function SKIN:PaintTree(panel, w, h)
	surface.SetDrawColor(C.panel)
	surface.DrawRect(0, 0, w, h)
end

function SKIN:PaintTreeNodeButton(panel, w, h)
	if panel.m_bSelected then
		hGrad(34, 0, w - 34, h, C.accent, C.purple)   -- orange -> purple gradient
	elseif panel.Hovered then
		draw.RoundedBox(3, 34, 0, w - 34, h, C.panel2)
	end
end

-- tool list / any DListView selection -> orange -> purple gradient (was yellow)
function SKIN:PaintListViewLine(panel, w, h)
	if panel:IsSelected() then
		hGrad(0, 0, w, h, C.accent, C.purple)
	elseif panel.Hovered then
		surface.SetDrawColor(C.panel2)
		surface.DrawRect(0, 0, w, h)
	end
end

------------------------------------------------------------- text controls
function SKIN:PaintTextEntry(panel, w, h)
	if panel.m_bBackground then
		draw.RoundedBox(4, 0, 0, w, h, C.header)
		surface.SetDrawColor(panel:HasFocus() and C.accent or C.border)
		surface.DrawOutlinedRect(0, 0, w, h)
	end
	panel:DrawTextEntryText(C.text, panel.m_colHighlight or C.accent, C.text)
end

function SKIN:PaintComboBox(panel, w, h)
	local col = panel.Hovered and C.panel2 or C.header
	draw.RoundedBox(4, 0, 0, w, h, col)
	surface.SetDrawColor(C.border)
	surface.DrawOutlinedRect(0, 0, w, h)
end

function SKIN:PaintNumSlider(panel, w, h)
	surface.SetDrawColor(C.border)
	surface.DrawRect(8, h / 2 - 1, w - 16, 2)
end

function SKIN:PaintCheckBox(panel, w, h)
	draw.RoundedBox(3, 0, 0, w, h, C.header)
	if panel:GetChecked() then
		draw.RoundedBox(2, 3, 3, w - 6, h - 6, C.accent)
	end
	surface.SetDrawColor(C.border)
	surface.DrawOutlinedRect(0, 0, w, h)
end

----------------------------------------------------------------- menus
function SKIN:PaintMenu(panel, w, h)
	draw.RoundedBox(4, 0, 0, w, h, C.border)
	draw.RoundedBox(4, 1, 1, w - 2, h - 2, C.bg)
end

function SKIN:PaintMenuOption(panel, w, h)
	if panel.m_bBackground and (panel.Hovered or panel.Highlight) then
		surface.SetDrawColor(C.accent)
		surface.DrawRect(0, 0, w, h)
	end
end

--------------------------------------------------------------------- register
local skinReady = false

-- Overlay our readable text colours onto a COMPLETE copy of Default's Colours,
-- so every field panels read (Colours.Button/Tab/Tree/Label/...) always exists.
local function buildColours()
	local base = derma.GetDefaultSkin and derma.GetDefaultSkin() or nil
	if not base or not istable(base.Colours) then return false end

	local col = table.Copy(base.Colours)

	col.Label = col.Label or {}
	col.Label.Default   = C.text
	col.Label.Bright    = C.text
	col.Label.Dark      = C.muted
	col.Label.Highlight = C.accentL

	if istable(col.Button) then
		col.Button.Normal   = C.muted
		col.Button.Hovered  = C.text
		col.Button.Down     = C.text
		col.Button.Disabled = C.dim
	end

	if istable(col.Tab) then
		if istable(col.Tab.Active)   then col.Tab.Active.Text   = C.text end
		if istable(col.Tab.Inactive) then col.Tab.Inactive.Text = C.muted end
	end

	if istable(col.Tree) then
		col.Tree.Normal   = C.text
		col.Tree.Hovered  = C.text
		col.Tree.Selected = C.text
	end

	SKIN.Colours = col
	return true
end

local function define()
	if skinReady then return end
	if not buildColours() then return end -- Default not ready yet; try again later
	derma.DefineSkin("thegmodclub", "TheGmod.Club themed UI skin", SKIN)
	derma.RefreshSkins()
	skinReady = true
end

hook.Add("Initialize", "TGC_SpawnmenuSkin_Define", define)
timer.Simple(0, define) -- also covers lua auto-refresh (Initialize won't re-fire)

------------------------------------------------------------ force-theme walker
-- The skin only reaches panels that actually call skin paint hooks. A big chunk
-- of the spawnmenu (the tree sidebar, the tab bars, the tool control panels) is
-- hardcoded, so we walk the built panel tree and repaint those by class name.
-- vgui.Create names a scripted panel after its class, so panel:GetName() gives
-- us "DTree", "DPropertySheet", etc.

local function paintFill(col)
	return function(s, w, h)
		surface.SetDrawColor(col)
		surface.DrawRect(0, 0, w, h)
	end
end

-- subtle vertical orange->purple accent line (for section dividers)
local function vAccentLine(x, h)
	local steps = 28
	local sh = h / steps
	for i = 0, steps - 1 do
		local t = i / (steps - 1)
		surface.SetDrawColor(
			Lerp(t, C.accent.r, C.purple.r),
			Lerp(t, C.accent.g, C.purple.g),
			Lerp(t, C.accent.b, C.purple.b), 120)
		surface.DrawRect(x, i * sh, 2, sh + 1)
	end
end

local function themeTabs(sheet)
	for _, item in ipairs(sheet.Items or {}) do
		local tab = item.Tab
		if IsValid(tab) and not tab.tgcThemed then
			tab.tgcThemed = true
			tab.Paint = function(s, w, h)
				local active = IsValid(sheet) and sheet:GetActiveTab() == s
				surface.SetDrawColor(active and C.panel or C.header)
				surface.DrawRect(0, 0, w, h)
				if active then hGrad(0, h - 3, w, 3, C.accent, C.purple) end
			end
			if tab.SetTextColor then tab:SetTextColor(C.text) end
		end
	end
end

local textClasses = {
	DLabel = true, DButton = true, DCheckBoxLabel = true, DTextEntry = true,
	ToolMenuOption = true, ContentHeader = true, DCollapsibleCategory = true,
}

local function themeOne(p)
	if not IsValid(p) then return end
	local n = (p.GetName and p:GetName()) or ""

	-- force white text on elements that cached a dark default colour
	if textClasses[n] and p.SetTextColor then
		p:SetTextColor(C.text)
	end
	-- tree node labels (left spawnlist tree) keep their own label button
	if n == "DTree_Node" and IsValid(p.Label) and p.Label.SetTextColor then
		p.Label:SetTextColor(C.text)
	end

	-- orange hover outline on spawn/tool icons (added via PaintOver so it doesn't
	-- disturb the icon's own rendering)
	if (n == "ContentIcon" or n == "SpawnIcon") and not p.tgcHover then
		p.tgcHover = true
		local oldPO = p.PaintOver
		p.PaintOver = function(s, iw, ih)
			if oldPO then oldPO(s, iw, ih) end
			if s.IsHovered and s:IsHovered() then
				surface.SetDrawColor(255, 122, 26, 255)
				surface.DrawOutlinedRect(0, 0, iw, ih, 2)
			end
		end
	end

	-- tool-list rows are DButtons under DCollapsibleCategory that draw their own
	-- yellow selection + alt-line striping (bypassing the skin). Wrap them so the
	-- selected tool gets the orange->purple gradient; redraw the label ourselves.
	if n == "DButton" and not p.tgcTool then
		local par = p:GetParent()
		if IsValid(par) and par.GetName and par:GetName() == "DCollapsibleCategory" then
			p.tgcTool = true
			p.Paint = function(s, bw, bh)
				if s.m_bSelected then
					hGrad(0, 0, bw, bh, C.accent, C.purple)
				elseif s.Hovered then
					surface.SetDrawColor(C.panel2)
					surface.DrawRect(0, 0, bw, bh)
				elseif s.AltLine then
					surface.SetDrawColor(255, 255, 255, 5)
					surface.DrawRect(0, 0, bw, bh)
				end
				local txt = (s.GetText and s:GetText()) or ""
				if txt ~= "" then
					local font = (s.GetFont and s:GetFont()) or "DermaDefault"
					local ix = 6
					if s.GetTextInset then local a = s:GetTextInset(); if a then ix = a end end
					draw.SimpleText(txt, font, ix + 4, bh * 0.5,
						s.m_bSelected and color_white or C.text,
						TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
				end
				return true
			end
		end
	end

	if n == "DTree" or n == "ContentSidebar" then
		p.Paint = windowGlowPaint
	elseif n == "DCategoryList" or n == "ControlPanel" or n == "DForm" then
		p.Paint = windowGlowPaint
	elseif n == "ContentContainer" or n == "DTileLayout" or n == "DIconLayout" then
		p.Paint = windowGlowPaint
	elseif n == "DListView" then
		p.Paint = windowGlowPaint
	elseif n == "DScrollPanel" then
		p.Paint = windowGlowPaint
	elseif n == "DHorizontalDivider" then
		-- draw the accent line in the divider gap between the two columns
		p.Paint = function(s, w, h)
			local lw = s.m_iLeftWidth or (w * 0.5)
			local dw = s.m_iDividerWidth or 8
			vAccentLine(lw + dw * 0.5 - 1, h)
		end
	elseif n == "DTextEntry" then
		p.Paint = function(s, w, h)
			surface.SetDrawColor(C.header)
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(s:HasFocus() and C.accent or C.border)
			surface.DrawOutlinedRect(0, 0, w, h)
			s:DrawTextEntryText(C.text, C.accent, C.text)
		end
	elseif n == "DComboBox" then
		p.Paint = function(s, w, h)
			draw.RoundedBox(4, 0, 0, w, h, C.header)
			surface.SetDrawColor(C.border)
			surface.DrawOutlinedRect(0, 0, w, h)
		end
		if p.SetTextColor then p:SetTextColor(C.text) end
	elseif n == "DBinder" then
		p.Paint = function(s, w, h)
			draw.RoundedBox(4, 0, 0, w, h, C.panel2)
			surface.SetDrawColor(C.border)
			surface.DrawOutlinedRect(0, 0, w, h)
		end
		if p.SetTextColor then p:SetTextColor(C.text) end
	elseif n == "DCollapsibleCategory" then
		p.Paint = function(s, w, h)
			local hh = (s.Header and IsValid(s.Header) and s.Header:GetTall()) or 20
			surface.SetDrawColor(C.header)
			surface.DrawRect(0, 0, w, hh)
			hGrad(0, hh - 2, w, 2, C.accent, C.purple)
		end
	elseif n == "DPropertySheet" then
		themeTabs(p)
	end
end

local function walk(p)
	if not IsValid(p) then return end
	themeOne(p)
	for _, c in ipairs(p:GetChildren()) do walk(c) end
end

------------------------------------------------------------ apply to spawnmenu
local function applySkin()
	define() -- make sure the skin exists before we point the menu at it
	if not skinReady then return end
	if IsValid(g_SpawnMenu) then
		g_SpawnMenu:SetSkin("thegmodclub")
		g_SpawnMenu:InvalidateChildren(true)
		walk(g_SpawnMenu)
	end
end

hook.Add("SpawnMenuOpen", "TGC_SpawnmenuSkin_Apply", function()
	timer.Simple(0, applySkin)
	-- keep re-theming while the menu is open so lazily-built panels (tool
	-- control panels, freshly opened tabs) also get caught, then stop on close.
	timer.Create("TGC_SpawnmenuSkin_Walk", 0.25, 0, function()
		if not IsValid(g_SpawnMenu) or not g_SpawnMenu:IsVisible() then
			timer.Remove("TGC_SpawnmenuSkin_Walk")
			return
		end
		applySkin()
	end)
end)

timer.Simple(1, applySkin) -- in case the menu already exists (lua refresh)
