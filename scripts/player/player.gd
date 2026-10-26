class_name Player
extends Node3D
## Lógica do corredor: avanço automático, troca de faixa, pulo, deslize,
## morte e invencibilidade após continuar. Não usa o motor de física:
## a posição é calculada diretamente, o que é previsível e barato.

signal jumped
signal slid
signal landed
signal lane_changed(lane: int)

enum State { IDLE, RUNNING, DEAD }

var state: int = State.IDLE
var lane := 1
var previous_lane := 1
var distance := 0.0
var height := 0.0
var vertical_velocity := 0.0
var is_grounded := true
var is_sliding := false
var invincible_time := 0.0

var model: CharacterModel
var _blob: MeshInstance3D
var _x := 0.0
var _slide_time := 0.0
var _slide_queued := false
var _death_push := 0.0


func _ready() -> void:
	model = CharacterModel.new()
	add_child(model)
	_blob = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.9, 0.9)
	quad.orientation = PlaneMesh.FACE_Y
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0, 0, 0, 0.35)
	quad.material = mat
	_blob.mesh = quad
	_blob.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_blob)


func set_character(def: Dictionary) -> void:
	model.build(def)


func set_blob_shadow_visible(value: bool) -> void:
	_blob.visible = value


func go_idle() -> void:
	state = State.IDLE
	_reset_motion()
	model.pose = CharacterModel.Pose.IDLE
	model.rotation = Vector3.ZERO
	_apply_position()


func reset_run() -> void:
	_reset_motion()
	state = State.RUNNING
	model.pose = CharacterModel.Pose.RUN
	_apply_position()


func _reset_motion() -> void:
	lane = 1
	previous_lane = 1
	distance = 0.0
	height = 0.0
	vertical_velocity = 0.0
	is_grounded = true
	is_sliding = false
	invincible_time = 0.0
	_x = 0.0
	_slide_time = 0.0
	_slide_queued = false
	model.visible = true


func change_lane(direction: int) -> bool:
	if state != State.RUNNING:
		return false
	var target := clampi(lane + direction, 0, GameConfig.LANE_COUNT - 1)
	if target == lane:
		return false
	previous_lane = lane
	lane = target
	lane_changed.emit(lane)
	return true


func jump() -> bool:
	if state != State.RUNNING or not is_grounded:
		return false
	is_sliding = false
	_slide_queued = false
	vertical_velocity = GameConfig.JUMP_VELOCITY
	is_grounded = false
	jumped.emit()
	return true


func slide() -> bool:
	if state != State.RUNNING:
		return false
	if not is_grounded:
		# No ar: desce rápido e desliza ao tocar o chão.
		vertical_velocity = minf(vertical_velocity, GameConfig.FAST_FALL_VELOCITY)
		_slide_queued = true
		return true
	if is_sliding:
		_slide_time = GameConfig.SLIDE_DURATION
		return false
	_start_slide()
	return true


func _start_slide() -> void:
	is_sliding = true
	_slide_time = GameConfig.SLIDE_DURATION
	slid.emit()


func is_changing_lane() -> bool:
	return absf(_x - GameConfig.lane_x(lane)) > 0.05


func get_top() -> float:
	return height + (GameConfig.PLAYER_SLIDE_HEIGHT if is_sliding else GameConfig.PLAYER_HEIGHT)


func update_run(delta: float, speed: float) -> void:
	distance += speed * delta
	var target_x := GameConfig.lane_x(lane)
	_x = move_toward(_x, target_x, GameConfig.LANE_CHANGE_SPEED * delta)

	if not is_grounded:
		vertical_velocity -= GameConfig.GRAVITY * delta
		height += vertical_velocity * delta
		if height <= 0.0:
			height = 0.0
			vertical_velocity = 0.0
			is_grounded = true
			landed.emit()
			if _slide_queued:
				_slide_queued = false
				_start_slide()

	if is_sliding:
		_slide_time -= delta
		if _slide_time <= 0.0:
			is_sliding = false

	if invincible_time > 0.0:
		invincible_time -= delta
		model.visible = invincible_time <= 0.0 or fmod(invincible_time, 0.2) > 0.1

	model.run_speed = speed
	model.vertical_velocity = vertical_velocity
	if is_sliding:
		model.pose = CharacterModel.Pose.SLIDE
	elif not is_grounded:
		model.pose = CharacterModel.Pose.AIR
	else:
		model.pose = CharacterModel.Pose.RUN
	model.rotation.y = clampf(-(target_x - _x) * 0.3, -0.4, 0.4)
	_apply_position()


func update_dead(delta: float) -> void:
	distance -= _death_push * delta
	_death_push = move_toward(_death_push, 0.0, 10.0 * delta)
	if height > 0.0:
		vertical_velocity -= GameConfig.GRAVITY * delta
		height = maxf(height + vertical_velocity * delta, 0.0)
	model.rotation.y = lerp_angle(model.rotation.y, 0.0, 1.0 - exp(-8.0 * delta))
	_apply_position()


func die() -> void:
	state = State.DEAD
	is_sliding = false
	_slide_queued = false
	vertical_velocity = minf(vertical_velocity, 0.0)
	_death_push = 5.0
	model.visible = true
	model.pose = CharacterModel.Pose.DEAD


## Batida de raspão na lateral: volta para a faixa anterior.
func bounce_back() -> void:
	var back := previous_lane
	previous_lane = lane
	lane = back


func revive() -> void:
	state = State.RUNNING
	height = 0.0
	vertical_velocity = 0.0
	is_grounded = true
	is_sliding = false
	_x = GameConfig.lane_x(lane)
	invincible_time = GameConfig.REVIVE_INVINCIBILITY
	model.pose = CharacterModel.Pose.RUN
	_apply_position()


func _apply_position() -> void:
	position = Vector3(_x, height, -distance)
	_blob.position = Vector3(0, -height + 0.03, 0)
	var s := clampf(1.0 - height * 0.3, 0.4, 1.0)
	_blob.scale = Vector3(s, 1.0, s)
