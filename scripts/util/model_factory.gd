class_name ModelFactory
extends RefCounted
## Gera (uma única vez) e guarda em cache todas as malhas do mundo.
## Nenhum modelo externo é necessário: tudo é feito com blocos low-poly,
## e cada objeto vira UMA malha com UM material (barato para o celular).

const GROUND_HALF_WIDTH := 20.0
const GRASS_VARIANTS := 24

const GRASS_LIGHT := Color(0.6, 0.86, 0.38)
const GRASS_DARK := Color(0.54, 0.8, 0.34)
const ASPHALT := Color(0.34, 0.36, 0.42)
const ROAD_LINE := Color(0.95, 0.95, 0.9)
const WATER := Color(0.3, 0.66, 0.98)
const WATER_LIGHT := Color(0.5, 0.8, 1.0)
const GRAVEL := Color(0.6, 0.55, 0.5)
const TIE := Color(0.5, 0.35, 0.24)
const RAIL := Color(0.68, 0.7, 0.74)
const TRUNK := Color(0.5, 0.33, 0.22)
const LEAF_A := Color(0.3, 0.68, 0.3)
const LEAF_B := Color(0.38, 0.76, 0.34)
const ROCK := Color(0.62, 0.64, 0.66)
const LOG := Color(0.55, 0.36, 0.22)
const LOG_END := Color(0.82, 0.64, 0.42)
const LILY := Color(0.3, 0.72, 0.32)
const GLASS := Color(0.55, 0.78, 0.95)
const TIRE := Color(0.15, 0.15, 0.17)
const HEADLIGHT := Color(1.0, 0.95, 0.7)
const TAILLIGHT := Color(0.95, 0.15, 0.15)
const GOLD := Color(1.0, 0.76, 0.1)
const GOLD_LIGHT := Color(1.0, 0.9, 0.4)
const POLE := Color(0.3, 0.32, 0.36)

const CAR_COLORS := [
	Color(0.95, 0.3, 0.3), Color(0.25, 0.55, 0.95), Color(1.0, 0.8, 0.15),
	Color(0.3, 0.8, 0.45), Color(0.95, 0.55, 0.15), Color(0.65, 0.4, 0.9),
	Color(0.95, 0.95, 0.95),
]
const TRUCK_COLORS := [Color(0.25, 0.55, 0.95), Color(0.95, 0.3, 0.3), Color(0.3, 0.75, 0.45)]

static var _cache := {}
static var _grass_variants: Array = []


static func _mesh(key: String) -> ArrayMesh:
	return _cache.get(key)


## Gera tudo de uma vez na carga (evita engasgos durante a partida).
static func warm_up() -> void:
	if not _cache.is_empty():
		return
	for parity in 2:
		_cache["grass_%d" % parity] = _build_grass(parity)
	for dash in 2:
		_cache["road_%d" % dash] = _build_road(dash == 1)
	for v in 2:
		_cache["river_%d" % v] = _build_river(v)
	_cache["rail"] = _build_rail()
	for i in CAR_COLORS.size():
		_cache["car_%d" % i] = _build_car(CAR_COLORS[i])
	for i in TRUCK_COLORS.size():
		_cache["truck_%d" % i] = _build_truck(TRUCK_COLORS[i])
	_cache["train"] = _build_train()
	for length in [2, 3, 4]:
		_cache["log_%d" % length] = _build_log(length)
	_cache["lily"] = _build_lily()
	_cache["coin"] = _build_coin()
	_cache["signal"] = _build_signal()
	_build_grass_variants()


static func grass(parity: int) -> ArrayMesh:
	return _mesh("grass_%d" % parity)


static func road(dashed: bool) -> ArrayMesh:
	return _mesh("road_%d" % (1 if dashed else 0))


static func river(variant: int) -> ArrayMesh:
	return _mesh("river_%d" % variant)


static func rail() -> ArrayMesh:
	return _mesh("rail")


