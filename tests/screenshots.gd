extends Node
## Gera capturas de tela para conferência visual (precisa de vídeo):
##   godot --path . --rendering-driver opengl3 res://tests/screenshots.tscn -- <pasta>

var main: Node
var out_dir := "user://screenshots"


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	SaveManager.reset_progress()
	main = load("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	await _wait(1.2)
	await _shot("01_menu")
	main._start_run()
	await _wait(1.0)
	await _shot("02_inicio")
	main._player.invincible_time = 999.0
	for i in 12:
		main._on_swipe(Vector2i.UP)
		await _wait(0.25)
	await _shot("03_avancando")
	for i in 14:
		main._on_swipe(Vector2i.UP)
		await _wait(0.2)
	await _wait(0.1)
	await _shot("04_mais_longe")
	main._player.invincible_time = 0.0
	main._kill("squash")
	await _wait(0.5)
	await _shot("05_atropelado")
	await _wait(1.2)
	await _shot("06_continuar")
	main._revive_menu._on_skip()
	await _wait(0.4)
	await _shot("07_fim_de_jogo")
	main._go_to_menu()
	main._open_submenu(main._characters_menu)
	for i in 4:
		await _wait(0.8)
		await _shot("08_personagem_%d" % i)
		main._characters_menu._change(1)
	main._back_to_main_menu()
	SaveManager.reset_progress()
	get_tree().quit()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(out_dir.path_join(name + ".png"))
	print("captura: ", name)
