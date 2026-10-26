class_name CharacterModel
extends Node3D
## Personagem low-poly montado com caixas e animado por código:
## parado, corrida, pulo, deslize e morte, com transições suaves.
## A frente do personagem aponta para -Z (direção da corrida).

enum Pose { IDLE, RUN, AIR, SLIDE, DEAD }

const HIP_HEIGHT := 0.8
const BLEND_SPEED := 18.0

var pose: int = Pose.IDLE:
	set(value):
		if value == Pose.DEAD and pose != Pose.DEAD:
			_dead_time = 0.0
		pose = value
var run_speed := 11.0
var vertical_velocity := 0.0

var _phase := 0.0
var _time := 0.0
var _dead_time := 0.0
var _body: Node3D
var _head: Node3D
var _arm_l: Node3D
var _arm_r: Node3D
var _leg_l: Node3D
var _leg_r: Node3D


func build(def: Dictionary) -> void:
	for child in get_children():
		child.queue_free()
	var skin: Color = def["skin"]
	var shirt: Color = def["shirt"]
	var pants: Color = def["pants"]
	var shoes: Color = def["shoes"]
	var hair: Color = def["hair"]
	var accent: Color = def["accent"]
	var accessory: String = def["accessory"]

	_body = Node3D.new()
	_body.position.y = HIP_HEIGHT
	add_child(_body)

	# Tronco (inclui quadril)
	var mb := MeshBuilder.new()
	mb.box(Vector3(0, 0.34, 0), Vector3(0.5, 0.56, 0.28), shirt, true)
	mb.box(Vector3(0, 0.03, 0), Vector3(0.46, 0.14, 0.26), pants, true)
	if accessory == "antenna":
		mb.box(Vector3(0, 0.38, -0.15), Vector3(0.22, 0.18, 0.03), accent)
	_add_part(_body, mb.commit(), Vector3.ZERO)

	# Cabeça
	_head = Node3D.new()
	_head.position = Vector3(0, 0.62, 0)
	_body.add_child(_head)
	mb = MeshBuilder.new()
	mb.box(Vector3(0, 0.2, 0), Vector3(0.38, 0.38, 0.36), skin, true)
	mb.box(Vector3(0, 0.0, 0), Vector3(0.14, 0.06, 0.14), skin.darkened(0.1))
	var eye_color := Color(0.1, 0.1, 0.12)
	if accessory == "antenna":
		mb.box(Vector3(0, 0.23, -0.185), Vector3(0.3, 0.09, 0.02), Color(0.3, 0.95, 1.0))
	else:
		for ex in [-0.08, 0.08]:
			mb.box(Vector3(ex, 0.23, -0.185), Vector3(0.06, 0.08, 0.02), eye_color)
	match accessory:
		"cap":
			mb.box(Vector3(0, 0.4, 0.0), Vector3(0.42, 0.1, 0.4), accent)
			mb.box(Vector3(0, 0.37, -0.25), Vector3(0.36, 0.04, 0.2), accent.darkened(0.15))
			mb.box(Vector3(0, 0.3, 0.17), Vector3(0.4, 0.12, 0.06), hair)
		"ponytail":
			mb.box(Vector3(0, 0.39, 0.02), Vector3(0.4, 0.1, 0.4), hair)
			mb.box(Vector3(0, 0.28, 0.17), Vector3(0.4, 0.22, 0.06), hair)
			mb.box(Vector3(0, 0.2, 0.25), Vector3(0.12, 0.3, 0.12), hair)
			mb.box(Vector3(0, 0.34, 0.2), Vector3(0.14, 0.06, 0.06), accent)
		"antenna":
			mb.frustum(Vector3(0, 0.39, 0), 0.025, 0.02, 0.22, 5, Color(0.4, 0.42, 0.45))
			mb.box(Vector3(0, 0.64, 0), Vector3(0.09, 0.09, 0.09), accent)
			for ex in [-0.2, 0.2]:
				mb.box(Vector3(ex, 0.2, 0), Vector3(0.04, 0.12, 0.12), Color(0.45, 0.47, 0.5))
		"ears":
			for ex in [-0.12, 0.12]:
				mb.frustum(Vector3(ex, 0.38, 0), 0.09, 0.0, 0.18, 4, skin)
			mb.box(Vector3(0, 0.15, -0.185), Vector3(0.07, 0.05, 0.02), accent)
			mb.box(Vector3(0, 0.1, -0.182), Vector3(0.22, 0.1, 0.02), Color(1, 0.95, 0.9))
	_add_part(_head, mb.commit(), Vector3.ZERO)

	# Braços
	_arm_l = _make_arm(Vector3(-0.31, 0.56, 0), shirt, skin)
	_arm_r = _make_arm(Vector3(0.31, 0.56, 0), shirt, skin)
	# Pernas
	_leg_l = _make_leg(Vector3(-0.12, 0.0, 0), pants, shoes)
	_leg_r = _make_leg(Vector3(0.12, 0.0, 0), pants, shoes)
	if accessory == "ears":
		# rabo do gato
		var tail := MeshBuilder.new()
		tail.box(Vector3(0, 0.12, 0.25), Vector3(0.08, 0.08, 0.3), skin)
		tail.box(Vector3(0, 0.25, 0.38), Vector3(0.08, 0.26, 0.08), skin)
		_add_part(_body, tail.commit(), Vector3.ZERO)


