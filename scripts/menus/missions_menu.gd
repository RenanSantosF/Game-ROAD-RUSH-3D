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
	var back := UiTheme.make_button(tr("BACK"), UiTheme.COLOR_NEUTRAL, Vector2(200, 72), 28)
	back.pressed.connect(func(): back_pressed.emit())
	top.add_child(back)
	top.add_child(UiTheme.spacer(false))
	_coins = CoinCounter.new(32)
	_coins.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(_coins)
	col.add_child(UiTheme.make_label(tr("DAILY_MISSIONS"), 44))

	var panel := UiTheme.make_panel()
	col.add_child(panel)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 12)
	panel.add_child(_rows)

	var goals := UiTheme.make_panel()
	col.add_child(goals)
	var gcol := VBoxContainer.new()
	gcol.add_theme_constant_override("separation", 6)
	goals.add_child(gcol)
	_goal = UiTheme.make_wrapped_label("", 26, UiTheme.COLOR_GOLD)
	gcol.add_child(_goal)
	_goal_bar = ProgressBar.new()
	_goal_bar.custom_minimum_size = Vector2(0, 20)
	_goal_bar.show_percentage = false
	gcol.add_child(_goal_bar)
	_goal_info = UiTheme.make_wrapped_label("", 22, Color(0.85, 0.9, 1.0))
	gcol.add_child(_goal_info)

	col.add_child(UiTheme.make_wrapped_label(tr("MISSIONS_RESET_INFO"), 20, Color(0.8, 0.85, 0.95)))
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
		_goal.text = tr("ALL_GOALS_DONE")
		_goal_bar.value = 100
	else:
		var target: int = GameConfig.MILESTONES[next_index]
		_goal.text = tr("NEXT_GOAL_REWARD") % [target, GameConfig.milestone_reward(next_index)]
		_goal_bar.max_value = target
		_goal_bar.value = mini(best, target)
	_goal_info.text = tr("GOALS_INFO") % [
		SaveManager.get_milestones_claimed_count(), GameConfig.MILESTONES.size(), best]


func _make_row(index: int, m: Dictionary) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	var text := UiTheme.make_wrapped_label(m["text"], 28)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	box.add_child(text)
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 18)
	bar.show_percentage = false
	bar.max_value = m["target"]
	bar.value = m["progress"]
	box.add_child(bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	box.add_child(row)
	var progress := UiTheme.make_label("%d / %d" % [m["progress"], m["target"]], 22, Color(0.8, 0.85, 0.95), HORIZONTAL_ALIGNMENT_LEFT)
	progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(progress)
	row.add_child(UiTheme.make_label("+%d" % m["reward"], 30, UiTheme.COLOR_GOLD))
	var button := UiTheme.make_button("", UiTheme.COLOR_PRIMARY, Vector2(250, 70), 26)
	if m["claimed"]:
		button.text = tr("CLAIMED")
		button.disabled = true
	elif m["complete"]:
		button.text = tr("CLAIM")
		UiTheme.style_button(button, UiTheme.COLOR_ACCENT)
		button.pressed.connect(_claim.bind(index))
	else:
		button.text = tr("IN_PROGRESS")
		button.disabled = true
	row.add_child(button)
	return box


func _claim(index: int) -> void:
	if Missions.claim(index) > 0:
		AudioManager.play_sfx("reward")
	_refresh()
