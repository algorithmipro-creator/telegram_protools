# Track A Storage Reserve Policy Design

## Goal

Document the Track A Treasury storage reserve policy before mainnet work continues: how much reserve is needed, why unbounded on-chain proposal history is unsafe, and what cleanup/indexing strategy is required before scale.

## Context

Track A has now passed testnet deployment, manual payout validation, source verification dry-run, and a live gas/fee baseline. The remaining security discussion uncovered a separate mainnet risk: TON storage fees grow with contract state size. If Treasury stores unlimited proposals and approvals on-chain, required reserve grows quickly and frozen/deleted account risk becomes harder to reason about.

The current MVP has `feeReserve = 0.1 TON`. Based on the current deployed state after proposal `1`, the account state is estimated at `45 cells` and `11094 bits`. Using current mainnet basechain storage pricing, the current state costs about `0.016165473 TON` per year, so `0.1 TON` covers roughly 6 years for the current small state. That reserve is not enough for long-lived high-history usage.

## Mainnet Storage Estimates

Record these estimates in a new research document. They are policy inputs, not final audit-grade proofs.

| Scenario | Estimated State Size | 1 Year | 5 Years | 10 Years | Approx Freeze Time With Zero Balance |
|---|---:|---:|---:|---:|---:|
| Current state | `45 cells`, `11094 bits` | `0.016165473 TON` | `0.080827361 TON` | `0.161654722 TON` | `~6.18 years` |
| 10 proposals | `109 cells`, `23982 bits` | `0.037765631 TON` | `0.188828152 TON` | `0.377656304 TON` | `~2.65 years` |
| 100 proposals | `829 cells`, `168972 bits` | `0.280767411 TON` | `1.403837051 TON` | `2.807674102 TON` | `~130 days` |
| 1000 proposals | `8029 cells`, `1618872 bits` | `2.710785209 TON` | `13.553926041 TON` | `27.107852081 TON` | `~13 days` |

The estimates use current mainnet basechain storage parameters: `bit_price_ps = 1`, `cell_price_ps = 500`, `freeze_due_limit = 0.1 TON`, and `delete_due_limit = 1 TON`. Before mainnet release, the exact numbers must be regenerated from current network config and from measured max-state sandbox fixtures.

## Policy

Track A should not rely on unlimited on-chain history.

For MVP/testnet, keep the current reserve and document that it is not a final mainnet sizing decision. For mainnet candidate work, choose one of these paths before public launch:

- Add bounded on-chain retention and cleanup/pruning for terminal proposals.
- Move long-term history to an off-chain indexer while keeping only active or recently terminal state on-chain.
- Raise `feeReserve` according to a measured max-state target and documented retention window.

The recommended mainnet policy is hybrid: keep only security-critical active state on-chain, prune terminal proposals after a safe visibility window, and store full historical UX/audit views in an indexer. On-chain data remains public and authoritative for current authorization; off-chain history is product evidence and must be reproducible from transaction history.

## Reserve Tiers

Use these tiers as defaults for planning, not immutable protocol constants:

| Tier | Intended Use | Recommended Reserve |
|---|---|---:|
| Testnet/MVP | low-value validation, few proposals | `0.1 TON` |
| Small mainnet treasury | bounded active proposals, low history | `0.5 TON` |
| Medium team treasury | up to about 100 retained proposals without cleanup | `3.5-4 TON` |
| High-history treasury | hundreds or thousands of retained proposals | avoid; require cleanup/indexer first |

These tiers should be reviewed after measured max-state tests. If a future design allows 1000 retained proposals, reserve must be much higher or the design should be rejected for normal team treasuries.

## Threshold And Governance Note

`threshold` remains immutable in the Track A MVP. Changing `threshold`, owner set, or reserve policy changes the security model and must not be added as a normal payout proposal. Future governance changes need a separate design with stronger approval rules, such as supermajority or unanimous approval, plus warnings and potentially time locks.

## Documentation Updates

Implementation should add `docs/research/track-a-storage-reserve-policy.md` and update:

- `docs/security-model.md` with the storage reserve evidence and unbounded-history risk.
- `docs/research/track-a-security-checklist.md` with reserve sizing and cleanup/indexer follow-ups.
- `docs/beta/architecture-scorecard.md` with the Track A storage reserve caveat.
- `docs/beta-test-plan.md` if beta readiness wording needs to distinguish testnet reserve from mainnet reserve.

## Out Of Scope

- Contract code changes.
- Implementing pruning or indexer behavior.
- Changing `feeReserve` in deployed testnet Treasury.
- Changing `threshold` or owner governance.
- Mainnet deployment.
- Final source verification transaction.

## Success Criteria

- Storage reserve estimates are recorded with assumptions and limitations.
- Mainnet blockers explicitly include reserve sizing and on-chain history policy.
- Docs state that unbounded proposal/approval history is not acceptable for mainnet scale.
- Docs state that `threshold` remains immutable in MVP and governance changes require separate design.
- No secrets, mnemonics, wallet files, or verifier transaction bodies are added.