func _make_arm(pivot: Vector3, shirt: Color, skin: Color) -> Node3D:
	var node := Node3D.new()
	node.position = pivot
	_body.add_child(node)
	var mb := MeshBuilder.new()
	mb.box(Vector3(0, -0.12, 0), Vector3(0.15, 0.26, 0.17), shirt, true)
	mb.box(Vector3(0, -0.36, 0), Vector3(0.12, 0.24, 0.13), skin, true)
	mb.box(Vector3(0, -0.52, 0), Vector3(0.14, 0.1, 0.14), skin, true)
	_add_part(node, mb.commit(), Vector3.ZERO)
	return node


func _make_leg(pivot: Vector3, pants: Color, shoes: Color) -> Node3D:
	var node := Node3D.new()
	node.position = pivot
	_body.add_child(node)
	var mb := MeshBuilder.new()
	mb.box(Vector3(0, -0.33, 0), Vector3(0.19, 0.66, 0.21), pants, true)
	mb.box(Vector3(0, -0.73, -0.05), Vector3(0.21, 0.14, 0.32), shoes, true)
	_add_part(node, mb.commit(), Vector3.ZERO)
	return node


func _add_part(parent: Node3D, mesh: Mesh, offset: Vector3) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = offset
	parent.add_child(mi)


func _process(delta: float) -> void:
	if _body == null:
		return
	_time += delta
	var k := 1.0 - exp(-BLEND_SPEED * delta)
	var leg_l := 0.0
	var leg_r := 0.0
	var arm_l := 0.0
	var arm_r := 0.0
	var arm_spread := 0.08
	var body_x := 0.0
	var body_y := HIP_HEIGHT
	var head_x := 0.0

	match pose:
		Pose.IDLE:
			arm_l = sin(_time * 1.8) * 0.06
			arm_r = -arm_l
			body_y = HIP_HEIGHT + sin(_time * 2.4) * 0.01
			head_x = sin(_time * 0.9) * 0.05
		Pose.RUN:
			_phase += delta * (run_speed * 0.55 + 4.5)
			var s := sin(_phase)
			leg_l = s * 1.0
			leg_r = -s * 1.0
			arm_l = -s * 0.9
			arm_r = s * 0.9
			arm_spread = 0.12
			body_y = HIP_HEIGHT + absf(cos(_phase)) * 0.07
			body_x = -0.18
		Pose.AIR:
			var rising := vertical_velocity > 0.0
			leg_l = 1.0 if rising else 0.5
			leg_r = -0.4 if rising else 0.1
			arm_l = 2.6
			arm_r = 2.3
			arm_spread = 0.35
			body_x = -0.12
		Pose.SLIDE:
			body_x = 1.2
			body_y = 0.38
			leg_l = 0.25
			leg_r = -0.05
			arm_l = -0.5
			arm_r = 1.6
			arm_spread = 0.4
			head_x = -0.8
		Pose.DEAD:
			_dead_time += delta
			body_x = 1.45
			var hop := maxf(sin(minf(_dead_time / 0.45, 1.0) * PI), 0.0)
			body_y = 0.25 + hop * 0.7
			arm_l = 2.2
			arm_r = 2.0
			arm_spread = 1.0
			leg_l = 0.3
			leg_r = -0.2
			head_x = -0.3

	_body.rotation.x = lerp_angle(_body.rotation.x, body_x, k)
	_body.position.y = lerpf(_body.position.y, body_y, k)
	_head.rotation.x = lerp_angle(_head.rotation.x, head_x, k)
	_leg_l.rotation.x = lerp_angle(_leg_l.rotation.x, leg_l, k)
	_leg_r.rotation.x = lerp_angle(_leg_r.rotation.x, leg_r, k)
	_arm_l.rotation.x = lerp_angle(_arm_l.rotation.x, arm_l, k)
	_arm_r.rotation.x = lerp_angle(_arm_r.rotation.x, arm_r, k)
	_arm_l.rotation.z = lerp_angle(_arm_l.rotation.z, -arm_spread, k)
	_arm_r.rotation.z = lerp_angle(_arm_r.rotation.z, arm_spread, k)
