class_name Lane
extends Node3D
## Uma linha do mundo (1 m de profundidade): grama, rua, rio ou trilho.
## Os objetos que se movem (carros, troncos, trem) andam em "loop":
## ao sair por um lado, voltam pelo outro mantendo o espaçamento.
## Os nós são reaproveitados quando a linha sai de cena (pooling).

enum Type { GRASS, ROAD, RIVER, RAIL }

const HALF_SPAN := 15.0
const LOOP := HALF_SPAN * 2.0
const RIVER_STAND_Y := 0.06
const TRAIN_SPEED := 32.0
const TRAIN_WARNING := 1.6

signal train_warning(lane: Lane)

var type: int = Type.GRASS
var row := 0
var direction := 1.0
var speed := 0.0
var blocked := PackedInt32Array()
var is_lily := false
var coin_col := 0
var has_coin := false

var _ground: MeshInstance3D
var _decor: MeshInstance3D
var _coin: MeshInstance3D
var _movers: Array[MeshInstance3D] = []
var _halves := PackedFloat32Array()
var _active := 0
var _signal: MeshInstance3D
var _light: MeshInstance3D
var _train_state := 0
var _train_timer := 0.0
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_ground = MeshInstance3D.new()
	_ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ground)
	_decor = MeshInstance3D.new()
	add_child(_decor)
	_coin = MeshInstance3D.new()
	_coin.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_coin)


func _reset_common(new_row: int, new_type: int) -> void:
	row = new_row
	type = new_type
	position = Vector3(0, 0, -new_row)
	direction = 1.0
	speed = 0.0
	blocked = PackedInt32Array()
	is_lily = false
	has_coin = false
	_coin.visible = false
	_decor.visible = false
	for m in _movers:
		m.visible = false
	_active = 0
	if _signal != null:
		_signal.visible = false
		_light.visible = false
	_rng.randomize()


# --------------------------------------------------------------- Montagem

func setup_grass(new_row: int, variant: Dictionary, parity: int) -> void:
	_reset_common(new_row, Type.GRASS)
	_ground.mesh = ModelFactory.grass(parity)
	_decor.mesh = variant["mesh"]
	_decor.visible = true
	blocked = variant["blocked"]


func setup_road(new_row: int, dashed: bool, dir: float, spd: float, specs: Array, min_gap: float, max_gap: float) -> void:
	_reset_common(new_row, Type.ROAD)
	_ground.mesh = ModelFactory.road(dashed)
	direction = dir
	speed = spd
	_layout(specs, min_gap, max_gap)


func setup_river_logs(new_row: int, dir: float, spd: float, specs: Array, min_gap: float, max_gap: float) -> void:
	_reset_common(new_row, Type.RIVER)
	_ground.mesh = ModelFactory.river(new_row % 2)
	direction = dir
	speed = spd
	_layout(specs, min_gap, max_gap)


func setup_river_lily(new_row: int, columns: Array) -> void:
	_reset_common(new_row, Type.RIVER)
	_ground.mesh = ModelFactory.river(new_row % 2)
	is_lily = true
	for c in columns:
		var m := _mover(_active)
		m.mesh = ModelFactory.lily()
		m.position = Vector3(c, 0, 0)
		m.rotation.y = _rng.randf() * TAU
		_halves[_active] = 0.4
		_active += 1


func setup_rail(new_row: int, dir: float) -> void:
	_reset_common(new_row, Type.RAIL)
	_ground.mesh = ModelFactory.rail()
	direction = dir
	speed = TRAIN_SPEED
	if _signal == null:
		_signal = MeshInstance3D.new()
		_signal.mesh = ModelFactory.signal_pole()
		add_child(_signal)
		_light = MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.18, 0.18, 0.06)
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(1.0, 0.15, 0.1)
		box.material = mat
		_light.mesh = box
		_light.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(_light)
	_signal.position = Vector3(-(GameConfig.COLUMNS_HALF + 0.9), 0, -0.42)
	_light.position = _signal.position + Vector3(0, 1.5, 0.1)
	_signal.visible = true
	var train := _mover(0)
	train.mesh = ModelFactory.train()
	train.rotation.y = 0.0 if dir > 0.0 else PI
	_halves[0] = 7.8
	train.visible = false
	_active = 0
	_train_state = 0
	_train_timer = _rng.randf_range(1.5, 5.0)


func place_coin(col: int) -> void:
	coin_col = col
	has_coin = true
	_coin.mesh = ModelFactory.coin()
	_coin.position = Vector3(col, 0.5, 0)
	_coin.scale = Vector3.ONE
	_coin.visible = true