static func car(index: int) -> ArrayMesh:
	return _mesh("car_%d" % index)


static func truck(index: int) -> ArrayMesh:
	return _mesh("truck_%d" % index)


static func train() -> ArrayMesh:
	return _mesh("train")


static func log_mesh(length: int) -> ArrayMesh:
	return _mesh("log_%d" % length)


static func lily() -> ArrayMesh:
	return _mesh("lily")


static func coin() -> ArrayMesh:
	return _mesh("coin")


static func signal_pole() -> ArrayMesh:
	return _mesh("signal")


## Variantes de decoração da grama: {"mesh": ArrayMesh, "blocked": PackedInt32Array}
## Índice 0 = sem obstáculos na área jogável; índice 1 = muro de árvores.
static func grass_variant(index: int) -> Dictionary:
	return _grass_variants[index]


static func grass_variant_count() -> int:
	return _grass_variants.size()


# ----------------------------------------------------------------- Chão

static func _strip(mb: MeshBuilder, color: Color, y_top: float, thickness: float) -> void:
	var inner := GameConfig.COLUMNS_HALF + 0.5
	var outer := GROUND_HALF_WIDTH
	var y := y_top - thickness * 0.5
	mb.box(Vector3(0, y, 0), Vector3(inner * 2.0, thickness, 1.0), color)
	var side_w := outer - inner
	var dark := color.darkened(0.22)
	for s in [-1.0, 1.0]:
		mb.box(Vector3(s * (inner + side_w * 0.5), y, 0), Vector3(side_w, thickness, 1.0), dark)


static func _build_grass(parity: int) -> ArrayMesh:
	var mb := MeshBuilder.new()
	_strip(mb, GRASS_LIGHT if parity == 0 else GRASS_DARK, 0.0, 0.6)
	return mb.commit()


static func _build_road(dashed: bool) -> ArrayMesh:
	var mb := MeshBuilder.new()
	_strip(mb, ASPHALT, -0.08, 0.52)
	if dashed:
		var x := -GROUND_HALF_WIDTH + 0.5
		while x < GROUND_HALF_WIDTH:
			mb.box(Vector3(x, -0.074, 0.5), Vector3(0.6, 0.012, 0.07), ROAD_LINE)
			x += 1.4
	return mb.commit()


static func _build_river(variant: int) -> ArrayMesh:
	var mb := MeshBuilder.new()
	_strip(mb, WATER, -0.3, 0.3)
	var rng := RandomNumberGenerator.new()
	rng.seed = 99 + variant
	for i in 10:
		var x := rng.randf_range(-GROUND_HALF_WIDTH + 1.0, GROUND_HALF_WIDTH - 1.0)
		var z := rng.randf_range(-0.35, 0.35)
		mb.box(Vector3(x, -0.295, z), Vector3(rng.randf_range(0.6, 1.4), 0.01, 0.06), WATER_LIGHT)
	return mb.commit()


static func _build_rail() -> ArrayMesh:
	var mb := MeshBuilder.new()
	_strip(mb, GRAVEL, -0.04, 0.56)
	var x := -GROUND_HALF_WIDTH + 0.3
	while x < GROUND_HALF_WIDTH:
		mb.box(Vector3(x, -0.02, 0), Vector3(0.18, 0.04, 0.86), TIE)
		x += 0.6
	for z in [-0.25, 0.25]:
		mb.box(Vector3(0, 0.02, z), Vector3(GROUND_HALF_WIDTH * 2.0, 0.07, 0.07), RAIL)
	return mb.commit()


# ------------------------------------------------------- Árvores e pedras

static func _add_tree(mb: MeshBuilder, x: float, rng: RandomNumberGenerator) -> void:
	var levels := 3 if rng.randf() < 0.12 else rng.randi_range(1, 2)
	mb.box(Vector3(x, 0.2, 0), Vector3(0.24, 0.4, 0.24), TRUNK)
	var y := 0.4
	for i in levels:
		var size := 0.82 - i * 0.12
		var h := 0.5
		mb.box(Vector3(x, y + h * 0.5, 0), Vector3(size, h, size), LEAF_A if i % 2 == 0 else LEAF_B)
		y += h


