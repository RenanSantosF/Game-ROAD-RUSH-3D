# Publicação na Google Play — Road Rush 3D

Guia passo a passo, feito para seguir pelo celular. Itens marcados com **(você)** só você pode fazer
(exigem sua conta, pagamento ou documentos). O resto já está pronto no repositório.

> As regras mudam com frequência. Antes de cada etapa, confira a página oficial indicada.
> Nada aqui garante aprovação: a revisão do Google decide.

## O que já está pronto

| Item | Onde |
|---|---|
| Jogo v1.0.0, target **API 36** (exigido para apps novos desde 31/08/2026) | `export_presets.cfg` + workflow |
| AdMob: premiado opcional + intersticial com limites (só ao sair do fim de jogo, 1 a cada 3 partidas, 2 min de intervalo, nunca nas 3 primeiras partidas), configurado para crianças | `scripts/autoload/ads_manager.gd` |
| Permissões de ID de publicidade removidas (Famílias) | workflow, etapa "Template Android" |
| AAB assinado gerado pelo GitHub Actions | artefato `RoadRush3D-aab` (depois do passo 3) |
| Ícone 512, gráfico de recursos, 4 capturas × 3 idiomas | `store/images/` |
| Textos da ficha PT/EN/ES | `store/listing.md` |
| Política de privacidade PT/EN/ES | `store/privacy-policy.html` |

## 1. Conta de desenvolvedor Google Play (você)

1. Acesse <https://play.google.com/console/signup> e crie uma conta **Pessoal**.
2. Pague a taxa única de registro (US$ 25 — confira o valor na tela).
3. Faça a verificação de identidade (documento) e verifique um **aparelho Android** pelo app Play Console.
4. Contas pessoais novas precisam de um **teste fechado com pelo menos 12 testadores por 14 dias seguidos**
   antes de liberar a produção (passo 7). Já vá separando 12+ pessoas com conta Google (e-mails Gmail).

## 2. AdMob (você)

1. Acesse <https://admob.google.com> com a mesma conta Google e conclua o cadastro (dados de pagamento/impostos).
2. **Apps > Adicionar app** > Android > "O app ainda não está publicado" > nome **Road Rush 3D**.
3. Copie o **ID do app** (formato `ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY`).
4. **Blocos de anúncios > Adicionar > Premiado (Rewarded)** > nome "Continuar" > copie o **ID do bloco**
   (formato `ca-app-pub-XXXXXXXXXXXXXXXX/ZZZZZZZZZZ`).
5. **Blocos de anúncios > Adicionar > Intersticial** > nome "Fim de jogo" > copie o **ID do bloco**.
6. **Me envie os três IDs.** Eu coloco em `scripts/data/ads_config.gd`
   (`REAL_APP_ID`, `REAL_REWARDED_ID` e `REAL_INTERSTITIAL_ID`).
   Enquanto estiverem vazios, o AAB sai **sem anúncios** (pode publicar assim e ativar numa atualização).
7. No AdMob, em **Controles de bloqueio > Configurações de conteúdo**, escolha a classificação máxima **G**.
8. Depois que o app estiver na Play, volte em **Apps > Configurações do app** e **vincule à Google Play**.

Importante: **nunca clique nos seus próprios anúncios reais**. O APK de teste usa só anúncios de teste do Google.

## 3. Chave de upload no GitHub (você)

Eu gerei a chave de upload e te enviei os arquivos. **Guarde o arquivo `roadrush3d-upload.jks` e a senha
em dois lugares seguros** (ex.: Google Drive + pendrive). Com a "Assinatura de apps do Google Play" ativa,
se perder a chave dá para pedir a troca ao suporte, mas evite.

No navegador do celular, abra o repositório > **Settings > Secrets and variables > Actions > New repository secret**
e crie os três segredos, copiando o conteúdo dos arquivos que te enviei:

| Nome do segredo | Conteúdo |
|---|---|
| `UPLOAD_KEYSTORE_BASE64` | todo o texto do arquivo `UPLOAD_KEYSTORE_BASE64.txt` |
| `UPLOAD_KEYSTORE_PASSWORD` | o texto do arquivo `UPLOAD_KEYSTORE_PASSWORD.txt` |
| `UPLOAD_KEY_ALIAS` | `upload` |

