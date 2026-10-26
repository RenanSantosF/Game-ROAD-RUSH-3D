class_name ModelFactory
extends RefCounted
## Gera (uma única vez) e guarda em cache todas as malhas do cenário.
## Nenhum modelo externo é necessário: tudo é feito com formas low-poly,
## e cada objeto vira UMA malha com UM material (barato para o celular).

const ROAD_VARIANTS := 2
const SIDE_VARIANTS := 6

const ASPHALT := Color(0.27, 0.29, 0.33)
const LINE_WHITE := Color(0.95, 0.95, 0.92)
const LINE_YELLOW := Color(1.0, 0.8, 0.2)
const CURB := Color(0.7, 0.7, 0.7)
const SIDEWALK := Color(0.76, 0.7, 0.62)
const SIDEWALK_SEAM := Color(0.62, 0.56, 0.5)
const PLAZA := Color(0.55, 0.6, 0.55)
const GRASS := Color(0.45, 0.74, 0.36)
const TRUNK := Color(0.45, 0.3, 0.2)
const LEAVES := Color(0.3, 0.66, 0.3)
const LEAVES_LIGHT := Color(0.42, 0.78, 0.36)
const POLE := Color(0.32, 0.34, 0.38)
const LAMP := Color(1.0, 0.95, 0.7)
const WINDOW := Color(0.4, 0.62, 0.88)
const SHOP_GLASS := Color(0.35, 0.55, 0.75)
const GLASS := Color(0.2, 0.28, 0.38)
const TIRE := Color(0.12, 0.12, 0.14)
const HUB := Color(0.75, 0.75, 0.78)
const TRIM := Color(0.2, 0.21, 0.24)
const HEADLIGHT := Color(1.0, 0.97, 0.8)
const TAILLIGHT := Color(0.9, 0.12, 0.12)
const GOLD := Color(1.0, 0.76, 0.1)
const GOLD_LIGHT := Color(1.0, 0.9, 0.4)
const STRIPE_RED := Color(0.9, 0.18, 0.18)
const STRIPE_WHITE := Color(0.97, 0.97, 0.97)
const WARNING_YELLOW := Color(1.0, 0.82, 0.1)
const WARNING_BLACK := Color(0.12, 0.12, 0.12)
const CONE_ORANGE := Color(1.0, 0.45, 0.1)

const CAR_COLORS := [
	Color(0.9, 0.2, 0.2), Color(0.2, 0.45, 0.92), Color(1.0, 0.78, 0.1),
	Color(0.25, 0.72, 0.35), Color(0.95, 0.95, 0.95), Color(1.0, 0.5, 0.15),
	Color(0.58, 0.32, 0.82),
]
const BUS_COLORS := [Color(1.0, 0.75, 0.1), Color(0.2, 0.6, 0.85), Color(0.85, 0.25, 0.3)]
const BUILDING_COLORS := [
	Color(0.93, 0.5, 0.42), Color(0.96, 0.78, 0.4), Color(0.45, 0.7, 0.88),
	Color(0.58, 0.8, 0.55), Color(0.8, 0.6, 0.88), Color(0.88, 0.84, 0.76),
	Color(0.95, 0.6, 0.3),
]
const AWNING_COLORS := [Color(0.9, 0.25, 0.25), Color(0.2, 0.6, 0.4), Color(0.25, 0.45, 0.85), Color(1.0, 0.6, 0.1)]

static var _cache := {}


static func road(variant: int) -> ArrayMesh:
	var key := "road_%d" % variant
	if not _cache.has(key):
		_cache[key] = _build_road(variant)
	return _cache[key]


static func side(side_sign: int, variant: int) -> ArrayMesh:
	var key := "side_%d_%d" % [side_sign, variant]
	if not _cache.has(key):
		_cache[key] = _build_side(side_sign, variant)
	return _cache[key]


static func car(color_index: int) -> ArrayMesh:
	var key := "car_%d" % color_index
	if not _cache.has(key):
		_cache[key] = _build_car(color_index)
	return _cache[key]


static func bus(color_index: int) -> ArrayMesh:
	var key := "bus_%d" % color_index
	if not _cache.has(key):
		_cache[key] = _build_bus(color_index)
	return _cache[key]


static func barrier() -> ArrayMesh:
	if not _cache.has("barrier"):
		_cache["barrier"] = _build_barrier()
	return _cache["barrier"]


static func cones() -> ArrayMesh:
	if not _cache.has("cones"):
		_cache["cones"] = _build_cones()
	return _cache["cones"]


