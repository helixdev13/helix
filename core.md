## Project

**Helix** — a **BNB Chain yield execution layer** built for two things that still matter on BSC in 2026:

1. **automated concentrated-liquidity management** on PancakeSwap and THENA, and
2. **BNB / liquid-staking collateral routing** into lending and low-risk carry strategies.

This is the modern version of the old PancakeBunny opportunity. The chain is still large enough to matter, with DeFiLlama listing about **$5.35B TVL**, **$14.23B stablecoin market cap**, **2.62M active addresses**, and **14.11M daily transactions** on BSC, while PancakeSwap still concentrates a large share of liquidity on the chain. ([DeFi Llama][1])

The reason this specific design makes sense is structural. BNB Chain’s own liquid-staking page says liquid-staking tokens are meant to be reused across **money markets, AMMs, yield farming, and restaking**, while also noting the ecosystem is still relatively limited versus Ethereum. At the same time, PancakeSwap v3 and THENA both rely on **concentrated liquidity**, which is more capital efficient but operationally much harder to manage; THENA explicitly notes frequent rebalancing is needed to avoid severe out-of-range behavior and impermanent-loss drift. PancakeSwap also retired its old integrated third-party position managers from the main interface in 2025, which left a real product gap. ([BNB Chain][2])

---

## 1. What Helix is

Helix is a **non-custodial vault protocol** on **BSC mainnet first**, with **opBNB later**.

It has three vault families:

### A. Helix Range Vaults

Automated CL vaults for pairs like:

* WBNB / USDT
* WBNB / FDUSD
* slisBNB / BNB
* blue-chip / stable pairs with deep routing

These vaults manage:

* fee-tier selection,
* range placement,
* fee collection,
* auto-compounding,
* idle buffer management,
* emergency widening / de-risking.

### B. Helix Base Vaults

Low-risk vaults for:

* BNB
* slisBNB
* BNBx
* stablecoins

These are simple yield-routing products using staking, lending, and standard wrappers.

### C. Helix Carry Vaults

Moderate-risk vaults that use:

* LST collateral,
* Venus lending markets,
* stable borrowing,
* constrained carry trades.

These are not “max yield” degen products. They are **bounded-risk spread products**.

---

## 2. Core thesis

The protocol should **not** try to recreate 2021 farm-token reflexivity.

It should do four things instead:

* turn hard-to-manage BNB Chain positions into **simple ERC-4626 vaults**,
* use **isolated adapters** instead of one giant strategy contract,
* value positions conservatively to avoid PancakeBunny-style accounting mistakes,
* monetize through **fees and infrastructure**, not emissions.

This is consistent with the current stack: Venus already exposes **isolated pools** and even **ERC-4626 wrappers** around vTokens, which is exactly the kind of composable base layer Helix should build on. OpenZeppelin’s ERC-4626 docs also explicitly warn about inflation-attack edge cases, so the accounting design must be deliberate from day one. ([docs-v4.venus.io][3])

---

## 3. Product definition

### User segments

**Retail passive users**

* want 1-click BNB yield,
* do not want to manage ranges or leverage,
* care about clean UX and transparent risk.

**Advanced LPs**

* understand CL and IL,
* want execution quality and lower maintenance burden,
* care about fee capture and net-of-cost returns.

**DAOs / treasury users**

* want managed BNB/stable liquidity,
* want white-label or segregated vaults,
* care about reporting, permissions, and limits.

---

## 4. The exact v1 product

### v1 launch wedge: Helix Range

This is the sharpest wedge.

Why:

* PancakeSwap v3 uses custom ranges, fee tiers, and NFT positions. ([docs.pancakeswap.finance][4])
* THENA uses Algebra-style concentrated liquidity with dynamic fees and hook-based extensibility. ([docs.thena.fi][5])
* PancakeSwap removed integrated position managers from the main UI in 2025. ([docs.pancakeswap.finance][6])
* Beefy’s CLM docs show that this problem is still real enough to support dedicated products. ([docs.beefy.finance][7])

### v1 vault list

1. **HLX-WBNB-USDT**
2. **HLX-slisBNB-BNB**
3. **HLX-WBNB-FDUSD**
4. **HLX-USDT Base**
5. **HLX-BNB Base**

### v1 exclusions

No perp vaults.
No cross-chain routing.
No permissionless strategy creation.
No public leverage loops.
No protocol token.

---

## 5. Smart-contract architecture

### Top-level contracts

#### `VaultFactory`

