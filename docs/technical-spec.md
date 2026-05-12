# TreasuryFlow TON Technical Spec

## Architecture Strategy

TreasuryFlow TON uses a dual testnet strategy before choosing a production architecture.

| Track | Description |
|---|---|
| Track A | Custom Tolk Treasury, Proposal logic, and Splitter contracts |
| Track B | Official TON multisig v2 as authorization layer with TreasuryFlow adapter and Splitter integration |

Both tracks must expose the same user-facing beta operations where possible.

## System Diagram

```text
Telegram Mini App
        |
        v
TON Connect + TreasuryFlow UI
        |
        v
Generated TypeScript Wrappers
        |
        +-----------------------------+
        |                             |
        v                             v
Track A Custom Tolk              Track B Official Multisig v2
Treasury + Splitter              Adapter + Splitter
        |                             |
        +--------------+--------------+
                       |
                       v
                 TON testnet
```

## Shared Operations

- Create treasury.
- Deposit TON.
- Create payout proposal.
- Approve proposal.
- Execute payout.
- Configure split rules.
- Create split distribution proposal.
- Approve split proposal.
- Execute split distribution.

## Onchain Boundary

Onchain state decides owners, threshold, proposal validity, approvals, execution status, split weights, payouts, and split execution.

## Offchain Boundary

Offchain systems may store names, comments, Telegram bindings, notifications, cached history, beta feedback, aliases, and analytics. They must not control funds or decide financial correctness.

## Track A Contract Units

| Unit | Responsibility |
|---|---|
| `Treasury.tolk` | owners, threshold, proposal registry, balance, authorization |
| Proposal logic | proposal status, approvals, expiry, nonce, action payload |
| `Splitter.tolk` | TON recipients, weights, deterministic distribution |
| Common helpers | errors, messages, ownership, fee reserve helpers |

## Track B Mapping Units

| TreasuryFlow Concept | Official Multisig v2 Mapping |
|---|---|
| Proposal | multisig order/action |
| Approval | multisig owner confirmation |
| Execute | multisig order execution |
| Split distribution | approved call to Splitter or batch actions |
| Status | official state plus indexer-derived view-state |
| Preview | UI parser over multisig payloads |

## Split Model

- Asset: TON only.
- Recipients: 2-20.
- Weights: positive integers.
- Denominator: `10_000` basis points.
- Total weight: exactly `10_000`.
- Dust: keep remainder in Treasury.
- Updates: approved proposal only.
- Distribution: approved proposal only.
