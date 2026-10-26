extends Node
## Teste automático (roda no PC/CI, não vai para o APK):
##   godot --headless --path . --fixed-fps 60 res://tests/smoke_test.tscn
## 1) Um "robô" joga várias partidas desviando dos obstáculos.
## 2) Testa pausa, morte, continuar, fim de jogo, moedas, compra e missões.
## Termina com "SMOKE TEST OK" ou "SMOKE TEST FAIL".

const BOT_RUN_SECONDS := 200.0
const BOT_RUNS := 3

var main: Node
var failures := []
var _bot_cooldown := 0.0


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
	var total_deaths := 0
	for run in BOT_RUNS:
		main._start_run()
		var time := 0.0
		var deaths := 0
		while time < BOT_RUN_SECONDS:
			await get_tree().process_frame
			time += 1.0 / 60.0
			if main.state == main.GameState.PLAYING:
				_bot_step(1.0 / 60.0)
			elif main.state == main.GameState.DYING:
				deaths += 1
				_report_death()
				# revive direto (sem anúncio) para continuar medindo
				main._spawner.clear_for_revive(main._player.distance)
				main._player.revive()
				main.state = main.GameState.PLAYING
				main._swipe.enabled = true
		print("Robô partida %d: %d m, %d moedas, %d batidas, obstáculos ativos=%d" % [
			run + 1, int(main._player.distance), main._run_coins, deaths, main._spawner.get_active_count()])
		total_deaths += deaths
		_check(main._player.distance > 1000.0, "robô não avançou o suficiente")
	print("Robô: total de batidas = %d" % total_deaths)
	_check(total_deaths <= BOT_RUNS * 3, "muitas batidas do robô (possível padrão impossível)")
	main._go_to_menu()


func _report_death() -> void:
	var p: Player = main._player
	for o in main._spawner._active:
		var d: float = o.get_along() - p.distance
		if absf(d) < 6.0:
			print("   batida perto de: tipo=%d faixa=%d d=%.1f  (jogador faixa=%d altura=%.2f deslizando=%s)" % [
				o.kind, o.lane, d, p.lane, p.height, p.is_sliding])


func _threat(lane: int, max_d: float) -> Obstacle:
	var p: Player = main._player
	var best: Obstacle = null
	var best_d := INF
	for o in main._spawner._active:
		if o.lane != lane:
			continue
		var front: float = o.get_along() - o.half_extents.z - p.distance
		if o.speed > 0.0:
			front *= main._speed / (main._speed + o.speed)
		if front < -o.half_extents.z * 2.0 - 0.5 or front > max_d:
			continue
		if front < best_d:
			best_d = front
			best = o
	return best


func _front(o: Obstacle) -> float:
	var p: Player = main._player
	var front: float = o.get_along() - o.half_extents.z - p.distance
	if o.speed > 0.0:
		front *= main._speed / (main._speed + o.speed)
	return front


func _is_hard(o: Obstacle) -> bool:
	return o.kind == Obstacle.Kind.CAR or o.kind == Obstacle.Kind.MOVING_CAR or o.kind == Obstacle.Kind.BUS


func _lane_cost(lane: int) -> float:
	var o := _threat(lane, 40.0)
	if o == null:
		return 0.0
	var f := _front(o)
	if _is_hard(o):
		return 100.0 - f
	return 10.0 - f * 0.1


func _bot_step(delta: float) -> void:
	_bot_cooldown -= delta
	var p: Player = main._player
	var speed: float = main._speed
	var o := _threat(p.lane, 40.0)
	if o != null:
		var f := _front(o)
		if _is_hard(o) and f < 30.0 and _bot_cooldown <= 0.0:
			var best_lane := p.lane
			var best_cost := _lane_cost(p.lane)
			for l in 3:
				if l == p.lane:
					continue
				var c := _lane_cost(l)
				if absi(l - p.lane) == 2:
					var mid := _threat(1, 40.0)
					if mid != null and _is_hard(mid) and _front(mid) < 3.0:
						continue
					c += 1.0
				if c < best_cost:
					best_cost = c
					best_lane = l
			if best_lane != p.lane:
				main._on_swipe(Vector2i.LEFT if best_lane < p.lane else Vector2i.RIGHT)
				_bot_cooldown = 0.12
		elif (o.kind == Obstacle.Kind.BARRIER or o.kind == Obstacle.Kind.CONES) and f < speed * 0.16 + 0.6 and f > 0.0:
			main._on_swipe(Vector2i.UP)
		elif o.kind == Obstacle.Kind.OVERHEAD and f < speed * 0.2 + 1.0 and f > -0.5 and not p.is_sliding:
			main._on_swipe(Vector2i.DOWN)


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
	var d_paused: float = main._player.distance
	await _frames(20)
	_check(is_equal_approx(d_paused, main._player.distance), "jogador andou durante a pausa")
	main._resume()
	await _frames(150)
	_check(not get_tree().paused, "contagem regressiva não retomou o jogo")

	# Moedas coletadas não duplicam
	main._run_coins = 10
	# Morte -> oferta de continuar -> anúncio simulado com recompensa
	main._kill_player()
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
	main._kill_player()
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

	# Recorde salvo e recarregado do disco
	var best := SaveManager.get_best_score()
	_check(best > 0, "recorde não foi salvo")
	SaveManager.load_game()
	_check(SaveManager.get_best_score() == best and SaveManager.get_coins() == doubled, "salvamento não persistiu")

	# Compra de personagem
	SaveManager.data["coins"] = 1000
	_check(not SaveManager.buy_character("miau", 1500), "comprou sem moedas suficientes")
	_check(SaveManager.buy_character("bia", 300), "não comprou personagem")
	_check(SaveManager.get_coins() == 700, "preço descontado errado")
	_check(not SaveManager.buy_character("bia", 300), "comprou o mesmo personagem duas vezes")
	_check(SaveManager.get_selected_character() == "bia", "personagem comprado não foi selecionado")

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