Deploys new vaults as minimal clones.

#### `HelixVault4626`

User-facing ERC-4626 vault.
Responsibilities:

* deposits,
* withdrawals,
* share mint/burn,
* fee accrual,
* idle buffer,
* withdrawals queue,
* state machine.

#### `StrategyRegistry`

Allowlist of approved strategies and adapters.

#### `AllocationController`

Maps each vault to one active strategy and permitted fallback strategies.

#### `RiskEngine`

Stores limits and validates strategy actions:

* max LTV,
* max exposure per venue,
* max slippage,
* stale-oracle rules,
* max daily drawdown,
* rebalance frequency floor,
* TVL caps.

#### `OracleRouter`

Returns conservative valuations using multiple sources.

#### `Executor`

Entry point for keeper / solver actions.
Only executes signed instructions that pass risk checks.

#### `FeeRouter`

Distributes management and performance fees.

#### `InsuranceReserve`

Protocol-owned reserve funded by fees.

#### `Guardian`

Emergency pause and unwind authority.

#### `Lens`

Read-only helper for frontends and analytics.

---

## 6. Adapter model

Each external venue gets its own adapter.

### Required adapters

#### `PancakeV3Adapter`

Handles:

* minting / increasing / decreasing NFT positions,
* fee collection,
* token swaps for rebalance,
* position valuation.

#### `ThenaCLAdapter`

Same job, but for THENA/Algebra pools.

#### `VenusSupplyAdapter`

Supplies assets to Venus markets or Venus ERC-4626 wrappers.

#### `LSTAdapter`

Handles mint/redeem for supported LST providers.

### Why adapters matter

PancakeBunny’s era favored monolithic strategy code. Helix should not do that.

Each adapter is:

* small,
* audited independently,
* replaceable,
* venue-specific,
* capped by vault risk settings.

A vault should never have arbitrary external-call power.

---

## 7. Vault accounting

This is the most important part.

### Share price

For each vault:

[
sharePrice = \frac{totalAssetsConservative - accruedFees}{totalSupply}
]

### Conservative NAV

[
totalAssetsConservative =
idle

* \sum haircut_i \cdot positionValue_i
* claimableFees

- totalDebt
- pendingExecutionCosts
  ]

### Rules

* **No AMM spot-only valuation.**
* Use **median / min-of-sources** logic where appropriate.
* Apply **haircuts** to less reliable components.
* If valuation is uncertain, **pause deposits before withdrawals**.
* If oracle deviation is too large, move vault to **WithdrawOnly**.

For ERC-4626 specifically, Helix should use:

* virtual shares / assets on initialization,
* minimum-liquidity seed,
* preview functions with conservative rounding,
* deposit caps while TVL is small.

That directly addresses the inflation-attack class OpenZeppelin documents for ERC-4626. ([OpenZeppelin Docs][8])

---

## 8. Oracle design

### Price sources

Helix should use a layered oracle stack:

1. **Primary**: robust external oracle for major assets
2. **Secondary**: DEX TWAP
3. **Tertiary**: protocol-native exchange rate / redemption rate
4. **Fallback**: last-good-price within bounded staleness

### Specific rules

#### For BNB/LST assets

Use the more conservative of:

* protocol redemption rate,
* bounded TWAP-implied rate.

#### For CL positions

Value the position as:

* current token balances implied by pool state,
* plus uncollected fees,
* all marked using TWAP/external oracle,
* minus slippage haircut for unwind.

#### For lending positions

Use:

* onchain debt,
* onchain collateral balances,
* protocol collateral factors,
* internal haircuts stricter than venue limits.

### Deposit protection

Helix should copy the best idea from modern CL managers: a **calm-zone** check.
Deposits should revert if current pool price deviates too far from TWAP. Beefy explicitly documents this pattern for flash-loan / manipulation defense. ([docs.beefy.finance][7])

---

## 9. Strategy logic

## 9.1 Range Vault algorithm

Each range vault manages **one primary position** and optionally **one buffer position**.

### Inputs

* realized volatility,
* TWAP trend,
* depth by fee tier,
* recent fee generation,
* gas cost,
* current inventory skew.

### Pool scoring

[
score = expectedFeeAPR - \lambda_1 \cdot outOfRangeRisk - \lambda_2 \cdot ILCost - \lambda_3 \cdot gasDrag
]

### Center selection

[
centerPrice = median(TWAP_{5m}, TWAP_{30m}, externalOracle)
]

### Width selection

