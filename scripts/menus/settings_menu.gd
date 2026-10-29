class_name SettingsMenu
extends BaseMenu
## Configurações: música, efeitos, sombras, FPS e política de privacidade.

signal back_pressed

const TOGGLES := [
	["music", "SET_MUSIC"],
	["sfx", "SET_SFX"],
	["shadows", "SET_SHADOWS"],
	["show_fps", "SET_FPS"],
]

var _buttons := {}
var _language: Button
var _privacy: PanelContainer
var _main_box: VBoxContainer


func _build() -> void:
	add_dim()
	var margin := add_safe_margin(20.0)
	var center := CenterContainer.new()
	margin.add_child(center)
	var panel := UiTheme.make_panel()
	center.add_child(panel)
	_main_box = VBoxContainer.new()
	_main_box.add_theme_constant_override("separation", 12)
	panel.add_child(_main_box)
	_main_box.add_child(UiTheme.make_label(tr("SETTINGS_TITLE"), 44))
	_language = UiTheme.make_button("", UiTheme.COLOR_ACCENT, Vector2(600, 76), 26)
	_language.pressed.connect(_on_language)
	_main_box.add_child(_language)
	for t in TOGGLES:
		var b := UiTheme.make_button("", UiTheme.COLOR_SECONDARY, Vector2(600, 76), 26)
		b.pressed.connect(_toggle.bind(t[0]))
		_buttons[t[0]] = b
		_main_box.add_child(b)
	var privacy := UiTheme.make_button(tr("PRIVACY_POLICY"), UiTheme.COLOR_NEUTRAL, Vector2(600, 76), 26)
	privacy.pressed.connect(_show_privacy.bind(true))
	_main_box.add_child(privacy)
	var back := UiTheme.make_button(tr("BACK"), UiTheme.COLOR_PRIMARY, Vector2(600, 84), 30)
	back.pressed.connect(func(): back_pressed.emit())
	_main_box.add_child(back)
	var version: String = ProjectSettings.get_setting("application/config/version", "")
	_main_box.add_child(UiTheme.make_label(tr("VERSION") % version, 18, Color(0.75, 0.8, 0.9)))

	_privacy = UiTheme.make_panel()
	_privacy.visible = false
	center.add_child(_privacy)
	var pbox := VBoxContainer.new()
	pbox.add_theme_constant_override("separation", 14)
	_privacy.add_child(pbox)
	pbox.add_child(UiTheme.make_label(tr("PRIVACY_TITLE"), 38))
	var text := UiTheme.make_label(tr("PRIVACY_TEXT"), 22)
	pbox.add_child(text)
	var close := UiTheme.make_button(tr("CLOSE"), UiTheme.COLOR_PRIMARY, Vector2(300, 76), 30)
	close.pressed.connect(_show_privacy.bind(false))
	pbox.add_child(UiTheme.center(close))


func _refresh() -> void:
	_show_privacy(false)
	_language.text = tr("LANGUAGE") % Loc.choice_label()
	for t in TOGGLES:
		var on := SaveManager.get_setting(t[0])
		var b: Button = _buttons[t[0]]
		b.text = "%s:  %s" % [tr(t[1]), tr("ON") if on else tr("OFF")]
		UiTheme.style_button(b, UiTheme.COLOR_SECONDARY if on else UiTheme.COLOR_NEUTRAL)


func _toggle(key: String) -> void:
	SaveManager.set_setting(key, not SaveManager.get_setting(key))
	_refresh()


## Troca o idioma e recarrega a cena para atualizar todos os textos.
func _on_language() -> void:
	Loc.cycle_choice()
	_reopen_after_reload()


func _reopen_after_reload() -> void:
	get_tree().set_meta("reopen_settings", true)
	get_tree().reload_current_scene()


func _show_privacy(value: bool) -> void:
	_privacy.visible = value
	_main_box.get_parent().visible = not value


func is_privacy_open() -> bool:
	return _privacy.visible
