extends Node3D
## Gera imagens para a loja e o ícone do app (precisa de vídeo):
##   godot --path . --rendering-driver opengl3 --resolution 1024x1024 res://tests/store_assets.tscn -- icon <arquivo.png>
##   godot --path . --rendering-driver opengl3 --resolution 1024x500 res://tests/store_assets.tscn -- feature <arquivo.png> [pt|en|es]


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var mode: String = args[0] if args.size() > 0 else "icon"
	var out: String = args[1] if args.size() > 1 else "user://%s.png" % mode
	if args.size() > 2:
		TranslationServer.set_locale(args[2])
	ModelFactory.warm_up()
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.45, 0.78, 0.98)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.82, 0.95)
	env.ambient_light_energy = 0.6
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 33, 0)
	sun.light_energy = 1.0
	sun.shadow_enabled = true
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-30, 200, 0)
	fill.light_energy = 0.35
	add_child(fill)

	var cam := Camera3D.new()
	add_child(cam)
	cam.current = true

	if mode == "icon_fg":
		# Frente do ícone adaptativo: só a galinha, fundo transparente.
		get_viewport().transparent_bg = true
		env.background_mode = Environment.BG_CLEAR_COLOR
		_animal("galinha", Vector3.ZERO, PI + 0.55, 1.0)
		cam.fov = 30.0
		cam.look_at_from_position(Vector3(1.9, 1.9, 3.6), Vector3(0, 0.5, 0), Vector3.UP)
	elif mode == "icon":
		_build_icon_scene(cam)
	else:
		_build_feature_scene(cam)

	for i in 6:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out)
	print("gerado: ", out)
	get_tree().quit()


func _animal(id: String, pos: Vector3, yaw: float, scale := 1.0) -> void:
	var m := AnimalModel.new()
	add_child(m)
	m.build(CharacterCatalog.get_by_id(id))
	m.position = pos
	m.scale = Vector3.ONE * scale
	m.rotation.y = yaw
	m.set_process(false)


func _lane(mesh: Mesh, row: int) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = Vector3(0, 0, -row)
	add_child(mi)


func _vehicle(mesh: Mesh, pos: Vector3, yaw: float) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.rotation.y = yaw
	add_child(mi)


func _build_icon_scene(cam: Camera3D) -> void:
	_lane(ModelFactory.grass(0), 0)
	_lane(ModelFactory.road(false), 1)
	_lane(ModelFactory.grass(1), -1)
	_vehicle(ModelFactory.car(0), Vector3(-2.0, -0.08, -1), 0.0)
	_animal("galinha", Vector3(0.2, 0, 0.1), PI + 0.55, 1.5)
	cam.fov = 36.0
	cam.look_at_from_position(Vector3(2.3, 2.5, 4.2), Vector3(-0.2, 0.7, -0.3), Vector3.UP)


func _build_feature_scene(cam: Camera3D) -> void:
	for r in range(-3, 8):
		var kind := posmod(r, 4)
		if kind == 1 or kind == 2:
			_lane(ModelFactory.road(kind == 2), r)
		else:
			_lane(ModelFactory.grass(posmod(r, 2)), r)
	_vehicle(ModelFactory.car(1), Vector3(-3.2, -0.08, -1), 0.0)
	_vehicle(ModelFactory.truck(1), Vector3(4.5, -0.08, -2), PI)
	_vehicle(ModelFactory.car(2), Vector3(-6.5, -0.08, -5), 0.0)
	_vehicle(ModelFactory.car(4), Vector3(3.5, -0.08, -6), PI)
	_animal("galinha", Vector3(1.0, 0, 0), PI + 0.4, 1.3)
	_animal("pato", Vector3(-0.6, 0, 0.6), PI - 0.3, 1.0)
	_animal("porco", Vector3(2.6, 0, 0.8), PI + 0.7, 1.0)
	_animal("gato", Vector3(-2.2, 0, 0.3), PI - 0.5, 1.0)
	cam.fov = 42.0
	cam.look_at_from_position(Vector3(0.6, 5.2, 5.6), Vector3(0.3, 0.2, -1.2), Vector3.UP)
	var layer := CanvasLayer.new()
	add_child(layer)
	var title := UiTheme.make_label("ROAD RUSH 3D", 84, Color.WHITE)
	title.add_theme_constant_override("outline_size", 22)
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 18
	title.offset_bottom = 130
	layer.add_child(title)
