# TreasuryFlow TON Security Model

## Security Position

TreasuryFlow handles team funds. Every payout, split distribution, and configuration update is a financial security event.

The first beta is testnet only. Mainnet is blocked until architecture selection, security review, and release checklist approval.

Track A hardening evidence:

- Testnet deployment and manual payout flow: `docs/research/track-a-testnet-deployment.md`.
- Source verification dry-run: `docs/research/track-a-source-verification.md`.
- Gas/fee baseline: `docs/research/track-a-gas-fee-baseline.md`.
- Storage reserve policy: `docs/research/track-a-storage-reserve-policy.md`.
- Security review readiness checklist: `docs/research/track-a-security-checklist.md`.

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
| Bounded on-chain history | Treasury does not rely on unlimited retained proposals/approvals |
| Payload transparency | Payload is decoded or marked with a warning |
| Replay protection | Proposal/action cannot be reused after terminal status |

## Threats And Mitigations

| Threat | Mitigation |
|---|---|
| Single owner drain | N-of-M approval threshold |
| Replay | nonce, status, terminal proposal states |
| Storage exhaustion | reserve sizing, bounded retention, cleanup/indexer policy |
| Double approval | approval bitmap/map per proposal |
| Expired execution | expiry check before approval and execution |
| Unknown payload | human-readable parser plus raw technical details |
| Owner spoofing | onchain sender validation |
| Threshold attack | threshold updates disabled in beta UI or require approved proposal |
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
