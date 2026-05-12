# ADR 0001: Dual Testnet Track

## Status

Accepted for beta.

## Context

TreasuryFlow TON needs a secure N-of-M treasury architecture. A custom Tolk implementation gives product flexibility, while official TON multisig v2 may provide stronger production security posture.

Choosing one architecture before testnet validation would hide important UX, security, gas, and development trade-offs.

## Decision

Build and test two comparable testnet tracks:

- Track A: custom Tolk Treasury, Proposal logic, and Splitter contracts.
- Track B: official TON multisig v2 based TreasuryFlow with adapter and Splitter integration.

Use the same beta scenario and score both tracks with a balanced score matrix.

## Consequences

- More Phase 1 work is required because two tracks must be evaluated.
- Production architecture will be selected using evidence rather than preference.
- Mainnet remains blocked until a later production ADR is accepted.
