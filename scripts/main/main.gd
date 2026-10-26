extends Control
## Cena de diagnóstico da Etapa 1.
## Mostra versão do Godot, renderizador, resolução e FPS para confirmar
## que o projeto está configurado corretamente no celular.
## Será substituída pelo jogo real nas próximas etapas.

const FPS_REFRESH_INTERVAL := 0.5

var _fps_timer := 0.0
var _last_touch := "nenhum"

@onready var _info_label: Label = %InfoLabel
@onready var _fps_label: Label = %FpsLabel


func _ready() -> void:
	get_viewport().size_changed.connect(_update_info)
	_update_info()
	print("[Road Rush 3D] Etapa 1 OK - ", Engine.get_version_info().string)


func _process(delta: float) -> void:
	_fps_timer += delta
	if _fps_timer >= FPS_REFRESH_INTERVAL:
		_fps_timer = 0.0
		_fps_label.text = "FPS: %d" % Engine.get_frames_per_second()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_last_touch = "(%d, %d)" % [event.position.x, event.position.y]
		_update_info()


func _update_info() -> void:
	var lines: PackedStringArray = [
		"ROAD RUSH 3D - Etapa 1",
		"Godot: %s" % Engine.get_version_info().string,
		"Renderizador: %s" % RenderingServer.get_current_rendering_method(),
		"GPU: %s" % RenderingServer.get_video_adapter_name(),
		"Sistema: %s" % OS.get_name(),
		"Tela física: %s" % str(DisplayServer.screen_get_size()),
		"Área do jogo: %s" % str(get_viewport_rect().size),
		"Último toque: %s" % _last_touch,
	]
	_info_label.text = "\n".join(lines)
