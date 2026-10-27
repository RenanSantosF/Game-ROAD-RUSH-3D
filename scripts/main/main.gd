extends Node3D
## Controlador principal do jogo.
## Liga o bichinho, o mundo, a câmera panorâmica, a interface, o
## salvamento, as missões e os anúncios. Cada sistema fica no seu próprio
## script; aqui ficam só o fluxo da partida (estados) e a câmera.

enum GameState { MENU, PLAYING, DYING, REVIVE_OFFER, GAME_OVER }

const DEATH_DELAY := 1.2
const TUTORIAL_GAMES := 3

# Câmera panorâmica (de cima, na diagonal).
const PLAY_CAM_OFFSET := Vector3(1.5, 12.0, 5.2)
const PLAY_LOOK_OFFSET := Vector3(0.0, 0.0, -2.0)
const MENU_CAM_OFFSET := Vector3(0.6, 5.0, 4.6)
const MENU_LOOK_OFFSET := Vector3(0.0, -0.6, -0.4)
const SHOP_CAM_OFFSET := Vector3(0.4, 3.2, 3.4)
const SHOP_LOOK_OFFSET := Vector3(0.0, -0.6, -0.3)

var state: int = GameState.MENU

var _score := 0
var _run_coins := 0
var _run_time := 0.0
var _run_hops := 0
var _run_roads := 0
var _revived := false
var _run_committed := false
var _double_used := false
var _death_timer := 0.0
var _next_milestone := -1
var _scrolling := false
var _focus := 0.0

var _cam_pos := Vector3(3, 9, 7)
var _cam_look := Vector3.ZERO
var _cam_x := 0.0
var _shake := 0.0
var _rng := RandomNumberGenerator.new()

@onready var _player: Player = %Player
@onready var _world: World = %World
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

	_player.hopped.connect(_on_player_hopped)
	_player.landed.connect(_on_player_landed)
	_player.bumped.connect(func(): AudioManager.play_sfx("bump"))
	_swipe.swiped.connect(_on_swipe)
	_world.train_warning.connect(_on_train_warning)

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
	if get_tree().has_meta("reopen_settings"):
		# Voltando de uma troca de idioma: reabre as configurações.
		get_tree().remove_meta("reopen_settings")
		_open_submenu(_settings_menu)
	_snap_camera()
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


func _reset_world() -> void:
	_world.reset()
	_player.set_character(CharacterCatalog.get_by_id(SaveManager.get_selected_character()))
	_focus = 0.0
	_cam_x = 0.0


func _go_to_menu() -> void:
	get_tree().paused = false
	state = GameState.MENU
	_swipe.enabled = false
	_close_all_menus()
	_hud.visible = false
	_reset_world()
	_player.place(0, 0, 0.0, false)
	_player.model.face(Vector2i.DOWN)
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
	if state != GameState.MENU:
		_reset_world()
	_player.place(0, 0, 0.0, true)
	_score = 0
	_run_coins = 0
	_run_time = 0.0
	_run_hops = 0
	_run_roads = 0
	_revived = false
	_run_committed = false
	_double_used = false
	_scrolling = false
	_focus = 0.0
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
		GameState.MENU, GameState.DYING, GameState.REVIVE_OFFER, GameState.GAME_OVER:
			_world.update(delta, int(floor(_focus)))
			if state == GameState.DYING:
				_death_timer -= delta
				if _death_timer <= 0.0:
					_after_death()
	_update_camera(delta)


func _update_playing(delta: float) -> void:
	_run_time += delta
	_world.update(delta, int(floor(_focus)))
	_player.update(delta, _world)
	_check_hazards(delta)
	if state != GameState.PLAYING:
		return
	if _scrolling:
		_focus += GameConfig.scroll_speed_for_row(_score) * delta
	var desired := float(_player.row)
	if desired > _focus:
		_focus = lerpf(_focus, desired, 1.0 - exp(-4.0 * delta))
	if float(_player.row) < _focus - GameConfig.BEHIND_LIMIT:
		_kill("eagle")


func _check_hazards(delta: float) -> void:
	if _player.state != Player.State.ALIVE:
		return
	var lane := _world.get_lane(_player.visual_row())
	if lane == null:
		return
	if lane.is_dangerous():
		if _player.invincible_time <= 0.0 and lane.hit_test(_player.position.x, GameConfig.PLAYER_HALF_WIDTH):
			_kill("squash")
		return
	if lane.type == Lane.Type.RIVER and _player.is_grounded():
		var v := lane.platform_velocity_at(_player.position.x)
		if is_nan(v):
			_kill("water")
			return
		_player.ride(v * delta)
		if absf(_player.position.x) > GameConfig.COLUMNS_HALF + 0.6:
			_kill("water")


