extends Node
## Camada de anúncios (Autoload "Ads"), separada da lógica do jogo.
##
## Provedores:
## - ADMOB: no Android, quando o plugin do AdMob (Poing Studios, MIT) está
##   no APK. Builds de teste usam os IDs de TESTE do Google; o AAB de
##   publicação usa os IDs reais de AdsConfig (vazios = anúncios desligados).
## - DEBUG_MOCK: no PC durante o desenvolvimento, um "anúncio simulado"
##   local e identificado, só para testar o fluxo.
## - NONE: sem anúncios (os botões de anúncio somem).
##
## Público infantil (Google Play Famílias): todas as solicitações vão marcadas
## como direcionadas a crianças (COPPA), menores de idade (GDPR) e com
## classificação máxima "G". Assim não há anúncios personalizados nem
## remarketing, e o identificador de publicidade não é enviado.
##
## Só anúncios RECOMPENSADOS e opcionais (o jogador escolhe assistir), nunca
## no meio de uma ação. A recompensa só é entregue quando o SDK confirma que
## o anúncio foi assistido (on_user_earned_reward) e ele foi fechado.

signal ad_closed(placement: String, rewarded: bool)

enum Provider { NONE, DEBUG_MOCK, ADMOB }

const MOCK_DURATION := 3
const RELOAD_DELAY := 20.0

var provider: int = Provider.NONE

var _showing := false
var _placement := ""
var _callback: Callable
var _layer: CanvasLayer
var _countdown_label: Label
var _reward_button: Button
var _seconds_left := 0
var _timer: Timer

var _rewarded_ad: RewardedAd
var _loading := false
var _earned := false
var _reload_timer := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.get_name() == "Android" and Engine.has_singleton("PoingGodotAdMob"):
		if AdsConfig.rewarded_unit_id() != "":
			provider = Provider.ADMOB
			_init_admob()
	elif OS.is_debug_build():
		provider = Provider.DEBUG_MOCK


func is_rewarded_available() -> bool:
	if _showing:
		return false
	match provider:
		Provider.DEBUG_MOCK:
			return true
		Provider.ADMOB:
			return _rewarded_ad != null
	return false


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
		Provider.ADMOB:
			_show_admob()


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


# ------------------------------------------------------------------ AdMob

func _init_admob() -> void:
	var config := RequestConfiguration.new()
	config.tag_for_child_directed_treatment = RequestConfiguration.TagForChildDirectedTreatment.TRUE
	config.tag_for_under_age_of_consent = RequestConfiguration.TagForUnderAgeOfConsent.TRUE
	config.max_ad_content_rating = RequestConfiguration.MAX_AD_CONTENT_RATING_G
	MobileAds.set_request_configuration(config)
	var listener := OnInitializationCompleteListener.new()
	listener.on_initialization_complete = func(_status) -> void: _load_rewarded()
	MobileAds.initialize(listener)


func _process(delta: float) -> void:
	if provider != Provider.ADMOB or _rewarded_ad != null or _loading:
		return
	if _reload_timer > 0.0:
		_reload_timer -= delta
		if _reload_timer <= 0.0:
			_load_rewarded()


func _load_rewarded() -> void:
	if _loading or _rewarded_ad != null:
		return
	_loading = true
	var callback := RewardedAdLoadCallback.new()
	callback.on_ad_loaded = func(ad: RewardedAd) -> void:
		_loading = false
		_rewarded_ad = ad
	callback.on_ad_failed_to_load = func(error: LoadAdError) -> void:
		_loading = false
		_reload_timer = RELOAD_DELAY
		print("AdMob: falha ao carregar: ", error.message)
	RewardedAdLoader.new().load(AdsConfig.rewarded_unit_id(), AdRequest.new(), callback)


func _show_admob() -> void:
	var ad := _rewarded_ad
	_rewarded_ad = null
	_earned = false
	ad.full_screen_content_callback.on_ad_dismissed_full_screen_content = func() -> void:
		ad.destroy()
		_finish(_earned)
		_load_rewarded()
	ad.full_screen_content_callback.on_ad_failed_to_show_full_screen_content = func(_error) -> void:
		ad.destroy()
		_finish(false)
		_load_rewarded()
	var reward := OnUserEarnedRewardListener.new()
	reward.on_user_earned_reward = func(_item) -> void: _earned = true
	ad.show(reward)


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
