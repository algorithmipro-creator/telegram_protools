# Track A Treasury Security Checklist

## Scope

This checklist covers the custom Track A `Treasury.tolk` MVP on TON testnet. It is a security review readiness checklist, not an audit report.

Out of scope for this checklist: Splitter, Jettons, frontend, backend/indexer, Track B official multisig v2, anonymous approvals, ZK flows, and mainnet deployment.

## Review Status

| Area | Status | Evidence Or Follow-Up |
|---|---|---|
| Owner set | Needs review | Confirm owners are immutable or changes require a reviewed proposal flow before beta expansion. |
| Threshold | Needs review | Confirm threshold is initialized safely and cannot be lowered without explicit reviewed governance. |
| Duplicate approvals | Covered by tests, needs external review | Unit tests cover duplicate approval rejection; review approval key derivation and map semantics. |
| Proposal lifecycle | Covered by tests, needs external review | Unit tests cover pending, executable, executed, canceled, and expired paths. |
| Expiry | Covered by tests, needs external review | Confirm expiry checks are applied consistently to approve and execute paths. |
| Cancel constraints | Covered by tests, needs external review | Confirm only intended owner/creator authority can cancel and that cancellation is terminal. |
| Execute once | Covered by tests, needs external review | Unit tests and testnet flow show proposal `0` reaches `Executed`; review terminal-state enforcement. |
| Reserve accounting | Covered by tests, needs external review | Confirm `feeReserve` prevents draining below reserve across edge-case amounts and message values. |
| Replay and double execution | Covered by tests, needs external review | Confirm proposal IDs, status transitions, and approval keys prevent replay after terminal states. |
| External message value assumptions | Needs review | Confirm minimum inbound value assumptions for create, approve, cancel, and execute messages. |
| Getter and storage visibility | Needs review | Confirm public getters expose enough review data without leaking sensitive operational data. |
| Source verification | Dry-run complete | See `docs/research/track-a-source-verification.md`; final verifier transaction not sent. |
| Operational blockers | Active | Mainnet remains blocked pending review/audit and release checklist. |

## Required Checks Before Beta Expansion

| Check | Required Outcome |
|---|---|
| Owner validation | Every externally callable state-changing path verifies the sender is an owner when required. |
| Threshold validation | The contract cannot enter an impossible state such as threshold `0` or threshold greater than owner count. |
| Duplicate approval prevention | One owner can contribute at most one approval per proposal. |
| Proposal ID uniqueness | Proposal IDs are monotonic and cannot overwrite existing proposals. |
| Lifecycle terminal states | Executed, canceled, and expired proposals cannot be approved or executed later. |
| Expiry semantics | Expired proposals are consistently rejected at approval and execution time. |
| Cancellation semantics | Cancellation cannot bypass threshold execution rules or revive a proposal. |
| Execution atomicity | A payout cannot be marked executed unless the execution path is intended to be final. |
| Reserve invariant | Execution cannot reduce balance below `feeReserve` except for expected gas effects. |
| Replay protection | Reusing old proposal/action data cannot mutate terminal proposal state. |
| Message value assumptions | Required inbound values are documented and enforced or intentionally delegated to operational scripts. |
| Getter completeness | Reviewers can inspect owner count, threshold, proposals, approvals, and reserve state. |
| Failure visibility | Expected rejection cases have deterministic tests or scripted evidence. |
| Source verification | Dry-run is recorded; final transaction is separately approved before any public claim that source verification is complete. |

## Known Evidence

- Deterministic contract tests: `20 passed in 1 file`.
- Testnet deployment: `kQAEswTqc4bDarhACzMsgMhOXOgYcYHaXLLnwwOnMepqhSnA`.
- Testnet manual flow: create proposal, second-owner approve, execute payout.
- Proposal `0` final status: `Executed`.
- Recipient received `0.05 TON` on testnet.
- Source verification dry-run: verifier backend accepted 2 source files and prepared the verification transaction body, which is not recorded in the repository.

## Mainnet Blockers

- Complete security review or external audit of custom multisig logic.
- Decide Track A versus Track B with comparable evidence.
- Send source verification transaction only after explicit approval.
- Record gas and fee baseline for normal and rejection paths.
- Define operational recovery playbook for stuck proposals, expired proposals, and wallet/key loss.
- Approve mainnet release checklist.
