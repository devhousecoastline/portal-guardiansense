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

### Automático (recomendado)

Qualquer **merge/push na `main`** dispara o workflow [Deploy Hosting](.github/workflows/deploy-hosting.yml):

1. sobe patch + build (`pubspec.yaml` e `AppConstants`);
2. `flutter build web --release --pwa-strategy=none`;
3. `firebase deploy --only hosting`;
4. commit `chore(portal): release vX.Y.Z+N [skip ci]` de volta na `main`.

**Secret obrigatório** no repositório GitHub (`Settings` → `Secrets and variables` → `Actions`):

| Secret | Como obter |
|--------|------------|
| `FIREBASE_TOKEN` | `npx firebase-tools login:ci` (na máquina com acesso ao projeto) |

Também dá para rodar manualmente em **Actions** → **Deploy Hosting** → **Run workflow**.

### Manual (local)

O script já faz bump + build + deploy:

```powershell
.\scripts\deploy_hosting.ps1
```
