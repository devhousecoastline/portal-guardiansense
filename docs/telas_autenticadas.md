# Telas autenticadas

Depois do login e do aceite, o `GuardianScaffold` envolve as rotas do shell: **sidebar** em tela larga, **drawer** no mobile web. Seta voltar no topo em todas as telas **exceto** Proteção (`/dashboard`).

Tema claro/escuro (`ThemeController`) persiste no dispositivo e vale para o portal inteiro.

## Navegação

**Principal**

| Item | Rota | Função |
|------|------|--------|
| Proteção | `/dashboard` | Centro: índice, checklist, contenção |
| Localizar | `/locate` | Última posição conhecida |
| Eventos | `/events` | Timeline de segurança |
| Dispositivos | `/devices` | Vínculo, QR, histórico e cota de trocas |
| Configurações | `/settings` | Tema + camadas (leitura do app) |

**Rodapé do menu**

| Item | Rota |
|------|------|
| Privacidade | `/privacy` |
| Sobre | `/about` |
| Minha conta | `/account` |
| Premium (teaser / atalho) | `/premium` |

Detalhe de um dia: `/events-details/yyyy-MM-dd` (URL inválida redireciona para `/events`).

---

## Proteção (`/dashboard`)

Home da central. Escuta o **aparelho primário** verificado (`DashboardService.watchPrimaryDevice`).

Sem aparelho: `DevicePairingCard` (QR).

Com aparelho:

- pills **Online/Offline** e **Verificado** no subtítulo;
- **Índice de proteção** (`ProtectionStatusHero`);
- **Como está o aparelho** / setup (`ProtectionSetupCard`);
- **Checklist** do que falta configurar;
- **Contenção remota** — “Fechar ostra” grava `commands/{id}` tipo `close_oyster` `pending`; o app aplica; só reabre no app;
- link **Celular Seguro** (MJSP) para bloqueio de IMEI/linha;
- layout 2×2 em notebook, empilhado no celular.

O portal **não** altera switches de proteção; só dispara contenção.

## Localizar (`/locate`)

Última posição do aparelho primário (`DeviceLocation` no doc do device).

- Card com endereço (geocode) e recência;
- mapa em largura total (`flutter_map`);
- sem device verificado: pede QR no Centro.

Localização de emergência é responsabilidade do app (ostra fechada / opt-in). O portal só exibe o que já está no Firestore.

## Eventos (`/events` e `/events-details/:dia`)

Timeline do aparelho primário: `users/{uid}/devices/{deviceId}/events`, até 120 docs, ordenados por `occurredAt`.

- filtros (tipo / período);
- textos humanizados (`event_display`);
- dedupe de eventos idênticos;
- toque no dia abre o detalhe.

Sem aparelho verificado a lista fica vazia.

## Dispositivos (`/devices`)

Lista após `DeviceRegistry`:

- **ativos verificados**, deduplicados por fingerprint (ou legado plataforma+modelo), respeitando `UserPlan.deviceLimit` (free = 1);
- **histórico** `status: released`;
- cota de trocas (`deviceSwitches`);
- banner de plano se passou do limite.

Sem ativo: de novo o card do QR. Pills de status/verificação no tile.

## Configurações (`/settings`)

Subtítulo: *Sincronizadas com o app — o celular é soberano*.

- **Aparência:** tema do portal (único bloco que o portal controla);
- aparelho vinculado, versão do app, lastSeen;
- **camadas protegidas** e checklist — snapshot que o app gravou; detalhe em dialog, sem edição remota.

## Privacidade e Sobre

- `/privacy` — política completa (mesma versão do gate).
- `/about` — nome do produto e versão/build desta Central (`1.0.x`), independente da versão do app no aparelho.

## Minha conta (`/account`)

- identidade (e-mail / Google);
- **Plano:** trial, ativo ou expirado; **início** e **vence em** (data e hora, alinhado ao app);
- dados da conta;
- **Sair da conta**;
- em debug: reset de verificação e de trial (não vão para produção).

## Premium (`/premium`)

Assinatura anual **R$ 118,80** (`annual_12m`, equivalente R$ 9,90/mês). Trial de **7 dias**.

1. `ensureTrial` na primeira visita, se ainda não houver entitlement.
2. `createPixAnnualPayment` gera QR PIX + copia-cola.
3. Webhook `mercadopagoPixWebhook` confirma o pagamento no Mercado Pago e grava `subscription.status = active` (store `pix`). Cliente não consegue promover a conta sozinho.

---

## Comportamento compartilhado

- **Refresh** nas telas com stream: barra de tick (`OnlineRefresh`) sem recarregar a página.
- **Loading** na troca pelo drawer (`NavigationLoadingController`).
- **Pills** de status/plano/verificação usam o mesmo componente (`StatusPill` / chips) em Proteção, Dispositivos, Conta e Premium.
- Aparelho **não verificado** (`verified == false`) é invisível no registry — o usuário vê o QR, não um device “fantasma”.
