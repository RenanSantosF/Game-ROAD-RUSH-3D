class_name AnimalModel
extends Node3D
## Bichinho low-poly feito de blocos (galinha, pato, porco, gato) com
## animações por código: respirar, pulinho com "estica e achata",
## esbarrão, e as mortes (achatado, afogado e engolido pela nuvem).
## A frente do modelo aponta para -Z.

var hop_t := -1.0

var _pivot: Node3D
var _mesh: MeshInstance3D
var _target_yaw := 0.0
var _land_timer := 0.0
var _bump_timer := 0.0
var _death := ""
var _death_time := 0.0
var _time := 0.0


func _ready() -> void:
	_pivot = Node3D.new()
	add_child(_pivot)
	_mesh = MeshInstance3D.new()
	_pivot.add_child(_mesh)


func build(def: Dictionary) -> void:
	var mb := MeshBuilder.new()
	var c: Color = def["color"]
	var a: Color = def["accent"]
	match def["species"]:
		"duck":
			_build_bird(mb, c, Color(1.0, 0.55, 0.1), a, true)
		"pig":
			_build_pig(mb, c, a)
		"cat":
			_build_cat(mb, c, a)
		_:
			_build_bird(mb, c, Color(1.0, 0.6, 0.15), a, false)
	_mesh.mesh = mb.commit()
	reset()


func reset() -> void:
	_death = ""
	_death_time = 0.0
	hop_t = -1.0
	_land_timer = 0.0
	_bump_timer = 0.0
	position = Vector3.ZERO
	_pivot.scale = Vector3.ONE
	_pivot.position = Vector3.ZERO
	_pivot.rotation = Vector3.ZERO
	visible = true


func face(dir: Vector2i) -> void:
	if dir == Vector2i.UP:
		_target_yaw = 0.0
	elif dir == Vector2i.DOWN:
		_target_yaw = PI
	elif dir == Vector2i.LEFT:
		_target_yaw = PI * 0.5
	elif dir == Vector2i.RIGHT:
		_target_yaw = -PI * 0.5


func land() -> void:
	_land_timer = 0.1


func bump() -> void:
	_bump_timer = 0.18


func die(cause: String) -> void:
	_death = cause
	_death_time = 0.0
	hop_t = -1.0
	visible = true


func _process(delta: float) -> void:
	if _pivot == null:
		return
	_time += delta
	rotation.y = lerp_angle(rotation.y, _target_yaw, 1.0 - exp(-28.0 * delta))
	if _death != "":
		_animate_death(delta)
		return
	var sx := 1.0
	var sy := 1.0
	if hop_t >= 0.0:
		var s := sin(PI * hop_t)
		sx = 1.0 - 0.12 * s
		sy = 1.0 + 0.22 * s
	elif _land_timer > 0.0:
		_land_timer -= delta
		var k := maxf(_land_timer / 0.1, 0.0)
		sx = 1.0 + 0.15 * k
		sy = 1.0 - 0.25 * k
	else:
		sy = 1.0 + sin(_time * 3.2) * 0.025
	_pivot.scale = Vector3(sx, sy, sx)
	if _bump_timer > 0.0:
		_bump_timer -= delta
		_pivot.position.x = sin(_bump_timer * 70.0) * 0.06
	else:
		_pivot.position.x = 0.0


func _animate_death(delta: float) -> void:
	_death_time += delta
	var k := 1.0 - exp(-30.0 * delta)
	match _death:
		"squash":
			_pivot.scale = _pivot.scale.lerp(Vector3(1.45, 0.12, 1.45), k)
		"water":
			_pivot.position.y = lerpf(_pivot.position.y, -0.9, 1.0 - exp(-4.0 * delta))
			_pivot.scale = _pivot.scale.lerp(Vector3(0.6, 0.6, 0.6), 1.0 - exp(-3.0 * delta))
		"cloud":
			# Rodopia e some dentro da nuvem.
			var t := clampf(_death_time / 0.6, 0.0, 1.0)
			_pivot.rotation.y += delta * 14.0
			_pivot.position.y = sin(t * PI) * 0.6
			_pivot.scale = Vector3.ONE * maxf(1.0 - t, 0.01)


# ------------------------------------------------------------- Modelos

