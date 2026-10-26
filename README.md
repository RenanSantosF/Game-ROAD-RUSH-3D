# Road Rush 3D

Endless runner 3D low-poly para Android, feito em **Godot 4.3** (GDScript, renderizador Compatibility).
Corra pela cidade, troque de faixa, pule barreiras, deslize sob placas, desvie dos carros e colete moedas.

## Baixar o APK de teste

Cada `push` gera um APK automaticamente (workflow `.github/workflows/android-apk.yml`).

- **Mais fácil no celular:** abra a página **Releases** do repositório > **APK de teste** > toque em `RoadRush3D.apk`.
- **Pelo Actions:** aba **Actions** > execução mais recente (verde) > seção **Artifacts** > `RoadRush3D-apk` (vem em .zip; extraia antes de instalar).

Na primeira instalação, o Android pede para permitir "instalar apps desta fonte". Todas as builds usam a mesma
chave de depuração (`ci/debug.keystore`), então uma build nova instala **por cima** da anterior sem perder o progresso.

> A chave em `ci/debug.keystore` serve **só para testes**. A chave de publicação na Play Store será outra,
> criada na Etapa 15, e nunca deve ser enviada ao GitHub.

## Controles

| Gesto | Ação |
|---|---|
| Deslizar para a esquerda/direita | Trocar de faixa |
| Deslizar para cima | Pular (barreiras e cones) |
| Deslizar para baixo | Deslizar (placas suspensas); no ar, desce rápido |
| Botão `II` / botão Voltar do Android | Pausar |

No PC: setas/WASD/espaço e Esc.

## O que já existe

- 3 faixas, avanço automático, velocidade e dificuldade crescentes.
- Carros parados e em movimento, ônibus, barreiras, cones e placas (sempre com pelo menos uma saída).
- Moedas, distância, recorde, metas de distância com recompensa única.
- Menu, pausa (com contagem 3-2-1), fim de jogo, reinício, configurações e política de privacidade.
- Salvamento local (JSON com backup) de moedas, recorde, personagens, missões e configurações.
- 4 personagens (1 grátis + 3 desbloqueáveis com moedas do jogo).
- 3 missões diárias (moedas, distância e tempo/ações) com resgate.
- Música e efeitos sintetizados por código (sem arquivos de terceiros).
- Camada de anúncios separada: **nenhum SDK real ainda**. O APK de teste mostra um "anúncio simulado" local,
  identificado como tal, só para testar o fluxo de continuar e dobrar moedas.

## Estrutura

```
scenes/main/main.tscn         cena principal (mundo 3D + interface)
scripts/main/main.gd          fluxo da partida e câmera
scripts/player/               jogador, modelo animado, gestos
scripts/road/                 estrada infinita reaproveitada
scripts/obstacles/            obstáculos, geração e pooling
scripts/ui/ e scripts/menus/  HUD, tema e telas
scripts/autoload/             SaveManager, AudioManager, Missions, Ads
scripts/data/                 balanceamento e personagens
scripts/util/                 geração das malhas low-poly
tests/                        teste automático (robô) e capturas de tela
```

## Abrir no editor Godot do Android

1. Instale o **Godot Engine 4.3** (a versão do editor precisa ser a mesma do projeto).
2. Baixe o código: botão **Code > Download ZIP** (escolha o branch antes), extraia e use **Import** no Godot
   selecionando o `project.godot`.

## Progresso

- [x] Etapas 1 a 12: projeto, estrada, personagem, controles, pulo/deslize, obstáculos, moedas/pontuação,
  menus, salvamento, personagens, missões, sons e otimização (versão jogável 0.2.0)
- [ ] Etapa 13: AdMob real + configurações para público infantil (Famílias)
- [ ] Etapa 14: testes completos em aparelhos Android
- [ ] Etapa 15: AAB assinado e publicação na Google Play
