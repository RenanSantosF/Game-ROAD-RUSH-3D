class_name UiTheme
extends RefCounted
## Tema visual e "fábrica" de elementos de interface (botões grandes,
## textos com contorno, painéis arredondados). Tudo em um só lugar para
## manter o visual consistente e fácil de ajustar.

const COLOR_PRIMARY := Color(0.2, 0.75, 0.38)
const COLOR_SECONDARY := Color(0.2, 0.55, 0.95)
const COLOR_ACCENT := Color(1.0, 0.62, 0.15)
const COLOR_DANGER := Color(0.92, 0.32, 0.32)
const COLOR_NEUTRAL := Color(0.38, 0.42, 0.5)
const COLOR_GOLD := Color(1.0, 0.84, 0.25)
const COLOR_PANEL := Color(0.07, 0.09, 0.16, 0.86)
const COLOR_DIM := Color(0.02, 0.03, 0.08, 0.6)

static var _theme: Theme


static func get_theme() -> Theme:
	if _theme == null:
		_theme = _build_theme()
	return _theme


static func _build_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 30
	t.set_color("font_color", "Label", Color.WHITE)
	t.set_color("font_outline_color", "Label", Color(0, 0, 0, 0.8))
	t.set_constant("outline_size", "Label", 8)

	t.set_stylebox("normal", "Button", button_box(COLOR_SECONDARY))
	t.set_stylebox("hover", "Button", button_box(COLOR_SECONDARY.lightened(0.08)))
	t.set_stylebox("pressed", "Button", button_box(COLOR_SECONDARY.darkened(0.2), true))
	t.set_stylebox("disabled", "Button", button_box(COLOR_NEUTRAL.darkened(0.2)))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_font_size("font_size", "Button", 32)
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		t.set_color(key, "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", Color(1, 1, 1, 0.55))
	t.set_color("font_outline_color", "Button", Color(0, 0, 0, 0.45))
	t.set_constant("outline_size", "Button", 6)

	t.set_stylebox("panel", "PanelContainer", panel_box())

	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(1, 1, 1, 0.15)
	bar_bg.set_corner_radius_all(10)
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = COLOR_PRIMARY
	bar_fill.set_corner_radius_all(10)
	t.set_stylebox("background", "ProgressBar", bar_bg)
	t.set_stylebox("fill", "ProgressBar", bar_fill)
	return t


static func button_box(color: Color, pressed := false) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(20)
	sb.content_margin_left = 26
	sb.content_margin_right = 26
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	sb.border_color = color.darkened(0.35)
	sb.border_width_bottom = 2 if pressed else 7
	sb.border_width_top = 5 if pressed else 0
	return sb


static func panel_box(color := COLOR_PANEL) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(26)
	sb.content_margin_left = 28
	sb.content_margin_right = 28
	sb.content_margin_top = 20
	sb.content_margin_bottom = 20
	return sb


static func style_button(b: Button, color: Color) -> void:
	b.add_theme_stylebox_override("normal", button_box(color))
	b.add_theme_stylebox_override("hover", button_box(color.lightened(0.08)))
	b.add_theme_stylebox_override("pressed", button_box(color.darkened(0.2), true))


static func make_button(text: String, color := COLOR_SECONDARY, min_size := Vector2(380, 88), font_size := 32) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", font_size)
	style_button(b, color)
	b.pressed.connect(AudioManager.play_sfx.bind("click"))
	return b


static func make_label(text: String, size := 30, color := Color.WHITE, align := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", maxi(4, size / 5))
	return l


## Texto que quebra linha automaticamente (precisa de uma largura mínima).
static func make_wrapped_label(text: String, size := 30, color := Color.WHITE, min_width := 0.0) -> Label:
	var l := make_label(text, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = min_width
	return l


static func make_panel() -> PanelContainer:
	return PanelContainer.new()


## Envolve um controle para centralizá-lo horizontalmente em um VBox.
static func center(control: Control) -> CenterContainer:
	var c := CenterContainer.new()
	c.add_child(control)
	return c


static func spacer(vertical := true) -> Control:
	var s := Control.new()
	if vertical:
		s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	else:
		s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return s


## Margens que respeitam entalhes/câmeras da tela (área segura).
static func safe_margins(viewport: Viewport, base := 20.0) -> Vector4:
	var result := Vector4(base, base, base, base)
	var win := Vector2(DisplayServer.window_get_size())
	if win.x <= 0.0 or win.y <= 0.0:
		return result
	var safe := DisplayServer.get_display_safe_area()
	var vp := viewport.get_visible_rect().size
	var scale := vp / win
	var left := clampf(safe.position.x * scale.x, 0.0, 120.0)
	var top := clampf(safe.position.y * scale.y, 0.0, 120.0)
	var right := clampf((win.x - safe.end.x) * scale.x, 0.0, 120.0)
	var bottom := clampf((win.y - safe.end.y) * scale.y, 0.0, 120.0)
	return Vector4(base + left, base + top, base + right, base + bottom)


static func make_safe_margin(viewport: Viewport, base := 20.0) -> MarginContainer:
	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := safe_margins(viewport, base)
	m.add_theme_constant_override("margin_left", int(v.x))
	m.add_theme_constant_override("margin_top", int(v.y))
	m.add_theme_constant_override("margin_right", int(v.z))
	m.add_theme_constant_override("margin_bottom", int(v.w))
	return m