func _build_bird(mb: MeshBuilder, body: Color, beak: Color, accent: Color, duck: bool) -> void:
	var legs := Color(1.0, 0.55, 0.1)
	for s in [-1.0, 1.0]:
		mb.box(Vector3(s * 0.12, 0.1, 0.0), Vector3(0.06, 0.2, 0.06), legs)
		mb.box(Vector3(s * 0.12, 0.015, -0.05), Vector3(0.14, 0.03, 0.18), legs)
		mb.box(Vector3(s * 0.29, 0.44, 0.04), Vector3(0.06, 0.24, 0.34), body.darkened(0.08))
		mb.box(Vector3(s * 0.165, 0.86, -0.22), Vector3(0.02, 0.07, 0.07), Color(0.08, 0.08, 0.1))
	mb.box(Vector3(0, 0.42, 0.02), Vector3(0.52, 0.44, 0.58), body, true)
	mb.box(Vector3(0, 0.78, -0.18), Vector3(0.32, 0.34, 0.3), body)
	mb.box(Vector3(0, 0.6, 0.33), Vector3(0.28, 0.24, 0.1), body.darkened(0.05))
	if duck:
		mb.box(Vector3(0, 0.74, -0.4), Vector3(0.24, 0.07, 0.18), beak)
		mb.box(Vector3(0, 0.98, -0.16), Vector3(0.08, 0.08, 0.14), body.darkened(0.1))
	else:
		mb.box(Vector3(0, 0.78, -0.39), Vector3(0.12, 0.08, 0.12), beak)
		mb.box(Vector3(0, 0.67, -0.35), Vector3(0.06, 0.1, 0.05), accent)
		mb.box(Vector3(0, 1.0, -0.2), Vector3(0.07, 0.14, 0.22), accent)


func _build_pig(mb: MeshBuilder, body: Color, accent: Color) -> void:
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			mb.box(Vector3(sx * 0.18, 0.09, sz * 0.2), Vector3(0.12, 0.18, 0.12), accent)
		mb.box(Vector3(sx * 0.13, 0.72, -0.26), Vector3(0.12, 0.1, 0.06), accent)
		mb.box(Vector3(sx * 0.1, 0.56, -0.47), Vector3(0.06, 0.07, 0.02), Color(0.08, 0.08, 0.1))
		mb.box(Vector3(sx * 0.04, 0.44, -0.535), Vector3(0.04, 0.05, 0.02), accent.darkened(0.3))
	mb.box(Vector3(0, 0.38, 0.02), Vector3(0.6, 0.42, 0.62), body, true)
	mb.box(Vector3(0, 0.5, -0.33), Vector3(0.44, 0.4, 0.28), body)
	mb.box(Vector3(0, 0.44, -0.5), Vector3(0.22, 0.14, 0.06), accent)
	mb.box(Vector3(0, 0.52, 0.36), Vector3(0.06, 0.1, 0.06), accent)


func _build_cat(mb: MeshBuilder, body: Color, accent: Color) -> void:
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			mb.box(Vector3(sx * 0.14, 0.1, sz * 0.2), Vector3(0.1, 0.2, 0.1), body)
		mb.frustum(Vector3(sx * 0.12, 0.98, -0.3), 0.08, 0.0, 0.16, 4, body)
		mb.box(Vector3(sx * 0.09, 0.84, -0.49), Vector3(0.06, 0.08, 0.02), Color(0.08, 0.08, 0.1))
	mb.box(Vector3(0, 0.38, 0.04), Vector3(0.44, 0.36, 0.62), body, true)
	for z in [-0.12, 0.08, 0.26]:
		mb.box(Vector3(0, 0.565, z), Vector3(0.3, 0.01, 0.06), accent)
	mb.box(Vector3(0, 0.78, -0.32), Vector3(0.4, 0.36, 0.32), body)
	mb.box(Vector3(0, 0.72, -0.485), Vector3(0.06, 0.05, 0.02), Color(1.0, 0.55, 0.65))
	mb.box(Vector3(0, 0.66, -0.48), Vector3(0.2, 0.08, 0.02), Color(1, 0.95, 0.9))
	mb.box(Vector3(0, 0.62, 0.38), Vector3(0.08, 0.08, 0.16), body)
	mb.box(Vector3(0, 0.82, 0.44), Vector3(0.08, 0.36, 0.08), accent)
