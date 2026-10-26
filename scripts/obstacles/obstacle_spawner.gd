class_name ObstacleSpawner
extends Node3D
## Gera fileiras de obstáculos e moedas à frente do jogador, com
## dificuldade progressiva, e reaproveita tudo (pooling).
##
## Regras de justiça:
## - Toda fileira tem pelo menos uma faixa passável (livre, pular ou deslizar).
## - O espaço entre fileiras cresce com a velocidade (tempo de reação).
## - Carros em movimento são calculados para cruzar o jogador exatamente
##   na posição da fileira, e a faixa deles fica livre até lá.

enum Slot { EMPTY, CAR, MOVING_CAR, BUS, BARRIER, CONES, OVERHEAD }

const COIN_HEIGHT := 0.9
const COIN_SPACING := 2.4
const COLLECT_ANIM_TIME := 0.22

var _rng := RandomNumberGenerator.new()
var _free_obstacles := {}
var _active: Array[Obstacle] = []
var _free_coins: Array[MeshInstance3D] = []
var _active_coins: Array[MeshInstance3D] = []
var _collecting: Array[MeshInstance3D] = []
var _collect_time := PackedFloat32Array()
var _next_row := 0.0
var _rows_generated := 0
var _lane_clear_until := PackedFloat32Array([0.0, 0.0, 0.0])
var _coin_spin := 0.0


func _ready() -> void:
	_rng.randomize()
	for k in Obstacle.Kind.values():
		_free_obstacles[k] = []
	for i in 6:
		for k in [Obstacle.Kind.CAR, Obstacle.Kind.BARRIER, Obstacle.Kind.OVERHEAD]:
			_release(_create_obstacle(k))
	for i in 60:
		_free_coins.append(_create_coin())


func reset() -> void:
	for o in _active:
		_release(o)
	_active.clear()
	for c in _active_coins:
		_release_coin(c)
	_active_coins.clear()
	for c in _collecting:
		_release_coin(c)
	_collecting.clear()
	_collect_time.clear()
	_next_row = GameConfig.FIRST_ROW_DISTANCE
	_rows_generated = 0
	_lane_clear_until = PackedFloat32Array([0.0, 0.0, 0.0])


func update(delta: float, player_along: float, speed: float) -> void:
	while _next_row < player_along + GameConfig.SPAWN_AHEAD:
		_next_row += _generate_row(_next_row, player_along, speed)

	var limit := player_along - GameConfig.DESPAWN_BEHIND
	var i := _active.size() - 1
	while i >= 0:
		var o := _active[i]
		if o.speed != 0.0:
			o.position.z += o.speed * delta
		if o.get_along() + o.half_extents.z < limit:
			_release(o)
			_active[i] = _active[_active.size() - 1]
			_active.pop_back()
		i -= 1

	_coin_spin = wrapf(_coin_spin + delta * 3.2, 0.0, TAU)
	i = _active_coins.size() - 1
	while i >= 0:
		var c := _active_coins[i]
		c.rotation.y = _coin_spin
		if -c.position.z < limit:
			_release_coin(c)
			_active_coins[i] = _active_coins[_active_coins.size() - 1]
			_active_coins.pop_back()
		i -= 1

	i = _collecting.size() - 1
	while i >= 0:
		_collect_time[i] += delta
		var t := _collect_time[i] / COLLECT_ANIM_TIME
		var c := _collecting[i]
		if t >= 1.0:
			_release_coin(c)
			_collecting[i] = _collecting[_collecting.size() - 1]
			_collecting.pop_back()
			_collect_time[i] = _collect_time[_collect_time.size() - 1]
			_collect_time.resize(_collect_time.size() - 1)
		else:
			c.position.y += delta * 6.0
			c.position.z -= speed * delta
			c.rotation.y += delta * 20.0
			c.scale = Vector3.ONE * (1.0 - t * 0.8)
		i -= 1


## Retorna o primeiro obstáculo que encosta na caixa do jogador (ou null).
func find_collision(px: float, bottom: float, top: float, along: float) -> Obstacle:
	for o in _active:
		if absf(o.get_along() - along) > o.half_extents.z + GameConfig.PLAYER_HALF_DEPTH:
			continue
		if absf(o.position.x - px) > o.half_extents.x + GameConfig.PLAYER_HALF_WIDTH:
			continue
		if top <= o.min_y or bottom >= o.max_y:
			continue
		return o
	return null


