class_name Obstacle
extends MeshInstance3D
## Um obstáculo reaproveitável (pooling). A colisão é uma caixa simples
## calculada à mão: meia largura (x), meio comprimento (z) e faixa de altura.

enum Kind { CAR, MOVING_CAR, BUS, BARRIER, CONES, OVERHEAD }

var kind: int = Kind.CAR
var lane := 1
var half_extents := Vector3.ONE
var min_y := 0.0
var max_y := 1.0
## Velocidade em direção ao jogador (m/s). Zero para obstáculos parados.
var speed := 0.0


func configure(new_kind: int, new_mesh: Mesh, new_lane: int, along: float) -> void:
	kind = new_kind
	mesh = new_mesh
	lane = new_lane
	speed = 0.0
	min_y = 0.0
	match kind:
		Kind.CAR, Kind.MOVING_CAR:
			half_extents = Vector3(0.92, 0.0, 2.0)
			max_y = 1.55
		Kind.BUS:
			half_extents = Vector3(1.17, 0.0, 4.5)
			max_y = 3.1
		Kind.BARRIER:
			half_extents = Vector3(1.2, 0.0, 0.22)
			max_y = 0.85
		Kind.CONES:
			half_extents = Vector3(1.1, 0.0, 0.3)
			max_y = 0.75
		Kind.OVERHEAD:
			half_extents = Vector3(1.25, 0.0, 0.22)
			min_y = 1.1
			max_y = 3.0
	rotation = Vector3(0.0, PI if kind == Kind.MOVING_CAR else 0.0, 0.0)
	position = Vector3(GameConfig.lane_x(lane), 0.0, -along)
	visible = true


func get_along() -> float:
	return -position.z
