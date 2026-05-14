# Track A Storage Reserve Policy

## Purpose

Define how Track A treats TON storage fees, reserve sizing, and proposal history retention before any mainnet candidate work continues.

This document is policy evidence, not an audit report. The estimates are based on current mainnet basechain storage parameters and an approximate state-size model from the deployed testnet Treasury after proposal `1`.

## Current Evidence

- Track A Treasury testnet address: `kQAEswTqc4bDarhACzMsgMhOXOgYcYHaXLLnwwOnMepqhSnA`.
- Current observed deployed state after proposal `1`: `45 cells`, `11094 bits`.
- Current MVP `feeReserve`: `0.1 TON`.
- Mainnet basechain storage parameters used for this estimate: `bit_price_ps = 1`, `cell_price_ps = 500`, `freeze_due_limit = 0.1 TON`, `delete_due_limit = 1 TON`.

## Storage Fee Estimates

| Scenario | Estimated State Size | 1 Year | 5 Years | 10 Years | Approx Freeze Time With Zero Balance |
|---|---:|---:|---:|---:|---:|
| Current state | `45 cells`, `11094 bits` | `0.016165473 TON` | `0.080827361 TON` | `0.161654722 TON` | `~6.18 years` |
| 10 proposals | `109 cells`, `23982 bits` | `0.037765631 TON` | `0.188828152 TON` | `0.377656304 TON` | `~2.65 years` |
| 100 proposals | `829 cells`, `168972 bits` | `0.280767411 TON` | `1.403837051 TON` | `2.807674102 TON` | `~130 days` |
| 1000 proposals | `8029 cells`, `1618872 bits` | `2.710785209 TON` | `13.553926041 TON` | `27.107852081 TON` | `~13 days` |

## Interpretation

- `0.1 TON` is acceptable for low-value MVP/testnet validation with a small number of proposals.
- `0.1 TON` is not enough for a mainnet treasury that keeps long-lived proposal history on-chain.
- At 100 retained proposals, a 10-year reserve estimate is already about `2.81 TON` before safety margin.
- At 1000 retained proposals, on-chain history retention is not a normal treasury design; it requires cleanup/indexer architecture or very high reserve.

## Reserve Tiers

| Tier | Intended Use | Recommended Reserve |
|---|---|---:|
| Testnet/MVP | low-value validation, few proposals | `0.1 TON` |
| Small mainnet treasury | bounded active proposals, low history | `0.5 TON` |
| Medium team treasury | up to about 100 retained proposals without cleanup | `3.5-4 TON` |
| High-history treasury | hundreds or thousands of retained proposals | avoid; require cleanup/indexer first |

These tiers are planning defaults, not immutable protocol constants. Before mainnet, regenerate the estimates from current network config and measured max-state sandbox fixtures.

## Retention Policy

Track A must not rely on unlimited on-chain proposal and approval history.

Mainnet candidate work must choose one of these paths before public launch:

- Keep only active or recently terminal proposals on-chain and prune terminal proposals after a safe visibility window.
- Store long-term user-facing history in an off-chain indexer, reproducible from transaction history.
- Raise `feeReserve` according to a measured max-state target and a documented retention window.

Recommended direction: hybrid retention. Keep security-critical active state on-chain, prune terminal proposal state after the product has indexed it, and keep full historical UX/audit views off-chain.

## Governance Note

`threshold` remains immutable in the Track A MVP. Changing `threshold`, owner set, or reserve policy changes the security model and must not be added as a normal payout proposal.

Future governance/config changes require a separate design with stronger approval rules, such as supermajority or unanimous approval, plus explicit UI warnings and potentially time locks.

## Mainnet Requirements

- Measure max-state cells/bits in deterministic sandbox tests.
- Decide retention policy: bounded on-chain history, cleanup/pruning, or indexer-backed history.
- Set `feeReserve` from measured max-state size and target reserve lifetime.
- Add monitoring/alerts for Treasury balance approaching reserve.
- Keep mainnet blocked until security review accepts the reserve and retention policy.

## Limitations

- Estimates are approximate and based on current observed Track A state plus linear scaling assumptions.
- Network config can change; values must be regenerated before mainnet release.
- This document does not implement cleanup, pruning, indexer behavior, or contract-level reserve changes.
