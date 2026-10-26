extends Node
## Missões diárias (Autoload "Missions").
##
## A cada dia (pela data do aparelho) são sorteadas 3 missões: uma de
## moedas, uma de distância e uma de tempo/ações. O sorteio usa a data
## como semente, então é estável durante o dia.
##
## Limitação de um sistema 100% local: a data vem do relógio do celular.
## Se o jogador adiantar o relógio, recebe missões novas antes da hora.
## Para reduzir abuso, se o relógio voltar para uma data anterior, as
## missões atuais são mantidas (não há sorteio novo nem recompensa extra).
## Só um servidor de horário eliminaria isso, o que não faz parte da v1.

signal missions_changed

const TEMPLATES := [
	{"id": "run_coins", "group": 0, "stat": "coins", "mode": "best",
		"text": "Colete %d moedas em uma partida", "targets": [25, 40, 60], "rewards": [50, 80, 120]},
	{"id": "day_coins", "group": 0, "stat": "coins", "mode": "sum",
		"text": "Colete %d moedas hoje", "targets": [80, 150, 250], "rewards": [60, 100, 150]},
	{"id": "run_distance", "group": 1, "stat": "distance", "mode": "best",
		"text": "Percorra %d m em uma partida", "targets": [400, 800, 1500], "rewards": [50, 100, 150]},
	{"id": "day_distance", "group": 1, "stat": "distance", "mode": "sum",
		"text": "Percorra %d m hoje", "targets": [1500, 3000, 5000], "rewards": [60, 100, 150]},
	{"id": "run_time", "group": 2, "stat": "time", "mode": "best",
		"text": "Sobreviva %d segundos em uma partida", "targets": [40, 70, 110], "rewards": [50, 90, 140]},
	{"id": "day_jumps", "group": 2, "stat": "jumps", "mode": "sum",
		"text": "Pule %d vezes", "targets": [20, 40, 70], "rewards": [40, 70, 100]},
	{"id": "day_slides", "group": 2, "stat": "slides", "mode": "sum",
		"text": "Deslize %d vezes", "targets": [15, 30, 50], "rewards": [40, 70, 100]},
	{"id": "day_games", "group": 2, "stat": "games", "mode": "sum",
		"text": "Jogue %d partidas", "targets": [3, 5, 8], "rewards": [40, 60, 90]},
]


func _ready() -> void:
	ensure_today()


func today() -> String:
	return Time.get_date_string_from_system(false)


func ensure_today() -> void:
	var stored := SaveManager.get_missions_data()
	var current := today()
	var stored_date: String = stored.get("date", "")
	if stored_date != "" and current <= stored_date and stored.has("list"):
		return
	SaveManager.set_missions_data(_generate(current))
	SaveManager.save_game()
	missions_changed.emit()


func _generate(date: String) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(date)
	var list := []
	for group in 3:
		var options := []
		for i in TEMPLATES.size():
			if TEMPLATES[i]["group"] == group:
				options.append(i)
		var tid: int = options[rng.randi() % options.size()]
		var level := rng.randi() % 3
		list.append({
			"template": TEMPLATES[tid]["id"],
			"target": TEMPLATES[tid]["targets"][level],
			"reward": TEMPLATES[tid]["rewards"][level],
			"progress": 0,
			"claimed": false,
		})
	return {"date": date, "list": list}


func _template(id: String) -> Dictionary:
	for t in TEMPLATES:
		if t["id"] == id:
			return t
	return TEMPLATES[0]


## Lista pronta para a interface.
func get_missions() -> Array:
	ensure_today()
	var result := []
	for m in SaveManager.get_missions_data()["list"]:
		var t := _template(m["template"])
		var target := int(m["target"])
		var progress := mini(int(m["progress"]), target)
		result.append({
			"text": t["text"] % target,
			"target": target,
			"progress": progress,
			"reward": int(m["reward"]),
			"claimed": bool(m["claimed"]),
			"complete": progress >= target,
		})
	return result


## Atualiza o progresso com os dados de uma partida.
## Retorna os textos das missões concluídas agora.
func record_run(stats: Dictionary) -> Array:
	ensure_today()
	var completed := []
	for m in SaveManager.get_missions_data()["list"]:
		var t := _template(m["template"])
		var target := int(m["target"])
		var before := int(m["progress"])
		if before >= target:
			continue
		var value := int(stats.get(t["stat"], 0))
		var after := maxi(before, value) if t["mode"] == "best" else before + value
		m["progress"] = mini(after, target)
		if after >= target:
			completed.append(t["text"] % target)
	SaveManager.save_game()
	missions_changed.emit()
	return completed


## Entrega a recompensa uma única vez. Retorna as moedas recebidas.
func claim(index: int) -> int:
	var list: Array = SaveManager.get_missions_data()["list"]
	if index < 0 or index >= list.size():
		return 0
	var m: Dictionary = list[index]
	if bool(m["claimed"]) or int(m["progress"]) < int(m["target"]):
		return 0
	m["claimed"] = true
	var reward := int(m["reward"])
	SaveManager.add_coins(reward)
	SaveManager.save_game()
	missions_changed.emit()
	return reward


func has_claimable() -> bool:
	for m in get_missions():
		if m["complete"] and not m["claimed"]:
			return true
	return false
