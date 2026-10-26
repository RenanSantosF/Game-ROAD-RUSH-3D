class_name PauseMenu
extends BaseMenu
## Tela de pausa (o jogo fica congelado enquanto ela está aberta).

signal resume_pressed
signal restart_pressed
signal menu_pressed

var _music: Button
var _sfx: Button


func _build() -> void:
	add_dim()
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := UiTheme.make_panel()
	center.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	panel.add_child(col)
	col.add_child(UiTheme.make_label("PAUSADO", 52))
	var resume := UiTheme.make_button("CONTINUAR", UiTheme.COLOR_PRIMARY, Vector2(440, 92), 36)
	resume.pressed.connect(func(): resume_pressed.emit())
	col.add_child(resume)
	var restart := UiTheme.make_button("REINICIAR", UiTheme.COLOR_SECONDARY)
	restart.pressed.connect(func(): restart_pressed.emit())
	col.add_child(restart)
	var menu := UiTheme.make_button("MENU PRINCIPAL", UiTheme.COLOR_NEUTRAL)
	menu.pressed.connect(func(): menu_pressed.emit())
	col.add_child(menu)
	var sound_row := HBoxContainer.new()
	sound_row.add_theme_constant_override("separation", 12)
	col.add_child(sound_row)
	_music = UiTheme.make_button("", UiTheme.COLOR_NEUTRAL, Vector2(214, 64), 22)
	_music.pressed.connect(_toggle.bind("music"))
	sound_row.add_child(_music)
	_sfx = UiTheme.make_button("", UiTheme.COLOR_NEUTRAL, Vector2(214, 64), 22)
	_sfx.pressed.connect(_toggle.bind("sfx"))
	sound_row.add_child(_sfx)


func _refresh() -> void:
	var music := SaveManager.get_setting("music")
	var sfx := SaveManager.get_setting("sfx")
	_music.text = "Música: %s" % ("SIM" if music else "NÃO")
	_sfx.text = "Efeitos: %s" % ("SIM" if sfx else "NÃO")
	UiTheme.style_button(_music, UiTheme.COLOR_SECONDARY if music else UiTheme.COLOR_NEUTRAL)
	UiTheme.style_button(_sfx, UiTheme.COLOR_SECONDARY if sfx else UiTheme.COLOR_NEUTRAL)


func _toggle(key: String) -> void:
	SaveManager.set_setting(key, not SaveManager.get_setting(key))
	_refresh()
