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
## Formatos:
## - RECOMPENSADO, opcional (o jogador escolhe assistir). A recompensa só é
##   entregue quando o SDK confirma (on_user_earned_reward) e o anúncio fecha.
## - INTERSTICIAL, só na transição natural da tela de fim de jogo para a
##   próxima partida/menu, nunca durante o jogo. Limites (AdsConfig): no máximo
##   1 a cada 3 partidas, 2 minutos desde o último anúncio, nunca nas 3
##   primeiras partidas do jogador e nunca numa partida em que ele já assistiu
##   um recompensado.

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

var _interstitial_ad: InterstitialAd
var _interstitial_loading := false
var _interstitial_reload := 0.0
var _games_since_interstitial := 0
var _last_ad_time := -100000.0
var _rewarded_this_game := false
var _rewarded_ad: RewardedAd
var _loading := false
var _earned := false
var _reload_timer := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.get_name() == "Android" and Engine.has_singleton("PoingGodotAdMob"):
		if AdsConfig.rewarded_unit_id() != "" or AdsConfig.interstitial_unit_id() != "":
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
	_last_ad_time = _now()
	if rewarded:
		_rewarded_this_game = true
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
	listener.on_initialization_complete = func(_status) -> void:
		_load_rewarded()
		_load_interstitial()
	MobileAds.initialize(listener)


func _process(delta: float) -> void:
	if provider != Provider.ADMOB:
		return
	if _rewarded_ad == null and not _loading and _reload_timer > 0.0:
		_reload_timer -= delta
		if _reload_timer <= 0.0:
			_load_rewarded()
	if _interstitial_ad == null and not _interstitial_loading and _interstitial_reload > 0.0:
		_interstitial_reload -= delta
		if _interstitial_reload <= 0.0:
			_load_interstitial()


func _load_rewarded() -> void:
	if AdsConfig.rewarded_unit_id() == "" or _loading or _rewarded_ad != null:
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


# ------------------------------------------------------------- Intersticial

func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


## Chame ao fim de cada partida (conta para o limite de frequência).
func on_game_finished() -> void:
	_games_since_interstitial += 1


## Chame ao começar uma partida nova.
func on_game_started() -> void:
	_rewarded_this_game = false


## O intersticial pode aparecer agora? (todas as regras de frequência)
func can_show_interstitial() -> bool:
	if _showing or provider == Provider.NONE:
		return false
	if provider == Provider.ADMOB and _interstitial_ad == null:
		return false
	if SaveManager.get_stat("games") < AdsConfig.INTERSTITIAL_MIN_TOTAL_GAMES:
		return false
	if _games_since_interstitial < AdsConfig.INTERSTITIAL_EVERY_GAMES:
		return false
	if _now() - _last_ad_time < AdsConfig.INTERSTITIAL_MIN_SECONDS:
		return false
	return not _rewarded_this_game


## Mostra o intersticial se as regras permitirem e depois chama on_done().
## Se não puder mostrar, chama on_done() na hora.
func show_interstitial_if_allowed(on_done: Callable) -> void:
	if not can_show_interstitial():
		on_done.call()
		return
	_games_since_interstitial = 0
	_showing = true
	_placement = "interstitial"
	_callback = func(_ignored: bool) -> void: on_done.call()
	AudioManager.set_ducked(true)
	match provider:
		Provider.DEBUG_MOCK:
			_show_mock(true)
		Provider.ADMOB:
			_show_admob_interstitial()


func _load_interstitial() -> void:
	if AdsConfig.interstitial_unit_id() == "" or _interstitial_loading or _interstitial_ad != null:
		return
	_interstitial_loading = true
	var callback := InterstitialAdLoadCallback.new()
	callback.on_ad_loaded = func(ad: InterstitialAd) -> void:
		_interstitial_loading = false
		_interstitial_ad = ad
	callback.on_ad_failed_to_load = func(error: LoadAdError) -> void:
		_interstitial_loading = false
		_interstitial_reload = RELOAD_DELAY
		print("AdMob: falha ao carregar intersticial: ", error.message)
	InterstitialAdLoader.new().load(AdsConfig.interstitial_unit_id(), AdRequest.new(), callback)


func _show_admob_interstitial() -> void:
	var ad := _interstitial_ad
	_interstitial_ad = null
	ad.full_screen_content_callback.on_ad_dismissed_full_screen_content = func() -> void:
		ad.destroy()
		_finish(false)
		_load_interstitial()
	ad.full_screen_content_callback.on_ad_failed_to_show_full_screen_content = func(_error) -> void:
		ad.destroy()
		_finish(false)
		_load_interstitial()
	ad.show()


# ------------------------------------------------- Anúncio simulado (debug)

func _show_mock(interstitial := false) -> void:
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
	if interstitial:
		_reward_button = UiTheme.make_button(tr("CLOSE"), UiTheme.COLOR_NEUTRAL)
		_reward_button.disabled = true
		_reward_button.pressed.connect(_finish.bind(false))
		box.add_child(UiTheme.center(_reward_button))
	else:
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
