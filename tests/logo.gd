extends Node3D
## Renderiza as peças 3D do logo (fundo transparente). A montagem final
## (raios de sol, contorno de adesivo, sombra) é feita em tools/make_logo.py.
##   godot --path . --rendering-driver opengl3 --resolution 1024x1024 res://tests/logo.tscn -- <chicken|scene|coin> <arquivo.png>

const WHITE := Color(0.99, 0.99, 0.97)
const SHADE := Color(0.88, 0.89, 0.9)
const RED := Color(0.93, 0.17, 0.17)
const ORANGE := Color(1.0, 0.6, 0.12)
const BLACK := Color(0.07, 0.07, 0.09)


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var mode: String = args[0] if args.size() > 0 else "chicken"
	var out: String = args[1] if args.size() > 1 else "user://logo_%s.png" % mode
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	get_viewport().transparent_bg = true
	ModelFactory.warm_up()

	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.88, 0.95)
	env.ambient_light_energy = 0.7
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-40, 25, 0)
	key.light_energy = 1.05
	add_child(key)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-20, 160, 0)
	rim.light_energy = 0.45
	add_child(rim)

	var cam := Camera3D.new()
	add_child(cam)
	cam.current = true
	match mode:
		"chicken":
			_add_mesh(_jumping_chicken(), Vector3.ZERO, Vector3(deg_to_rad(-8), deg_to_rad(25), deg_to_rad(-6)))
			cam.fov = 30.0
			cam.look_at_from_position(Vector3(0.5, 1.0, -3.6), Vector3(0, 0.6, 0), Vector3.UP)
		"scene":
			_add_mesh(_crosswalk(), Vector3.ZERO, Vector3.ZERO)
			_add_mesh(ModelFactory.car(0), Vector3(-1.4, 0.0, 0.05), Vector3.ZERO)
			cam.fov = 36.0
			cam.look_at_from_position(Vector3(0.6, 3.0, 5.4), Vector3(-0.5, 0.25, 0), Vector3.UP)
		"coin":
			_add_mesh(ModelFactory.coin(), Vector3.ZERO, Vector3(0, deg_to_rad(-25), deg_to_rad(12)))
			cam.fov = 24.0
			cam.look_at_from_position(Vector3(0, 0, 2.0), Vector3.ZERO, Vector3.UP)

	for i in 6:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out)
	print("gerado: ", out)
	get_tree().quit()


func _add_mesh(mesh: Mesh, pos: Vector3, rot: Vector3) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.rotation = rot
	add_child(mi)


## Galinha no meio do pulo: asas abertas, olhos arregalados e bico aberto.
func _jumping_chicken() -> ArrayMesh:
	var mb := MeshBuilder.new()
	# corpo esticado
	mb.box(Vector3(0, 0.5, 0.02), Vector3(0.5, 0.5, 0.56), WHITE, true)
	mb.box(Vector3(0, 0.62, 0.34), Vector3(0.28, 0.26, 0.1), SHADE)
	# cabeça
	mb.box(Vector3(0, 0.9, -0.16), Vector3(0.34, 0.36, 0.32), WHITE, true)
	mb.box(Vector3(0, 1.13, -0.16), Vector3(0.08, 0.16, 0.24), RED)
	mb.box(Vector3(0, 1.17, -0.06), Vector3(0.07, 0.1, 0.08), RED)
	# bico aberto (susto!)
	mb.box(Vector3(0, 0.92, -0.37), Vector3(0.14, 0.05, 0.12), ORANGE)
	mb.box(Vector3(0, 0.84, -0.36), Vector3(0.12, 0.04, 0.1), ORANGE.darkened(0.15))
	mb.box(Vector3(0, 0.76, -0.33), Vector3(0.06, 0.08, 0.04), RED)
	# olhos grandes (branco + pupila) dos dois lados e na frente
	for s in [-1.0, 1.0]:
		mb.box(Vector3(s * 0.175, 0.95, -0.2), Vector3(0.02, 0.12, 0.12), Color.WHITE)
		mb.box(Vector3(s * 0.187, 0.95, -0.22), Vector3(0.02, 0.07, 0.06), BLACK)
		mb.box(Vector3(s * 0.09, 0.97, -0.33), Vector3(0.1, 0.11, 0.02), Color.WHITE)
		mb.box(Vector3(s * 0.09, 0.97, -0.343), Vector3(0.055, 0.065, 0.02), BLACK)
		# asas abertas para cima
		mb.set_transform(Transform3D(Basis(Vector3.BACK, s * deg_to_rad(50)), Vector3(s * 0.27, 0.62, 0.02)))
		mb.box(Vector3(s * 0.16, 0.0, 0), Vector3(0.34, 0.07, 0.34), WHITE)
		mb.box(Vector3(s * 0.3, 0.0, 0.0), Vector3(0.1, 0.06, 0.3), SHADE)
		mb.reset_transform()
		# pernas penduradas
		mb.box(Vector3(s * 0.12, 0.17, 0.02), Vector3(0.06, 0.2, 0.06), ORANGE)
		mb.box(Vector3(s * 0.12, 0.07, -0.03), Vector3(0.13, 0.03, 0.17), ORANGE)
	return mb.commit()


func _crosswalk() -> ArrayMesh:
	var mb := MeshBuilder.new()
	mb.box(Vector3(0, -0.1, 0), Vector3(5.0, 0.2, 1.6), ModelFactory.ASPHALT)
	var x := -2.2
	while x < 2.3:
		mb.box(Vector3(x, 0.006, 0), Vector3(0.32, 0.012, 1.3), Color(0.97, 0.97, 0.95))
		x += 0.62
	for z in [-0.82, 0.82]:
		mb.box(Vector3(0, 0.0, z), Vector3(5.0, 0.24, 0.06), Color(0.98, 0.82, 0.15))
	return mb.commit()