## Recolhe as moedas que o jogador tocou. Cada moeda sai da lista
## ativa no mesmo instante, então nunca é contada duas vezes.
func collect_coins(px: float, bottom: float, along: float) -> int:
	var count := 0
	var center_y := bottom + 0.8
	var i := _active_coins.size() - 1
	while i >= 0:
		var c := _active_coins[i]
		if absf(-c.position.z - along) < 0.9 and absf(c.position.x - px) < 0.95 and absf(c.position.y - center_y) < 1.1:
			_active_coins[i] = _active_coins[_active_coins.size() - 1]
			_active_coins.pop_back()
			_collecting.append(c)
			_collect_time.append(0.0)
			count += 1
		i -= 1
	return count


## Usado ao continuar a partida: limpa o caminho à frente.
func clear_for_revive(along: float) -> void:
	var i := _active.size() - 1
	while i >= 0:
		var o := _active[i]
		var a := o.get_along()
		var near := a > along - 6.0 and a < along + GameConfig.REVIVE_CLEAR_DISTANCE
		if near or (o.speed > 0.0 and a > along - 6.0):
			_release(o)
			_active[i] = _active[_active.size() - 1]
			_active.pop_back()
		i -= 1
	for l in GameConfig.LANE_COUNT:
		_lane_clear_until[l] = 0.0


func get_active_count() -> int:
	return _active.size()


# ----------------------------------------------------------------- Geração

func _generate_row(row: float, player_along: float, speed: float) -> float:
	var d := GameConfig.difficulty_for_distance(row)
	var slots := [Slot.EMPTY, Slot.EMPTY, Slot.EMPTY]
	var reserved := [false, false, false]
	for l in 3:
		reserved[l] = row < _lane_clear_until[l]

	var count := 1
	if _rows_generated >= 3:
		if _rng.randf() < 0.2 + d * 0.5:
			count = 2
		if d > 0.3 and _rng.randf() < 0.1 + d * 0.25:
			count = 3

	if _rows_generated >= 4 and d > 0.2 and _rng.randf() < 0.07:
		# Fileira inteira: obriga a pular ou deslizar.
		var wall: int = Slot.OVERHEAD if _rng.randf() < 0.5 else (Slot.BARRIER if _rng.randf() < 0.6 else Slot.CONES)
		for l in 3:
			if not reserved[l]:
				slots[l] = wall
	else:
		var lanes := [0, 1, 2]
		for a in range(2, 0, -1):
			var b := _rng.randi_range(0, a)
			var tmp = lanes[a]
			lanes[a] = lanes[b]
			lanes[b] = tmp
		var placed := 0
		var hard := 0
		for l in lanes:
			if placed >= count:
				break
			if reserved[l]:
				continue
			var slot := _pick_slot(d)
			if _is_hard(slot) and hard >= 2:
				slot = Slot.BARRIER if _rng.randf() < 0.5 else Slot.OVERHEAD
			if _is_hard(slot):
				hard += 1
			slots[l] = slot
			placed += 1

	var gap := GameConfig.speed_for_distance(row) * lerpf(1.55, 1.0, d) + 5.0 + _rng.randf_range(0.0, 6.0)
	for l in 3:
		var slot: int = slots[l]
		if slot == Slot.EMPTY:
			continue
		match slot:
			Slot.CAR:
				_spawn(Obstacle.Kind.CAR, l, row + 2.0)
			Slot.MOVING_CAR:
				_spawn_moving_car(l, row + 2.0, player_along, speed)
			Slot.BUS:
				_spawn(Obstacle.Kind.BUS, l, row + 4.5)
				gap = maxf(gap, 9.0 + GameConfig.speed_for_distance(row) * 0.9 + 4.0)
			Slot.BARRIER:
				_spawn(Obstacle.Kind.BARRIER, l, row)
			Slot.CONES:
				_spawn(Obstacle.Kind.CONES, l, row)
			Slot.OVERHEAD:
				_spawn(Obstacle.Kind.OVERHEAD, l, row)

	_place_coins(row, gap, slots, reserved)
	_rows_generated += 1
	return gap


