# Road Rush 3D

Jogo 3D low-poly de **atravessar a rua** para Android, feito em **Godot 4.7.2** (GDScript, renderizador Compatibility).
Ajude a galinha (e os outros bichinhos) a atravessar ruas cheias de carros, rios com troncos e trilhos de trem,
pulando de quadrado em quadrado o mais longe possível. Câmera panorâmica, de cima e na diagonal,
em **orientação vertical (retrato)**.

**Idiomas:** português, inglês e espanhol. O jogo usa o idioma do celular automaticamente (outros idiomas caem
para inglês) e pode ser trocado em Configurações > Idioma. Todos os textos ficam em
`scripts/autoload/localization.gd`.

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
| Toque rápido na tela | Pula para a frente |
| Deslizar para esquerda/direita | Pula para o lado |
| Deslizar para baixo | Pula para trás |
| Deslizar para cima | Pula para a frente |
| Botão `II` / botão Voltar do Android | Pausar |

No PC: setas/WASD/espaço e Esc.

## Como funciona

- Mundo infinito em linhas: **grama** (com árvores e pedras), **ruas** (carros e caminhões),
  **rios** (troncos e vitórias-régias) e **trilhos** (o sinal pisca antes de o trem passar).
- Morre atropelado, afogado ao cair na água ou levado pela correnteza, e a **nuvem** engole quem ficar
  para trás (a câmera avança sozinha). A velocidade sobe devagar com os pontos (0,6 → 1,35 linha/s)
  e estabiliza em 350 pontos; ajuste em `scripts/data/game_config.gd`.
- Pontos = quantas linhas você avançou. Moedas espalhadas pelo caminho.
- Recorde, metas de pontos com recompensa única, 3 missões diárias e 4 bichinhos
  (Galinha grátis; Pato, Porquinho e Gato desbloqueáveis com moedas do jogo).
- Menu, pausa (contagem 3-2-1), fim de jogo, continuar, configurações e política de privacidade.
- Salvamento local (JSON com backup). Música e efeitos sintetizados por código.
- Camada de anúncios separada: **nenhum SDK real ainda**. O APK de teste mostra um "anúncio simulado" local,
  identificado como tal, só para testar o fluxo de continuar e dobrar moedas.

## Estrutura

```
scenes/main/main.tscn         cena principal (mundo 3D + interface)
scripts/main/main.gd          fluxo da partida e câmera
scripts/player/               bichinho (pulos na grade), modelos animados, gestos
scripts/world/                linhas do mundo (grama/rua/rio/trilho), geração e reciclagem
scripts/ui/ e scripts/menus/  HUD, tema e telas
scripts/autoload/             SaveManager, AudioManager, Missions, Ads
scripts/data/                 balanceamento e personagens
scripts/util/                 geração das malhas low-poly
tests/                        teste automático (robô) e capturas de tela
```

## Abrir no editor Godot do Android

1. Instale o **Godot Engine 4.7.2** (a versão do editor precisa ser a mesma do projeto).
2. Baixe o código: botão **Code > Download ZIP** (escolha o branch antes), extraia e use **Import** no Godot
   selecionando o `project.godot`.

## Publicação

Guia passo a passo: [`docs/PUBLICACAO.md`](docs/PUBLICACAO.md). Material da loja (textos PT/EN/ES,
ícone, gráfico de recursos, capturas e política de privacidade) em [`store/`](store/).

## Progresso

- [x] Etapas 1 a 12 no novo formato "atravessar a rua": mundo em grade, bichinhos, toques/deslizes, carros,
  rios, trens, moedas/pontos, menus, salvamento, personagens, missões, sons e otimização (versão 0.3.0)
- [x] Versão 0.4.0: tela vertical, idiomas PT/EN/ES
- [x] Versão 0.5.0: nuvem que engole no lugar da águia, câmera mais rápida com aceleração gradual e teto
- [x] Etapa 13: AdMob (recompensado) + configurações para público infantil (Famílias), target API 36
- [ ] Etapa 14: testes completos em aparelhos Android
- [ ] Etapa 15: AAB assinado (pronto no CI, falta a chave nos segredos) e publicação na Google Play