[
widthBps = clamp(minWidth,\ \alpha \sigma \sqrt{T},\ maxWidth)
]

Where:

* (\sigma) = realized volatility,
* (T) = expected time until next rebalance.

### Rebalance triggers

Rebalance if any of these happen:

* current tick leaves 70% of target band,
* expected fee APR drops below threshold,
* inventory skew exceeds limit,
* oracle disagreement exceeds threshold,
* volatility regime changes.

### Execution

A rebalance does:

1. collect fees,
2. exit old range,
3. swap to target inventory,
4. mint new range,
5. leave 3–10% idle buffer.

### User promise

Users are not promised “highest APY”.
They are promised:

* disciplined range management,
* bounded execution,
* transparent risk score,
* simple exit.

---

## 9.2 Base Vault algorithm

### `HLX-BNB Base`

* deposit BNB,
* split among supported LST routes according to capacity and price quality,
* keep idle redemption buffer,
* compound yield periodically.

### `HLX-USDT Base`

* supply to approved lending markets / wrappers,
* no leverage,
* no CL,
* strict venue concentration caps.

These are treasury-friendly vaults.

---

## 9.3 Carry Vault algorithm

This is v2, not day-one.

### Flow

1. user deposits BNB or LST,
2. protocol stakes into supported LST if needed,
3. supplies collateral to Venus,
4. borrows stablecoins only if net spread exceeds hurdle,
5. deploys borrowed stables into approved low-risk stable strategies,
6. auto-delevers on spread compression or health deterioration.

### Safety rules

* hard max LTV below venue max,
* soft delever threshold above hard threshold,
* no recursive looping beyond configured limit,
* no strategy if borrow liquidity is thin,
* no carry deployment during oracle stress.

This fits Venus well because Venus already supports isolated pools with tailored risk parameters, and its vToken / ERC-4626 architecture is cleanly composable. ([docs-v4.venus.io][3])

---

## 10. Vault state machine

Each vault has five states:

### `Active`

Normal operations.

### `Caution`

Deposits limited, tighter execution bounds.

### `WithdrawOnly`

No new deposits. Only unwind / withdrawals.

### `Paused`

No external strategy actions.

### `EmergencyExit`

Adapters unwind to base asset as fast as permitted.

State transitions are triggered by:

* stale oracles,
* excessive drawdown,
* governance action,
* venue outage,
* insolvency risk,
* abnormal pool behavior.

---

## 11. Governance

## Launch governance

No DAO at launch.

Use:

* **3/5 multisig** for operations,
* **48h timelock** for non-emergency changes,
* **separate Guardian** for pause-only powers,
* **Risk Council** for parameter changes inside strict bounds.

### Roles

* Governor
* Guardian
* Risk Council
* Strategist
* Keeper
* Treasury

### Hard limits

Some parameters should be immutable or nearly immutable:

* max management fee,
* max performance fee,
* max leverage cap,
* approved adapter types,
* admin withdrawal impossibility.

---

## 12. Fee model

No inflationary token.

### Fees

* **Base Vaults**: 0.25–0.75% management fee
* **Range Vaults**: 8–15% performance fee
* **Carry Vaults**: 10–20% performance fee
* **White-label vaults**: custom B2B pricing

### Fee split

* 50% treasury
* 25% insurance reserve
* 15% strategists / keepers
* 10% ecosystem / partner rebates

### Why no token

A token would weaken the design early.
The protocol should prove:

* retention,
* net yield,
* security,
* white-label demand,
  before adding governance-token complexity.

---

## 13. Security program

### Security assumptions

External protocols can fail.
Oracle feeds can fail.
Keepers can act maliciously.
Users can attempt sandwich or deposit-manipulation attacks.

### Required controls

* two external audits before mainnet,
* formal review of share-accounting math,
* invariant testing,
* fork testing on BSC,
* per-adapter property tests,
* bug bounty,
* execution simulation before every rebalance.

### Specific invariants

1. user shares can never exceed conservative NAV,
2. adapter cannot move funds to non-allowlisted targets,
3. debt cannot exceed vault risk limits,
4. emergency exit must remain callable when governance is unavailable,
5. fee minting cannot dilute users beyond configured ceiling.

---

## 14. Frontend and UX

The frontend should look simple even if the backend is not.

### Core UI objects

* vault card,
* risk score,
* APY breakdown,
* current allocation,
* max drawdown since inception,
* current health factor,
* position composition,
* withdrawal ETA.

### Deposit UX

