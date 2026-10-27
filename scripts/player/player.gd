class_name Player
extends Node3D
## O bichinho: anda pulando de quadrado em quadrado (frente, trás e
## lados), guarda um comando enquanto está no ar, sobe em troncos e
## morre de formas diferentes. Não usa o motor de física: as posições
## são calculadas na grade, o que é previsível e barato.

signal hopped(direction: Vector2i)
signal landed
signal bumped

enum State { IDLE, ALIVE, DEAD }

var state: int = State.IDLE
var row := 0
var from_row := 0
var hopping := false
var invincible_time := 0.0
var model: AnimalModel

var _t := 0.0
var _from := Vector3.ZERO
var _to := Vector3.ZERO
var _drift := 0.0
var _queued := Vector2i.ZERO
var _has_queue := false
var _blob: MeshInstance3D


func _ready() -> void:
	model = AnimalModel.new()
	add_child(model)
	_blob = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.75, 0.75)
	quad.orientation = PlaneMesh.FACE_Y
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0, 0, 0, 0.3)
	quad.material = mat
	_blob.mesh = quad
	_blob.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_blob)


func set_character(def: Dictionary) -> void:
	model.build(def)


func set_blob_shadow_visible(value: bool) -> void:
	_blob.visible = value


## Coloca o bichinho em (coluna, linha) pronto para jogar ou parado no menu.
func place(col: int, new_row: int, y: float, alive: bool) -> void:
	state = State.ALIVE if alive else State.IDLE
	row = new_row
	from_row = new_row
	hopping = false
	_has_queue = false
	_drift = 0.0
	invincible_time = 0.0
	position = Vector3(col, y, -new_row)
	model.reset()
	model.face(Vector2i.UP)
	_update_blob()


func request_hop(dir: Vector2i, world: World) -> void:
	if state != State.ALIVE:
		return
	if hopping:
		_queued = dir
		_has_queue = true
		return
	_start_hop(dir, world)


func _start_hop(dir: Vector2i, world: World) -> void:
	var target_row := row
	if dir == Vector2i.UP:
		target_row += 1
	elif dir == Vector2i.DOWN:
		target_row -= 1
	var current: Lane = world.get_lane(row)
	var on_log := current != null and current.type == Lane.Type.RIVER
	var target_x := float(roundi(position.x) + dir.x)
	_drift = 0.0
	if on_log and dir.x != 0:
		# De lado em cima do tronco: o pulo acompanha o tronco.
		target_x = position.x + dir.x
		var v := current.platform_velocity_at(position.x)
		_drift = 0.0 if is_nan(v) else v
	model.face(dir)
	if world.is_blocked(target_row, roundi(target_x)):
		model.bump()
		bumped.emit()
		return
	from_row = row
	row = target_row
	_from = position
	_to = Vector3(target_x, world.surface_y(target_row), -target_row)
	_t = 0.0
	hopping = true
	model.hop_t = 0.0
	hopped.emit(dir)


func update(delta: float, world: World) -> void:
	if invincible_time > 0.0:
		invincible_time -= delta
		model.visible = invincible_time <= 0.0 or fmod(invincible_time, 0.2) > 0.1
	if state != State.ALIVE or not hopping:
		return
	_t += delta / GameConfig.HOP_TIME
	_from.x += _drift * delta
	_to.x += _drift * delta
	if _t >= 1.0:
		hopping = false
		position = _to
		model.hop_t = -1.0
		model.land()
		_update_blob()
		landed.emit()
		if _has_queue:
			_has_queue = false
			_start_hop(_queued, world)
		return
	var p := _from.lerp(_to, _t)
	p.y += sin(PI * _t) * GameConfig.HOP_HEIGHT
	position = p
	model.hop_t = _t
	_update_blob()


## Linha em que o corpo está "de verdade" durante o pulo (para colisões).
func visual_row() -> int:
	return from_row if hopping and _t < 0.5 else row


func is_grounded() -> bool:
	return not hopping


func current_column() -> int:
	return roundi(position.x)


## Movimento lateral do tronco em que está em cima.
func ride(dx: float) -> void:
	position.x += dx


func die(cause: String) -> void:
	state = State.DEAD
	hopping = false
	_has_queue = false
	model.visible = true
	model.die(cause)


func revive_at(col: int, new_row: int, y: float) -> void:
	place(col, new_row, y, true)
	invincible_time = GameConfig.REVIVE_INVINCIBILITY


func _update_blob() -> void:
	var ground := lerpf(_from.y, _to.y, _t) if hopping else position.y
	_blob.position = Vector3(0, ground - position.y + 0.02, 0)
	var s := clampf(1.0 - (position.y - ground) * 0.6, 0.5, 1.0)
	_blob.scale = Vector3(s, 1.0, s)
