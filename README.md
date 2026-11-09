# SATURN — Compilações públicas de teste 🪐

Este repositório contém um **snapshot de código para testes e compilação**, sem o histórico Git do projeto principal. Foi preparado para aproveitar os runners padrão gratuitos do GitHub Actions em um repositório público.

**Versão do código:** SATURN 0.7.0 (cópia de validação; não é uma versão homologada).

## O que você pode fazer

Em **Actions → SATURN Public Build → Run workflow**, executar:
- Análise Flutter, testes de catálogo e regressão.
- Compilação de APK Android **debug**, com assinatura temporária de desenvolvimento.
- Compilação de aplicativo iOS **apenas para simulador**, sem certificado de distribuição.

Os artefatos de testes aparecem nas execuções, por tempo limitado. Nenhum desses arquivos substitui o APK de produção instalado no celular, nem é um IPA para iPhone físico.

## O que não está neste repositório

Não contém histórico Git privado, chaves de assinatura Android, chaves Apple, secrets TMDB/OMDb, credenciais Supabase, banco de dados pessoal, catálogos exportados ou workflows de publicação de produção.

O catálogo de títulos é obtido de serviços externos pelos caminhos públicos do aplicativo. A sincronização privada de dados do casal permanece desativada sem um projeto Supabase dedicado.

## Transparência sobre visibilidade

**Todo o código aqui fica publicamente acessível enquanto o repositório for público.** Torná-lo privado depois não remove clones, cópias ou forks feitos durante esse período. A ausência de um arquivo LICENSE não concede permissão geral de redistribuição de código, conteúdo ou marcas.

## Sobre APIs e mídia

Dados e capas podem vir de [TMDB](https://www.themoviedb.org/), [Open Library](https://openlibrary.org/) e outros serviços, sujeitos às respectivas condições. Os trailers do YouTube usam o player oficial. Um reprodutor Flutter independente só funciona com vídeos cuja distribuição esteja autorizada.

**Não adicione secrets de produção a este repositório público.** Assinatura final Android e TestFlight pertencem a um fluxo privado e controlado.

---
Este é um snapshot sem histórico privado. O projeto original não foi tornado público.


## SATURN Web — instalação no iPhone

O arquivo `web/manifest.json` e os ícones PWA são gerados automaticamente pela rotina `scripts/create_pwa_icons.py`. A publicação está em `.github/workflows/pages.yml`, usando GitHub Pages.

**Primeiro uso:** em **Settings → Pages → Build and deployment → Source**, selecione **GitHub Actions**. O workflow `SATURN Web · iPhone PWA` publicará em `https://nrzxl.github.io/saturn-build-public/` após a primeira execução verde. Antes disso, o endereço pode retornar 404.

**No iPhone:** abra o site no Safari → Compartilhar → Adicionar à Tela de Início → Abrir como App (se aparecer). O ícone SATURN será instalado na Tela de Início. Em atualizações futuras, abra `Atualizar SATURN` dentro da Web para conferir a publicação mais recente e atualizar a página quando houver versão nova.

A Web ainda não sincroniza a coleção com Android porque um projeto Supabase SATURN dedicado não foi ativado. Não desinstale a Web com notas locais importantes. Offline completo não está garantido: o Flutter moderno não inclui cache offline automático por padrão.

## Por que o Android não ofereceu a 0.7?

O APK gerado em Actions deste repositório é **debug**, não é uma versão com a assinatura Android permanente. O canal de produção `Nrzxl/saturn-downloads/update.json` permanece na 0.6.0 assinada até uma nova release de produção ser verificada e publicada. Nunca tente instalar o APK debug por cima da versão assinada e **não desinstale a versão atual**, pois isso pode apagar suas listas e avaliações locais.
