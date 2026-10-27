class_name GameConfig
extends RefCounted
## Constantes de jogabilidade. Ajuste aqui para balancear o jogo.
## O mundo é uma grade: cada quadrado mede 1 m. A linha (row) cresce
## para a frente (eixo -Z) e a coluna é o eixo X.

# Colunas jogáveis: de -COLUMNS_HALF até +COLUMNS_HALF.
const COLUMNS_HALF := 4

# Pulo
const HOP_TIME := 0.13
const HOP_HEIGHT := 0.5
const PLAYER_HALF_WIDTH := 0.3

# Geração do mundo
const ROWS_AHEAD := 22
const ROWS_BEHIND := 8
const START_SAFE_ROWS := 3
const DIFFICULTY_FULL_ROW := 300

# A câmera avança sozinha e uma nuvem vem atrás: quem fica para trás é engolido.
# A velocidade (linhas por segundo) cresce aos poucos com os pontos e para de
# crescer ao chegar em SCROLL_RAMP_POINTS (~5 minutos de jogo).
const SCROLL_SPEED_START := 0.6
const SCROLL_SPEED_MAX := 1.35
const SCROLL_RAMP_POINTS := 350.0
const BEHIND_LIMIT := 3.6

const REVIVE_INVINCIBILITY := 2.0

# Metas de pontos (recompensa única, na primeira vez que forem atingidas).
const MILESTONES := [25, 50, 100, 150, 200, 300, 400, 500]
const MILESTONE_REWARDS := [20, 40, 80, 120, 180, 250, 350, 500]


static func difficulty_for_row(row: int) -> float:
	return clampf(float(row) / DIFFICULTY_FULL_ROW, 0.0, 1.0)


static func scroll_speed_for_row(row: int) -> float:
	var t := clampf(float(row) / SCROLL_RAMP_POINTS, 0.0, 1.0)
	# Curva suave: começa a subir devagar e desacelera antes de estabilizar.
	return lerpf(SCROLL_SPEED_START, SCROLL_SPEED_MAX, t * t * (3.0 - 2.0 * t))


static func milestone_reward(index: int) -> int:
	return MILESTONE_REWARDS[index]


static func is_playable_column(col: int) -> bool:
	return absi(col) <= COLUMNS_HALF