static func overhead() -> ArrayMesh:
	if not _cache.has("overhead"):
		_cache["overhead"] = _build_overhead()
	return _cache["overhead"]


static func coin() -> ArrayMesh:
	if not _cache.has("coin"):
		_cache["coin"] = _build_coin()
	return _cache["coin"]


## Gera tudo de uma vez na carga (evita engasgos durante a partida).
static func warm_up() -> void:
	for v in ROAD_VARIANTS:
		road(v)
	for v in SIDE_VARIANTS:
		side(-1, v)
		side(1, v)
	for i in CAR_COLORS.size():
		car(i)
	for i in BUS_COLORS.size():
		bus(i)
	barrier()
	cones()
	overhead()
	coin()


# --------------------------------------------------------------------- Rua

static func _build_road(variant: int) -> ArrayMesh:
	var mb := MeshBuilder.new()
	var length := GameConfig.SEGMENT_LENGTH
	var zc := -length * 0.5
	var crosswalk := variant == 1
	mb.box(Vector3(0, -0.1, zc), Vector3(9.2, 0.2, length), ASPHALT)
	for s in [-1.0, 1.0]:
		mb.box(Vector3(s * 4.15, 0.006, zc), Vector3(0.14, 0.012, length), LINE_YELLOW)
		mb.box(Vector3(s * 4.72, 0.1, zc), Vector3(0.24, 0.2, length), CURB)
		mb.box(Vector3(s * 6.1, 0.09, zc), Vector3(2.52, 0.18, length), SIDEWALK)
		for i in range(1, 8):
			mb.box(Vector3(s * 6.1, 0.183, -i * 3.0), Vector3(2.52, 0.01, 0.06), SIDEWALK_SEAM)
	for lx in [-GameConfig.LANE_WIDTH * 0.5, GameConfig.LANE_WIDTH * 0.5]:
		var z := -1.5
		while z > -length:
			if not crosswalk or absf(z - 1.25 - zc) > 3.5:
				mb.box(Vector3(lx, 0.006, z - 1.25), Vector3(0.14, 0.012, 2.5), LINE_WHITE)
			z -= 6.0
	if crosswalk:
		var x := -3.6
		while x <= 3.61:
			mb.box(Vector3(x, 0.006, zc), Vector3(0.5, 0.012, 3.2), LINE_WHITE)
			x += 0.9
	return mb.commit()


# --------------------------------------------------- Calçada e construções

