# Citrea Operations

## Summary

The first Helix Citrea release is operationally conservative:

- `HLX-ctUSD Base`
- no strategy attached
- `maxAllocationBps = 0`

That minimizes venue risk, but it does not eliminate Citrea-specific operational risk.

The two biggest differences from BSC are:

- Bitcoin-anchored finality model
- bridge and stablecoin infrastructure being part of product risk

## Finality Model

Citrea documentation distinguishes between:

- soft-confirmed
- finalized
- proven

Helix operations should respect those as distinct states, not as interchangeable synonyms.

### Soft-confirmed

Use for:

- UI acknowledgement
- low-risk operational observation
- internal monitoring

Do not use soft-confirmation alone as the basis for:

- treasury accounting finality
- incident resolution closure
- emergency all-clear declarations

### Finalized

Use for:

- normal operational settlement assumptions
- deposit and withdrawal bookkeeping
- vault accounting reconciliation

Citrea’s documentation also points to Bitcoin-anchored finality depth. Runbooks should treat that
as the minimum safe state for routine accounting confidence.

### Proven

Use for:

- post-incident review closure
- highest-confidence reconciliation
- deep operational audits when chain conditions are abnormal

## When Deposits And Withdrawals Are Operationally Safe

### Deposits

Operationally safe for normal monitoring when:

- the deposit transaction is finalized on Citrea
- no bridge incident is active for the relevant asset path
- no chain anomaly is active

### Withdrawals

Operationally safe for normal user operations when:

- the withdrawal transaction is finalized on Citrea
- the vault is not under chain or bridge incident response
- users are not relying on bridge-offboarding assumptions that are currently degraded

### During anomalies

If Citrea is only soft-confirming reliably but not finalizing normally:

- keep user messaging conservative
- consider pausing new deposits
- allow withdrawals if the chain is functioning and asset transfers remain safe

The current Helix emergency philosophy still applies:

- prioritize exits
- freeze new risk-taking first

## Guardian Actions

### Oracle issues

For the first Citrea base-vault release:

- oracle issues should not affect vault settlement directly because no strategy is attached and
  Helix does not depend on a `ctUSD/USD` settlement oracle

Guardian response:

- monitor and document the issue
- do not pause solely for a non-settlement oracle issue unless it signals broader chain instability

### Bridge issues

Bridge issues are operationally important even for a no-strategy base vault because users may be
onboarding or offboarding through:

- Bridge Hub
- MoonPay
- Clementine
- other ecosystem bridges

Guardian response to a material bridge issue:

1. assess whether the issue affects the held vault asset directly
2. if the issue affects `ctUSD` solvency, redemption, or transfer confidence, move the vault to
   withdraw-only
3. publish user guidance before considering stricter measures

### Chain or finality anomalies

Examples:

- prolonged failure to reach finalized state
- widespread RPC divergence
- sequencer instability
- reorg behavior outside expected bounds

Guardian response:

1. stop new risk-taking first
2. set withdraw-only if user exits still appear safe
3. only escalate further if chain behavior makes ordinary transfers unsafe or unverifiable

## Recommended RPC And Node Posture

For the first Citrea release, Helix should not rely on a single public RPC endpoint as its only
truth source.

Minimum recommendation:

- one primary paid or dedicated RPC/provider
- one secondary fallback RPC
- explorer checks as a tertiary cross-check, not as the sole source of truth

Preferred production posture:

- a dedicated archival or near-archival node path if practical
- independent monitoring for finalized and proven state transitions

## Monitoring Requirements

### Chain monitoring

Track:

- latest soft-confirmed height
- latest finalized height
- latest proven height if available in tooling
- RPC divergence across providers
- transaction inclusion latency

### Vault monitoring

Track:

- `totalAssets`
- `totalIdle`
- `totalStrategyAssets`
- `paused`
- `withdrawOnly`
- deposit cap utilization
- guardian and owner actions

### Asset monitoring

Track:

- `ctUSD` transfer behavior
- `ctUSD` holder concentration if possible
- any issuer or redemption incidents
- bridge or peg incidents that could affect user confidence

## Incident Classification

### Low severity

- explorer outage
- non-critical oracle outage
- isolated RPC instability with healthy fallback

Typical action:

- no state change
- heightened monitoring

### Medium severity

- persistent RPC divergence
- delayed finalization
- bridge degradation that affects onboarding confidence but not asset transfer safety

Typical action:

- operational warning
- consider pausing deposits
- keep exits open if safe

### High severity

- `ctUSD` solvency or transfer concern
- chain/finality anomaly that undermines confidence in state
- bridge incident that directly affects vault asset integrity

Typical action:

- move to withdraw-only
- communicate clearly
- avoid attaching any strategy or new risk

## Why This Release Leaves Strategy Unset

Leaving strategy unset is operationally intentional because it:

- eliminates venue dependency
- eliminates strategy unwind risk
- eliminates allocator-specific oracle dependence
- makes `totalAssets` fully auditable as vault idle balance only
- keeps guardian response simple for the first Citrea release

This is not an incomplete launch. It is the correct low-risk launch shape for an early Citrea
deployment.

## Related Docs

- [CITREA_DEPLOYMENT_RUNBOOK.md](./CITREA_DEPLOYMENT_RUNBOOK.md)
- [CITREA_RISKS.md](./CITREA_RISKS.md)
- [CITREA_INTEGRATION_PLAN.md](./CITREA_INTEGRATION_PLAN.md)
