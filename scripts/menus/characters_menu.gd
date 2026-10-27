class_name CharactersMenu
extends BaseMenu
## Escolha e compra de personagens com moedas do jogo.
## O personagem é mostrado no próprio cenário 3D (sinal preview_changed).

signal back_pressed
signal preview_changed(def: Dictionary)

var _index := 0
var _coins: CoinCounter
var _name: Label
var _description: Label
var _status: Label
var _action: Button
var _counter: Label


func _build() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var margin := add_safe_margin(24.0)
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(col)

	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(top)
	var back := UiTheme.make_button(tr("BACK"), UiTheme.COLOR_NEUTRAL, Vector2(200, 76), 28)
	back.pressed.connect(func(): back_pressed.emit())
	top.add_child(back)
	top.add_child(UiTheme.spacer(false))
	_coins = CoinCounter.new(34)
	top.add_child(_coins)

	col.add_child(UiTheme.spacer())

	var panel := UiTheme.make_panel()
	col.add_child(panel)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 8)
	panel.add_child(info)
	_counter = UiTheme.make_label("", 22, Color(0.8, 0.85, 0.95))
	info.add_child(_counter)
	_name = UiTheme.make_label("", 46)
	info.add_child(_name)
	_description = UiTheme.make_wrapped_label("", 26, Color(0.85, 0.9, 1.0))
	info.add_child(_description)
	_status = UiTheme.make_wrapped_label("", 24, UiTheme.COLOR_GOLD)
	info.add_child(_status)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	info.add_child(row)
	var prev := UiTheme.make_button("<", UiTheme.COLOR_SECONDARY, Vector2(96, 96), 48)
	prev.pressed.connect(_change.bind(-1))
	row.add_child(prev)
	_action = UiTheme.make_button("", UiTheme.COLOR_PRIMARY, Vector2(0, 96), 28)
	_action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_action.pressed.connect(_on_action)
	row.add_child(_action)
	var next := UiTheme.make_button(">", UiTheme.COLOR_SECONDARY, Vector2(96, 96), 48)
	next.pressed.connect(_change.bind(1))
	row.add_child(next)


func open() -> void:
	_index = CharacterCatalog.index_of(SaveManager.get_selected_character())
	super.open()
	preview_changed.emit(CharacterCatalog.get_by_index(_index))


func _change(step: int) -> void:
	_index = wrapi(_index + step, 0, CharacterCatalog.count())
	_status.text = ""
	_refresh()
	preview_changed.emit(CharacterCatalog.get_by_index(_index))


func _refresh() -> void:
	var def := CharacterCatalog.get_by_index(_index)
	var id: String = def["id"]
	var price: int = def["price"]
	_coins.set_value(SaveManager.get_coins())
	_counter.text = "%d / %d" % [_index + 1, CharacterCatalog.count()]
	_name.text = tr(def["name"])
	_description.text = tr(def["description"])
	if SaveManager.get_selected_character() == id:
		_action.text = tr("IN_USE")
		_action.disabled = true
		UiTheme.style_button(_action, UiTheme.COLOR_NEUTRAL)
	elif SaveManager.is_unlocked(id):
		_action.text = tr("USE")
		_action.disabled = false
		UiTheme.style_button(_action, UiTheme.COLOR_PRIMARY)
	else:
		_action.text = tr("BUY_FOR") % price
		_action.disabled = false
		UiTheme.style_button(_action, UiTheme.COLOR_ACCENT)


func _on_action() -> void:
	var def := CharacterCatalog.get_by_index(_index)
	var id: String = def["id"]
	if SaveManager.is_unlocked(id):
		SaveManager.set_selected_character(id)
		_status.text = ""
	elif SaveManager.buy_character(id, int(def["price"])):
		AudioManager.play_sfx("reward")
		_status.text = tr("UNLOCKED")
	else:
		var missing := int(def["price"]) - SaveManager.get_coins()
		_status.text = tr("MISSING_COINS") % missing
	_refresh()
