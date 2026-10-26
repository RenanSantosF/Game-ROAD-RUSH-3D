extends Node3D
## Controlador principal do jogo.
## Liga jogador, estrada, obstáculos, câmera, interface, salvamento,
## missões e anúncios. Cada sistema fica no seu próprio script; aqui só
## ficam o fluxo da partida (estados) e a câmera.

enum GameState { MENU, PLAYING, DYING, REVIVE_OFFER, GAME_OVER }

const DEATH_DELAY := 1.1
const TUTORIAL_GAMES := 3
const TUTORIAL_TIME := 5.0

var state: int = GameState.MENU

var _speed := 0.0
var _run_coins := 0
var _run_time := 0.0
var _run_jumps := 0
var _run_slides := 0
var _revived := false
var _run_committed := false
var _double_used := false
var _death_timer := 0.0
var _last_score := -1
var _next_milestone := -1

var _cam_blend := 0.0
var _cam_x := 0.0
var _shake := 0.0
var _rng := RandomNumberGenerator.new()

@onready var _player: Player = %Player
@onready var _road: RoadManager = %Road
@onready var _spawner: ObstacleSpawner = %Spawner
@onready var _camera: Camera3D = %Camera
@onready var _sun: DirectionalLight3D = %Sun
@onready var _swipe: SwipeInput = %SwipeInput
@onready var _hud: Hud = %HUD
@onready var _main_menu: MainMenu = %MainMenu
@onready var _characters_menu: CharactersMenu = %CharactersMenu
@onready var _missions_menu: MissionsMenu = %MissionsMenu
@onready var _settings_menu: SettingsMenu = %SettingsMenu
@onready var _pause_menu: PauseMenu = %PauseMenu
@onready var _revive_menu: ReviveMenu = %ReviveMenu
@onready var _game_over_menu: GameOverMenu = %GameOverMenu


func _ready() -> void:
	_rng.randomize()
	get_tree().quit_on_go_back = false
	ModelFactory.warm_up()
	_player.set_character(CharacterCatalog.get_by_id(SaveManager.get_selected_character()))

	_player.jumped.connect(_on_player_jumped)
	_player.slid.connect(_on_player_slid)
	_player.lane_changed.connect(func(_lane: int): AudioManager.play_sfx("click", 0.1))
	_swipe.swiped.connect(_on_swipe)

	_hud.pause_pressed.connect(_pause)
	_hud.countdown_finished.connect(_on_countdown_finished)
	_main_menu.play_pressed.connect(_start_run)
	_main_menu.characters_pressed.connect(_open_submenu.bind(_characters_menu))
	_main_menu.missions_pressed.connect(_open_submenu.bind(_missions_menu))
	_main_menu.settings_pressed.connect(_open_submenu.bind(_settings_menu))
	_characters_menu.back_pressed.connect(_back_to_main_menu)
	_characters_menu.preview_changed.connect(_player.set_character)
	_missions_menu.back_pressed.connect(_back_to_main_menu)
	_settings_menu.back_pressed.connect(_back_to_main_menu)
	_pause_menu.resume_pressed.connect(_resume)
	_pause_menu.restart_pressed.connect(_restart_from_pause)
	_pause_menu.menu_pressed.connect(_menu_from_pause)
	_revive_menu.revive_accepted.connect(_on_revive_accepted)
	_revive_menu.revive_declined.connect(_finish_run)
	_game_over_menu.restart_pressed.connect(_start_run)
	_game_over_menu.menu_pressed.connect(_go_to_menu)
	_game_over_menu.double_pressed.connect(_on_double_pressed)

	SaveManager.settings_changed.connect(_apply_settings)
	_apply_settings()
	_go_to_menu()
	AudioManager.play_music()


func _apply_settings() -> void:
	var shadows := SaveManager.get_setting("shadows")
	_sun.shadow_enabled = shadows
	_player.set_blob_shadow_visible(not shadows)
	_hud.set_fps_visible(SaveManager.get_setting("show_fps"))


# ------------------------------------------------------------------ Fluxo

func _close_all_menus() -> void:
	for menu in [_main_menu, _characters_menu, _missions_menu, _settings_menu, _pause_menu, _revive_menu, _game_over_menu]:
		menu.close()


func _go_to_menu() -> void:
	get_tree().paused = false
	state = GameState.MENU
	_swipe.enabled = false
	_close_all_menus()
	_hud.visible = false
	_spawner.reset()
	_road.reset()
	_player.set_character(CharacterCatalog.get_by_id(SaveManager.get_selected_character()))
	_player.go_idle()
	_main_menu.open()


func _open_submenu(menu: BaseMenu) -> void:
	_main_menu.close()
	menu.open()


func _back_to_main_menu() -> void:
	_characters_menu.close()
	_missions_menu.close()
	_settings_menu.close()
	_player.set_character(CharacterCatalog.get_by_id(SaveManager.get_selected_character()))
	_main_menu.open()


