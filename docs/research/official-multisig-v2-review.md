# Official TON Multisig v2 Review

## Purpose

Determine whether official TON multisig v2 can serve as the production trust layer for TreasuryFlow TON.

## Sources To Review

- Official TON multisig v2 repository.
- Contract storage schema.
- Order/action lifecycle.
- Owner confirmation mechanics.
- Execution semantics.
- Getter availability.
- Existing tests and audit notes if available.

## Review Questions

| Question | Finding | Impact |
|---|---|---|
| How are owners stored? | Not reviewed yet | Blocks Track B mapping |
| How is threshold enforced? | Not reviewed yet | Blocks security comparison |
| How are orders created? | Not reviewed yet | Blocks proposal UX mapping |
| How are confirmations recorded? | Not reviewed yet | Blocks approval UI mapping |
| How is execution triggered? | Not reviewed yet | Blocks payout/split flow |
| Can arbitrary actions call Splitter? | Not reviewed yet | Blocks TON split design |
| Which getters are available? | Not reviewed yet | Blocks frontend/indexer design |
| How are expired orders handled? | Not reviewed yet | Blocks proposal state mapping |
| What replay protections exist? | Not reviewed yet | Blocks security comparison |
| What source verification path exists? | Not reviewed yet | Blocks release gate |

## Required Output

The review must end with one of these recommendations:

- Track B is viable for beta prototype.
- Track B is viable only with adapter constraints.
- Track B is not viable for the first beta.

## Notes

Replace each `Not reviewed yet` cell with a concrete finding during the review. Do not use this file as production evidence until every review row has a finding.
