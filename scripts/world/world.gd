class_name World
extends Node3D
## Gera o mundo infinito, linha por linha, à frente do jogador e
## recicla as linhas que ficaram para trás.
##
## Regras de justiça:
## - Linhas de grama vizinhas sempre têm pelo menos uma coluna livre em comum.
## - Carros sempre deixam espaço suficiente para passar entre eles.
## - O primeiro trecho é seguro, e a dificuldade cresce aos poucos.

signal train_warning(row: int)

var _lanes := {}
var _pool: Array[Lane] = []
var _min_row := 0
var _next_row := 0
var _plan: Array = []
var _rng := RandomNumberGenerator.new()
var _prev_type := -1
var _prev_open := PackedInt32Array()
var _prev_dir := 1.0
var _prev_lily := false


func _ready() -> void:
	_rng.randomize()


func reset() -> void:
	for lane in _lanes.values():
		_recycle(lane)
	_lanes.clear()
	_plan.clear()
	_prev_type = -1
	_prev_open = PackedInt32Array()
	_prev_lily = false
	_min_row = -GameConfig.ROWS_BEHIND
	_next_row = _min_row
	_ensure(GameConfig.ROWS_AHEAD)


func update(delta: float, focus_row: int) -> void:
	_ensure(focus_row + GameConfig.ROWS_AHEAD)
	while _min_row < focus_row - GameConfig.ROWS_BEHIND:
		if _lanes.has(_min_row):
			_recycle(_lanes[_min_row])
			_lanes.erase(_min_row)
		_min_row += 1
	for r in range(_min_row, _next_row):
		var lane: Lane = _lanes.get(r)
		if lane != null:
			lane.update(delta)


# ---------------------------------------------------------------- Consultas

func get_lane(row: int) -> Lane:
	return _lanes.get(row)


func is_blocked(row: int, col: int) -> bool:
	if not GameConfig.is_playable_column(col):
		return true
	var lane: Lane = _lanes.get(row)
	if lane == null:
		return true
	return lane.type == Lane.Type.GRASS and lane.blocked.has(col)


func surface_y(row: int) -> float:
	var lane: Lane = _lanes.get(row)
	return 0.0 if lane == null else lane.surface_y()


func take_coin(row: int, col: int) -> bool:
	var lane: Lane = _lanes.get(row)
	return lane != null and lane.take_coin(col)


## Linha de grama segura mais próxima (para continuar após um anúncio).
func find_safe_spot(from_row: int) -> Vector2i:
	for r in range(from_row, _min_row, -1):
		var lane: Lane = _lanes.get(r)
		if lane == null or lane.type != Lane.Type.GRASS:
			continue
		for offset in [0, 1, -1, 2, -2, 3, -3, 4, -4]:
			if not lane.blocked.has(offset):
				return Vector2i(offset, r)
	return Vector2i(0, from_row)


# ---------------------------------------------------------------- Geração

func _ensure(up_to: int) -> void:
	while _next_row <= up_to:
		_generate(_next_row)
		_next_row += 1


func _acquire() -> Lane:
	if _pool.is_empty():
		var lane := Lane.new()
		lane.train_warning.connect(func(l: Lane): train_warning.emit(l.row))
		add_child(lane)
		return lane
	var reused: Lane = _pool.pop_back()
	reused.visible = true
	return reused


func _recycle(lane: Lane) -> void:
	lane.visible = false
	_pool.append(lane)


func _next_type(row: int) -> int:
	if row <= GameConfig.START_SAFE_ROWS:
		return Lane.Type.GRASS
	if _plan.is_empty():
		_plan_block(row)
	return _plan.pop_front()


func _plan_block(row: int) -> void:
	var d := GameConfig.difficulty_for_row(row)
	var options := [Lane.Type.ROAD]
	var weights := [1.0]
	if row > 10:
		options.append(Lane.Type.RIVER)
		weights.append(0.55 + d * 0.2)
	if row > 18:
		options.append(Lane.Type.RAIL)
		weights.append(0.3)
	var total := 0.0
	for w in weights:
		total += w
	var pick := _rng.randf() * total
	var hazard: int = options[0]
	for i in options.size():
		pick -= weights[i]
		if pick <= 0.0:
			hazard = options[i]
			break
	var count := 1
	match hazard:
		Lane.Type.ROAD:
			count = _rng.randi_range(1, 2 + int(d * 3.0))
		Lane.Type.RIVER:
			count = _rng.randi_range(1, mini(2 + int(d * 2.0), 4))
		Lane.Type.RAIL:
			count = _rng.randi_range(1, 1 + int(d * 1.5))
	for i in count:
		_plan.append(hazard)
	var grass := _rng.randi_range(1, 2 if d < 0.5 else 1)
	if d > 0.35 and _rng.randf() < 0.25:
		grass = 0
	for i in grass:
		_plan.append(Lane.Type.GRASS)


