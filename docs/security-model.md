# TreasuryFlow TON Security Model

## Security Position

TreasuryFlow handles team funds. Every payout, split distribution, and configuration update is a financial security event.

The first beta is testnet only. Mainnet is blocked until architecture selection, security review, and release checklist approval.

Track A hardening evidence:

- Testnet deployment and manual payout flow: `docs/research/track-a-testnet-deployment.md`.
- Source verification dry-run: `docs/research/track-a-source-verification.md`.
- Gas/fee baseline: `docs/research/track-a-gas-fee-baseline.md`.
- Storage reserve policy: `docs/research/track-a-storage-reserve-policy.md`.
- Proposal pruning design: `docs/superpowers/specs/2026-05-18-treasury-proposal-pruning-design.md`.
- Security review readiness checklist: `docs/research/track-a-security-checklist.md`.

This document tracks the broader TreasuryFlow security model. The Track A Treasury Core v0.1 evidence currently covers TON payout proposals plus typed governance/config proposals for owners, `payoutThreshold`, `configThreshold`, and `feeReserve`; Splitter, Telegram, backend/indexer, Track B, and mainnet remain product-wide or future scope unless explicitly listed as Track A Core evidence.

## Assets To Protect

- Treasury TON balance.
- Owner list.
- Threshold.
- Pending proposals.
- Approval records.
- Split rules.
- Deployment keys and wallet configuration.
- Telegram bot token.
- Offchain metadata integrity.

## Invariants

| Invariant | Requirement |
|---|---|
| Owner-only proposal creation | Non-owner cannot create financial proposals |
| Owner-only approval | Non-owner cannot approve |
| No double approval | One owner cannot increase approval count twice |
| Threshold required | Execution before threshold is rejected |
| Expiry enforced | Expired proposal cannot execute |
| No double execution | Executed proposal cannot execute again |
| Deterministic split math | UI preview and onchain result match |
| Fee reserve | Treasury does not drain below configured reserve |
| Bounded owner count | Treasury owner count is limited to `2..10` in Core v0.1 |
| Minimum message value | State-changing messages enforce per-operation inbound value minimums |
| Bounded proposal expiry | Payout proposal expiry is in the future and no more than 30 days ahead |
| Recipient sanity | Payout recipient cannot be the Treasury contract itself |
| Execute action success | Successful execution emits the intended payout action and child transfer evidence |
| On-chain history retention | Bounded retention or cleanup/indexer policy is required before mainnet; Core v0.1 still retains proposal/approval history on-chain |
| Pruning safety | Future pruning must be owner-only in v1, must not remove pending or executable current-version proposals, and must not leave orphan approvals |
| Payload transparency | Payload is decoded or marked with a warning |
| Replay protection | Proposal/action cannot be reused after terminal status |
| Current-config authority | Config changes require approval from current owners under the current config threshold |
| Typed config governance | Config changes use only `SetTreasuryConfigProposal`; arbitrary governance payloads remain excluded |
| Config threshold lock | `configThresholdMutable` is deploy-time only and immutable after deploy |
| Stale after config change | Pending proposals from old config versions cannot approve, execute, or cancel |
| Governance deadlock prevention | Final config must satisfy `1 <= payoutThreshold <= configThreshold <= ownerCount` |
| Config owner preview | Proposed owner set is inspectable before approval via getter |

## Threats And Mitigations

| Threat | Mitigation |
|---|---|
| Single owner drain | N-of-M approval threshold |
| Replay | nonce, status, terminal proposal states |
| Storage exhaustion | reserve sizing evidence; bounded retention or cleanup/indexer policy remains a mainnet blocker |
| Prune abuse | Phase 4 design limits pruning to current owners and only to Executed, Cancelled, Expired, or Stale proposals |
| Owner-set growth | hard-coded `MAX_OWNER_COUNT = 10` and deployment-time config validation |
| Underfunded state-changing message | per-operation minimum inbound value checks |
| Stale long-lived proposal | maximum proposal expiry window |
| Self-payout noise | recipient cannot equal Treasury contract address |
| Action-phase ambiguity | deterministic test inspects action phase and payout transaction evidence |
| Double approval | approval bitmap/map per proposal |
| Expired execution | expiry check before approval and execution |
| Unknown payload | human-readable parser plus raw technical details |
| Owner spoofing | onchain sender validation |
| Threshold attack | typed config proposals require current `configThreshold`, stale proposals are invalidated after config changes, and final config validation prevents impossible owner/threshold states |
| Jetton spoofing | Jettons excluded from first beta |
| Bounce confusion | activity visibility and explicit failure state where possible |
| Frontend compromise | onchain checks, generated wrappers, raw payload preview, source verification |

## Mainnet Blockers

Mainnet is forbidden until all of these are complete:

- Architecture decision record is approved.
- Threat model is reviewed.
- Critical unit and fuzz tests pass.
- Gas and fee implications are understood.
- Storage reserve sizing is measured against max-state fixtures.
- On-chain history retention policy is approved.
- Source verification workflow is confirmed.
- Security checklist is reviewed and all critical findings are resolved.
- External review or audit is completed.
- Mainnet release checklist is approved.
