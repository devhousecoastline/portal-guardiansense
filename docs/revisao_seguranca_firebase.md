# Revisão de segurança — Guardian Portal / Firebase

**Data:** 23/07/2026  
**Projeto Firebase:** `guardian-sense-dbdfa`  
**Domínio:** `https://guardian-sense.com`  
**Objetivo:** checklist para revisar amanhã antes do deploy (ou logo após).

---

## 1. Resumo executivo

| Área | Status agora | Nota |
|------|--------------|------|
| Auth (login obrigatório no portal) | OK | Rotas privadas redirecionam sem usuário |
| Firestore Rules (arquivo local) | OK | Só o dono acessa `users/{uid}` |
| Rules compilam | OK | `firebase deploy --only firestore:rules --dry-run` passou |
| Rules **publicadas** no console | **Conferir amanhã** | Dry-run ≠ deploy; validar no Console |
| HTTPS / domínio customizado | OK | SSL ativo em apex e `www` |
| Domínios Auth autorizados | OK | Inclui `guardian-sense.com` e `www` |
| App Web no Firebase | OK | `Guardian Portal` registrado |
| App Check | **Não implementado** | Reforço recomendado (não bloqueante) |
| Conta portal sem app | Esperado | Só Auth; Firestore nasce no onboarding mobile |

**Veredito atual:** base de segurança adequada para o estágio. Não está “aberto”, mas ainda há itens de conferência (principalmente Rules deployadas + App Check).

---

## 2. O que já está protegido

### 2.1 Autenticação
- Portal usa Firebase Auth (e-mail/senha + Google).
- `GoRouter` manda para `/login` se não houver usuário.
- Domínios autorizados (configurados nesta sessão):
  - `localhost`
  - `guardian-sense-dbdfa.firebaseapp.com`
  - `guardian-sense-dbdfa.web.app`
  - `guardian-sense.com`
  - `www.guardian-sense.com`

### 2.2 Firestore Rules (repo: `firestore.rules`)
- `isOwner(userId)` → `request.auth != null && request.auth.uid == userId`
- Leitura/escrita de `users/{userId}` e subcoleções (`devices`, `events`, `commands`) **somente pelo dono**
- `users/{uid}`: **delete bloqueado** (`allow delete: if false`)
- Comandos remotos (`close_oyster`, `protect_app`, `protect_apps`) com validação de campos e status

### 2.3 Hosting / domínio
- Site: `guardian-sense-dbdfa`
- Custom domains: `guardian-sense.com` + `www.guardian-sense.com`
- HTTPS responde com `Strict-Transport-Security` (SSL liberado)
- Conteúdo ainda **404** até o deploy do build web

### 2.4 Chaves do cliente (Web)
- `apiKey` / `appId` no `firebase_options.dart` são **públicos por design**
- A proteção real é Auth + Rules (não esconder a apiKey)

---

## 3. Checklist para amanhã

Marcar cada item:

### A. Firebase Console — Auth
- [ ] **Authentication → Sign-in method**
  - [ ] E-mail/senha **ativado**
  - [ ] Google **ativado** (se for oferecer no portal)
- [ ] **Authentication → Settings → Authorized domains**
  - [ ] Confirmar `guardian-sense.com` e `www.guardian-sense.com`
- [ ] **Authentication → Users**
  - [ ] Contas de teste aparecem (portal cria Auth mesmo sem Firestore)

### B. Firebase Console — Firestore
- [ ] **Firestore → Rules**
  - [ ] Conteúdo no console **igual** ao `firestore.rules` do repo
  - [ ] Se diferente → publicar:  
    `firebase deploy --only firestore:rules --project guardian-sense-dbdfa`
- [ ] **Firestore → Data**
  - [ ] Conta **só criada no portal** (sem app): **não** deve ter `users/{uid}` com devices
  - [ ] Conta com app + onboarding: deve ter `users/{uid}/devices/...`
- [ ] Teste rápido de Rules (Rules Playground ou app):
  - [ ] Sem auth → leitura de `users/qualquer` **nega**
  - [ ] Com auth do próprio uid → leitura **permite**
  - [ ] Com auth tentando outro uid → **nega**

### C. Hosting / domínio
- [ ] Abrir `https://guardian-sense.com` e `https://www.guardian-sense.com`
  - [ ] Cadeado SSL ok (sem aviso de certificado)
  - [ ] Após deploy: login carrega (não 404)
- [ ] Cloudflare DNS
  - [ ] A / CNAME do Firebase em **DNS only** (nuvem cinza), não Proxied
  - [ ] MX/e-mail (Email Routing) intactos se ainda usar `suporte@` / `contato@`

### D. Portal (produto)
- [ ] Empty state “nenhum aparelho vinculado” está claro
- [ ] Sair da conta volta ao login
- [ ] Fechar popup do Google não trava loading eterno
- [ ] “Esqueci a senha” envia e-mail e limpa o formulário

### E. Reforços recomendados (não urgentes, mas anotar)
- [ ] Avaliar **Firebase App Check** (Web + Android) para reduzir abuso da API
- [ ] Revisar política de senha / MFA (Auth) se o produto exigir
- [ ] Confirmar que Storage (se existir) também tem Rules por uid
- [ ] Backup / export periódico de Rules e índices
- [ ] Não commitar service account / Admin SDK JSON

---

## 4. Fluxo de dados (lembrar)

```
Criar conta no portal  →  Firebase Auth (sim)
                       →  Firestore users/{uid} (não)

App mobile + mesma conta + onboarding  →  cria/atualiza Firestore
Portal  →  lê/escreve só o que o Auth + Rules permitem
```

Isso **não é bug de segurança**; é arquitetura. O empty state do Centro/Dispositivos deve continuar explicando isso.

---

## 5. Comandos úteis

```bash
# Validar rules sem publicar
firebase deploy --only firestore:rules --project guardian-sense-dbdfa --dry-run

# Publicar rules
firebase deploy --only firestore:rules --project guardian-sense-dbdfa

# Build + hosting (quando for a hora)
flutter build web
firebase deploy --only hosting --project guardian-sense-dbdfa
```

Console:
- https://console.firebase.google.com/project/guardian-sense-dbdfa/authentication
- https://console.firebase.google.com/project/guardian-sense-dbdfa/firestore/rules
- https://console.firebase.google.com/project/guardian-sense-dbdfa/hosting

---

## 6. Achados desta sessão (23/07)

1. App Web **Guardian Portal** criado; `firebase_options` atualizado.
2. Domínio customizado + Auth domains configurados; SSL **ativo**.
3. **App Check** não está no portal (`pubspec` / código).
4. Rules locais **compilam**; publicação no projeto precisa ser **confirmada amanhã** no Console.
5. Conta nova só no portal → Auth sim, Firestore não (esperado).

---

## 7. Decisão sugerida amanhã

1. Conferir Rules no Console (= repo?). Se não, deploy das rules.  
2. Smoke test Auth + empty state + HTTPS.  
3. Só então **deploy hosting** do portal.  
4. Agendar App Check como melhoria (não bloquear o go-live se Rules estiverem ok).

---

*Documento gerado para revisão interna. Atualizar este arquivo após a conferência de amanhã (marcar checkboxes e anotar o que foi feito).*
