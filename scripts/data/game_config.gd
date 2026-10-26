class_name GameConfig
extends RefCounted
## Constantes de jogabilidade. Ajuste aqui para balancear o jogo.

const LANE_COUNT := 3
const LANE_WIDTH := 2.6

# Velocidade (m/s) cresce suavemente com a distância.
const START_SPEED := 11.0
const MAX_SPEED := 26.0
const SPEED_CURVE_DISTANCE := 2600.0
const DIFFICULTY_FULL_DISTANCE := 3500.0

# Física do personagem (altura máxima do pulo ~1,45 m, menor que um carro).
const GRAVITY := 32.0
const JUMP_VELOCITY := 9.6
const FAST_FALL_VELOCITY := -16.0
const SLIDE_DURATION := 0.75
const LANE_CHANGE_SPEED := 15.0

# Caixa de colisão do personagem.
const PLAYER_HALF_WIDTH := 0.35
const PLAYER_HALF_DEPTH := 0.3
const PLAYER_HEIGHT := 1.7
const PLAYER_SLIDE_HEIGHT := 0.8

# Cenário e geração.
const SEGMENT_LENGTH := 24.0
const SEGMENTS_AHEAD := 7
const SPAWN_AHEAD := 120.0
const DESPAWN_BEHIND := 15.0
const FIRST_ROW_DISTANCE := 45.0

const REVIVE_INVINCIBILITY := 2.5
const REVIVE_CLEAR_DISTANCE := 45.0

# Metas de distância (recompensa única, na primeira vez que forem atingidas).
const MILESTONES := [250, 500, 1000, 2000, 3000, 5000, 7500, 10000]
const MILESTONE_REWARDS := [20, 40, 80, 120, 180, 250, 350, 500]


static func lane_x(lane: int) -> float:
	return (lane - 1) * LANE_WIDTH


static func speed_for_distance(distance: float) -> float:
	return START_SPEED + (MAX_SPEED - START_SPEED) * (1.0 - exp(-distance / SPEED_CURVE_DISTANCE))


static func difficulty_for_distance(distance: float) -> float:
	return clampf(distance / DIFFICULTY_FULL_DISTANCE, 0.0, 1.0)


static func milestone_reward(index: int) -> int:
	return MILESTONE_REWARDS[index]
