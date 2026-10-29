class_name AdsConfig
extends RefCounted
## Identificadores do AdMob.
##
## - Builds de TESTE (APK do GitHub Actions) usam SEMPRE os IDs de teste
##   oficiais do Google, que exibem anúncios de teste sem gerar receita.
## - Builds de PUBLICAÇÃO (AAB) usam os IDs reais abaixo. Enquanto eles
##   estiverem vazios, os anúncios ficam desligados na versão publicada.
##
## O App ID real também precisa ir em addons/admob/android/config.gd
## (APPLICATION_ID); o GitHub Actions faz isso a partir de REAL_APP_ID.
## Nunca clique nos seus próprios anúncios reais.

# IDs de teste oficiais do Google (https://developers.google.com/admob/android/test-ads)
const TEST_APP_ID := "ca-app-pub-3940256099942544~3347511713"
const TEST_REWARDED_ID := "ca-app-pub-3940256099942544/5224354917"

# Preencha com os IDs da sua conta AdMob (formato ca-app-pub-XXXX~YYYY e ca-app-pub-XXXX/ZZZZ).
const REAL_APP_ID := ""
const REAL_REWARDED_ID := ""


static func rewarded_unit_id() -> String:
	return TEST_REWARDED_ID if OS.is_debug_build() else REAL_REWARDED_ID