func _pick_slot(d: float) -> int:
	var options := [Slot.CAR, Slot.BARRIER, Slot.CONES]
	var weights := [1.0, 0.6, 0.35]
	if _rows_generated >= 2:
		options.append(Slot.OVERHEAD)
		weights.append(0.55)
	if d > 0.12:
		options.append(Slot.MOVING_CAR)
		weights.append(0.25 + d * 0.6)
	if d > 0.2:
		options.append(Slot.BUS)
		weights.append(0.3)
	var total := 0.0
	for w in weights:
		total += w
	var r := _rng.randf() * total
	for i in options.size():
		r -= weights[i]
		if r <= 0.0:
			return options[i]
	return options[0]


func _is_hard(slot: int) -> bool:
	return slot == Slot.CAR or slot == Slot.MOVING_CAR or slot == Slot.BUS


func _spawn(kind: int, lane: int, along: float) -> Obstacle:
	var o := _acquire(kind)
	var mesh: Mesh
	match kind:
		Obstacle.Kind.CAR, Obstacle.Kind.MOVING_CAR:
			mesh = ModelFactory.car(_rng.randi() % ModelFactory.CAR_COLORS.size())
		Obstacle.Kind.BUS:
			mesh = ModelFactory.bus(_rng.randi() % ModelFactory.BUS_COLORS.size())
		Obstacle.Kind.BARRIER:
			mesh = ModelFactory.barrier()
		Obstacle.Kind.CONES:
			mesh = ModelFactory.cones()
		_:
			mesh = ModelFactory.overhead()
	o.configure(kind, mesh, lane, along)
	_active.append(o)
	return o


func _spawn_moving_car(lane: int, meet_along: float, player_along: float, speed: float) -> void:
	var car_speed := _rng.randf_range(4.0, 7.0)
	var time_to_meet := maxf(meet_along - player_along, 1.0) / maxf(speed, 1.0)
	var start := meet_along + car_speed * time_to_meet
	var o := _spawn(Obstacle.Kind.MOVING_CAR, lane, start)
	o.speed = car_speed
	_lane_clear_until[lane] = start + 6.0


func _place_coins(row: float, gap: float, slots: Array, reserved: Array) -> void:
	if _rng.randf() > 0.75:
		return
	var free_lanes := []
	var jump_lanes := []
	var slide_lanes := []
	for l in 3:
		if reserved[l]:
			continue
		match slots[l]:
			Slot.EMPTY:
				free_lanes.append(l)
			Slot.BARRIER, Slot.CONES:
				jump_lanes.append(l)
			Slot.OVERHEAD:
				slide_lanes.append(l)
	if not jump_lanes.is_empty() and _rng.randf() < 0.35:
		var lane: int = jump_lanes[_rng.randi() % jump_lanes.size()]
		for i in 5:
			var u := (i - 2) / 2.0
			_add_coin(lane, row + u * 3.6, COIN_HEIGHT + 1.25 * (1.0 - u * u))
	elif not slide_lanes.is_empty() and _rng.randf() < 0.3:
		var lane: int = slide_lanes[_rng.randi() % slide_lanes.size()]
		for i in 3:
			_add_coin(lane, row - 2.4 + i * 2.4, 0.5)
	elif not free_lanes.is_empty():
		var lane: int = free_lanes[_rng.randi() % free_lanes.size()]
		var n := clampi(int((gap - 7.0) / COIN_SPACING), 2, 8)
		for i in n:
			_add_coin(lane, row + 2.0 + i * COIN_SPACING, COIN_HEIGHT)


# ------------------------------------------------------------------ Pooling

func _create_obstacle(kind: int) -> Obstacle:
	var o := Obstacle.new()
	o.kind = kind
	add_child(o)
	return o


func _acquire(kind: int) -> Obstacle:
	var pool: Array = _free_obstacles[kind]
	if pool.is_empty():
		return _create_obstacle(kind)
	return pool.pop_back()


func _release(o: Obstacle) -> void:
	o.visible = false
	o.speed = 0.0
	_free_obstacles[o.kind].append(o)


func _create_coin() -> MeshInstance3D:
	var c := MeshInstance3D.new()
	c.mesh = ModelFactory.coin()
	c.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	c.visible = false
	add_child(c)
	return c


func _add_coin(lane: int, along: float, y: float) -> void:
	var c: MeshInstance3D = _free_coins.pop_back() if not _free_coins.is_empty() else _create_coin()
	c.position = Vector3(GameConfig.lane_x(lane), y, -along)
	c.scale = Vector3.ONE
	c.rotation.y = _coin_spin
	c.visible = true
	_active_coins.append(c)


func _release_coin(c: MeshInstance3D) -> void:
	c.visible = false
	_free_coins.append(c)
