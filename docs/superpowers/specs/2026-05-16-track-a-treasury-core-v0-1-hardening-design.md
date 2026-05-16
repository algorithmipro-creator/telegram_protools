# Track A Treasury Core v0.1 Hardening Design

## Purpose

Harden the current Track A Treasury Core before any governance, Splitter, Telegram Mini App, backend, Jetton, or arbitrary payload work.

Treasury Core v0.1 remains a narrow TON payout treasury:

- Owners and threshold are immutable after deploy.
- The only proposal action is a TON payout.
- Plain empty-body deposits remain allowed.
- Owners create, approve, cancel, and execute payout proposals.
- The contract enforces safety limits without trusting UI, scripts, backend, or Telegram.

This design does not claim mainnet readiness.

## Current Context

The repository already contains a custom Tolk `Treasury` contract with:

- owner map and owner count,
- threshold,
- proposal sequence,
- fee reserve,
- proposal map,
- approval map,
- payout proposal creation,
- creator auto-approval,
- approval,
- cancellation,
- execution,
- expiry,
- dynamic proposal view status,
- Tolk and TypeScript wrappers,
- Acton tests and testnet scripts.

The next work should close hardening gaps in the existing core rather than expand the product surface.

## Explicit Non-Goals

Do not implement these in this task:

- governance or config proposals,
- `configVersion`,
- stale proposal semantics,
- owner addition or removal,
- threshold changes after deploy,
- fee reserve changes after deploy,
- Splitter,
- Jettons,
- Telegram Mini App,
- backend or indexer,
- arbitrary payload proposal execution,
- mainnet release claims.

## Contract Constants

Add these constants to the contract type layer:

```tolk
const MIN_OWNER_COUNT: uint8 = 2
const MAX_OWNER_COUNT: uint8 = 10
const MAX_EXPIRY_SECONDS: uint32 = 2592000

const MIN_CREATE_VALUE: coins = ton("0.05")
const MIN_APPROVE_VALUE: coins = ton("0.05")
const MIN_CANCEL_VALUE: coins = ton("0.05")
const MIN_EXECUTE_VALUE: coins = ton("0.05")
```

`MAX_EXPIRY_SECONDS` is 30 days. The `0.05 TON` message value constants are conservative testnet/MVP values. They should be revisited after gas snapshots and live fee evidence mature.

## Error Model

Add one new error:

```tolk
InsufficientMessageValue = 144
```

Keep `InvalidRecipient = 133` and make it active by enforcing a recipient policy.

## Storage Config Validation

Update `Storage.assertValidConfig` to enforce:

- `ownerCount >= MIN_OWNER_COUNT`,
- `ownerCount <= MAX_OWNER_COUNT`,
- `ownerMapCount() == ownerCount`,
- `threshold > 0`,
- `threshold <= ownerCount`.

The current product target is 2-10 owners, so single-owner treasuries are not part of Core v0.1.

## Message Value Policy

State-changing messages must attach at least the configured minimum value:

- `CreatePayoutProposal`: `MIN_CREATE_VALUE`,
- `ApproveProposal`: `MIN_APPROVE_VALUE`,
- `CancelProposal`: `MIN_CANCEL_VALUE`,
- `ExecuteProposal`: `MIN_EXECUTE_VALUE`.

Plain empty-body deposits remain accepted from any sender and do not require owner authorization or a minimum message value.

Unknown non-empty message bodies must continue to fail with `Errors.InvalidMessage`.

## Expiry Policy

Proposal creation must enforce both lower and upper expiry bounds:

- `expiresAt > blockchain.now()`,
- `expiresAt <= blockchain.now() + MAX_EXPIRY_SECONDS`.

The exact upper bound is valid. Proposals beyond the upper bound are rejected with `Errors.InvalidExpiry`.

## Recipient Policy

Payout recipient validation should be explicit in Core v0.1.

Use `Errors.InvalidRecipient` when the payout recipient is the Treasury contract itself:

```tolk
assert (msg.recipient != contract.getAddress()) throw Errors.InvalidRecipient;
```