func take_coin(col: int) -> bool:
	if not has_coin or col != coin_col:
		return false
	has_coin = false
	_coin.visible = false
	return true


## Distribui os veículos/troncos no loop: cada espaço tem pelo menos
## min_gap, e a sobra é repartida aleatoriamente.
func _layout(specs: Array, min_gap: float, _max_gap: float) -> void:
	var total := 0.0
	for s in specs:
		total += float(s["half"]) * 2.0
	var leftover := maxf(LOOP - total - min_gap * specs.size(), 0.0)
	var weights := PackedFloat32Array()
	var weight_sum := 0.0
	for s in specs:
		var w := _rng.randf_range(0.2, 1.0)
		weights.append(w)
		weight_sum += w
	var u := _rng.randf() * LOOP
	for i in specs.size():
		var half: float = specs[i]["half"]
		var m := _mover(i)
		m.mesh = specs[i]["mesh"]
		m.rotation.y = 0.0 if direction > 0.0 else PI
		m.position = Vector3(wrapf(u + half, -HALF_SPAN, HALF_SPAN), 0, 0)
		m.visible = true
		_halves[i] = half
		u += half * 2.0 + min_gap + leftover * weights[i] / weight_sum
	_active = specs.size()


func _mover(i: int) -> MeshInstance3D:
	while _movers.size() <= i:
		var m := MeshInstance3D.new()
		m.visible = false
		add_child(m)
		_movers.append(m)
		_halves.append(0.5)
	var mover := _movers[i]
	mover.visible = true
	mover.rotation = Vector3.ZERO
	return mover


# --------------------------------------------------------------- Atualização

func update(delta: float) -> void:
	if _coin.visible:
		_coin.rotation.y += delta * 3.0
	if type == Type.RAIL:
		_update_train(delta)
		return
	if speed == 0.0:
		return
	var dx := direction * speed * delta
	for i in _active:
		var m := _movers[i]
		var x := m.position.x + dx
		if x > HALF_SPAN:
			x -= LOOP
		elif x < -HALF_SPAN:
			x += LOOP
		m.position.x = x


func _update_train(delta: float) -> void:
	var train := _movers[0]
	match _train_state:
		0:
			_train_timer -= delta
			if _train_timer <= 0.0:
				_train_state = 1
				_train_timer = TRAIN_WARNING
				train_warning.emit(self)
		1:
			_train_timer -= delta
			_light.visible = fmod(_train_timer, 0.3) > 0.15
			if _train_timer <= 0.0:
				_train_state = 2
				_light.visible = true
				train.position.x = -direction * (HALF_SPAN + _halves[0])
				train.visible = true
				_active = 1
		2:
			train.position.x += direction * speed * delta
			if direction * train.position.x > HALF_SPAN + _halves[0]:
				_train_state = 0
				_train_timer = _rng.randf_range(2.5, 6.0)
				train.visible = false
				_light.visible = false
				_active = 0


# ---------------------------------------------------------------- Consultas

func surface_y() -> float:
	match type:
		Type.ROAD:
			return -0.08
		Type.RIVER:
			return RIVER_STAND_Y
		Type.RAIL:
			return -0.04
	return 0.0


func is_dangerous() -> bool:
	return type == Type.ROAD or type == Type.RAIL


## Algum veículo encosta na posição x?
func hit_test(px: float, half_w: float) -> bool:
	for i in _active:
		if absf(_movers[i].position.x - px) < _halves[i] + half_w:
			return true
	return false


## Velocidade da plataforma (tronco) sob x, ou NAN se for água.
func platform_velocity_at(px: float) -> float:
	for i in _active:
		if absf(_movers[i].position.x - px) < _halves[i] + 0.12:
			return 0.0 if is_lily else direction * speed
	return NAN


## Previsões usadas pelo teste automático (robô).
func predict_hit(px: float, half_w: float, t: float) -> bool:
	if type == Type.RAIL:
		if _train_state != 0 or _train_timer < t + 0.4:
			return true
		return false
	for i in _active:
		var x := _movers[i].position.x + direction * speed * t
		x = wrapf(x, -HALF_SPAN, HALF_SPAN)
		if absf(x - px) < _halves[i] + half_w:
			return true
	return false


func predict_platform(px: float, t: float, margin: float) -> bool:
	for i in _active:
		var x := _movers[i].position.x + (0.0 if is_lily else direction * speed * t)
		x = wrapf(x, -HALF_SPAN, HALF_SPAN)
		if absf(x - px) < _halves[i] - margin:
			return true
	return false
