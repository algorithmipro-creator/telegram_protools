# TreasuryFlow TON Product Spec

## Summary

TreasuryFlow TON is a Telegram-native treasury tool for teams that need shared control over TON funds, approval-based payouts, and transparent TON revenue splits.

The first beta is not a mainnet product. It is a TON testnet validation of two architecture tracks using one shared user-facing flow.

## Product Goals

- Let a small team create a shared treasury with 2-10 owners.
- Require N-of-M approvals before funds leave the treasury.
- Make every payout and split action understandable before signing.
- Support TON payouts and TON splits in the first testnet beta.
- Collect feedback from open beta testers and known friendly teams.
- Choose the production architecture using measured evidence.

## Target Users

- Telegram Mini App developer teams.
- Creator and Telegram channel teams.
- DAO and community groups.
- NFT and drop teams.
- Agencies and microbusinesses that receive or pay TON.

Feedback must always record the tester segment because each group has different expectations and technical comfort.

## First Beta Scope

| Area | Decision |
|---|---|
| Network | TON testnet only |
| Asset | TON only |
| Core flow | create treasury, deposit, payout proposal, approvals, execution |
| Splits | TON split rule setup and TON split distribution |
| Wallet | TON Connect |
| UI | Telegram Mini App style frontend |
| Architecture | Track A custom Tolk and Track B official multisig v2 based |

## Non-Goals

- Mainnet deployment.
- Jetton payouts.
- Protocol fees.
- Lending, DEX, yield, prediction markets, and token launch features.
- Custodial accounts or server-controlled funds.
- Advanced DAO governance.
- Fiat on/off-ramp.

## Success Criteria

- Testers can complete treasury creation, payout, and split flows on testnet.
- Testers understand what they approve before signing.
- Track-specific issues are recorded separately.
- The team can score Track A and Track B using security, UX, complexity, gas, Acton compatibility, and extensibility evidence.