This prevents self-payout proposals that add storage/history noise without moving funds to an external recipient. Other recipient restrictions are deferred until the product has a stronger address policy.

## Reserve Policy

Execution must continue to check reserve using pre-inbound balance:

```tolk
val availableBalance = contract.getOriginalBalance() - in.valueCoins;
assert (availableBalance >= proposal.amount + storage.feeReserve) throw Errors.InsufficientBalance;
```

The execute inbound value must not help a proposal pass the reserve check.

Exact-reserve execution remains valid only when the pre-inbound balance is sufficient.

## Action-Phase Safety Requirement

The implementation plan must include an Acton trace/action-phase test for payout execution.

The test must determine whether a proposal can become `Executed` while the outbound payout action fails or does not deliver the expected transfer.

If the trace confirms that this unsafe state is possible, the hardening implementation must change execution behavior so the proposal cannot remain `Executed` without the payout being reliably emitted according to TON/Acton semantics.

This requirement is intentionally evidence-driven because action-phase behavior should be verified in the toolchain rather than assumed.

## Terminal State Protections

The contract must keep these protections:

- executed proposals cannot be approved,
- executed proposals cannot be cancelled,
- executed proposals cannot be executed again,
- cancelled proposals cannot be approved,
- cancelled proposals cannot be executed,
- expired pending proposals cannot be approved or executed,
- expired view status must not require storage mutation.

## Wrapper Policy

Generated wrappers must not be edited manually.

Any ABI or getter change must regenerate wrappers through Acton tooling and commit generated output with the contract changes.

## Documentation Updates

Update security/readiness documentation to record:

- bounded owner count,
- message value policy,
- expiry upper bound,
- recipient self-payout rejection,
- action-phase safety evidence,
- no mainnet readiness claim.

Do not change product docs to imply governance, Splitter, Telegram, or mainnet support.

## Test Requirements

Add deterministic Acton tests for:

- `ownerCount < MIN_OWNER_COUNT` is rejected,
- `ownerCount > MAX_OWNER_COUNT` is rejected,
- `threshold = 0` is rejected,
- `threshold > ownerCount` is rejected,
- duplicate or collapsed owner maps are rejected,
- create rejects value below `MIN_CREATE_VALUE`,
- approve rejects value below `MIN_APPROVE_VALUE`,
- cancel rejects value below `MIN_CANCEL_VALUE`,
- execute rejects value below `MIN_EXECUTE_VALUE`,
- empty-body deposit from non-owner still succeeds,
- unknown non-empty body is rejected,
- create rejects `expiresAt <= now`,
- create rejects `expiresAt > now + MAX_EXPIRY_SECONDS`,
- create accepts `expiresAt == now + MAX_EXPIRY_SECONDS`,
- create rejects Treasury self-recipient,
- execute cannot use inbound value to satisfy `feeReserve`,
- exact reserve execution remains correct,
- executed proposals cannot be approved,
- cancelled proposals cannot be approved,
- cancelled proposals cannot be executed,
- action-phase payout safety is verified by trace or equivalent Acton evidence.

## Verification Commands

The implementation plan should run, where supported by the local toolchain:

```powershell
acton fmt
acton build
acton test
acton check
acton test --coverage
acton test --snapshot gas-baseline.json
git diff --check
```

It should also scan changed source and docs for hidden bidirectional, zero-width, and unexpected control characters.

If local Windows PATH does not expose `acton`, use the existing project WSL or validation-host pattern already documented in repository plans.

## Acceptance Criteria

Treasury Core v0.1 hardening is accepted when:

- the contract enforces bounded owner count,
- all state-changing messages enforce minimum inbound value,
- proposal expiry has a maximum bound,
- self-recipient payout proposals are rejected,
- empty-body deposits still work,
- reserve checks remain pre-inbound,
- terminal state protections are covered,
- action-phase payout safety is tested and documented,
- wrappers are regenerated only by Acton,
- security docs reflect the hardened core,
- all required checks pass or any toolchain blocker is documented,
- no mainnet readiness is claimed.