static func _add_rock(mb: MeshBuilder, x: float) -> void:
	mb.box(Vector3(x, 0.2, 0), Vector3(0.72, 0.4, 0.66), ROCK)
	mb.box(Vector3(x - 0.08, 0.46, 0.04), Vector3(0.4, 0.14, 0.36), ROCK.lightened(0.12))


static func _build_grass_variants() -> void:
	_grass_variants.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 2024
	for v in GRASS_VARIANTS:
		var mb := MeshBuilder.new()
		var blocked := PackedInt32Array()
		if v == 1:
			for c in range(-GameConfig.COLUMNS_HALF, GameConfig.COLUMNS_HALF + 1):
				blocked.append(c)
		elif v >= 2:
			var count := rng.randi_range(1, 4)
			while blocked.size() < count:
				var c := rng.randi_range(-GameConfig.COLUMNS_HALF, GameConfig.COLUMNS_HALF)
				if not blocked.has(c):
					blocked.append(c)
		for c in blocked:
			if rng.randf() < 0.75:
				_add_tree(mb, c, rng)
			else:
				_add_rock(mb, c)
		for side in [-1, 1]:
			for c in range(GameConfig.COLUMNS_HALF + 1, int(GROUND_HALF_WIDTH) - 4):
				if c == GameConfig.COLUMNS_HALF + 1 or rng.randf() < 0.3:
					_add_tree(mb, side * c, rng)
		_grass_variants.append({"mesh": mb.commit(), "blocked": blocked})


# ---------------------------------------------------------------- Veículos
# Todos os veículos são montados com a frente apontando para +X.

static func _wheels(mb: MeshBuilder, xs: Array, half_w: float, r: float) -> void:
	for x in xs:
		for s in [-1.0, 1.0]:
			mb.box(Vector3(x, r, s * half_w), Vector3(r * 2.0, r * 2.0, 0.12), TIRE)


static func _build_car(c: Color) -> ArrayMesh:
	var mb := MeshBuilder.new()
	mb.box(Vector3(0, 0.36, 0), Vector3(1.4, 0.42, 0.8), c)
	mb.box(Vector3(-0.05, 0.74, 0), Vector3(0.8, 0.34, 0.72), c.lightened(0.15))
	mb.box(Vector3(-0.05, 0.72, 0), Vector3(0.82, 0.22, 0.74), GLASS)
	mb.box(Vector3(0.71, 0.42, 0.25), Vector3(0.04, 0.1, 0.16), HEADLIGHT)
	mb.box(Vector3(0.71, 0.42, -0.25), Vector3(0.04, 0.1, 0.16), HEADLIGHT)
	mb.box(Vector3(-0.71, 0.42, 0.25), Vector3(0.04, 0.1, 0.16), TAILLIGHT)
	mb.box(Vector3(-0.71, 0.42, -0.25), Vector3(0.04, 0.1, 0.16), TAILLIGHT)
	_wheels(mb, [-0.45, 0.45], 0.38, 0.15)
	return mb.commit()


static func _build_truck(c: Color) -> ArrayMesh:
	var mb := MeshBuilder.new()
	mb.box(Vector3(0.88, 0.55, 0), Vector3(0.7, 0.8, 0.86), c)
	mb.box(Vector3(1.0, 0.72, 0), Vector3(0.48, 0.3, 0.88), GLASS)
	mb.box(Vector3(-0.36, 0.72, 0), Vector3(1.74, 1.06, 0.92), Color(0.96, 0.96, 0.94))
	mb.box(Vector3(-0.36, 0.72, 0), Vector3(1.4, 0.3, 0.94), c.lightened(0.2))
	mb.box(Vector3(1.24, 0.4, 0.28), Vector3(0.04, 0.1, 0.14), HEADLIGHT)
	mb.box(Vector3(1.24, 0.4, -0.28), Vector3(0.04, 0.1, 0.14), HEADLIGHT)
	_wheels(mb, [-0.85, -0.2, 0.85], 0.42, 0.17)
	return mb.commit()


