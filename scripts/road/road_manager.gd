class_name RoadManager
extends Node3D
## Estrada infinita feita com poucos trechos reaproveitados: quando um
## trecho fica para trás da câmera, ele é movido para a frente com
## outra combinação de prédios (nenhum objeto novo é criado na partida).

var _segments: Array[Node3D] = []
var _indices := PackedInt32Array()
var _next_index := 0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	for i in GameConfig.SEGMENTS_AHEAD + 2:
		var seg := Node3D.new()
		for part in ["Road", "Left", "Right"]:
			var mi := MeshInstance3D.new()
			mi.name = part
			if part != "Road":
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			seg.add_child(mi)
		add_child(seg)
		_segments.append(seg)
		_indices.append(0)
	reset()


func reset() -> void:
	_next_index = -1
	for i in _segments.size():
		_place(i)


func update(player_distance: float) -> void:
	var length := GameConfig.SEGMENT_LENGTH
	for i in _segments.size():
		if (_indices[i] + 1) * length < player_distance - 12.0:
			_place(i)


func _place(i: int) -> void:
	var seg := _segments[i]
	_indices[i] = _next_index
	seg.position = Vector3(0, 0, -_next_index * GameConfig.SEGMENT_LENGTH)
	var road_variant := 1 if _rng.randf() < 0.15 else 0
	(seg.get_child(0) as MeshInstance3D).mesh = ModelFactory.road(road_variant)
	(seg.get_child(1) as MeshInstance3D).mesh = ModelFactory.side(-1, _rng.randi() % ModelFactory.SIDE_VARIANTS)
	(seg.get_child(2) as MeshInstance3D).mesh = ModelFactory.side(1, _rng.randi() % ModelFactory.SIDE_VARIANTS)
	_next_index += 1
