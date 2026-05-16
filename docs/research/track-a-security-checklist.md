# Track A Treasury Security Checklist

## Scope

This checklist covers the custom Track A `Treasury.tolk` MVP on TON testnet. It is a security review readiness checklist, not an audit report.

Out of scope for this checklist: Splitter, Jettons, frontend, backend/indexer, Track B official multisig v2, anonymous approvals, ZK flows, and mainnet deployment.

## Review Status

| Area | Status | Evidence Or Follow-Up |
|---|---|---|
| Owner set | Bounded in Core v0.1, needs external review | Owners are immutable after deploy and owner count is limited to `2..10`; governance changes remain out of scope. |
| Threshold | Covered by config validation, needs external review | Threshold must be greater than `0` and no greater than owner count; post-deploy threshold changes remain out of scope. |
| Duplicate approvals | Covered by tests, needs external review | Unit tests cover duplicate approval rejection; review approval key derivation and map semantics. |
| Proposal lifecycle | Covered by tests, needs external review | Unit tests cover pending, executable, executed, canceled, and expired paths. |
| Expiry | Covered by tests, needs external review | Proposal creation enforces future expiry and a 30-day maximum; approve and execute reject expired proposals. |
| Cancel constraints | Covered by tests, needs external review | Confirm only intended owner/creator authority can cancel and that cancellation is terminal. |
| Execute once | Covered by tests, needs external review | Unit tests and testnet flow show proposal `0` reaches `Executed`; review terminal-state enforcement. |
| Reserve accounting | Covered by tests, needs external review | `feeReserve` uses pre-inbound balance for execute and includes exact-reserve and drain-prevention tests. |
| Storage reserve sizing | Policy recorded, needs measured max-state tests | See `docs/research/track-a-storage-reserve-policy.md`; regenerate estimates before mainnet. |
| Proposal history retention | Needs design before mainnet scale | Unbounded on-chain proposal/approval history is not acceptable for mainnet scale. |
| Replay and double execution | Covered by tests, needs external review | Confirm proposal IDs, status transitions, and approval keys prevent replay after terminal states. |
| External message value assumptions | Enforced in contract, needs external review | Create, approve, cancel, and execute enforce per-operation minimum inbound values. |
| Recipient validation | Covered by tests, needs external review | Payout recipient cannot be the Treasury contract address. |
| Action-phase evidence | Covered by tests, needs external review | Execute tests inspect action-phase success and payout transaction evidence. |
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
| Storage reserve policy | `feeReserve` is sized from measured max-state storage and target reserve lifetime. |
| History retention policy | Terminal proposal history is bounded on-chain or backed by a reproducible off-chain indexer. |
| Replay protection | Reusing old proposal/action data cannot mutate terminal proposal state. |
| Message value assumptions | Required inbound values are documented and enforced or intentionally delegated to operational scripts. |
| Getter completeness | Reviewers can inspect owner count, threshold, proposals, approvals, and reserve state. |
| Failure visibility | Expected rejection cases have deterministic tests or scripted evidence. |
| Source verification | Dry-run is recorded; final transaction is separately approved before any public claim that source verification is complete. |

## Known Evidence

- Deterministic contract tests: hardening suite covers config bounds, message values, expiry bounds, recipient validation, terminal states, reserve behavior, and action-phase payout evidence.
- Testnet deployment: `kQAEswTqc4bDarhACzMsgMhOXOgYcYHaXLLnwwOnMepqhSnA`.
- Testnet manual flow: create proposal, second-owner approve, execute payout.
- Proposal `0` final status: `Executed`.
- Recipient received `0.05 TON` on testnet.
- Gas/fee baseline recorded for proposal `1` create, approve, and execute: `docs/research/track-a-gas-fee-baseline.md`.
- Storage reserve policy and mainnet retention caveats: `docs/research/track-a-storage-reserve-policy.md`.
- Source verification dry-run: verifier backend accepted 2 source files and prepared the verification transaction body, which is not recorded in the repository.

## Mainnet Blockers

- Complete security review or external audit of custom multisig logic.
- Decide Track A versus Track B with comparable evidence.
- Send source verification transaction only after explicit approval.
- Review recorded Track A gas/fee baseline and add rejection-path fee evidence before mainnet.
- Measure max-state storage size and approve bounded history or cleanup/indexer strategy before mainnet.
- Define operational recovery playbook for stuck proposals, expired proposals, and wallet/key loss.
- Approve mainnet release checklist.