Depois disso, cada build gera também o **AAB** em Actions > execução > Artifacts > `RoadRush3D-aab`
(vem em .zip; dentro está o `RoadRush3D.aab`).

## 4. Política de privacidade com URL pública (você)

A Play exige um link público. O repositório é privado, então use uma destas opções:
- **Google Sites** (grátis): crie um site, cole o texto de `store/privacy-policy.html`
  (troque `[SEU E-MAIL DE CONTATO]` pelo seu e-mail) e publique.
- Ou crie um repositório **público** só com esse arquivo e ative o GitHub Pages.

## 5. Criar o app no Play Console (você)

**Criar app** > nome "Road Rush 3D" > idioma padrão **Português (Brasil)** > **Jogo** > **Gratuito** > aceite as declarações.

### Ficha da loja
Copie de `store/listing.md` e envie as imagens de `store/images/` (ícone, gráfico de recursos e capturas).
Adicione as traduções en-US e es-ES com os textos e capturas de cada idioma.

### Conteúdo do app (Política > Conteúdo do app)
- **Política de privacidade:** a URL do passo 4.
- **Anúncios:** "Sim, meu app contém anúncios" (marque "Não" se publicar sem os IDs do AdMob).
- **Acesso ao app:** "Todas as funcionalidades estão disponíveis sem restrições".
- **Classificação do conteúdo:** questionário IARC, categoria **Jogos**. Responda com sinceridade:
  violência só em estilo de desenho, sem sangue (o bichinho fica "achatado" ou é levado pela nuvem);
  sem interação entre usuários, sem compras, sem compartilhamento de localização.
- **Público-alvo e conteúdo:** escolha as faixas etárias reais do público (ex.: 6–8, 9–12, 13–15, 16–17, 18+).
  Como inclui crianças, o app entra nas regras de **Famílias**. Confirme que os anúncios seguem a
  política de Famílias (o AdMob está na lista de SDKs autocertificados).
  Política: <https://support.google.com/googleplay/android-developer/answer/9893335>
- **Segurança dos dados** — base: documentação oficial do AdMob
  (<https://developers.google.com/admob/android/privacy/play-data-disclosure>). Com AdMob ativo, declare:
  - O app coleta dados? **Sim** (pelo SDK do AdMob). Compartilha? **Sim** (com o Google, para anúncios).
  - Tipos: **Local aproximado** (IP), **Atividade no app › Interações com o app**,
    **Informações e desempenho do app › Diagnóstico**, **Dispositivo ou outros IDs** (ID do conjunto de apps;
    o ID de publicidade foi removido do manifesto).
  - Finalidades: **Publicidade ou marketing**, **Análise**, **Prevenção de fraudes, segurança e compliance**.
  - Criptografados em trânsito: **Sim**. Usuário pode pedir exclusão: **Não** (nenhum dado fica com você).
  - Sem os IDs do AdMob (sem anúncios), a resposta passa a ser "Não coleta dados".
- **Apps de notícias / saúde / financeiros / governo:** Não.

## 6. Primeira versão no teste fechado

1. **Testar > Teste fechado > Criar faixa** (ou use "Alpha") > **Testadores**: crie uma lista com os e-mails.
2. **Criar nova versão** > ative a **Assinatura de apps do Google Play** (recomendado) >
   envie o `RoadRush3D.aab` > notas da versão > **Revisar e lançar**.
3. Envie aos testadores o **link de participação** (aparece na faixa). Cada um precisa aceitar e instalar.
4. Mantenha **12+ testadores ativos por 14 dias seguidos**. Peça para jogarem de verdade.

## 7. Produção

Depois dos 14 dias: **Painel > Solicitar acesso à produção** e responda o questionário.
Quando aprovado: **Produção > Criar nova versão** > mesmo AAB (ou um mais novo) > **Enviar para revisão**.
A revisão costuma levar de alguns dias a algumas semanas.

## Atualizações futuras

Cada push gera um AAB com `versionCode` maior (número da execução do Actions). Para atualizar:
nova versão na faixa > envie o AAB mais recente.