* single-asset deposit,
* auto-zap where useful,
* preview slippage,
* preview expected share mint,
* visible reasons when deposit is blocked.

### Risk labels

* Base
* Moderate
* Active LP
* Levered Carry

No cartoon APY numbers.
No “safe” label.
No hidden leverage.

---

## 15. Data layer

Helix needs a strong read layer.

### Backend

* BSC indexer,
* vault event processor,
* strategy-state cache,
* NAV calculator,
* performance API.

### Public analytics

* gross vs net APY,
* fee APR,
* realized vs unrealized IL,
* current exposure by venue,
* execution history,
* oracle status.

---

## 16. Compliance and legal posture

Protocol contracts remain permissionless.
Frontend can be selective.

### Public vaults

No KYC. Standard non-custodial disclosures.

### Institutional / RWA vaults

Optional permissioned share token or allowlist extension.

That becomes especially useful on THENA-style hookable infrastructure, because hook systems can support compliance-aware pool logic. ([docs.thena.fi][5])

---

## 17. Go-to-market

### Phase 0

* publish audit-first design,
* launch analytics dashboard before deposits,
* recruit power LPs and BNB-native treasuries.

### Phase 1

* launch 2–3 Range Vaults,
* launch 1 Base stable vault,
* cap TVL aggressively.

### Phase 2

* launch white-label vaults for token projects,
* add Base BNB vault,
* add venue-specific optimizer logic.

### Phase 3

* launch Carry Vaults,
* explore opBNB expansion,
* explore permissioned RWA vaults.

---

## 18. Team

Minimum team:

* 2 smart-contract engineers
* 1 backend / indexer engineer
* 1 frontend engineer
* 1 quant / risk engineer
* 1 product / BD operator

Optional:

* dedicated auditor liaison,
* keeper-ops engineer.

---

## 19. KPIs

The right KPIs are not TVL-first.

### Product KPIs

* net APY vs manual benchmark,
* % time in range for CL vaults,
* average slippage per rebalance,
* withdrawal fulfillment time,
* share-price volatility,
* oracle incident count.

### Business KPIs

* 30d retention,
* fee revenue per active vault,
* TVL concentration by whale,
* partner vault count,
* insurance reserve growth.

---

## 20. Main failure modes

This project fails if:

1. it becomes a disguised leverage casino,
2. accounting uses manipulable spot prices,
3. strategy logic is opaque,
4. fees are too high relative to manual alternatives,
5. governance can hot-patch user funds without constraint,
6. the first product launch is too broad.

So the design must stay narrow at first:

* BSC only,
* few vaults,
* low TVL caps,
* conservative execution,
* visible risk.

---

## Final version of the project

If I were actually building this, the exact project would be:

**Helix**
**Tagline:** “Automated liquidity and yield execution for BNB Chain.”
**Wedge:** CL vaults after PancakeSwap’s position-manager sunset.
**Core tech:** ERC-4626 vaults + isolated adapters + conservative oracle router + risk engine + keeper execution.
**Revenue:** management/performance/B2B fees.
**Token:** none at launch.
**Moat:** execution quality, safety, white-label infra, and BNB-native integrations.

That is the version most likely to work in 2026.

The next useful step is turning this into a full **contract-level spec**: exact interfaces, storage layout, events, access control, and the first three vault parameters.

[1]: https://defillama.com/chain/bsc?utm_source=chatgpt.com "BSC - DeFi TVL, Fees, & Revenue - DefiLlama"
[2]: https://www.bnbchain.org/en/liquid-staking?utm_source=chatgpt.com "Liquid Staking - BNB Chain"
[3]: https://docs-v4.venus.io/whats-new/isolated-pools?utm_source=chatgpt.com "Isolated Pools | Venus Protocol"
[4]: https://docs.pancakeswap.finance/products/pancakeswap-exchange/faq?utm_source=chatgpt.com "Swap FAQ | PancakeSwap"
[5]: https://docs.thena.fi/thena/liquidity-provision/concentrated-liquidity?utm_source=chatgpt.com "Concentrated Liquidity | THENA"
[6]: https://docs.pancakeswap.finance/archive/legacy-products/archived-position-manager?utm_source=chatgpt.com "[Archived] Position Manager | PancakeSwap"
[7]: https://docs.beefy.finance/beefy-products/clm?utm_source=chatgpt.com "CLM | Beefy"
[8]: https://docs.openzeppelin.com/contracts/5.x/erc4626?utm_source=chatgpt.com "ERC-4626 | OpenZeppelin Docs"
