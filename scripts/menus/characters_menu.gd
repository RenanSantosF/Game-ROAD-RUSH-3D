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
	var back := UiTheme.make_button("VOLTAR", UiTheme.COLOR_NEUTRAL, Vector2(200, 76), 28)
	back.pressed.connect(func(): back_pressed.emit())
	top.add_child(back)
	top.add_child(UiTheme.spacer(false))
	_coins = CoinCounter.new(34)
	top.add_child(_coins)

	col.add_child(UiTheme.spacer())

	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_BEGIN
	bottom.add_theme_constant_override("separation", 18)
	col.add_child(bottom)
	var prev := UiTheme.make_button("<", UiTheme.COLOR_SECONDARY, Vector2(96, 104), 48)
	prev.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	prev.pressed.connect(_change.bind(-1))
	bottom.add_child(prev)

	var panel := UiTheme.make_panel()
	panel.custom_minimum_size = Vector2(440, 0)
	bottom.add_child(panel)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 6)
	panel.add_child(info)
	_counter = UiTheme.make_label("", 20, Color(0.8, 0.85, 0.95))
	info.add_child(_counter)
	_name = UiTheme.make_label("", 44)
	info.add_child(_name)
	_description = UiTheme.make_label("", 22, Color(0.85, 0.9, 1.0))
	info.add_child(_description)
	_status = UiTheme.make_label("", 22, UiTheme.COLOR_GOLD)
	info.add_child(_status)
	_action = UiTheme.make_button("", UiTheme.COLOR_PRIMARY, Vector2(380, 84), 28)
	_action.pressed.connect(_on_action)
	info.add_child(UiTheme.center(_action))

	var next := UiTheme.make_button(">", UiTheme.COLOR_SECONDARY, Vector2(96, 104), 48)
	next.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	next.pressed.connect(_change.bind(1))
	bottom.add_child(next)


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
	_name.text = def["name"]
	_description.text = def["description"]
	if SaveManager.get_selected_character() == id:
		_action.text = "EM USO"
		_action.disabled = true
		UiTheme.style_button(_action, UiTheme.COLOR_NEUTRAL)
	elif SaveManager.is_unlocked(id):
		_action.text = "USAR"
		_action.disabled = false
		UiTheme.style_button(_action, UiTheme.COLOR_PRIMARY)
	else:
		_action.text = "COMPRAR  -  %d moedas" % price
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
		_status.text = "Desbloqueado!"
	else:
		var missing := int(def["price"]) - SaveManager.get_coins()
		_status.text = "Faltam %d moedas. Continue jogando!" % missing
	_refresh()
