class_name CloudWall
extends Node3D
## A nuvem que vem por trás: acompanha a câmera e engole quem ficar
## para trás. É uma malha só (vários "pufes" brancos) que balança de leve.

const WIDTH := 26.0
const DEPTH := 6.0

var _mesh: MeshInstance3D
var _time := 0.0
var _front := 0.0


func _ready() -> void:
	_mesh = MeshInstance3D.new()
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mesh.mesh = _build()
	add_child(_mesh)


## Posiciona a borda da frente da nuvem na linha indicada (pode ser fracionária).
func set_front_row(row: float) -> void:
	_front = row
	position = Vector3(0, 0, -row)


func _process(delta: float) -> void:
	_time += delta
	_mesh.position = Vector3(sin(_time * 0.7) * 0.3, sin(_time * 1.3) * 0.08, 0)


func _build() -> ArrayMesh:
	var mb := MeshBuilder.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	# Base que esconde o chão por baixo da nuvem.
	mb.box(Vector3(0, 0.35, DEPTH * 0.5 + 0.6), Vector3(WIDTH, 0.7, DEPTH), Color(0.86, 0.9, 0.97))
	# Fileira da frente: pufes menores e baixos.
	var x := -WIDTH * 0.5
	while x < WIDTH * 0.5:
		var r := rng.randf_range(0.55, 0.95)
		_puff(mb, Vector3(x, r * 0.55, 0.2 + r), r, rng)
		x += r * rng.randf_range(1.1, 1.5)
	# Fileiras de trás: pufes maiores e mais altos.
	for layer in 2:
		x = -WIDTH * 0.5 + rng.randf() * 0.8
		while x < WIDTH * 0.5:
			var r := rng.randf_range(0.9, 1.5) + layer * 0.3
			_puff(mb, Vector3(x, r * 0.7 + layer * 0.5, 1.6 + layer * 1.6 + r * 0.5), r, rng)
			x += r * rng.randf_range(1.0, 1.4)
	return mb.commit()


## Um "pufe" de nuvem arredondado (octógono achatado em três camadas).
func _puff(mb: MeshBuilder, center: Vector3, r: float, rng: RandomNumberGenerator) -> void:
	var light := Color(1, 1, 1)
	var mid := Color(0.93, 0.95, 1.0)
	var shade := Color(0.8, 0.85, 0.95)
	var h := r * 0.45
	var base := center - Vector3(0, h * 1.5, 0)
	mb.frustum(base, r * 0.7, r, h, 8, shade, false)
	mb.frustum(base + Vector3(0, h, 0), r, r * 0.85, h, 8, mid, false)
	mb.frustum(base + Vector3(0, h * 2.0, 0), r * 0.85, r * 0.45, h, 8, light)
	if rng.randf() < 0.5:
		var s := r * 0.55
		var top := base + Vector3(rng.randf_range(-0.3, 0.3) * r, h * 2.6, 0)
		mb.frustum(top, s, s * 0.8, s * 0.5, 8, mid, false)
		mb.frustum(top + Vector3(0, s * 0.5, 0), s * 0.8, s * 0.3, s * 0.5, 8, light)
