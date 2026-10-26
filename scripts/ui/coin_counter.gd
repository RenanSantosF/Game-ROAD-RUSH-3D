class_name CoinCounter
extends PanelContainer
## Indicador de moedas: ícone + número, em uma "pílula".

var _label: Label


func _init(font_size := 32) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := UiTheme.panel_box(Color(0.05, 0.07, 0.13, 0.7))
	sb.content_margin_left = 14
	sb.content_margin_right = 22
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	add_theme_stylebox_override("panel", sb)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	row.add_child(CoinIcon.new(font_size * 1.1))
	_label = UiTheme.make_label("0", font_size, UiTheme.COLOR_GOLD)
	row.add_child(_label)


func set_value(value: int) -> void:
	_label.text = str(value)
