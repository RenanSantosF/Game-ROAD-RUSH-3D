extends Node
## Salvamento local (Autoload "SaveManager").
## Grava um JSON em user://save.json, que no Android fica na pasta
## privada do app (nenhuma permissão é necessária e nada sai do aparelho).
## A gravação é feita em arquivo temporário + troca, com cópia de
## segurança, para não corromper o progresso se o app fechar no meio.

signal coins_changed(total: int)
signal settings_changed

const SAVE_PATH := "user://save.json"
const TEMP_PATH := "user://save.tmp"
const BACKUP_PATH := "user://save.bak"
const SAVE_VERSION := 2

var data: Dictionary = {}


func _ready() -> void:
	load_game()


func _defaults() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"coins": 0,
		"best_score": 0,
		"language": "auto",
		"selected_character": CharacterCatalog.DEFAULT_ID,
		"unlocked": [CharacterCatalog.DEFAULT_ID],
		"settings": {
			"music": true,
			"sfx": true,
			"shadows": true,
			"show_fps": false,
		},
		"stats": {
			"games": 0,
			"total_distance": 0,
			"total_coins": 0,
		},
		"milestones_claimed": {},
		"missions": {},
	}


# ------------------------------------------------------------ Leitura/gravação

func load_game() -> void:
	var loaded := _read_json(SAVE_PATH)
	if loaded.is_empty():
		loaded = _read_json(BACKUP_PATH)
	data = _merge(_defaults(), loaded)
	if int(loaded.get("version", SAVE_VERSION)) < SAVE_VERSION:
		# v1 era o protótipo de corrida: recorde, metas e missões não valem mais.
		data["version"] = SAVE_VERSION
		data["best_score"] = 0
		data["milestones_claimed"] = {}
		data["missions"] = {}
		data["selected_character"] = CharacterCatalog.DEFAULT_ID


func save_game() -> void:
	var file := FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Falha ao salvar: %s" % error_string(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify(data))
	file.close()
	var dir := DirAccess.open("user://")
	if dir == null:
		return
	if dir.file_exists("save.json"):
		if dir.file_exists("save.bak"):
			dir.remove("save.bak")
		dir.rename("save.json", "save.bak")
	dir.rename("save.tmp", "save.json")


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


## Mantém a estrutura padrão e aproveita só valores válidos do arquivo.
func _merge(defaults: Dictionary, loaded: Dictionary) -> Dictionary:
	var result := defaults.duplicate(true)
	for key in defaults.keys():
		if not loaded.has(key):
			continue
		var def_value = defaults[key]
		var value = loaded[key]
		if typeof(def_value) == TYPE_DICTIONARY and typeof(value) == TYPE_DICTIONARY:
			if (def_value as Dictionary).is_empty():
				result[key] = value
			else:
				result[key] = _merge(def_value, value)
		elif typeof(def_value) == TYPE_INT and (typeof(value) == TYPE_FLOAT or typeof(value) == TYPE_INT):
			result[key] = int(value)
		elif typeof(def_value) == typeof(value):
			result[key] = value
	return result


func reset_progress() -> void:
	var settings: Dictionary = data["settings"]
	data = _defaults()
	data["settings"] = settings
	save_game()
	coins_changed.emit(get_coins())


# ------------------------------------------------------------------ Moedas

func get_coins() -> int:
	return int(data["coins"])


func add_coins(amount: int) -> void:
	if amount <= 0:
		return
	data["coins"] = get_coins() + amount
	coins_changed.emit(get_coins())


func spend_coins(amount: int) -> bool:
	if amount < 0 or get_coins() < amount:
		return false
	data["coins"] = get_coins() - amount
	coins_changed.emit(get_coins())
	return true


# ---------------------------------------------------- Recorde e estatísticas

func get_best_score() -> int:
	return int(data["best_score"])


func get_stat(key: String) -> int:
	return int(data["stats"].get(key, 0))


## Registra o fim de uma partida. Retorna true se for novo recorde.
func record_run(score: int, coins: int) -> bool:
	var new_record := score > get_best_score()
	if new_record:
		data["best_score"] = score
	add_coins(coins)
	var stats: Dictionary = data["stats"]
	stats["games"] = int(stats["games"]) + 1
	stats["total_distance"] = int(stats["total_distance"]) + score
	stats["total_coins"] = int(stats["total_coins"]) + coins
	save_game()
	return new_record


# ----------------------------------------------------------- Personagens

func get_selected_character() -> String:
	var id: String = data["selected_character"]
	var exists: bool = CharacterCatalog.get_by_id(id)["id"] == id
	return id if exists and is_unlocked(id) else CharacterCatalog.DEFAULT_ID


func set_selected_character(id: String) -> void:
	if is_unlocked(id):
		data["selected_character"] = id
		save_game()


func is_unlocked(id: String) -> bool:
	return id == CharacterCatalog.DEFAULT_ID or (data["unlocked"] as Array).has(id)


## Compra um personagem. Só desconta se tiver moedas e ainda não possuir.
func buy_character(id: String, price: int) -> bool:
	if is_unlocked(id):
		return false
	if not spend_coins(price):
		return false
	(data["unlocked"] as Array).append(id)
	data["selected_character"] = id
	save_game()
	return true


# ------------------------------------------------------------------ Metas

func is_milestone_claimed(meters: int) -> bool:
	return (data["milestones_claimed"] as Dictionary).has(str(meters))


## Marca a meta como alcançada. Retorna false se já tinha sido paga.
func claim_milestone(meters: int, reward: int) -> bool:
	if is_milestone_claimed(meters):
		return false
	data["milestones_claimed"][str(meters)] = true
	add_coins(reward)
	save_game()
	return true


func get_milestones_claimed_count() -> int:
	return (data["milestones_claimed"] as Dictionary).size()


# ----------------------------------------------------------- Configurações

func get_setting(key: String) -> bool:
	return bool(data["settings"].get(key, true))


func set_setting(key: String, value: bool) -> void:
	data["settings"][key] = value
	save_game()
	settings_changed.emit()


# ----------------------------------------------------------------- Idioma

func get_language() -> String:
	return str(data.get("language", "auto"))


func set_language(value: String) -> void:
	data["language"] = value
	save_game()


# ---------------------------------------------------------------- Missões

func get_missions_data() -> Dictionary:
	return data["missions"]


func set_missions_data(value: Dictionary) -> void:
	data["missions"] = value
