# Guardian Context Engine — contrato do portal (set/2026)

Documentação **deste repositório**. Descreve o que o portal lê e exibe em relação ao contexto situacional (Casa / Trabalho / Rua). Badge de leitura no Centro de Proteção; sem controle de modo.

Nome de produto: **Guardian Context Engine**. No app a inferência vive no `SituationEngine`; no portal só há consumo do snapshot.

## Papel do portal

O app no celular **infere** a situação (Wi‑Fi, horário, rotina, motion — GPS contínuo fora do MVP).

O portal **só lê e mostra** o que o app publicou no device. Não redefine Casa / Trabalho / Rua, não oferece botão de “modo de segurança” no MVP e não fecha a ostra porque a situação é `street`.

| O portal faz | O portal não faz |
|--------------|------------------|
| Exibir “Contexto atual” (situação + confiança + quando atualizou) | Inferir modo a partir do histórico GPS / events |
| Usar os mesmos IDs do wire | Inventar enum paralelo (`modo_casa`, etc.) |
| Em fase Observe: status como telemetria / transparência | Tratar `street` como comando de contenção |
| Labels em PT só na UI | Botão que muda a proteção remota por “modo” |

Fechar / abrir ostra continua sendo **comando** (`close_oyster` / estado de ostra no app), independente da situação.

## IDs (contrato wire)

Persistência, sync e filtros usam o ID. Labels são só UI.

| ID | Label (PT) | Hint (PT) |
|----|------------|-----------|
| `home` | Casa | Ambiente confiável |
| `trusted` | Trabalho | Ambiente confiável |
| `street` | Rua | Proteção reforçada |
| `transit` | Deslocamento | Em movimento |
| `unknown` | Ambiente em análise | Aguardando sinais de lugar |

Trabalho no MVP **não** é um ID separado: usa `trusted` (trabalho, casa dos pais, etc.).

## Filosofia (espelho de produto)

Frase-guia: *Em casa é discreto. Na rua reforça. Se detectar furto, reage em segundos.*

Pipeline (responsável no app; o portal só observa o resultado):

```
Sensores → DeviceContext → SituationEngine → RiskEngine
  → Debounce → CriticalConfirmed → Ostra fecha
```

- Situação **calibra** risco (quando Influence estiver ativo no app).
- Situação **nunca** fecha a ostra sozinha.
- Risk alto ≠ ostra fechada.

## Campos no DeviceSnapshot

Documento: `users/{uid}/devices/{deviceId}`.

Quando o app publicar a fase Observe, o snapshot deve incluir:

```json
{
  "situation": "home",
  "situationConfidence": 0.87,
  "situationReasons": ["known_wifi", "habitual_time", "repeated_pattern"],
  "situationUpdatedAt": "..."
}
```

| Campo | Tipo | Uso no portal |
|-------|------|----------------|
| `situation` | string (um dos IDs acima) | Badge / texto “Contexto atual” |
| `situationConfidence` | number `0..1` | Disponível no snapshot; UI do badge não mostra % no MVP |
| `situationReasons` | lista de codes estáveis | Breakdown / diagnóstico (não texto livre de UI) |
| `situationUpdatedAt` | timestamp | “Atualizado há …” |

Dashboard e Localizar (quando houver UI): ler **primariamente o snapshot**. Não derivar situação a partir de `events` nem da trilha `locations`.

### Codes de `situationReasons` (estáveis)

Exemplos previstos (lista pode crescer; portal trata code desconhecido como genérico):

- `known_wifi`
- `habitual_time`
- `repeated_pattern`

## Fases (impacto no portal)

Mesma linha do app (Observe → Validate → Influence):

1. **Observe** — app calcula e grava snapshot; **não** altera Risk. Portal pode mostrar o status (transparência).
2. **Validate** — ajuste de qualidade no app; portal continua só leitura.
3. **Influence** — no app a situação calibra limiares do Risk. Portal **não** liga/desliga Influence; só reflete o que o device publica.

Enquanto o app não publicar os campos, a UI de “Contexto atual” fica ausente ou em estado vazio — não inventar valor default enganoso (`street` / `home`).

## Matriz de sinais (referência — app)

O portal **não** implementa esta matriz. Serve para entender o que o snapshot representa.

| Sinal | `home` | `trusted` | `street` | `transit` |
|-------|--------|-----------|----------|-----------|
| Wi‑Fi conhecido | forte + | forte + | — | — |
| Horário habitual | médio + | médio + | neutro | neutro |
| Recorrência histórica | forte + | forte + | — | — |
| Motion parado | compatível | compatível | compatível | — |
| Motion walking | possível | possível | forte contexto | — |
| Motion vehicle | — | — | — | forte + |
| GPS contínuo | fora do MVP | fora do MVP | fora do MVP | fora do MVP |

- Wi‑Fi sozinho nunca decide.
- Ambiente desconhecido ≠ `street` automático: sem confiança suficiente → `unknown` (neutro).

## Relação com Localizar / GPS

O portal já lê `lastLocation` e `devices/{id}/locations` (trilha). Isso é **posição**, não **situação**.

- Não usar a trilha GPS para inventar Casa/Trabalho/Rua no MVP.
- GPS/locais cadastrados entram depois, no app; o portal continua consumindo o snapshot.

## UX prevista (quando for a hora)

- Badge **Contexto atual** no Centro (Proteção): mesmo copy do app (`Casa · Ambiente confiável`).
- Opcional depois: confiança / reasons / `situationUpdatedAt` em detalhe.
- Sem seletor de modo no MVP.
- Contenção remota permanece nos comandos já existentes — independente de `situation`.

## Princípios

- Mesmos IDs e significados em app e portal; labels PT só na UI.
- Portal consome; app decide.
- Rua reforça no aparelho; no portal não vira “fechar ostra”.
- Preferir snapshot a heurísticas locais no web.
- Não implementar UI desta feature em detrimento do que já está em produção (vínculo, Localizar, Eventos, contenção).

## Critério de sucesso

O usuário vê no portal o **mesmo contexto** que o aparelho entendeu — transparência, sem controle paralelo que minta o estado de proteção.
