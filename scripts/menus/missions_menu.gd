class_name MissionsMenu
extends BaseMenu
## Missões diárias com barra de progresso e botão de resgate,
## mais o acompanhamento das metas de distância.

signal back_pressed

var _coins: CoinCounter
var _rows: VBoxContainer
var _goal: Label
var _goal_bar: ProgressBar
var _goal_info: Label


func _build() -> void:
	add_dim()
	var margin := add_safe_margin(20.0)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	margin.add_child(col)

	var top := HBoxContainer.new()
	col.add_child(top)
	var back := UiTheme.make_button("VOLTAR", UiTheme.COLOR_NEUTRAL, Vector2(200, 72), 28)
	back.pressed.connect(func(): back_pressed.emit())
	top.add_child(back)
	var title := UiTheme.make_label("MISSÕES DIÁRIAS", 40)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	_coins = CoinCounter.new(32)
	_coins.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(_coins)

	var panel := UiTheme.make_panel()
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.custom_minimum_size = Vector2(980, 0)
	col.add_child(panel)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 12)
	panel.add_child(_rows)

	var goals := UiTheme.make_panel()
	goals.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	goals.custom_minimum_size = Vector2(980, 0)
	col.add_child(goals)
	var gcol := VBoxContainer.new()
	gcol.add_theme_constant_override("separation", 6)
	goals.add_child(gcol)
	_goal = UiTheme.make_label("", 26, UiTheme.COLOR_GOLD, HORIZONTAL_ALIGNMENT_LEFT)
	gcol.add_child(_goal)
	_goal_bar = ProgressBar.new()
	_goal_bar.custom_minimum_size = Vector2(0, 20)
	_goal_bar.show_percentage = false
	gcol.add_child(_goal_bar)
	_goal_info = UiTheme.make_label("", 20, Color(0.85, 0.9, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	gcol.add_child(_goal_info)

	col.add_child(UiTheme.make_label("Novas missões todos os dias à meia-noite (horário do celular).", 18, Color(0.8, 0.85, 0.95)))
	SaveManager.coins_changed.connect(func(total: int): _coins.set_value(total))


func _refresh() -> void:
	_coins.set_value(SaveManager.get_coins())
	for child in _rows.get_children():
		child.queue_free()
	var missions := Missions.get_missions()
	for i in missions.size():
		_rows.add_child(_make_row(i, missions[i]))

	var best := SaveManager.get_best_score()
	var next_index := -1
	for i in GameConfig.MILESTONES.size():
		if not SaveManager.is_milestone_claimed(GameConfig.MILESTONES[i]):
			next_index = i
			break
	if next_index == -1:
		_goal.text = "Todas as metas concluídas!"
		_goal_bar.value = 100
	else:
		var target: int = GameConfig.MILESTONES[next_index]
		_goal.text = "Próxima meta: %d pontos em uma partida  (+%d moedas)" % [target, GameConfig.milestone_reward(next_index)]
		_goal_bar.max_value = target
		_goal_bar.value = mini(best, target)
	_goal_info.text = "Metas alcançadas: %d de %d   |   Seu recorde: %d" % [
		SaveManager.get_milestones_claimed_count(), GameConfig.MILESTONES.size(), best]


func _make_row(index: int, m: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 4)
	row.add_child(info)
	info.add_child(UiTheme.make_label(m["text"], 26, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT))
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 18)
	bar.show_percentage = false
	bar.max_value = m["target"]
	bar.value = m["progress"]
	info.add_child(bar)
	info.add_child(UiTheme.make_label("%d / %d" % [m["progress"], m["target"]], 18, Color(0.8, 0.85, 0.95), HORIZONTAL_ALIGNMENT_LEFT))

	var reward := UiTheme.make_label("+%d" % m["reward"], 30, UiTheme.COLOR_GOLD)
	reward.custom_minimum_size = Vector2(90, 0)
	row.add_child(reward)
	var button := UiTheme.make_button("", UiTheme.COLOR_PRIMARY, Vector2(230, 72), 26)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if m["claimed"]:
		button.text = "RESGATADO"
		button.disabled = true
	elif m["complete"]:
		button.text = "RESGATAR"
		UiTheme.style_button(button, UiTheme.COLOR_ACCENT)
		button.pressed.connect(_claim.bind(index))
	else:
		button.text = "EM ANDAMENTO"
		button.disabled = true
	row.add_child(button)
	return row


func _claim(index: int) -> void:
	if Missions.claim(index) > 0:
		AudioManager.play_sfx("reward")
	_refresh()
