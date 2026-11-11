# SATURN Android — Publicação assinada oficial

Este processo publica um APK de produção em [Nrzxl/saturn-downloads](https://github.com/Nrzxl/saturn-downloads/releases). O código Web/PWA já aprovado continua em [Nrzxl/saturn-build-public](https://github.com/Nrzxl/saturn-build-public). **Nenhuma chave ou senha é publicada no código-fonte.**

## Estado validado em 11/11/2026

- Último APK público existente: **0.6.0, build 1008**, arquivo `SATURN.apk`.
- SHA-256 do APK original: `cb0a0763036cecb4f8c797d49649c53e908b8851c9b1ef90842d72693218619e`.
- Pacote Android fixo: `com.nrzxl.saturn`.
- Feed de atualizações: `https://raw.githubusercontent.com/Nrzxl/saturn-downloads/main/update.json`.
- Fonte desta nova release: versão do código aprovada em `saturn-build-public/main`; a publicação é **manual**.
- A nova linha de build começa em `2001` (2000 + número da execução GitHub), acima de 1008, para permitir atualização no lugar.

## Preparar no computador Windows (uma vez)

**Obrigatório:** a **mesma** chave original usada para assinar o SATURN 0.6.0. O script não gera chave nova. Se a chave original não estiver nesse computador, é necessário recuperá-la do backup. Nunca a envie pelo chat.

1. Instale/valide **Java 17+** (`keytool`), **Android SDK Build-Tools** (`apksigner`) e **GitHub CLI** (`gh`).
2. No PowerShell, use `gh auth login` e confirme que a conta é `Nrzxl`.
3. Abra [configurar_assinatura_publica.ps1](../scripts/configurar_assinatura_publica.ps1), revise e execute no PowerShell. Por padrão procura `Documentos/SATURN_SIGNING/saturn-release.keystore`; também aceita `-KeystorePath "C:\caminho\da\chave-original.keystore"`.
4. Informe a senha **localmente**, sem compartilhá-la em mensagens. O script baixa o APK 0.6.0 oficial, valida seu SHA-256, confere o certificado público com a chave original e bloqueia qualquer incompatibilidade.
5. O script grava de forma segura no GitHub Actions de **saturn-build-public** os quatro secrets de assinatura:
   - `SATURN_KEYSTORE_BASE64`
   - `SATURN_KEYSTORE_PASSWORD`
   - `SATURN_KEY_ALIAS`
   - `SATURN_KEY_PASSWORD`
6. Crie um Fine-grained Personal Access Token em [GitHub Settings](https://github.com/settings/personal-access-tokens/new) com acesso **somente ao repositório Nrzxl/saturn-downloads**, permissão **Contents: Read and write**. Informe-o somente ao prompt local do script, que grava `SATURN_RELEASE_TOKEN` no GitHub Secrets. **Não use um token amplo nem envie o token neste chat.**

Opcional: configure variáveis públicas `SATURN_SUPABASE_URL` e `SATURN_SUPABASE_PUBLISHABLE_KEY` em `saturn-build-public` para manter a integração SATURN Cloud, se já homologada. **Nunca configure `service_role` em APK ou Web.**

## Publicar o APK

Abra [SATURN · APK público assinado](https://github.com/Nrzxl/saturn-build-public/actions/workflows/android-public-release.yml), clique **Run workflow** e selecione a branch `main`. A publicação é manual, sem disparos automáticos.

O pipeline realiza, nesta ordem:

1. Verificação dos cinco secrets e acesso restrito ao canal de downloads.
2. `flutter analyze lib`, `flutter test` e testes Python existentes.
3. Compilação `flutter build apk --release` com a assinatura persistente.
4. Verificação `apksigner`, identidade `com.nrzxl.saturn` e **comparação criptográfica do certificado com a release 0.6.0**.
5. Geração de tag e publicação de `SATURN.apk` em `saturn-downloads/releases`.
6. Validação do SHA-256 do arquivo publicado.
7. Atualização de `saturn-downloads/update.json` **somente depois** de todas as verificações.

**Se qualquer etapa falhar, o manifesto anterior permanece preservado**; nunca anuncie uma versão cuja publicação não esteja concluída.

## Homologação física antes de distribuir amplamente

Instale sobre a versão 0.6.0 em um dispositivo de teste. Confirme que não foi exigida desinstalação, que as avaliações e Watchlist existentes foram preservadas e que Início, Explorar, Coleção e Nossa Órbita estão navegáveis. Depois valide o fluxo de **Atualizar SATURN** em outra instalação e se o Android confirma a atualização.

Dados do APK e da Web/PWA são armazenados em ambientes diferentes até que a sincronização de nuvem esteja efetivamente conectada; não presumir migração automática de armazenamento local do navegador.

### Segurança operacional

- Nunca envie keystore, senhas, tokens ou certificados privados ao chat.
- Faça backup externo seguro da **chave original** e da respectiva senha.
- Não desinstale o app anterior se ele contiver dados sem backup.
- Uma versão pública anterior **já existe**: não anunciar esta versão como publicada até que o workflow termine com `success`.
- O aplicativo consulta o manifesto de versões, mas **não valida internamente os bytes do APK baixado** nesta etapa; a verificação de hash e certificado é realizada no pipeline antes da publicação.
