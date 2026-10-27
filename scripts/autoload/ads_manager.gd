extends Node
## Camada de anúncios (Autoload "Ads"), separada da lógica do jogo.
##
## Situação atual (versão de testes):
## - NENHUM SDK de anúncios está incluído e o app não acessa a internet.
## - Em builds de depuração (APK do GitHub Actions) existe um "anúncio
##   simulado" local, claramente identificado, só para testar o fluxo de
##   recompensa (continuar a partida e dobrar moedas). Ele não exibe
##   anúncio real, não gera impressão e não envia dados.
## - Em builds de release o provedor é NONE e os botões de anúncio somem.
##
## A integração real com o Google AdMob (plugin oficial do Godot +
## configuração para público infantil) será feita na Etapa 13,
## implementando um novo provedor aqui sem mexer no resto do jogo.
## A recompensa só é entregue quando o provedor confirma o resultado.

signal ad_closed(placement: String, rewarded: bool)

enum Provider { NONE, DEBUG_MOCK }

const MOCK_DURATION := 3

var provider: int = Provider.NONE

var _showing := false
var _placement := ""
var _callback: Callable
var _layer: CanvasLayer
var _countdown_label: Label
var _reward_button: Button
var _seconds_left := 0
var _timer: Timer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	provider = Provider.DEBUG_MOCK if OS.is_debug_build() else Provider.NONE


func is_rewarded_available() -> bool:
	return provider != Provider.NONE and not _showing


func is_showing() -> bool:
	return _showing


## Mostra um anúncio recompensado. on_done recebe true SOMENTE se o
## anúncio foi assistido até o fim.
func show_rewarded(placement: String, on_done: Callable) -> void:
	if not is_rewarded_available():
		on_done.call(false)
		return
	_showing = true
	_placement = placement
	_callback = on_done
	AudioManager.set_ducked(true)
	match provider:
		Provider.DEBUG_MOCK:
			_show_mock()


func _finish(rewarded: bool) -> void:
	if not _showing:
		return
	_showing = false
	AudioManager.set_ducked(false)
	if _layer != null:
		_layer.queue_free()
		_layer = null
	var cb := _callback
	_callback = Callable()
	ad_closed.emit(_placement, rewarded)
	if cb.is_valid():
		cb.call(rewarded)


# ------------------------------------------------- Anúncio simulado (debug)

func _show_mock() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 100
	add_child(_layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = UiTheme.get_theme()
	_layer.add_child(root)
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.06, 0.1, 0.96)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 20)
	root.add_child(box)
	box.add_child(UiTheme.make_label(tr("AD_MOCK_TITLE"), 48, UiTheme.COLOR_GOLD))
	box.add_child(UiTheme.make_label(tr("AD_MOCK_INFO"), 26))
	_countdown_label = UiTheme.make_label("", 34)
	box.add_child(_countdown_label)
	_reward_button = UiTheme.make_button(tr("AD_GET_REWARD"), UiTheme.COLOR_PRIMARY)
	_reward_button.disabled = true
	_reward_button.pressed.connect(_finish.bind(true))
	box.add_child(UiTheme.center(_reward_button))
	var cancel := UiTheme.make_button(tr("AD_CLOSE_NO_REWARD"), UiTheme.COLOR_NEUTRAL, Vector2(420, 72), 26)
	cancel.pressed.connect(_finish.bind(false))
	box.add_child(UiTheme.center(cancel))
	_seconds_left = MOCK_DURATION
	_update_mock_label()
	_timer = Timer.new()
	_timer.wait_time = 1.0
	_timer.timeout.connect(_on_mock_tick)
	_layer.add_child(_timer)
	_timer.start()


func _on_mock_tick() -> void:
	_seconds_left -= 1
	_update_mock_label()
	if _seconds_left <= 0:
		_timer.stop()
		_reward_button.disabled = false


func _update_mock_label() -> void:
	if _seconds_left > 0:
		_countdown_label.text = tr("AD_COUNTDOWN") % _seconds_left
	else:
		_countdown_label.text = tr("AD_READY")
