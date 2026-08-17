# Fluxo e autenticação

O router (`lib/core/routing/app_router.dart`) usa `resolveAuthRedirect` (`privacy_consent_redirect.dart`). A lógica é pura e coberta por testes.

## Rotas

| Rota | Acesso | Tela |
|------|--------|------|
| `/` | Pública | Landing “Em desenvolvimento” **ou** login (`showComingSoonLanding`) |
| `/login` | Pública | Login / criar conta (`?criar=1` abre no modo cadastro) |
| `/pair?c=CODIGO` | Pública (também logado) | Landing do QR — o vínculo **não** acontece aqui |
| `/privacy-consent` | Logado, sem aceite vigente | Gate da política |
| `/dashboard` … `/premium` | Logado + aceite | Shell autenticado (`NavigationShell`) |

Rotas autenticadas: `/dashboard`, `/events`, `/events-details/:yyyy-MM-dd`, `/locate`, `/devices`, `/settings`, `/privacy`, `/about`, `/account`, `/premium`.

## Redirects

Enquanto o Firebase Auth não emite o primeiro `authStateChanges` (`authReady == false`), o router **não** manda para o login — evita flash no refresh.

| Estado | Destino |
|--------|---------|
| Sem sessão, fora de `/login`, `/pair` e (se landing) `/` | `/login` |
| Logado, Firestore de consentimento ainda não respondeu | fica na rota atual |
| Logado, política vigente não aceita, fora de `/pair` | `/privacy-consent` |
| Logado + aceite em `/`, `/login` ou `/privacy-consent` | `/dashboard` |
| Logado em `/pair` | permanece (landing do código) |

`/pair` é a exceção: a câmera do celular abre essa URL mesmo sem sessão no navegador. Confirmar identidade é no **app**, não nesta página.

## Login

`AuthController` — mesma conta do app.

- E-mail e senha: `signInWithEmail` / `registerWithEmail`
- Google: `signInWithPopup` no web (timeout 90s)
- Recuperar senha: `sendPasswordReset`
- Sair: `signOut` (Minha conta)

Domínios Auth autorizados: `localhost`, `*.firebaseapp.com` / `*.web.app` do projeto, `guardian-sense.com` e `www.guardian-sense.com`. Detalhes em [revisao_seguranca_firebase.md](revisao_seguranca_firebase.md).

## Aceite de privacidade

Independente do aceite local do app. Gravado em `users/{uid}.portalPrivacyConsent` (`version` + `acceptedAt`).

- Versão vigente: `PrivacyPolicy.version` (hoje `1.1`), alinhada ao app.
- Se a versão mudar, o portal pede de novo.
- Sem aceite, o shell autenticado não abre (exceto `/pair`).

Controller: `PrivacyConsentController`. Tela: `/privacy-consent`. Texto completo também em `/privacy` (drawer).

## Fluxo do usuário

```mermaid
flowchart TD
  A[Abre guardian-sense.com] --> B{Sessão?}
  B -->|não| C[Login / criar conta]
  C --> D{Aceitou política vigente?}
  B -->|sim| D
  D -->|não| E[/privacy-consent]
  E --> F[/dashboard]
  D -->|sim| F
  F --> G{Aparelho verificado?}
  G -->|não| H[QR em Proteção ou Dispositivos]
  H --> I[App: mesma conta + confirmar identidade]
  I --> J[Function confirmDevicePairing]
  J --> K[Portal sincroniza]
  G -->|sim| K
```

## QR de verificação de identidade

Objetivo: o usuário prova que o celular da conta é aquele aparelho. Sem isso o portal **não sincroniza** (não mostra o device ativo).

1. Portal autenticado chama `createDevicePairing` (região `southamerica-east1`).
2. Function grava em `users/{uid}/devicePairings/{id}`: código de 6 caracteres, TTL **5 minutos**, até **20 criações/hora**. Cliente **não** escreve nessa coleção.
3. QR aponta para `https://guardian-sense.com/pair?c=CODIGO`.
4. `/pair` só exibe o código e instrui a abrir o app.
5. No app, mesma conta, `confirmDevicePairing` marca o device `verified: true`, `verifiedVia: 'qr'`.
6. `DeviceRegistry` só inclui no portal aparelhos com `verified != false`. Legado sem o campo (`verified == null`) continua visível.

Onde o QR aparece no portal: card vazio de **Proteção**, **Configurações** e **Dispositivos** quando não há aparelho ativo verificado.

Debug/QA (`kDebugMode`): botão para `resetDeviceVerification` (só Admin SDK). **Não aparece em produção.**

## O que o portal escreve (exceções)

Além de ler, o cliente autenticado pode:

- gravar aceite de privacidade;
- criar comando `close_oyster` `pending`;
- criar trial de assinatura (sem marcar pago);
- chamar Functions (`createDevicePairing`, `createPixAnnualPayment`, reset de verificação em debug).
