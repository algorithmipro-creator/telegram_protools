# Track A Storage Reserve Policy

## Purpose

Define how Track A treats TON storage fees, reserve sizing, and proposal history retention before any mainnet candidate work continues.

This document is policy evidence, not an audit report. The estimates are based on current mainnet basechain storage parameters, live-chain observation, and deterministic Acton sandbox fixtures.

## Current Evidence

- Track A Treasury testnet address: `kQAEswTqc4bDarhACzMsgMhOXOgYcYHaXLLnwwOnMepqhSnA`.
- Current observed deployed testnet state after proposal `1`: `45 cells`, `11094 bits`; this remains live-chain evidence, not the deterministic sizing fixture.
- Deterministic Acton sandbox fixtures now measure retained proposal scenarios for `0`, `10`, `100`, and `1000` proposals through contract messages.
- Current MVP `feeReserve`: `0.1 TON`.
- Mainnet basechain storage parameters used for the policy estimate: `bit_price_ps = 1`, `cell_price_ps = 500`, `freeze_due_limit = 0.1 TON`, `delete_due_limit = 1 TON`.

## Storage Fee Estimates

Sandbox fixture rows use measured cells/bits/refs from Acton tests. Fee columns are policy estimates recomputed from those measured sizes with the mainnet basechain parameters above, not raw sandbox-config fee output.

| Scenario | Source | State Size | 1 Year | 5 Years | 10 Years | Notes |
|---|---|---:|---:|---:|---:|---|
| Observed testnet after proposal `1` | Live-chain observed / prior policy estimate | `45 cells`, `11094 bits` | `16165473 nanotons` (`0.016165473 TON`) | `80827361 nanotons` (`0.080827361 TON`) | `161654722 nanotons` (`0.161654722 TON`) | Live-chain evidence; not the deterministic sizing fixture. |
| Sandbox `0` proposals | Deterministic Acton sandbox fixture | `4 cells`, `687 bits`, `3 refs` | `1292988 nanotons` (`0.001292988 TON`) | `6464938 nanotons` (`0.006464938 TON`) | `12929876 nanotons` (`0.012929876 TON`) | Baseline deployed state with no retained proposals. |
| Sandbox `10` proposals | Deterministic Acton sandbox fixture | `52 cells`, `10512 bits`, `51 refs` | `17569618 nanotons` (`0.017569618 TON`) | `87848086 nanotons` (`0.087848086 TON`) | `175696172 nanotons` (`0.175696172 TON`) | Small retained-history fixture. |
| Sandbox `100` proposals | Deterministic Acton sandbox fixture | `502 cells`, `98569 bits`, `501 refs` | `168213013 nanotons` (`0.168213013 TON`) | `841065063 nanotons` (`0.841065063 TON`) | `1682130125 nanotons` (`1.682130125 TON`) | Current bounded-history sizing input. |
| Sandbox `1000` proposals | Deterministic Acton sandbox fixture | `5002 cells`, `976248 bits`, `5001 refs` | `1673255813 nanotons` (`1.673255813 TON`) | `8366279063 nanotons` (`8.366279063 TON`) | `16732558125 nanotons` (`16.732558125 TON`) | Stable stress evidence; not a recommended normal treasury retention target. |

## Interpretation

- `0.1 TON` remains a testnet/MVP reserve, not a mainnet reserve policy for long-lived treasury history.
- Deterministic fixtures provide the baseline sizing evidence for `0`, `10`, and `100` retained proposals.
- The measured `100` proposal fixture is the current bounded-history sizing input.
- Unbounded on-chain proposal history remains unacceptable for a mainnet treasury.
- The measured `1000` proposal fixture is stress evidence, not a normal treasury retention target.

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

- Bounded scenario sizes are measured in the Acton sandbox from contract messages.
- Live-chain state can differ from deterministic sandbox fixture state.
- Network config can change; values must be regenerated before mainnet release.
- This document does not implement cleanup, pruning, indexer behavior, or contract-level reserve changes.
