class_name AdsConfig
extends RefCounted
## Identificadores do AdMob.
##
## - Builds de TESTE (APK do GitHub Actions) usam SEMPRE os IDs de teste
##   oficiais do Google, que exibem anúncios de teste sem gerar receita.
## - Builds de PUBLICAÇÃO (AAB) usam os IDs reais abaixo. Enquanto eles
##   estiverem vazios, os anúncios ficam desligados na versão publicada.
##
## O App ID real fica em project.godot ([admob] general/android/app_id),
## lido pelo plugin AdMob (Poing Studios v5.1.0) na exportação.
## Nunca clique nos seus próprios anúncios reais.

# IDs de teste oficiais do Google (https://developers.google.com/admob/android/test-ads)
const TEST_APP_ID := "ca-app-pub-3940256099942544~3347511713"
const TEST_REWARDED_ID := "ca-app-pub-3940256099942544/5224354917"
const TEST_INTERSTITIAL_ID := "ca-app-pub-3940256099942544/1033173712"

# Preencha com os IDs da sua conta AdMob (formato ca-app-pub-XXXX~YYYY e ca-app-pub-XXXX/ZZZZ).
const REAL_APP_ID := "ca-app-pub-4311255826061303~9743261011"
const REAL_REWARDED_ID := "ca-app-pub-4311255826061303/4012422187"
const REAL_INTERSTITIAL_ID := "ca-app-pub-4311255826061303/3201903396"


# Limites do intersticial (só na saída da tela de fim de jogo).
const INTERSTITIAL_EVERY_GAMES := 3
const INTERSTITIAL_MIN_SECONDS := 120.0
const INTERSTITIAL_MIN_TOTAL_GAMES := 3


static func rewarded_unit_id() -> String:
	return TEST_REWARDED_ID if OS.is_debug_build() else REAL_REWARDED_ID


static func interstitial_unit_id() -> String:
	return TEST_INTERSTITIAL_ID if OS.is_debug_build() else REAL_INTERSTITIAL_ID
