# Guardian Portal

Portal web da **Central de Proteção** do Guardian Sense (Flutter Web).

O usuário entra com a mesma conta do app, confirma o aparelho com QR e acompanha proteção, eventos, posição e contenção remota.

- Site: https://guardian-sense.com
- Versão: ver `pubspec.yaml` e `lib/app/constants.dart` (`portalVersion`)

## Documentação

Tudo o que o portal faz hoje está em [`docs/`](docs/README.md):

1. [Visão geral](docs/visao_geral.md)
2. [Fluxo e autenticação](docs/fluxo_e_autenticacao.md)
3. [Telas autenticadas](docs/telas_autenticadas.md)

Também há a [revisão de segurança Firebase](docs/revisao_seguranca_firebase.md) e o [plano de otimização Firestore](docs/plano_otimizacao_firestore.md).

## Desenvolvimento

```powershell
flutter pub get
flutter run -d chrome
```

## Publicar hosting

A `main` exige **pull request** (sem push direto). O bump de versão entra no PR.

### Automático (recomendado)

1. Na feature branch, antes do PR:
   ```powershell
   python scripts/bump_portal_version.py
   ```
   (atualiza `pubspec.yaml` e `AppConstants`)
2. Abra o PR → merge na `main`
3. O workflow [Deploy Hosting](.github/workflows/deploy-hosting.yml) faz build + Firebase Hosting

**Secret obrigatório** (`Settings` → `Secrets and variables` → `Actions`):

| Secret | Como obter |
|--------|------------|
| `FIREBASE_TOKEN` | `npx firebase-tools login:ci` |

Também dá para rodar manualmente em **Actions** → **Deploy Hosting** → **Run workflow**.

### Manual (local)

Bump + build + deploy (não usa a proteção da `main`):

```powershell
.\scripts\deploy_hosting.ps1
```
