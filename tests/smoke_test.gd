extends Node
## Teste automático (roda no PC/CI, não vai para o APK):
##   godot --headless --path . --fixed-fps 60 res://tests/smoke_test.tscn
## 1) Um "robô" joga várias partidas desviando dos obstáculos.
## 2) Testa pausa, morte, continuar, fim de jogo, moedas, compra e missões.
## Termina com "SMOKE TEST OK" ou "SMOKE TEST FAIL".

const BOT_RUN_SECONDS := 120.0
const BOT_RUNS := 3

var main: Node
var failures := []


func _ready() -> void:
	SaveManager.reset_progress()
	main = load("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	await _frames(5)
	await _test_bot()
	await _test_flows()
	if failures.is_empty():
		print("SMOKE TEST OK")
		get_tree().quit(0)
	else:
		for f in failures:
			print("FALHA: ", f)
		print("SMOKE TEST FAIL")
		get_tree().quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


# ----------------------------------------------------------------- Robô

func _test_bot() -> void:
	var best := 0
	var all_deaths := {}
	for run in BOT_RUNS:
		main._start_run()
		var time := 0.0
		var deaths := {}
		while time < BOT_RUN_SECONDS:
			await get_tree().process_frame
			time += 1.0 / 60.0
			if main.state == main.GameState.PLAYING:
				_bot_step()
			elif main.state == main.GameState.DYING:
				var cause: String = main._player.model._death
				deaths[cause] = deaths.get(cause, 0) + 1
				all_deaths[cause] = all_deaths.get(cause, 0) + 1
				# continua direto (sem anúncio) para seguir medindo
				main.state = main.GameState.REVIVE_OFFER
				main._revived = false
				Ads.show_rewarded("revive", main._on_revive_ad_result)
				Ads._finish(true)
		print("Robô partida %d: %d pontos, %d moedas, mortes=%s" % [run + 1, main._score, main._run_coins, deaths])
		best = maxi(best, main._score)
	print("Robô: melhor = %d, mortes = %s" % [best, all_deaths])
	_check(best >= 60, "robô não avançou o suficiente (melhor %d)" % best)
	main._go_to_menu()


func _lane(row: int) -> Lane:
	return main._world.get_lane(row)


## O destino (linha, x) é seguro para pousar e ficar um pouco?
func _safe_target(row: int, x: float, drift: float) -> bool:
	if main._world.is_blocked(row, roundi(x)):
		return false
	var lane := _lane(row)
	if lane == null:
		return false
	var hop := GameConfig.HOP_TIME
	if lane.is_dangerous():
		for i in 8:
			if lane.predict_hit(x, 0.5, hop * 0.5 + i * 0.08):
				return false
		return true
	if lane.type == Lane.Type.RIVER:
		var land_x := x + drift * hop
		return lane.predict_platform(land_x, hop, 0.2) and lane.predict_platform(land_x, hop + 0.25, 0.2)
	return true


func _safe_here() -> bool:
	var p: Player = main._player
	var lane := _lane(p.row)
	if lane.is_dangerous():
		for i in 6:
			if lane.predict_hit(p.position.x, 0.45, i * 0.08):
				return false
		return true
	if lane.type == Lane.Type.RIVER:
		return absf(p.position.x) < GameConfig.COLUMNS_HALF - 0.3 and lane.predict_platform(p.position.x, 0.35, 0.05)
	return true


func _bot_step() -> void:
	var p: Player = main._player
	if p.hopping:
		return
	var lane := _lane(p.row)
	var on_river := lane.type == Lane.Type.RIVER
	var drift := 0.0
	if on_river:
		var v := lane.platform_velocity_at(p.position.x)
		drift = 0.0 if is_nan(v) else v
	var col := roundi(p.position.x)
	if _safe_target(p.row + 1, float(col), 0.0) and _safe_now_for_hop():
		main._on_swipe(Vector2i.UP)
		return
	if main._world.is_blocked(p.row + 1, col) and lane.type == Lane.Type.GRASS:
		# Árvore à frente: anda para o lado até uma coluna livre.
		for step in [1, -1, 2, -2, 3, -3, 4, -4, 5, -5, 6, -6, 7, -7, 8, -8]:
			var c: int = col + step
			if GameConfig.is_playable_column(c) and not main._world.is_blocked(p.row + 1, c):
				var dir := Vector2i.RIGHT if step > 0 else Vector2i.LEFT
				if not main._world.is_blocked(p.row, col + dir.x):
					main._on_swipe(dir)
					return
	if _safe_here():
		return
	var options := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN]
	if p.position.x > 0.0:
		options = [Vector2i.LEFT, Vector2i.DOWN, Vector2i.RIGHT]
	for dir in options:
		var tx := float(col + dir.x)
		var tr := p.row + (-1 if dir == Vector2i.DOWN else 0)
		if on_river and dir.x != 0:
			tx = p.position.x + dir.x
		if _safe_target(tr, tx, drift if (on_river and dir.x != 0) else 0.0):
			main._on_swipe(dir)
			return


