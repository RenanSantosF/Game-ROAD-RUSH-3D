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
	await _wait(1.0)
	await _shot("01_menu")
	main._start_run()
	await _wait(2.5)
	await _shot("02_corrida")
	main._on_swipe(Vector2i.UP)
	await _wait(0.25)
	await _shot("03_pulo")
	await _wait(1.0)
	main._on_swipe(Vector2i.DOWN)
	await _wait(0.2)
	await _shot("04_deslize")
	main._player.invincible_time = 999.0
	await _wait(12.0)
	await _shot("05_corrida_longe")
	main._player.invincible_time = 0.0
	main._pause()
	await _wait(0.3)
	await _shot("06_pausa")
	main._resume()
	await _wait(2.2)
	main._kill_player()
	await _wait(0.6)
	await _shot("07_morte")
	await _wait(1.0)
	await _shot("08_continuar")
	main._revive_menu._on_skip()
	await _wait(0.4)
	await _shot("09_fim_de_jogo")
	main._go_to_menu()
	main._open_submenu(main._characters_menu)
	main._characters_menu._change(1)
	await _wait(0.6)
	await _shot("10_personagens")
	main._characters_menu._change(1)
	await _wait(0.4)
	await _shot("11_personagem_robo")
	main._characters_menu._change(1)
	await _wait(0.4)
	await _shot("12_personagem_gato")
	main._back_to_main_menu()
	main._open_submenu(main._missions_menu)
	await _wait(0.4)
	await _shot("13_missoes")
	main._back_to_main_menu()
	main._open_submenu(main._settings_menu)
	await _wait(0.4)
	await _shot("14_config")
	SaveManager.reset_progress()
	get_tree().quit()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(out_dir.path_join(name + ".png"))
	print("captura: ", name)
