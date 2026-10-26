class_name CoinIcon
extends Control
## Ícone de moeda desenhado por código (sem imagem).


func _init(icon_size := 40.0) -> void:
	custom_minimum_size = Vector2(icon_size, icon_size)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var r := minf(size.x, size.y) * 0.5
	var c := size * 0.5
	draw_circle(c, r, Color(0.75, 0.5, 0.05))
	draw_circle(c, r * 0.82, UiTheme.COLOR_GOLD)
	draw_circle(c, r * 0.5, Color(1.0, 0.93, 0.55))
