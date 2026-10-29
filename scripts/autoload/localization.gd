extends Node
## Idiomas (Autoload "Loc"): português, inglês e espanhol.
##
## Por padrão o jogo usa o idioma do celular (OS.get_locale_language()).
## Se o celular estiver em outro idioma, usa inglês. O jogador pode
## trocar manualmente em Configurações > Idioma.
##
## Os textos ficam todos aqui: cada chave tem [português, inglês, espanhol].
## No código, use tr("CHAVE") (ou tr("CHAVE") % valores para textos com números).

const LANGUAGES := ["pt", "en", "es"]
const FALLBACK := "en"

const STRINGS := {
	# Menu principal
	"MENU_PLAY": ["JOGAR", "PLAY", "JUGAR"],
	"MENU_CHARACTERS": ["PERSONAGENS", "CHARACTERS", "PERSONAJES"],
	"MENU_MISSIONS": ["MISSÕES", "MISSIONS", "MISIONES"],
	"MENU_MISSIONS_ALERT": ["MISSÕES  (!)", "MISSIONS  (!)", "MISIONES  (!)"],
	"MENU_SETTINGS": ["CONFIGURAÇÕES", "SETTINGS", "AJUSTES"],
	"BEST_POINTS": ["Recorde: %d pontos", "Best: %d points", "Récord: %d puntos"],
	"BEST": ["Recorde: %d", "Best: %d", "Récord: %d"],
	"BACK": ["VOLTAR", "BACK", "VOLVER"],

	# HUD e partida
	"TUTORIAL": [
		"Toque na tela para pular para a FRENTE\nDeslize para os LADOS ou para TRÁS para desviar",
		"Tap the screen to hop FORWARD\nSwipe SIDEWAYS or BACK to dodge",
		"Toca la pantalla para saltar HACIA ADELANTE\nDesliza a los LADOS o HACIA ATRÁS para esquivar",
	],
	"NEXT_GOAL": ["Próxima meta: %d pontos", "Next goal: %d points", "Próxima meta: %d puntos"],
	"ALL_GOALS_DONE": ["Todas as metas concluídas!", "All goals completed!", "¡Todas las metas completadas!"],
	"GOAL_REACHED": ["META DE %d PONTOS!  +%d moedas", "%d POINTS GOAL!  +%d coins", "¡META DE %d PUNTOS!  +%d monedas"],
	"CLOUD_GOT_YOU": ["A nuvem te engoliu!", "The cloud swallowed you!", "¡La nube te tragó!"],
	"KEEP_HOPPING": ["Continue pulando!", "Keep hopping!", "¡Sigue saltando!"],

	# Pausa
	"PAUSED": ["PAUSADO", "PAUSED", "PAUSA"],
	"RESUME": ["CONTINUAR", "RESUME", "CONTINUAR"],
	"RESTART": ["REINICIAR", "RESTART", "REINICIAR"],
	"MAIN_MENU": ["MENU PRINCIPAL", "MAIN MENU", "MENÚ PRINCIPAL"],
	"MUSIC_ON_OFF": ["Música: %s", "Music: %s", "Música: %s"],
	"SFX_ON_OFF": ["Efeitos: %s", "Sounds: %s", "Efectos: %s"],
	"YES": ["SIM", "ON", "SÍ"],
	"NO": ["NÃO", "OFF", "NO"],

	# Continuar
	"CONTINUE_Q": ["CONTINUAR?", "CONTINUE?", "¿CONTINUAR?"],
	"CONTINUE_INFO": [
		"Assista a um anúncio para continuar\nde onde parou (uma vez por partida).",
		"Watch an ad to continue\nfrom where you stopped (once per game).",
		"Mira un anuncio para continuar\ndonde te quedaste (una vez por partida).",
	],
	"WATCH_AND_CONTINUE": ["ASSISTIR E CONTINUAR", "WATCH AND CONTINUE", "MIRAR Y CONTINUAR"],
	"NO_THANKS": ["NÃO, OBRIGADO", "NO, THANKS", "NO, GRACIAS"],

	# Fim de jogo
	"GAME_OVER": ["FIM DE JOGO", "GAME OVER", "FIN DEL JUEGO"],
	"NEW_RECORD": ["NOVO RECORDE!", "NEW RECORD!", "¡NUEVO RÉCORD!"],
	"POINTS": ["%d pontos", "%d points", "%d puntos"],
	"PLUS_COINS": ["+%d moedas", "+%d coins", "+%d monedas"],
	"PLUS_COINS_DOUBLED": ["+%d moedas (dobrado!)", "+%d coins (doubled!)", "+%d monedas (¡duplicado!)"],
	"MISSION_DONE": ["Missão concluída: %s", "Mission completed: %s", "Misión completada: %s"],
	"DOUBLE_COINS_AD": ["DOBRAR MOEDAS (assistir anúncio)", "DOUBLE COINS (watch ad)", "DUPLICAR MONEDAS (ver anuncio)"],
	"COINS_DOUBLED": ["MOEDAS DOBRADAS", "COINS DOUBLED", "MONEDAS DUPLICADAS"],
	"MENU": ["MENU", "MENU", "MENÚ"],
	"PLAY_AGAIN": ["JOGAR DE NOVO", "PLAY AGAIN", "JUGAR DE NUEVO"],

	# Personagens
	"IN_USE": ["EM USO", "IN USE", "EN USO"],
	"USE": ["USAR", "USE", "USAR"],
	"BUY_FOR": ["COMPRAR  -  %d moedas", "BUY  -  %d coins", "COMPRAR  -  %d monedas"],
	"UNLOCKED": ["Desbloqueado!", "Unlocked!", "¡Desbloqueado!"],
	"MISSING_COINS": ["Faltam %d moedas. Continue jogando!", "You need %d more coins. Keep playing!", "Te faltan %d monedas. ¡Sigue jugando!"],
	"CHAR_GALINHA": ["Galinha Pipoca", "Popcorn Chicken", "Gallina Palomita"],
	"CHAR_GALINHA_DESC": ["Só quer chegar do outro lado!", "Just wants to get to the other side!", "¡Solo quiere llegar al otro lado!"],
	"CHAR_PATO": ["Patinho Amarelo", "Yellow Duckling", "Patito Amarillo"],
	"CHAR_PATO_DESC": ["Nada muito bem... de verdade!", "A great swimmer... really!", "Nada muy bien... ¡de verdad!"],
	"CHAR_PORCO": ["Porquinho Rosa", "Pink Piggy", "Cerdito Rosa"],
	"CHAR_PORCO_DESC": ["Pequeno, rosado e corajoso.", "Small, pink and brave.", "Pequeño, rosado y valiente."],
	"CHAR_GATO": ["Gato Listrado", "Striped Cat", "Gato Rayado"],
	"CHAR_GATO_DESC": ["Sete vidas? Aqui é só uma!", "Nine lives? Here you get just one!", "¿Siete vidas? ¡Aquí solo una!"],

	# Missões
	"DAILY_MISSIONS": ["MISSÕES DIÁRIAS", "DAILY MISSIONS", "MISIONES DIARIAS"],
	"MISSIONS_RESET_INFO": [
		"Novas missões todos os dias à meia-noite (horário do celular).",
		"New missions every day at midnight (phone time).",
		"Nuevas misiones cada día a medianoche (hora del teléfono).",
	],
	"NEXT_GOAL_REWARD": ["Próxima meta: %d pontos em uma partida  (+%d moedas)", "Next goal: %d points in one game  (+%d coins)", "Próxima meta: %d puntos en una partida  (+%d monedas)"],
	"GOALS_INFO": ["Metas alcançadas: %d de %d   |   Seu recorde: %d", "Goals reached: %d of %d   |   Your best: %d", "Metas alcanzadas: %d de %d   |   Tu récord: %d"],
	"CLAIMED": ["RESGATADO", "CLAIMED", "RECLAMADO"],
	"CLAIM": ["RESGATAR", "CLAIM", "RECLAMAR"],
	"IN_PROGRESS": ["EM ANDAMENTO", "IN PROGRESS", "EN CURSO"],
	"M_RUN_COINS": ["Colete %d moedas em uma partida", "Collect %d coins in one game", "Recoge %d monedas en una partida"],
	"M_DAY_COINS": ["Colete %d moedas hoje", "Collect %d coins today", "Recoge %d monedas hoy"],
	"M_RUN_DISTANCE": ["Faça %d pontos em uma partida", "Score %d points in one game", "Haz %d puntos en una partida"],
	"M_DAY_DISTANCE": ["Faça %d pontos somando o dia", "Score %d points in total today", "Haz %d puntos en total hoy"],
	"M_RUN_TIME": ["Sobreviva %d segundos em uma partida", "Survive %d seconds in one game", "Sobrevive %d segundos en una partida"],
	"M_DAY_HOPS": ["Dê %d pulinhos", "Hop %d times", "Da %d saltitos"],
	"M_DAY_ROADS": ["Atravesse %d ruas", "Cross %d roads", "Cruza %d calles"],
	"M_DAY_GAMES": ["Jogue %d partidas", "Play %d games", "Juega %d partidas"],

	# Configurações
	"SETTINGS_TITLE": ["CONFIGURAÇÕES", "SETTINGS", "AJUSTES"],
	"SET_MUSIC": ["Música", "Music", "Música"],
	"SET_SFX": ["Efeitos sonoros", "Sound effects", "Efectos de sonido"],
	"SET_SHADOWS": ["Sombras", "Shadows", "Sombras"],
	"SET_FPS": ["Mostrar FPS", "Show FPS", "Mostrar FPS"],
	"ON": ["LIGADO", "ON", "ACTIVADO"],
	"OFF": ["DESLIGADO", "OFF", "DESACTIVADO"],
	"LANGUAGE": ["Idioma: %s", "Language: %s", "Idioma: %s"],
	"LANG_AUTO": ["Automático (%s)", "Automatic (%s)", "Automático (%s)"],
	"LANG_NAME_PT": ["Português", "Português", "Português"],
	"LANG_NAME_EN": ["English", "English", "English"],
	"LANG_NAME_ES": ["Español", "Español", "Español"],
	"PRIVACY_POLICY": ["Política de privacidade", "Privacy policy", "Política de privacidad"],
	"PRIVACY_TITLE": ["PRIVACIDADE", "PRIVACY", "PRIVACIDAD"],
	"PRIVACY_TEXT": [
		"Este jogo não pede nem coleta dados pessoais.\nSeu progresso fica salvo só neste aparelho.\n\nOs vídeos opcionais com recompensa são do\nGoogle AdMob, configurado para crianças:\nsem anúncios personalizados e sem o ID de\npublicidade. O Google pode processar dados\ntécnicos (como endereço IP) para exibir os\nanúncios. Mais em policies.google.com.",
		"This game does not ask for or collect personal data.\nYour progress is saved only on this device.\n\nOptional reward videos come from Google AdMob,\nset up for children: no personalized ads and\nno advertising ID. Google may process technical\ndata (such as IP address) to show the ads.\nMore at policies.google.com.",
		"Este juego no pide ni recopila datos personales.\nTu progreso se guarda solo en este dispositivo.\n\nLos videos opcionales con recompensa son de\nGoogle AdMob, configurado para niños: sin\nanuncios personalizados y sin el ID de publicidad.\nGoogle puede procesar datos técnicos (como la\ndirección IP) para mostrar los anuncios.\nMás en policies.google.com.",
	],
	"CLOSE": ["FECHAR", "CLOSE", "CERRAR"],
	"VERSION": ["Versão %s", "Version %s", "Versión %s"],

	# Anúncio simulado
	"AD_MOCK_TITLE": ["ANÚNCIO SIMULADO", "SIMULATED AD", "ANUNCIO SIMULADO"],
	"AD_MOCK_INFO": [
		"Versão de testes: nenhum anúncio real é exibido\ne nenhum dado é enviado.",
		"Test version: no real ad is shown\nand no data is sent.",
		"Versión de prueba: no se muestra ningún anuncio real\nni se envía ningún dato.",
	],
	"AD_GET_REWARD": ["RECEBER RECOMPENSA", "GET REWARD", "RECIBIR RECOMPENSA"],
	"AD_CLOSE_NO_REWARD": ["FECHAR SEM RECOMPENSA", "CLOSE WITHOUT REWARD", "CERRAR SIN RECOMPENSA"],
	"AD_COUNTDOWN": ["Recompensa liberada em %d...", "Reward available in %d...", "Recompensa disponible en %d..."],
	"AD_READY": ["Pronto!", "Ready!", "¡Listo!"],
}

var _translations := {}


func _ready() -> void:
	for i in LANGUAGES.size():
		var t := Translation.new()
		t.locale = LANGUAGES[i]
		for key in STRINGS:
			t.add_message(key, STRINGS[key][i])
		TranslationServer.add_translation(t)
		_translations[LANGUAGES[i]] = t
	apply_language()


## Idioma do celular, se for um dos suportados; senão inglês.
func device_language() -> String:
	var lang := OS.get_locale_language()
	return lang if LANGUAGES.has(lang) else FALLBACK


## "auto", "pt", "en" ou "es".
func get_choice() -> String:
	return SaveManager.get_language()


func current_language() -> String:
	var choice := get_choice()
	return device_language() if choice == "auto" else choice


func apply_language() -> void:
	TranslationServer.set_locale(current_language())


## Alterna Automático > Português > English > Español.
func cycle_choice() -> void:
	var order := ["auto"] + LANGUAGES
	var index := order.find(get_choice())
	SaveManager.set_language(order[(index + 1) % order.size()])
	apply_language()


func choice_label() -> String:
	var choice := get_choice()
	var name := tr("LANG_NAME_" + current_language().to_upper())
	return tr("LANG_AUTO") % name if choice == "auto" else name
