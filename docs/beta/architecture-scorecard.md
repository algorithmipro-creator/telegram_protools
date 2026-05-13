# TreasuryFlow Architecture Scorecard

## Purpose

Compare Track A custom Tolk and Track B official multisig v2 based architecture after testnet validation.

## Weighted Score

| Criterion | Weight | Track A Score 1-5 | Track B Score 1-5 | Evidence |
|---|---:|---:|---:|---|
| Security / auditability | 30 | 3 | 0 | Track A has 20 deterministic tests, testnet create/approve/execute evidence, source verification dry-run evidence, and a security checklist; final source verification transaction and security review are still required before mainnet. |
| User UX clarity | 20 | 2 | 0 | Contract flow works through scripts; no Mini App or user-facing signing flow has been tested yet. |
| Development complexity | 15 | 4 | 0 | Custom Tolk Treasury, wrappers, deploy script, and testnet scripts are implemented; TypeScript wrapper friction was resolved. |
| Gas/fees | 15 | 3 | 0 | Real testnet balances, transaction links, and observed wallet-side costs are recorded for Track A create/approve/execute; no mainnet fee guarantee exists yet. |
| Acton workflow compatibility | 10 | 4 | 0 | Acton build/test/check/fmt, wrapper generation, deployment, RPC decode, and testnet scripts work on Ubuntu. Windows/WSL networking remains environmental friction. |
| Extensibility for splits/Jettons | 10 | 2 | 0 | Track A payout core is isolated; Splitter and Jettons are intentionally out of scope and not validated. |

## Score Rules

- 1 means poor fit or high risk.
- 3 means acceptable with known trade-offs.
- 5 means strong fit with clear evidence.
- Do not assign a nonzero score without written evidence.

## Decision Outcomes

- Choose Track A only if security review supports custom multisig logic.
- Choose Track B if official multisig gives stronger safety without unacceptable UX constraints.
- Choose hybrid if official multisig handles authorization while custom contracts handle product-specific split and metadata flows.

## Track A Evidence Snapshot

- Deployed Treasury on testnet: `kQAEswTqc4bDarhACzMsgMhOXOgYcYHaXLLnwwOnMepqhSnA`.
- Deployment transaction: https://testnet.tonviewer.com/transaction/527e66692a2fb3226025b5b6dbb96834e82c102c129a2a682d96d16a3cb70c7f
- Manual flow completed on testnet: create proposal, second-owner approve, execute payout.
- Manual flow transactions:
  - Create: https://testnet.tonviewer.com/transaction/869e952d66ea95e64f8535b3a7d7ce030bcbc3c1e6e419e7682706d68156efd9
  - Approve: https://testnet.tonviewer.com/transaction/ead1526f089ee7c2689d003b8d07f84e0d948b75b41021bee2937fd51858d6b2
  - Execute: https://testnet.tonviewer.com/transaction/ba43948018c3621993005c5476bea0f0ecd66e051317fce6975876bd23a850e8
- Recipient received `0.05 TON` on testnet.
- Final decoded proposal state: proposal `0`, approval count `2`, status `Executed`.
- Full evidence: `docs/research/track-a-testnet-deployment.md`.
- Source verification dry-run completed with verifier backend acceptance: `docs/research/track-a-source-verification.md`.
- Gas/fee baseline for create, approve, and execute: `docs/research/track-a-gas-fee-baseline.md`.
- Security review checklist: `docs/research/track-a-security-checklist.md`.

## Current Decision

Track A is validated enough to continue hardening and beta preparation on testnet. Mainnet remains blocked until the final source verification transaction, security review/audit readiness, and a release checklist are complete. Track B remains unscored until official multisig v2 is tested with comparable evidence.