func _kill(cause: String) -> void:
	state = GameState.DYING
	_swipe.enabled = false
	_player.die(cause)
	_death_timer = DEATH_DELAY + (0.4 if cause == "eagle" else 0.0)
	_hud.set_pause_enabled(false)
	_hud.show_tutorial(false)
	match cause:
		"water":
			_shake = 0.15
			AudioManager.play_sfx("splash")
		"eagle":
			_shake = 0.3
			AudioManager.play_sfx("eagle")
			_hud.show_toast(tr("EAGLE_GOT_YOU"), Color(1.0, 0.75, 0.6))
		_:
			_shake = 0.45
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
	var start_row := maxi(_player.row, int(ceil(_focus - GameConfig.BEHIND_LIMIT + 1.0)))
	var spot := _world.find_safe_spot(start_row)
	_player.revive_at(spot.x, spot.y, 0.0)
	_focus = minf(_focus, float(spot.y))
	_hud.set_pause_enabled(true)
	_swipe.enabled = true
	state = GameState.PLAYING
	_hud.show_toast(tr("KEEP_HOPPING"), Color(0.6, 1.0, 0.6))


## Grava moedas, recorde, estatísticas e missões (uma única vez por partida).
func _commit_run() -> Dictionary:
	if _run_committed:
		return {}
	_run_committed = true
	var new_record := SaveManager.record_run(_score, _run_coins)
	var completed := Missions.record_run({
		"coins": _run_coins,
		"distance": _score,
		"time": int(_run_time),
		"hops": _run_hops,
		"roads": _run_roads,
		"games": 1,
	})
	return {"score": _score, "new_record": new_record, "completed": completed}


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


func _check_milestone() -> void:
	if _next_milestone < 0:
		return
	var target: int = GameConfig.MILESTONES[_next_milestone]
	if _score < target:
		return
	var reward := GameConfig.milestone_reward(_next_milestone)
	if SaveManager.claim_milestone(target, reward):
		AudioManager.play_sfx("reward")
		_hud.show_toast(tr("GOAL_REACHED") % [target, reward])
	_update_next_milestone()


func _update_next_milestone() -> void:
	_next_milestone = -1
	for i in GameConfig.MILESTONES.size():
		if not SaveManager.is_milestone_claimed(GameConfig.MILESTONES[i]):
			_next_milestone = i
			break
	if _next_milestone < 0:
		_hud.set_goal(tr("ALL_GOALS_DONE"))
	else:
		_hud.set_goal(tr("NEXT_GOAL") % GameConfig.MILESTONES[_next_milestone])


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
	state = GameState.GAME_OVER
	_start_run()


func _menu_from_pause() -> void:
	_commit_run()
	_go_to_menu()


# ----------------------------------------------------------------- Ações

func _on_swipe(direction: Vector2i) -> void:
	if state != GameState.PLAYING or get_tree().paused:
		return
	_player.request_hop(direction, _world)


func _on_player_hopped(_direction: Vector2i) -> void:
	_run_hops += 1
	if not _scrolling:
		_scrolling = true
		_hud.show_tutorial(false)
	AudioManager.play_sfx("hop", 0.08)


func _on_player_landed() -> void:
	if _world.take_coin(_player.row, _player.current_column()):
		_run_coins += 1
		_hud.set_coins(_run_coins)
		AudioManager.play_sfx("coin", 0.05)
	if _player.row > _score:
		_score = _player.row
		_hud.set_score(_score)
		var lane := _world.get_lane(_player.row)
		if lane != null and lane.type == Lane.Type.ROAD:
			_run_roads += 1
		_check_milestone()


func _on_train_warning(row: int) -> void:
	if state == GameState.PLAYING and absi(row - _player.row) < 7:
		AudioManager.play_sfx("bell")


# ----------------------------------------------------------------- Câmera

func _camera_targets() -> Array:
	var p := _player.position
	if state == GameState.MENU:
		if _characters_menu.visible:
			return [p + SHOP_CAM_OFFSET, p + SHOP_LOOK_OFFSET]
		return [p + MENU_CAM_OFFSET, p + MENU_LOOK_OFFSET]
	var focus := Vector3(_cam_x, 0.0, -_focus)
	return [focus + PLAY_CAM_OFFSET, focus + PLAY_LOOK_OFFSET]


func _snap_camera() -> void:
	var targets := _camera_targets()
	_cam_pos = targets[0]
	_cam_look = targets[1]


func _update_camera(delta: float) -> void:
	if state != GameState.MENU:
		_cam_x = lerpf(_cam_x, clampf(_player.position.x * 0.7, -2.2, 2.2), 1.0 - exp(-3.0 * delta))
	var targets := _camera_targets()
	var k := 1.0 - exp(-(8.0 if state == GameState.PLAYING else 4.0) * delta)
	_cam_pos = _cam_pos.lerp(targets[0], k)
	_cam_look = _cam_look.lerp(targets[1], k)
	var pos := _cam_pos
	if _shake > 0.0:
		_shake = maxf(_shake - delta, 0.0)
		var amount := _shake * 0.3
		pos += Vector3(_rng.randf_range(-amount, amount), _rng.randf_range(-amount, amount), 0.0)
	_camera.look_at_from_position(pos, _cam_look, Vector3.UP)


# ------------------------------------------------- Android: voltar / segundo plano

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED:
			if state == GameState.PLAYING and not get_tree().paused and not _hud.is_counting_down():
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
