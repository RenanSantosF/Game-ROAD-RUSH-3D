# Road Rush 3D

Endless runner 3D low-poly para Android, desenvolvido em **Godot 4.7.2 (estável)** com GDScript,
usando apenas o editor Godot para Android.

## Configuração-alvo

| Item | Valor |
|---|---|
| Engine | Godot 4.7.2 stable (editor Android) |
| Renderizador | Compatibility (OpenGL ES 3.0) — máxima compatibilidade com celulares modestos |
| Orientação | Paisagem com sensor (`sensor_landscape`) |
| Resolução base | 1280×720, stretch `canvas_items`, aspect `expand` |
| Exportação AAB / plugins (AdMob) | Gradle build via app **GABE** no próprio celular (Etapas 13 e 15) |

## Estrutura

```
res://
├── scenes/      main, player, road, obstacles, collectibles, ui, menus
├── scripts/     mesma divisão das cenas + autoload/ (singletons) + ads/ (monetização)
├── assets/      models, textures, audio/music, audio/sfx, fonts
├── data/        configurações de jogo (missões, personagens) em .tres/.json
└── docs/        roteiro, política de privacidade, notas de teste
```

## Progresso

- [x] Etapa 1 — Projeto vazio, configurações e estrutura de arquivos
- [ ] Etapa 2 — Estrada 3D low-poly, câmera e iluminação
- [ ] Etapa 3 — Personagem e movimentação automática
- [ ] Etapa 4 — Controles por toque e troca entre faixas
- [ ] Etapa 5 — Pulo, deslize e colisões
- [ ] Etapa 6 — Carros, obstáculos e geração progressiva
- [ ] Etapa 7 — Moedas, pontuação e recorde
- [ ] Etapa 8 — Menu, pausa, derrota e reinício
- [ ] Etapa 9 — Salvamento local
- [ ] Etapa 10 — Personagens desbloqueáveis
- [ ] Etapa 11 — Missões diárias e metas
- [ ] Etapa 12 — Sons, efeitos e otimização
- [ ] Etapa 13 — Anúncios (AdMob) e conformidade (Famílias)
- [ ] Etapa 14 — Testes completos no Android
- [ ] Etapa 15 — Exportação AAB e publicação
