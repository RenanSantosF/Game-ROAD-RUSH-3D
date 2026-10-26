class_name MeshBuilder
extends RefCounted
## Monta malhas low-poly com sombreamento chapado e cor por vértice.
## Todas as malhas usam um único material compartilhado (cor por vértice),
## o que reduz trocas de material e chamadas de desenho no celular.

static var _shared_material: StandardMaterial3D

var _st := SurfaceTool.new()
var _xf := Transform3D.IDENTITY


static func shared_material() -> StandardMaterial3D:
	if _shared_material == null:
		var mat := StandardMaterial3D.new()
		mat.vertex_color_use_as_albedo = true
		mat.vertex_color_is_srgb = true
		mat.roughness = 0.9
		mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		_shared_material = mat
	return _shared_material


func _init() -> void:
	_st.begin(Mesh.PRIMITIVE_TRIANGLES)


func set_transform(xf: Transform3D) -> void:
	_xf = xf


func reset_transform() -> void:
	_xf = Transform3D.IDENTITY


## Triângulo com normal da face. "outward" indica para onde a face aponta;
## a ordem dos vértices é corrigida automaticamente.
func triangle(a: Vector3, b: Vector3, c: Vector3, color: Color, outward: Vector3) -> void:
	var pa := _xf * a
	var pb := _xf * b
	var pc := _xf * c
	var n := (pb - pa).cross(pc - pa)
	if n.length_squared() < 0.0000001:
		return
	if n.dot(_xf.basis * outward) < 0.0:
		var tmp := pb
		pb = pc
		pc = tmp
		n = -n
	n = n.normalized()
	# O Godot considera frente as faces em sentido horário.
	for p in [pa, pc, pb]:
		_st.set_color(color)
		_st.set_normal(n)
		_st.add_vertex(p)


func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, color: Color, outward: Vector3) -> void:
	triangle(a, b, c, color, outward)
	triangle(a, c, d, color, outward)


## Caixa alinhada aos eixos. A face de baixo é omitida por padrão
## (objetos apoiados no chão nunca mostram a base).
func box(center: Vector3, size: Vector3, color: Color, with_bottom := false) -> void:
	var h := size * 0.5
	var faces := [
		[Vector3.RIGHT, Vector3.FORWARD, Vector3.UP],
		[Vector3.LEFT, Vector3.BACK, Vector3.UP],
		[Vector3.UP, Vector3.RIGHT, Vector3.FORWARD],
		[Vector3.BACK, Vector3.RIGHT, Vector3.UP],
		[Vector3.FORWARD, Vector3.LEFT, Vector3.UP],
		[Vector3.DOWN, Vector3.RIGHT, Vector3.BACK],
	]
	for f in faces:
		var n: Vector3 = f[0]
		if n == Vector3.DOWN and not with_bottom:
			continue
		var u: Vector3 = f[1]
		var v: Vector3 = f[2]
		var hn := absf(n.dot(h))
		var hu := absf(u.dot(h))
		var hv := absf(v.dot(h))
		var c := center + n * hn
		quad(
			c - u * hu - v * hv,
			c + u * hu - v * hv,
			c + u * hu + v * hv,
			c - u * hu + v * hv,
			color, n)


## Cilindro/cone low-poly ao longo do eixo Y local (base em "base").
func frustum(base: Vector3, r_bottom: float, r_top: float, height: float, sides: int, color: Color, caps := true) -> void:
	var top := base + Vector3(0.0, height, 0.0)
	for i in sides:
		var a0 := TAU * float(i) / sides
		var a1 := TAU * float(i + 1) / sides
		var d0 := Vector3(cos(a0), 0.0, sin(a0))
		var d1 := Vector3(cos(a1), 0.0, sin(a1))
		var mid := (d0 + d1).normalized()
		var b0 := base + d0 * r_bottom
		var b1 := base + d1 * r_bottom
		if r_top > 0.001:
			quad(b0, b1, top + d1 * r_top, top + d0 * r_top, color, mid)
			if caps:
				triangle(top, top + d0 * r_top, top + d1 * r_top, color, Vector3.UP)
		else:
			triangle(b0, b1, top, color, mid)
		if caps:
			triangle(base, b0, b1, color, Vector3.DOWN)


func commit() -> ArrayMesh:
	_st.set_material(shared_material())
	return _st.commit()
