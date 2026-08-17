# Visão geral do portal

O **Guardian Portal** é o cliente web da Central de Proteção. O usuário entra com a mesma conta do app, confirma o aparelho com QR e acompanha proteção, eventos, posição e contenção remota.

- **Produto:** Guardian Sense
- **Título da central:** Central de Proteção
- **Domínio:** https://guardian-sense.com
- **Projeto Firebase:** `guardian-sense-dbdfa`
- **Locale:** `pt_BR`

## Papel no produto

O **app no celular é soberano**: detecta risco, protege apps e grava o estado no Firestore.

O **portal é a central remota**: lê o que o app sincronizou e envia poucos comandos (fechar ostra). Sem QR de identidade, o portal não trata o aparelho como vinculado — Centro, Eventos e Localizar ficam cegos.

Conta criada só no portal (sem app) existe no Firebase Auth. O documento `users/{uid}` e os devices nascem no onboarding do app.

## Stack

| Camada | Tecnologia |
|--------|------------|
| UI | Flutter Web |
| Rotas | `go_router` |
| Auth | Firebase Auth (e-mail/senha + Google popup) |
| Dados | Cloud Firestore |
| Backend | Cloud Functions v2 (`southamerica-east1`) |
| Hosting | Firebase Hosting |
| Cobrança | PIX Mercado Pago (assinatura anual) |
| Mapa | `flutter_map` |

Código organizado por feature em `lib/features/` (auth, dashboard, devices, events, locate, containment, settings, account, subscription, info) e núcleo em `lib/core/` (tema, layout, rotas, widgets).

## Princípios de dados

1. **Portal não escreve estado de proteção.** `DeviceRepository` só lê `users/{uid}/devices`.
2. **`verified` só via Admin SDK.** O cliente não marca o aparelho como verificado; a Function `confirmDevicePairing` faz isso depois do QR no app.
3. **Assinatura paga só via backend.** Webhook PIX / Admin SDK. O cliente pode criar trial (`ensureTrial`), mas não pode gravar `status: active` nem `store: pix`.
4. **Comandos remotos** (`close_oyster`, `protect_app`, `protect_apps`) nascem `pending` pelo dono; o app atualiza para `applied` ou `failed`.
5. **Aparelho online** se `lastSeen` for mais recente que 4 minutos (`AppConstants.deviceOnlineThreshold`), alinhado ao heartbeat do app.

## Firestore (visão)

```
users/{uid}
  portalPrivacyConsent
  subscription
  plan / boundDeviceId / deviceSwitches
  devices/{deviceId}          # lastSeen, proteção, localização, verified
    events/{eventId}
    commands/{commandId}
  devicePairings/{pairingId}  # só Functions escrevem
  events/{eventId}            # legado
pixPayments/{paymentId}       # só Functions
```

Rules: `firestore.rules`. Só o dono lê `users/{uid}`. Delete de usuário e de device bloqueado.

## Versão e publicação

Convenção em `AppConstants` e `pubspec.yaml`:

- cada deploy sobe patch e build (`1.0.14+15` → `1.0.15+16`);
- minor/major só em mudança grande de produto;
- manter `portalVersion` / `portalBuild` iguais ao `version:` do pubspec.

Landing pública “Em desenvolvimento” na `/`: `AppConstants.showComingSoonLanding`. Hoje está `false` para testes (login na home). Voltar para `true` antes do próximo deploy público se a landing ainda for necessária.

Publicar o hosting:

```powershell
.\scripts\deploy_hosting.ps1
```

O script faz `flutter build web --release --pwa-strategy=none` e `firebase deploy --only hosting`. Sem service worker para o deploy aparecer na hora.

Functions (pairing, PIX, webhook) são um deploy separado: `firebase deploy --only functions --project guardian-sense-dbdfa`.