func _generate(row: int) -> void:
	var lane := _acquire()
	var type := _next_type(row)
	var d := GameConfig.difficulty_for_row(row)
	match type:
		Lane.Type.GRASS:
			_setup_grass(lane, row)
		Lane.Type.ROAD:
			_setup_road(lane, row, d)
		Lane.Type.RIVER:
			_setup_river(lane, row, d)
		Lane.Type.RAIL:
			var dir := 1.0 if _rng.randf() < 0.5 else -1.0
			lane.setup_rail(row, dir)
	if type != Lane.Type.GRASS:
		_prev_open = PackedInt32Array()
	if type != Lane.Type.RIVER:
		_prev_lily = false
	_prev_type = type
	_lanes[row] = lane


func _setup_grass(lane: Lane, row: int) -> void:
	var variant_index := 0
	if row < -2:
		variant_index = 1
	elif row > GameConfig.START_SAFE_ROWS:
		variant_index = _rng.randi_range(2, ModelFactory.grass_variant_count() - 1)
		if _rng.randf() < 0.2:
			variant_index = 0
		for attempt in 8:
			if _compatible(ModelFactory.grass_variant(variant_index)["blocked"]):
				break
			variant_index = _rng.randi_range(2, ModelFactory.grass_variant_count() - 1)
		if not _compatible(ModelFactory.grass_variant(variant_index)["blocked"]):
			variant_index = 0
	var variant := ModelFactory.grass_variant(variant_index)
	lane.setup_grass(row, variant, posmod(row, 2))
	var open := PackedInt32Array()
	for c in range(-GameConfig.COLUMNS_HALF, GameConfig.COLUMNS_HALF + 1):
		if not lane.blocked.has(c):
			open.append(c)
	_prev_open = open
	if row > 1 and not open.is_empty() and _rng.randf() < 0.22:
		lane.place_coin(open[_rng.randi() % open.size()])


func _compatible(blocked: PackedInt32Array) -> bool:
	if _prev_type != Lane.Type.GRASS or _prev_open.is_empty():
		return true
	for c in _prev_open:
		if not blocked.has(c):
			return true
	return false


func _setup_road(lane: Lane, row: int, d: float) -> void:
	var dir := -_prev_dir if _rng.randf() < 0.7 else _prev_dir
	_prev_dir = dir
	var spd := lerpf(1.8, 5.0, d) * _rng.randf_range(0.8, 1.2)
	var truck_lane := _rng.randf() < 0.3
	if truck_lane:
		spd *= 0.75
	var specs := []
	var half := 1.25 if truck_lane else 0.7
	var min_gap := 2.4 + spd * 0.3
	var fill := lerpf(0.18, 0.36, d) * _rng.randf_range(0.8, 1.2)
	var n := maxi(1, roundi(fill * Lane.LOOP / (half * 2.0)))
	while n > 1 and n * (half * 2.0 + min_gap) > Lane.LOOP:
		n -= 1
	for i in n:
		var mesh := ModelFactory.truck(_rng.randi() % ModelFactory.TRUCK_COLORS.size()) if truck_lane \
			else ModelFactory.car(_rng.randi() % ModelFactory.CAR_COLORS.size())
		specs.append({"mesh": mesh, "half": half})
	lane.setup_road(row, _prev_type == Lane.Type.ROAD, dir, spd, specs, min_gap, min_gap * 3.0)
	if _rng.randf() < 0.12:
		lane.place_coin(_rng.randi_range(-GameConfig.COLUMNS_HALF, GameConfig.COLUMNS_HALF))


func _setup_river(lane: Lane, row: int, d: float) -> void:
	if _prev_type == Lane.Type.RIVER and not _prev_lily and _rng.randf() < 0.3:
		var cols := []
		for c in range(-GameConfig.COLUMNS_HALF - 3, GameConfig.COLUMNS_HALF + 4):
			if _rng.randf() < 0.45:
				cols.append(c)
		var playable := 0
		for c in cols:
			if GameConfig.is_playable_column(c):
				playable += 1
		while playable < 3:
			var c := _rng.randi_range(-GameConfig.COLUMNS_HALF, GameConfig.COLUMNS_HALF)
			if not cols.has(c):
				cols.append(c)
				playable += 1
		lane.setup_river_lily(row, cols)
		_prev_lily = true
		return
	_prev_lily = false
	var dir := -_prev_dir if _rng.randf() < 0.75 else _prev_dir
	_prev_dir = dir
	var spd := lerpf(1.0, 2.4, d) * _rng.randf_range(0.85, 1.15)
	var specs := []
	var used := 0.0
	var max_gap := lerpf(2.2, 3.2, d)
	while used < Lane.LOOP - 6.0:
		var length := 4 if _rng.randf() < lerpf(0.4, 0.15, d) else (3 if _rng.randf() < 0.6 else 2)
		specs.append({"mesh": ModelFactory.log_mesh(length), "half": length * 0.5})
		used += length + (1.0 + max_gap) * 0.5
	lane.setup_river_logs(row, dir, spd, specs, 1.0, max_gap)