func _start_run() -> void:
	get_tree().paused = false
	_close_all_menus()
	_player.set_character(CharacterCatalog.get_by_id(SaveManager.get_selected_character()))
	_spawner.reset()
	_road.reset()
	_player.reset_run()
	_run_coins = 0
	_run_time = 0.0
	_run_jumps = 0
	_run_slides = 0
	_revived = false
	_run_committed = false
	_double_used = false
	_last_score = -1
	_speed = GameConfig.START_SPEED
	_update_next_milestone()
	_hud.reset(SaveManager.get_best_score())
	_hud.visible = true
	_hud.show_tutorial(SaveManager.get_stat("games") < TUTORIAL_GAMES)
	_swipe.enabled = true
	state = GameState.PLAYING
	Missions.ensure_today()


func _process(delta: float) -> void:
	if get_tree().paused:
		return
	match state:
		GameState.PLAYING:
			_update_playing(delta)
		GameState.DYING:
			_player.update_dead(delta)
			_death_timer -= delta
			if _death_timer <= 0.0:
				_after_death()
	_update_camera(delta)


func _update_playing(delta: float) -> void:
	_speed = GameConfig.speed_for_distance(_player.distance)
	_player.update_run(delta, _speed)
	_run_time += delta
	_spawner.update(delta, _player.distance, _speed)
	_road.update(_player.distance)
	_check_collision()
	if state != GameState.PLAYING:
		return
	var got := _spawner.collect_coins(_player.position.x, _player.height, _player.distance)
	if got > 0:
		_run_coins += got
		_hud.set_coins(_run_coins)
		AudioManager.play_sfx("coin", 0.05)
	var score := int(_player.distance)
	if score != _last_score:
		_last_score = score
		_hud.set_score(score)
		_check_milestone(score)
	if _run_time > TUTORIAL_TIME:
		_hud.show_tutorial(false)


func _check_collision() -> void:
	if _player.invincible_time > 0.0:
		return
	var o := _spawner.find_collision(_player.position.x, _player.height, _player.get_top(), _player.distance)
	if o == null:
		return
	var overlap_x := o.half_extents.x + GameConfig.PLAYER_HALF_WIDTH - absf(o.position.x - _player.position.x)
	var overlap_z := o.half_extents.z + GameConfig.PLAYER_HALF_DEPTH - absf(o.get_along() - _player.distance)
	if _player.is_changing_lane() and overlap_x < overlap_z:
		# Raspão lateral ao trocar de faixa: volta para a faixa anterior.
		if _player.lane == o.lane:
			_player.bounce_back()
			_shake = 0.25
			AudioManager.play_sfx("bump")
		return
	_kill_player()


func _kill_player() -> void:
	state = GameState.DYING
	_swipe.enabled = false
	_player.die()
	_death_timer = DEATH_DELAY
	_shake = 0.5
	_hud.set_pause_enabled(false)
	_hud.show_tutorial(false)
	AudioManager.play_sfx("crash")


func _after_death() -> void:
	if not _revived and Ads.is_rewarded_available():
		state = GameState.REVIVE_OFFER
		_revive_menu.open()
	else:
		_finish_run()


func _on_revive_accepted() -> void:
	Ads.show_rewarded("revive", _on_revive_ad_result)


func _on_revive_ad_result(rewarded: bool) -> void:
	if state != GameState.REVIVE_OFFER:
		return
	_revive_menu.close()
	if not rewarded:
		_finish_run()
		return
	_revived = true
	_spawner.clear_for_revive(_player.distance)
	_player.revive()
	_hud.set_pause_enabled(true)
	_swipe.enabled = true
	state = GameState.PLAYING
	_hud.show_toast("Continue correndo!", Color(0.6, 1.0, 0.6))


## Grava moedas, recorde, estatísticas e missões (uma única vez por partida).
func _commit_run() -> Dictionary:
	if _run_committed:
		return {}
	_run_committed = true
	var score := int(_player.distance)
	var new_record := SaveManager.record_run(score, _run_coins)
	var completed := Missions.record_run({
		"coins": _run_coins,
		"distance": score,
		"time": int(_run_time),
		"jumps": _run_jumps,
		"slides": _run_slides,
		"games": 1,
	})
	return {"score": score, "new_record": new_record, "completed": completed}


func _finish_run() -> void:
	if state == GameState.GAME_OVER:
		return
	state = GameState.GAME_OVER
	_swipe.enabled = false
	_revive_menu.close()
	_hud.visible = false
	var result := _commit_run()
	if result.is_empty():
		return
	if result["new_record"]:
		AudioManager.play_sfx("reward")
	_game_over_menu.show_results(
		result["score"], SaveManager.get_best_score(), _run_coins,
		result["new_record"], result["completed"],
		Ads.is_rewarded_available() and not _double_used)


func _on_double_pressed() -> void:
	if _double_used or not _run_committed or _run_coins <= 0:
		return
	Ads.show_rewarded("double_coins", _on_double_ad_result)