static func _build_train() -> ArrayMesh:
	var mb := MeshBuilder.new()
	# locomotiva na frente (+X), vagões atrás
	mb.box(Vector3(5.8, 0.75, 0), Vector3(3.8, 1.1, 0.9), Color(0.92, 0.25, 0.22))
	mb.box(Vector3(5.0, 1.45, 0), Vector3(1.6, 0.5, 0.86), Color(0.92, 0.25, 0.22))
	mb.box(Vector3(5.0, 1.42, 0), Vector3(1.62, 0.26, 0.88), GLASS)
	mb.box(Vector3(7.72, 0.6, 0), Vector3(0.06, 0.3, 0.5), HEADLIGHT)
	mb.box(Vector3(6.6, 1.45, 0), Vector3(0.3, 0.4, 0.3), Color(0.2, 0.2, 0.22))
	var colors := [Color(0.25, 0.55, 0.95), Color(1.0, 0.78, 0.15), Color(0.3, 0.75, 0.45)]
	for i in 3:
		var cx := 1.9 - i * 3.9
		mb.box(Vector3(cx, 0.8, 0), Vector3(3.7, 1.2, 0.9), colors[i])
		mb.box(Vector3(cx, 1.0, 0), Vector3(3.0, 0.32, 0.92), GLASS)
	for x in [-9.2, -5.3, -1.4, 2.5, 4.8, 7.0]:
		for s in [-1.0, 1.0]:
			mb.box(Vector3(x, 0.18, s * 0.36), Vector3(0.36, 0.36, 0.12), TIRE)
	return mb.commit()


# ------------------------------------------------------------------ Rio

static func _build_log(length: int) -> ArrayMesh:
	var mb := MeshBuilder.new()
	mb.box(Vector3(0, -0.08, 0), Vector3(length - 0.1, 0.3, 0.72), LOG)
	mb.box(Vector3(0, 0.075, 0.18), Vector3(length - 0.3, 0.02, 0.06), LOG.darkened(0.2))
	for s in [-1.0, 1.0]:
		mb.box(Vector3(s * (length * 0.5 - 0.07), -0.08, 0), Vector3(0.06, 0.26, 0.64), LOG_END)
	return mb.commit()


static func _build_lily() -> ArrayMesh:
	var mb := MeshBuilder.new()
	mb.frustum(Vector3(0, -0.26, 0), 0.42, 0.42, 0.06, 8, LILY)
	mb.box(Vector3(0.12, -0.19, -0.1), Vector3(0.12, 0.06, 0.12), Color(1.0, 0.6, 0.8))
	return mb.commit()


# ------------------------------------------------------------- Diversos

static func _build_coin() -> ArrayMesh:
	var mb := MeshBuilder.new()
	mb.set_transform(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO))
	mb.frustum(Vector3(0, -0.045, 0), 0.3, 0.3, 0.09, 10, GOLD)
	mb.frustum(Vector3(0, -0.06, 0), 0.2, 0.2, 0.12, 10, GOLD_LIGHT)
	mb.reset_transform()
	return mb.commit()


static func _build_signal() -> ArrayMesh:
	var mb := MeshBuilder.new()
	mb.box(Vector3(0, 0.7, 0), Vector3(0.12, 1.4, 0.12), POLE)
	mb.box(Vector3(0, 1.5, 0), Vector3(0.5, 0.3, 0.16), Color(0.15, 0.15, 0.17))
	mb.box(Vector3(0, 1.25, 0), Vector3(0.7, 0.12, 0.04), Color(0.95, 0.95, 0.95))
	return mb.commit()
