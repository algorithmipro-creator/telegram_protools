# TreasuryFlow Architecture Scorecard

## Purpose

Compare Track A custom Tolk and Track B official multisig v2 based architecture after testnet validation.

## Weighted Score

| Criterion | Weight | Track A Score 1-5 | Track B Score 1-5 | Evidence Required |
|---|---:|---:|---:|---|
| Security / auditability | 30 | 0 | 0 | invariant coverage, code complexity, reviewed base, audit readiness |
| User UX clarity | 20 | 0 | 0 | completion rate, confusion points, trust score |
| Development complexity | 15 | 0 | 0 | implementation effort, wrapper friction, debugging effort |
| Gas/fees | 15 | 0 | 0 | Acton gas snapshots and fee observations |
| Acton workflow compatibility | 10 | 0 | 0 | build/test/wrapper/deploy/verify smoothness |
| Extensibility for splits/Jettons | 10 | 0 | 0 | split fit, Jetton path, adapter complexity |

## Score Rules

- 1 means poor fit or high risk.
- 3 means acceptable with known trade-offs.
- 5 means strong fit with clear evidence.
- Do not assign a nonzero score without written evidence.

## Decision Outcomes

- Choose Track A only if security review supports custom multisig logic.
- Choose Track B if official multisig gives stronger safety without unacceptable UX constraints.
- Choose hybrid if official multisig handles authorization while custom contracts handle product-specific split and metadata flows.