func _on_double_ad_result(rewarded: bool) -> void:
	if not rewarded or _double_used:
		return
	_double_used = true
	SaveManager.add_coins(_run_coins)
	SaveManager.save_game()
	AudioManager.play_sfx("reward")
	_game_over_menu.mark_doubled(_run_coins)


func _check_milestone(score: int) -> void:
	if _next_milestone < 0:
		return
	var meters: int = GameConfig.MILESTONES[_next_milestone]
	if score < meters:
		return
	var reward := GameConfig.milestone_reward(_next_milestone)
	if SaveManager.claim_milestone(meters, reward):
		AudioManager.play_sfx("reward")
		_hud.show_toast("META DE %d m!  +%d moedas" % [meters, reward])
	_update_next_milestone()


func _update_next_milestone() -> void:
	_next_milestone = -1
	for i in GameConfig.MILESTONES.size():
		if not SaveManager.is_milestone_claimed(GameConfig.MILESTONES[i]):
			_next_milestone = i
			break
	if _next_milestone < 0:
		_hud.set_goal("Todas as metas concluídas!")
	else:
		_hud.set_goal("Próxima meta: %d m" % GameConfig.MILESTONES[_next_milestone])


# ----------------------------------------------------------------- Pausa

func _pause() -> void:
	if state != GameState.PLAYING or get_tree().paused or _hud.is_counting_down():
		return
	get_tree().paused = true
	_hud.set_pause_enabled(false)
	_pause_menu.open()


func _resume() -> void:
	if not _pause_menu.visible:
		return
	_pause_menu.close()
	_hud.start_countdown()


func _on_countdown_finished() -> void:
	get_tree().paused = false


func _restart_from_pause() -> void:
	_commit_run()
	_start_run()


func _menu_from_pause() -> void:
	_commit_run()
	_go_to_menu()


# ----------------------------------------------------------------- Ações

func _on_swipe(direction: Vector2i) -> void:
	if state != GameState.PLAYING or get_tree().paused:
		return
	match direction:
		Vector2i.LEFT:
			_player.change_lane(-1)
		Vector2i.RIGHT:
			_player.change_lane(1)
		Vector2i.UP:
			_player.jump()
		Vector2i.DOWN:
			_player.slide()


func _on_player_jumped() -> void:
	_run_jumps += 1
	AudioManager.play_sfx("jump", 0.05)


func _on_player_slid() -> void:
	_run_slides += 1
	AudioManager.play_sfx("slide")


# ----------------------------------------------------------------- Câmera

func _update_camera(delta: float) -> void:
	var in_run := state != GameState.MENU
	_cam_blend = move_toward(_cam_blend, 1.0 if in_run else 0.0, delta * 1.3)
	var b := smoothstep(0.0, 1.0, _cam_blend)
	var p := _player.position
	_cam_x = lerpf(_cam_x, p.x * 0.75, 1.0 - exp(-7.0 * delta))

	var chase_pos := Vector3(_cam_x, 3.5 + p.y * 0.35, p.z + 6.4)
	var chase_look := Vector3(_cam_x * 0.85, 1.1 + p.y * 0.3, p.z - 9.0)
	var menu_pos := Vector3(p.x + 0.9, 1.5, p.z - 4.4)
	var menu_look := Vector3(p.x + 1.7, 1.0, p.z)
	var pos := menu_pos.lerp(chase_pos, b)
	pos.x += sin(b * PI) * 3.5
	pos.y += sin(b * PI) * 1.2
	var look := menu_look.lerp(chase_look, b)

	if _shake > 0.0:
		_shake = maxf(_shake - delta, 0.0)
		var amount := _shake * 0.35
		pos += Vector3(_rng.randf_range(-amount, amount), _rng.randf_range(-amount, amount), 0.0)
	_camera.look_at_from_position(pos, look, Vector3.UP)
	var speed_factor := clampf((_speed - GameConfig.START_SPEED) / (GameConfig.MAX_SPEED - GameConfig.START_SPEED), 0.0, 1.0)
	_camera.fov = lerpf(60.0, lerpf(62.0, 72.0, speed_factor), b)


# ------------------------------------------------- Android: voltar / segundo plano

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED:
			if state == GameState.PLAYING and not get_tree().paused:
				if _hud.is_counting_down():
					return
				_pause()
		NOTIFICATION_WM_GO_BACK_REQUEST:
			_on_back()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).keycode == KEY_ESCAPE:
		_on_back()


func _on_back() -> void:
	if Ads.is_showing():
		return
	if _settings_menu.visible and _settings_menu.is_privacy_open():
		_settings_menu._show_privacy(false)
		return
	if _characters_menu.visible or _missions_menu.visible or _settings_menu.visible:
		_back_to_main_menu()
		return
	match state:
		GameState.MENU:
			get_tree().quit()
		GameState.PLAYING:
			if _pause_menu.visible:
				_resume()
			else:
				_pause()
		GameState.REVIVE_OFFER:
			_revive_menu._on_skip()
		GameState.GAME_OVER:
			_go_to_menu()
