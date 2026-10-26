class_name SettingsMenu
extends BaseMenu
## Configurações: música, efeitos, sombras, FPS e política de privacidade.

signal back_pressed

const TOGGLES := [
	["music", "Música"],
	["sfx", "Efeitos sonoros"],
	["shadows", "Sombras (desligue em celulares lentos)"],
	["show_fps", "Mostrar FPS"],
]

var _buttons := {}
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
	_main_box.add_child(UiTheme.make_label("CONFIGURAÇÕES", 42))
	for t in TOGGLES:
		var b := UiTheme.make_button("", UiTheme.COLOR_SECONDARY, Vector2(640, 70), 26)
		b.pressed.connect(_toggle.bind(t[0]))
		_buttons[t[0]] = b
		_main_box.add_child(b)
	var privacy := UiTheme.make_button("Política de privacidade", UiTheme.COLOR_NEUTRAL, Vector2(640, 70), 26)
	privacy.pressed.connect(_show_privacy.bind(true))
	_main_box.add_child(privacy)
	var back := UiTheme.make_button("VOLTAR", UiTheme.COLOR_PRIMARY, Vector2(640, 78), 30)
	back.pressed.connect(func(): back_pressed.emit())
	_main_box.add_child(back)
	var version: String = ProjectSettings.get_setting("application/config/version", "")
	_main_box.add_child(UiTheme.make_label("Versão %s" % version, 18, Color(0.75, 0.8, 0.9)))

	_privacy = UiTheme.make_panel()
	_privacy.visible = false
	center.add_child(_privacy)
	var pbox := VBoxContainer.new()
	pbox.add_theme_constant_override("separation", 14)
	_privacy.add_child(pbox)
	pbox.add_child(UiTheme.make_label("PRIVACIDADE", 38))
	var text := UiTheme.make_label(
		"Road Rush 3D não coleta dados pessoais.\n" +
		"Moedas, recordes, personagens e configurações ficam salvos\n" +
		"somente neste aparelho e são apagados ao desinstalar o jogo.\n" +
		"Esta versão não usa internet, não tem compras e não exibe\n" +
		"anúncios reais. Se isso mudar, esta política será atualizada.", 24)
	pbox.add_child(text)
	var close := UiTheme.make_button("FECHAR", UiTheme.COLOR_PRIMARY, Vector2(300, 76), 30)
	close.pressed.connect(_show_privacy.bind(false))
	pbox.add_child(UiTheme.center(close))


func _refresh() -> void:
	_show_privacy(false)
	for t in TOGGLES:
		var on := SaveManager.get_setting(t[0])
		var b: Button = _buttons[t[0]]
		b.text = "%s:  %s" % [t[1], "LIGADO" if on else "DESLIGADO"]
		UiTheme.style_button(b, UiTheme.COLOR_SECONDARY if on else UiTheme.COLOR_NEUTRAL)


func _toggle(key: String) -> void:
	SaveManager.set_setting(key, not SaveManager.get_setting(key))
	_refresh()


func _show_privacy(value: bool) -> void:
	_privacy.visible = value
	_main_box.get_parent().visible = not value


func is_privacy_open() -> bool:
	return _privacy.visible
