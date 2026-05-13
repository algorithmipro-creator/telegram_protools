# TreasuryFlow TON Beta Test Plan

## Beta Type

The first beta is a public TON testnet validation with direct outreach to known teams.

## Target Segments

- Telegram Mini App developer team.
- Creator or Telegram channel team.
- DAO or community group.
- NFT or drop team.
- Agency or microbusiness.
- Other TON testnet user.

## Required Scenario

Each tester should attempt this scenario:

1. Open the Mini App.
2. Connect wallet through TON Connect.
3. Create a treasury with 2-10 owners.
4. Deposit testnet TON.
5. Create a payout proposal.
6. Have another owner approve.
7. Execute payout after threshold.
8. Configure split recipients and weights.
9. Create split distribution proposal.
10. Approve and execute split distribution.
11. Submit feedback.

## Current Progress

- Track A custom Tolk Treasury is deployed on TON testnet.
- Internal script-driven payout flow is complete: create proposal, second-owner approve, execute payout.
- Recipient received `0.05 TON` on testnet.
- Evidence is recorded in `docs/research/track-a-testnet-deployment.md`.
- The Mini App, backend/indexer, Splitter, Jettons, and user-facing beta flow are not implemented yet.
- Mainnet remains blocked until source verification, security review/audit readiness, and release checklist completion.

## Metrics

| Metric | Meaning |
|---|---|
| Task completion | Whether treasury, payout, and split flows complete |
| Time-to-complete | Time spent per flow |
| Confusion points | Where tester pauses or asks for help |
| Trust clarity | Whether tester understands what they sign |
| Fee clarity | Whether tester understands fees and reserves |
| Approval clarity | Whether tester understands threshold and remaining approvals |
| Split clarity | Whether split preview matches expectation |
| Error clarity | Whether failures are understandable |
| Architecture finding | Track-specific friction or failure |

## Release Gates

| Gate | Requirement |
|---|---|
| Internal testnet | Contracts build/test, UI completes one payout |
| Known teams beta | Payout and splits work, feedback form active, no critical security gap |
| Open beta | Source verification dry-run, public test instructions, known failure handling |
| Architecture decision | Scorecard completed for Track A and Track B |
| Mainnet candidate | Audit/review, threat model, migration/deprecation plan |

## Next Beta Readiness Tasks

- Complete Track A source verification or verification dry-run on testnet.
- Add a security review checklist for the custom Treasury logic.
- Decide whether to run Track B official multisig v2 for a comparable scorecard baseline.
- Start the user-facing beta surface only after contract verification and review tasks are clear.