func _safe_now_for_hop() -> bool:
	var p: Player = main._player
	var lane := _lane(p.row)
	if lane.is_dangerous():
		return not lane.predict_hit(p.position.x, 0.45, GameConfig.HOP_TIME * 0.5)
	return true


# ----------------------------------------------------------------- Fluxos

func _test_flows() -> void:
	SaveManager.reset_progress()
	var coins_before := SaveManager.get_coins()

	# Partida + pausa
	main._start_run()
	await _frames(30)
	_check(main.state == main.GameState.PLAYING, "partida não começou")
	main._pause()
	_check(get_tree().paused, "pausa não congelou o jogo")
	main._on_swipe(Vector2i.UP)
	var pos_paused: Vector3 = main._player.position
	await _frames(20)
	_check(pos_paused == main._player.position, "jogador se mexeu durante a pausa")
	main._resume()
	await _frames(150)
	_check(not get_tree().paused, "contagem regressiva não retomou o jogo")

	# Moedas coletadas não duplicam
	main._run_coins = 10
	main._score = 7
	# Morte -> oferta de continuar -> anúncio simulado com recompensa
	main._kill("squash")
	await _frames(int(main.DEATH_DELAY * 60) + 10)
	_check(main.state == main.GameState.REVIVE_OFFER, "oferta de continuar não apareceu (estado %d)" % main.state)
	main._on_revive_accepted()
	await _frames(2)
	_check(Ads.is_showing(), "anúncio simulado não abriu")
	Ads._finish(true)
	await _frames(2)
	_check(main.state == main.GameState.PLAYING and main._revived, "não continuou após recompensa")

	# Segunda morte -> fim de jogo direto (só 1 continuar por partida)
	await _frames(200)
	main._kill("squash")
	await _frames(int(main.DEATH_DELAY * 60) + 10)
	_check(main.state == main.GameState.GAME_OVER, "fim de jogo não apareceu")
	var after_run := SaveManager.get_coins()
	_check(after_run >= coins_before + 10, "moedas da partida não foram salvas")
	main._finish_run()
	main._commit_run()
	_check(SaveManager.get_coins() == after_run, "moedas contadas duas vezes")

	# Dobrar moedas: recompensa só uma vez, e só com anúncio concluído
	main._on_double_pressed()
	await _frames(2)
	Ads._finish(false)
	_check(SaveManager.get_coins() == after_run, "recompensa entregue sem concluir o anúncio")
	main._on_double_pressed()
	await _frames(2)
	Ads._finish(true)
	var doubled := SaveManager.get_coins()
	_check(doubled == after_run + main._run_coins, "dobrar moedas falhou")
	main._on_double_pressed()
	await _frames(2)
	if Ads.is_showing():
		Ads._finish(true)
	_check(SaveManager.get_coins() == doubled, "dobrar moedas pagou duas vezes")

	# Intersticial: respeita as regras de frequência
	Ads._games_since_interstitial = 0
	Ads._last_ad_time = -100000.0
	Ads._rewarded_this_game = false
	SaveManager.data["stats"]["games"] = 10
	_check(not Ads.can_show_interstitial(), "intersticial antes de 3 partidas")
	for i in 3:
		Ads.on_game_finished()
	_check(Ads.can_show_interstitial(), "intersticial não liberou após 3 partidas")
	var shown := [false]
	Ads.show_interstitial_if_allowed(func(): shown[0] = true)
	await _frames(2)
	_check(Ads.is_showing(), "intersticial simulado não abriu")
	Ads._finish(false)
	_check(shown[0], "jogo não continuou depois do intersticial")
	for i in 3:
		Ads.on_game_finished()
	_check(not Ads.can_show_interstitial(), "intersticial ignorou o intervalo de 2 minutos")
	Ads._last_ad_time = -100000.0
	Ads._rewarded_this_game = true
	_check(not Ads.can_show_interstitial(), "intersticial na partida com recompensado")
	Ads._rewarded_this_game = false
	SaveManager.data["stats"]["games"] = 1
	_check(not Ads.can_show_interstitial(), "intersticial para jogador novo")

	# Recorde salvo e recarregado do disco
	var best := SaveManager.get_best_score()
	_check(best > 0, "recorde não foi salvo")
	SaveManager.load_game()
	_check(SaveManager.get_best_score() == best and SaveManager.get_coins() == doubled, "salvamento não persistiu")

	# Compra de personagem
	SaveManager.data["coins"] = 1000
	_check(not SaveManager.buy_character("gato", 1500), "comprou sem moedas suficientes")
	_check(SaveManager.buy_character("pato", 300), "não comprou personagem")
	_check(SaveManager.get_coins() == 700, "preço descontado errado")
	_check(not SaveManager.buy_character("pato", 300), "comprou o mesmo personagem duas vezes")
	_check(SaveManager.get_selected_character() == "pato", "personagem comprado não foi selecionado")

	# Missões: progresso, resgate único
	var missions := Missions.get_missions()
	_check(missions.size() == 3, "não gerou 3 missões")
	Missions.record_run({"coins": 9999, "distance": 99999, "time": 9999, "jumps": 999, "slides": 999, "games": 99})
	var coins0 := SaveManager.get_coins()
	var got := 0
	for i in 3:
		got += Missions.claim(i)
	_check(got > 0 and SaveManager.get_coins() == coins0 + got, "resgate de missões falhou")
	for i in 3:
		_check(Missions.claim(i) == 0, "missão resgatada duas vezes")

	# Idiomas: português, inglês e espanhol + automático
	for pair in [["pt", "JOGAR"], ["en", "PLAY"], ["es", "JUGAR"]]:
		SaveManager.set_language(pair[0])
		Loc.apply_language()
		_check(tr("MENU_PLAY") == pair[1], "tradução errada para %s" % pair[0])
	for key in Loc.STRINGS:
		_check(Loc.STRINGS[key].size() == 3, "texto sem as 3 traduções: %s" % key)
	SaveManager.set_language("auto")
	Loc.apply_language()
	_check(Loc.LANGUAGES.has(TranslationServer.get_locale()), "idioma automático inválido")

	# Metas: não pagam duas vezes
	_check(SaveManager.claim_milestone(99, 5), "meta não registrou")
	_check(not SaveManager.claim_milestone(99, 5), "meta paga duas vezes")

	# Telas abrem sem erro
	main._go_to_menu()
	for menu in [main._characters_menu, main._missions_menu, main._settings_menu]:
		main._open_submenu(menu)
		await _frames(3)
		main._back_to_main_menu()
	for key in ["music", "sfx", "shadows", "show_fps"]:
		SaveManager.set_setting(key, not SaveManager.get_setting(key))
		SaveManager.set_setting(key, not SaveManager.get_setting(key))
	await _frames(3)
	SaveManager.reset_progress()