static func _build_side(side_sign: int, variant: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7919 * (variant + 1) + (13 if side_sign > 0 else 0)
	var mb := MeshBuilder.new()
	var s := float(side_sign)
	var length := GameConfig.SEGMENT_LENGTH
	var zc := -length * 0.5
	var park := variant == SIDE_VARIANTS - 1
	mb.box(Vector3(s * 24.0, -0.05, zc), Vector3(33.2, 0.1, length), GRASS if park else PLAZA)
	_add_lamp(mb, s, -4.0)
	_add_tree(mb, Vector3(s * 5.5, 0.18, -16.0), rng)
	if park:
		for i in 5:
			_add_tree(mb, Vector3(s * rng.randf_range(10.0, 20.0), 0.0, -rng.randf_range(2.0, 22.0)), rng)
		for i in 4:
			var bush := Vector3(s * rng.randf_range(8.5, 12.0), 0.35, -rng.randf_range(1.0, 23.0))
			mb.box(bush, Vector3(1.2, 0.7, 1.2), LEAVES_LIGHT)
		# banco
		mb.box(Vector3(s * 8.4, 0.45, -10.0), Vector3(0.6, 0.1, 2.2), TRUNK)
		mb.box(Vector3(s * 8.7, 0.75, -10.0), Vector3(0.1, 0.5, 2.2), TRUNK)
		for bz in [-9.2, -10.8]:
			mb.box(Vector3(s * 8.4, 0.2, bz), Vector3(0.5, 0.4, 0.1), POLE)
	else:
		var z := -0.3
		var end_z := -length + 0.3
		while z - end_z > 4.0:
			var w := rng.randf_range(6.0, 10.0)
			if z - w - end_z < 5.0:
				w = z - end_z
			_add_building(mb, s, z, z - w, rng)
			z -= w + 0.6
	return mb.commit()


static func _add_lamp(mb: MeshBuilder, s: float, z: float) -> void:
	mb.frustum(Vector3(s * 7.0, 0.18, z), 0.09, 0.07, 4.5, 6, POLE)
	mb.box(Vector3(s * 6.35, 4.62, z), Vector3(1.3, 0.1, 0.1), POLE)
	mb.box(Vector3(s * 5.75, 4.52, z), Vector3(0.55, 0.14, 0.28), LAMP)


static func _add_tree(mb: MeshBuilder, base: Vector3, rng: RandomNumberGenerator) -> void:
	var scale := rng.randf_range(0.85, 1.25)
	mb.frustum(base, 0.14 * scale, 0.1 * scale, 1.3 * scale, 6, TRUNK)
	var leaves: Color = LEAVES if rng.randf() < 0.5 else LEAVES_LIGHT
	mb.frustum(base + Vector3(0, 1.0 * scale, 0), 1.0 * scale, 0.0, 1.7 * scale, 7, leaves)
	mb.frustum(base + Vector3(0, 1.9 * scale, 0), 0.75 * scale, 0.0, 1.4 * scale, 7, leaves.lightened(0.1))


static func _add_building(mb: MeshBuilder, s: float, z0: float, z1: float, rng: RandomNumberGenerator) -> void:
	var depth := rng.randf_range(7.0, 10.0)
	var floors := rng.randi_range(2, 6)
	var floor_h := 3.0
	var h := floors * floor_h + 0.6
	var x_front := 8.2
	var w := absf(z0 - z1)
	var zc := (z0 + z1) * 0.5
	var cx := s * (x_front + depth * 0.5)
	var col: Color = BUILDING_COLORS[rng.randi() % BUILDING_COLORS.size()]
	mb.box(Vector3(cx, h * 0.5, zc), Vector3(depth, h, w), col)
	mb.box(Vector3(cx, h + 0.15, zc), Vector3(depth + 0.3, 0.3, w + 0.3), col.darkened(0.25))
	if rng.randf() < 0.5:
		mb.box(Vector3(cx + s * 1.5, h + 0.6, zc), Vector3(1.6, 0.9, 1.6), Color(0.7, 0.72, 0.75))
	var face_x := s * (x_front - 0.04)
	var cols := maxi(int(w / 2.2), 1)
	for f in range(1, floors):
		var y := f * floor_h + 1.4
		for i in cols:
			var wz := z0 - (i + 0.5) * (w / cols)
			mb.box(Vector3(face_x, y, wz), Vector3(0.1, 1.3, 1.2), WINDOW)
	# Térreo: vitrine, porta e toldo.
	mb.box(Vector3(face_x, 1.3, zc + w * 0.12), Vector3(0.1, 1.6, w * 0.5), SHOP_GLASS)
	mb.box(Vector3(face_x, 1.1, zc - w * 0.3), Vector3(0.1, 2.2, 1.1), col.darkened(0.45))
	var awning: Color = AWNING_COLORS[rng.randi() % AWNING_COLORS.size()]
	mb.box(Vector3(s * (x_front - 0.6), 2.75, zc), Vector3(1.2, 0.15, w * 0.8), awning)


# ----------------------------------------------------------------- Veículos

static func _add_wheel(mb: MeshBuilder, center: Vector3, radius: float, width: float) -> void:
	mb.set_transform(Transform3D(Basis(Vector3.BACK, PI * 0.5), center))
	mb.frustum(Vector3(0, -width * 0.5, 0), radius, radius, width, 8, TIRE)
	mb.frustum(Vector3(0, -width * 0.5 - 0.01, 0), radius * 0.45, radius * 0.45, width + 0.02, 6, HUB)
	mb.reset_transform()


static func _build_car(color_index: int) -> ArrayMesh:
	var c: Color = CAR_COLORS[color_index]
	var mb := MeshBuilder.new()
	mb.box(Vector3(0, 0.62, 0), Vector3(1.8, 0.62, 3.9), c)
	mb.box(Vector3(0, 0.38, 0), Vector3(1.84, 0.16, 3.98), TRIM)
	mb.box(Vector3(0, 1.22, 0.3), Vector3(1.56, 0.58, 2.0), c.lightened(0.08))
	mb.box(Vector3(0, 1.2, 0.3), Vector3(1.6, 0.4, 2.04), GLASS)
	for sx in [-1.0, 1.0]:
		mb.box(Vector3(sx * 0.6, 0.74, -1.97), Vector3(0.4, 0.16, 0.06), HEADLIGHT)
		mb.box(Vector3(sx * 0.6, 0.74, 1.97), Vector3(0.4, 0.16, 0.06), TAILLIGHT)
		for wz in [-1.25, 1.3]:
			_add_wheel(mb, Vector3(sx * 0.84, 0.34, wz), 0.34, 0.3)
	if color_index == 2:
		# táxi: placa no teto
		mb.box(Vector3(0, 1.6, 0.3), Vector3(0.6, 0.18, 0.3), Color(0.15, 0.15, 0.15))
	return mb.commit()


static func _build_bus(color_index: int) -> ArrayMesh:
	var c: Color = BUS_COLORS[color_index]
	var mb := MeshBuilder.new()
	mb.box(Vector3(0, 1.65, 0), Vector3(2.3, 2.7, 9.0), c)
	mb.box(Vector3(0, 0.45, 0), Vector3(2.34, 0.3, 9.04), TRIM)
	mb.box(Vector3(0, 2.15, 0.4), Vector3(2.34, 0.85, 7.6), GLASS)
	mb.box(Vector3(0, 1.95, -4.51), Vector3(2.0, 1.2, 0.06), GLASS)
	mb.box(Vector3(0, 1.25, 0), Vector3(2.34, 0.14, 9.04), STRIPE_WHITE)
	mb.box(Vector3(0, 2.8, -4.52), Vector3(1.4, 0.3, 0.06), Color(1.0, 0.55, 0.1))
	mb.box(Vector3(0, 3.05, 0.5), Vector3(1.6, 0.2, 4.0), c.darkened(0.15))
	for sx in [-1.0, 1.0]:
		mb.box(Vector3(sx * 0.8, 0.8, -4.52), Vector3(0.4, 0.2, 0.06), HEADLIGHT)
		mb.box(Vector3(sx * 0.8, 0.8, 4.52), Vector3(0.4, 0.2, 0.06), TAILLIGHT)
		for wz in [-3.0, 3.0]:
			_add_wheel(mb, Vector3(sx * 1.05, 0.5, wz), 0.5, 0.34)
	return mb.commit()


# --------------------------------------------------------------- Obstáculos

static func _build_barrier() -> ArrayMesh:
	var mb := MeshBuilder.new()
	for sx in [-1.0, 1.0]:
		mb.box(Vector3(sx * 1.0, 0.42, 0), Vector3(0.12, 0.84, 0.12), POLE)
		mb.box(Vector3(sx * 1.0, 0.04, 0), Vector3(0.24, 0.08, 0.7), TRIM)
		mb.box(Vector3(sx * 1.0, 0.9, 0), Vector3(0.16, 0.12, 0.16), WARNING_YELLOW)
	var stripes := 6
	var width := 2.4
	for i in stripes:
		var x := -width * 0.5 + (i + 0.5) * width / stripes
		mb.box(Vector3(x, 0.64, 0), Vector3(width / stripes, 0.34, 0.12), STRIPE_RED if i % 2 == 0 else STRIPE_WHITE)
	return mb.commit()


static func _build_cones() -> ArrayMesh:
	var mb := MeshBuilder.new()
	for x in [-0.8, 0.0, 0.8]:
		mb.box(Vector3(x, 0.025, 0), Vector3(0.6, 0.05, 0.6), CONE_ORANGE.darkened(0.3))
		mb.frustum(Vector3(x, 0.05, 0), 0.26, 0.19, 0.27, 8, CONE_ORANGE, false)
		mb.frustum(Vector3(x, 0.32, 0), 0.19, 0.15, 0.13, 8, STRIPE_WHITE, false)
		mb.frustum(Vector3(x, 0.45, 0), 0.15, 0.04, 0.28, 8, CONE_ORANGE, false)
	mb.box(Vector3(0, 0.55, 0), Vector3(1.7, 0.08, 0.08), WARNING_YELLOW)
	return mb.commit()


static func _build_overhead() -> ArrayMesh:
	var mb := MeshBuilder.new()
	for sx in [-1.0, 1.0]:
		mb.frustum(Vector3(sx * 1.25, 0, 0), 0.08, 0.07, 1.95, 6, POLE)
	mb.box(Vector3(0, 1.48, 0), Vector3(2.5, 0.56, 0.12), WARNING_YELLOW)
	for i in 5:
		mb.box(Vector3(-1.0 + i * 0.5, 1.48, 0), Vector3(0.22, 0.56, 0.14), WARNING_BLACK)
	mb.box(Vector3(0, 1.92, 0), Vector3(2.66, 0.1, 0.1), POLE)
	return mb.commit()


static func _build_coin() -> ArrayMesh:
	var mb := MeshBuilder.new()
	mb.set_transform(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO))
	mb.frustum(Vector3(0, -0.05, 0), 0.36, 0.36, 0.1, 10, GOLD)
	mb.frustum(Vector3(0, -0.065, 0), 0.24, 0.24, 0.13, 10, GOLD_LIGHT)
	mb.reset_transform()
	return mb.commit()
