# TreasuryFlow TON Dual Testnet Specification

## 1. Executive Summary

TreasuryFlow TON is a Telegram-native treasury product for small teams, creators, DAOs, NFT/drop teams, agencies, and Telegram Mini App builders that need shared control over TON funds and predictable payouts.

The first specification uses a dual testnet strategy instead of choosing the final multisig architecture upfront. Two architecture tracks will be prototyped and tested on TON testnet with the same product flow, the same user-facing UX goals, and the same acceptance criteria.

- Track A: custom Tolk Treasury, Proposal, and Splitter contracts.
- Track B: TreasuryFlow built around official TON multisig v2 as the trust layer, with TreasuryFlow adapter and Splitter integration.

The production architecture will be selected after testnet validation using a balanced score matrix covering security, UX clarity, development complexity, gas and fees, Acton workflow compatibility, and extensibility.

Mainnet deployment is explicitly out of scope until the architecture decision is made, testnet evidence is reviewed, source verification is proven, and an external security review or audit is completed.

## 2. Product Goals

TreasuryFlow TON should let a team safely hold TON together and approve payouts through a simple Telegram-native interface.

Primary goals:

- Remove single-person custody risk for team funds.
- Make payout approvals understandable to non-DeFi users.
- Support N-of-M approval for financial actions.
- Support TON payouts and TON revenue splits in the first testnet beta.
- Keep critical financial rules onchain.
- Keep UX metadata, notifications, and analytics offchain.
- Use Acton and Tolk as the primary smart contract development workflow.

Non-goal for this stage: becoming a DAO super app, lending product, DEX, token factory, or custodial wallet service.

## 3. MVP / Beta Scope

The first beta is testnet-only and includes TON payouts plus TON split distribution.

| Area | In Scope |
|---|---|
| Network | TON testnet only |
| Asset | TON only |
| Wallet | TON Connect |
| Interface | Telegram Mini App style frontend |
| Core treasury flow | create treasury, deposit TON, create payout proposal, approve, execute |
| Split flow | configure recipients/weights, create split distribution proposal, approve, execute |
| Architecture | Track A and Track B prototypes |
| Toolchain | Acton, Tolk, generated TypeScript wrappers |
| Feedback | open beta invite plus known team outreach |

## 4. Non-Goals

The first beta must not include:

- Mainnet deployment.
- Jetton payouts.
- Protocol fees.
- Lending, DEX, yield, prediction markets, or other DeFi modules.
- DAO governance beyond N-of-M treasury approvals.
- Custodial accounts or server-controlled funds.
- Fiat on/off-ramp.
- Cross-chain support.
- Complex analytics or enterprise reporting.

These exclusions keep the beta focused on validating the core product loop and comparing the two architecture tracks.

## 5. Target Users and Beta Validation

The beta audience is intentionally broad but must be segmented during feedback analysis.

Target beta sources:

- Public open invitation for testnet users.
- Direct outreach to known Telegram teams and friendly projects.
- Telegram Mini App developer teams.
- Creator/channel teams.
- DAO/community groups.
- NFT/drop teams.
- Agencies and microbusinesses using TON payments.

Feedback must be tagged by user segment because developers, creators, DAOs, and NFT teams have different expectations and technical comfort levels.

The shared beta scenario is:

```text
1. Open the Mini App.
2. Connect wallet through TON Connect.
3. Create a treasury with 2-10 owners.
4. Deposit testnet TON.
5. Create a payout proposal.
6. Other owners approve the proposal.
7. Execute the payout after threshold.
8. Configure split recipients and weights.
9. Create a split distribution proposal.
10. Approve and execute the split distribution.
11. Submit feedback on clarity, trust, speed, and errors.
```

## 6. Dual Architecture Strategy

The first beta compares two architecture tracks.

| Track | Purpose | Main Benefit | Main Risk |
|---|---|---|---|
| Track A: Custom Tolk Treasury | Validate product-specific treasury, proposal, and split model | Maximum flexibility and Acton-native control | Custom multisig logic is security-critical |
| Track B: Official multisig v2 based | Validate official multisig as production trust layer | Better production security posture and ecosystem alignment | May constrain UX and product-specific proposal model |

The product must not assume either track is the final production architecture before beta evidence is collected.

Both tracks should expose the same user-facing operations where possible:

- Create treasury.
- Deposit TON.
- Create payout proposal.
- Approve proposal.
- Execute payout.
- Configure split rules.
- Create split distribution proposal.
- Approve split proposal.
- Execute split distribution.

If Track B cannot support a TreasuryFlow operation cleanly through official multisig v2, that is a comparison finding, not an automatic failure.

## 7. System Architecture

```text
Telegram Mini App
        |
        v
TON Connect + TreasuryFlow UI
        |
        v
Generated TypeScript Wrappers
        |
        +----------------------------+
        |                            |
        v                            v
Track A                         Track B
Custom Tolk Treasury            Official Multisig v2 Layer
+ Custom Proposal/Splitter       + TreasuryFlow Adapter/Splitter
        |                            |
        +-------------+--------------+
                      |
                      v
              TON testnet
                      |
                      v
        Backend / Indexer / Notifications
```

Onchain responsibilities:

- Owners.
- Threshold.
- Proposal validity.
- Approvals.
- Execution status.
- Split weights.
- TON payout and split execution.

Offchain responsibilities:

- Treasury names.
- Proposal comments and titles.
- Telegram chat bindings.
- Notifications.
- Readable cached activity history.
- Beta feedback and analytics.
- User aliases and UI preferences.

Frontend and backend must never be trusted for financial correctness.

## 8. Track A: Custom Tolk Treasury

Track A implements product-specific contracts in Tolk.

Core components:

| Component | Responsibility |
|---|---|
| `Treasury.tolk` | owners, threshold, proposal registry, TON balance, authorization |
| Proposal logic | status, approvals, expiry, nonce, action payload |
| `Splitter.tolk` | TON split recipients, weights, deterministic distribution |
| Common libraries | errors, messages, ownership helpers, fee logic |
| Acton tests | multisig invariants, split math, fees, bounce scenarios |

Track A storage requirements:

| Storage | Purpose |
|---|---|
| `owners` | List or map of owner addresses |
| `threshold` | Current approval threshold |
| `proposal_seqno` or nonce | Unique proposal IDs and replay protection |
| `proposals` | Proposal registry keyed by proposal ID |
| `approvals` | Approval bitmap/map per proposal |
| `split_rules` | Recipients, weights, and version |
| `fee_reserve` | Minimum TON reserve for fees |
| `config_version` | Owners/threshold/split config version |

Recommended Track A beta simplifications:

- Store proposals inside Treasury for MVP simplicity.
- Limit beta UI to payout and split actions.
- Keep owner and threshold updates out of beta UI unless a full config-version policy is implemented.
- Only owners can execute approved proposals during beta.
- Keep split dust in Treasury.

## 9. Track B: Official Multisig v2 Based TreasuryFlow

Track B uses official TON multisig v2 as the core authorization and execution layer.

Core components:

| Component | Responsibility |
|---|---|
| Official multisig v2 | N-of-M authorization and execution |
| TreasuryFlow adapter | Map product actions into multisig-compatible orders/actions |
| Splitter integration | Execute TON split distribution through approved multisig action |
| UI action parser | Explain multisig payloads in TreasuryFlow language |
| Indexer/status derivation | Build product view-state from official multisig state and events |

Mapping requirements:

| TreasuryFlow Concept | Official Multisig v2 Mapping |
|---|---|
| Proposal | Multisig order/action |
| Approval | Multisig owner confirmation |
| Execute | Multisig order execution |
| Split distribution | Multisig-approved call to Splitter or batch actions |
| Human-readable preview | UI parser over multisig payload/actions |
| Status | Derived from multisig order state plus indexer data |

If official multisig v2 lacks a direct getter or status needed by the UI, backend/indexer may compute read-only view-state. Financial correctness must remain onchain.

## 10. Shared Smart Contract Requirements

Core entities:

| Entity | Meaning |
|---|---|
| Treasury | Team treasury that holds TON and governance rules |
| Owner | Address allowed to create or approve proposals |
| Threshold | Minimum approvals required for execution |
| Proposal / Order | Financial or configuration action awaiting approvals |
| Approval | Owner confirmation for a specific proposal |
| Split Rule | Recipients and weights for TON distribution |
| Execution | Final onchain action after threshold is reached |

Proposal types for first beta:

| Type | Included | Notes |
|---|---|---|
| TON payout | Yes | Send TON to one recipient |
| Update split rules | Yes | Change recipients and weights |
| Distribute TON split | Yes | Distribute TON using current split rules |
| Add/remove owner | Spec-only or disabled | Not required in beta UI |
| Change threshold | Spec-only or disabled | Not required in beta UI |
| Jetton payout | No | MVP+ only |

Core invariants:

| Invariant | Requirement |
|---|---|
| Owner-only proposal creation | Non-owner cannot create financial proposals |
| Owner-only approval | Non-owner cannot approve |
| No double approval | One owner cannot increase approval count twice |
| Threshold required | Execution before threshold is rejected |
| Expiry enforced | Expired proposals cannot execute |
| No double execution | Executed proposal cannot execute again |
| Deterministic split math | UI preview and onchain result match |
| Fee reserve | Treasury does not drain below configured reserve |
| Payload transparency | Payload is decoded or marked unknown with warning |
| Replay protection | Proposal/action cannot be reused after terminal status |

## 11. Proposal and Split State Machines

Proposal state machine:

```text
created
  |
  v
pending
  |
  +-- approve until threshold --> executable
  |
  +-- expires_at passed -------> expired
  |
  +-- allowed cancel ----------> cancelled
  |
  v
executable
  |
  +-- execute success ---------> executed
  |
  +-- expires_at passed -------> expired
  |
  +-- execute failure/bounce --> execution_failed or pending_retry
```

Required proposal statuses:

| Status | Meaning |
|---|---|
| `pending` | Proposal exists and approvals are below threshold |
| `executable` | Threshold reached, execution not completed |
| `executed` | Execution completed or marked as sent according to track semantics |
| `expired` | Expiry passed and execution is forbidden |
| `cancelled` | Proposal cancelled by an allowed path |
| `execution_failed` | Optional explicit failure state if track can detect it |

Split rules for first beta:

| Rule | Decision |
|---|---|
| Asset | TON only |
| Recipients | 2-20 recipients |
| Weights | Positive integers |
| Weight total | Basis points with denominator `10_000` |
| Dust | Keep deterministic remainder in Treasury |
| Rule updates | Only through approved proposal |
| Distribution | Only through approved proposal |
| Failed transfer | Must be visible in activity; retry model may differ by track |

Initial split model: use basis points with denominator `10_000`, reject zero weights, require total weight to equal `10_000`, and keep dust in Treasury.

## 12. Frontend / Telegram Mini App UX

The UX goal is explainability. Users must understand what they approve before signing.

Core screens:

| Screen | Purpose |
|---|---|
| Landing / Connect | Explain product and connect wallet |
| Create Treasury | Owners, threshold, name, beta context |
| Dashboard | Balance, owners, threshold, pending proposals, split status |
| Create Payout | Recipient, amount, comment, expiry, preview |
| Proposal Detail | Status, approvals, action preview, raw details, approve/execute |
| Splits Setup | Recipients, weights, preview distribution |
| Split Distribution | Amount, recipient preview, approval/execute flow |
| Activity Log | Deposits, proposals, approvals, executions, failed/bounced events |
| Beta Feedback | Short feedback form after scenario completion |

Every financial action must show two layers:

| Layer | Content |
|---|---|
| Human-readable | Example: `Send 25 TON to <address> after 2 of 3 approvals` |
| Technical details | Contract address, amount in nanotons, proposal ID, expiry, payload hash, raw body |

Unknown payload rule:

```text
Warning: this action cannot be fully decoded.
Do not approve unless you trust the source.
Show raw payload and technical details.
```

Architecture track exposure:

- Default beta UX should hide track labels to reduce bias.
- Advanced technical testers may opt into visible track mode.
- Internally, every feedback record must include track ID.

## 13. Backend / Indexer / Notifications

The backend is non-custodial and must not control funds.

Responsibilities:

- Index treasury activity.
- Cache proposal metadata for fast UI.
- Store offchain names, comments, and Telegram bindings.
- Send Telegram notifications.
- Collect beta feedback.
- Monitor failed or bounced activity where possible.

Minimal notification events:

| Event | Recipient |
|---|---|
| New proposal created | Owners except creator |
| Proposal reached threshold | Owners |
| Proposal executed | Owners |
| Split rules updated | Owners |
| Execution failed/bounced | Creator and owners |

Telegram group binding and automatic reminders are MVP+ unless they are needed for beta operations.

## 14. Feedback Collection and Metrics

Feedback must measure task completion, trust, and architecture comparison.

Metrics:

| Metric | Signal |
|---|---|
| Task completion | Treasury, payout, and split flow completion |
| Time-to-complete | Time spent per flow |
| Confusion points | Where users stop or ask for help |
| Trust clarity | Whether users understand what they sign |
| Fee clarity | Whether users understand fees and reserves |
| Approval clarity | Whether users understand threshold and remaining approvals |
| Split clarity | Whether preview matches user expectation |
| Error clarity | Whether failures are understandable |
| Architecture findings | Track-specific friction and failures |

Feedback form:

| Question | Type |
|---|---|
| Which segment are you? dev team / creator / DAO / NFT / agency / other | Select |
| Did you create a treasury? | Yes/No |
| Did you complete a payout? | Yes/No |
| Did you complete a split distribution? | Yes/No |
| What was unclear? | Text |
| How well did you understand what you signed? | 1-5 |
| How much did you trust the process? | 1-5 |
| What must change before mainnet? | Text |
| Would you use this for a real team? | Yes/Maybe/No |

## 15. Acton Development Workflow

Acton is the default workflow for contract build, tests, wrappers, deployment scripts, and verification.

Reference workflow:

```text
acton new treasury-flow-ton --template counter --app
        |
replace counter with TreasuryFlow contracts
        |
acton build
        |
acton test
        |
acton wrapper --all --ts
        |
frontend integrates generated wrappers
        |
acton script scripts/deploy_*.tolk --net testnet
        |
acton verify ... --dry-run
        |
testnet beta
```

Recommended repository layout:

```text
treasury-flow-ton/
  Acton.toml
  docs/
    product-spec.md
    technical-spec.md
    security-model.md
    beta-test-plan.md
    architecture-decision-records.md
  contracts/
    src/
      Treasury.tolk
      Splitter.tolk
      adapters/
      common/
    tests/
      treasury.test.tolk
      splitter.test.tolk
      integration.test.tolk
      fuzz/
      gas/
  wrappers-ts/
  scripts/
    deploy_custom_testnet.tolk
    deploy_multisig_testnet.tolk
    setup_splitter.tolk
  app/
  backend/
```

Generated files policy:

- Do not commit `.acton/`, `build/`, or `gen/`.
- Commit generated Tolk wrappers and TypeScript wrappers if they are part of the frontend integration contract.
- Regenerate wrappers after ABI changes.

## 16. Testing Strategy

Required test matrix:

| Area | Required Tests |
|---|---|
| Treasury creation | owners count, duplicate owners, threshold bounds |
| Proposal creation | owner-only, valid recipient, valid amount, expiry |
| Approval | owner-only, no duplicate approvals, threshold reached |
| Execution | reject before threshold, execute after threshold, reject second execution |
| Expiry | reject approve and execute after expiry |
| Splits | valid weights, invalid weights, deterministic dust, insufficient balance |
| Security | replay, unauthorized sender, malicious or unknown payload |
| Bounce/failure | failed transfer visibility where technically possible |
| Track comparison | same scenario tested against Track A and Track B |

Acton fuzz properties:

| Property | Inputs |
|---|---|
| Threshold validity | random owners count, random threshold |
| Approval idempotency | random owner sequence with duplicates |
| Execution gate | random approval order |
| Split math | random recipients, weights, amount |
| Dust bound | random amount and weights |
| Expiry behavior | random expiry windows |

Recommended fuzz defaults:

```toml
[test.fuzz]
runs = 512
max-test-rejects = 4096
seed = 42
```

## 17. Gas and Fee Profiling

Gas and fees are part of the architecture comparison.

Snapshot scenarios:

| Scenario | Purpose |
|---|---|
| Create payout proposal | UX fee estimate and architecture comparison |
| Approve proposal | Frequent action cost |
| Execute payout | Financial action cost |
| Update split rules | Configuration action cost |
| Execute split distribution | Most gas-sensitive beta flow |

Commands:

```bash
acton test --snapshot gas-baseline.json
acton test --baseline-snapshot gas-baseline.json
```

After baseline stabilizes, CI may use:

```bash
acton test --baseline-snapshot gas-baseline.json --fail-on-diff
```

Gas snapshots must use deterministic test data and stable trace ordering.

## 18. Verification and Deployment Strategy

Deployment is performed through Tolk scripts, not a dedicated deploy command.

Testnet deployment requirements:

- `acton build` passes.
- `acton test` passes.
- TypeScript wrappers are generated for frontend integration.
- Deployment scripts succeed locally first.
- Testnet deployment succeeds through `acton script ... --net testnet`.
- `acton verify ... --dry-run` succeeds before public beta where applicable.
- Public beta docs show users which contracts they interact with.

Mainnet is forbidden until:

- Architecture decision is completed.
- Threat model is reviewed.
- Critical tests and fuzz tests pass.
- Gas and fee implications are understood.
- Source verification workflow is confirmed.
- External review or audit is completed.
- A mainnet release checklist is approved.

## 19. Security Model and Invariants

Assets to protect:

- Treasury TON balance.
- Owner list.
- Threshold.
- Pending proposals.
- Split rules.
- Deployment and admin keys.
- Telegram bot token.
- Offchain metadata integrity.

Threats and mitigations:

| Threat | Mitigation |
|---|---|
| Single owner drain | N-of-M threshold |
| Replay | Nonce, proposal status, terminal states |
| Double approval | Approval map/bitmap per proposal |
| Expired execution | Expiry check before approval/execution |
| Unknown payload | Human-readable parser plus raw warning |
| Owner spoofing | Sender validation onchain |
| Threshold attack | Threshold updates disabled in beta UI or require approved proposal |
| Jetton spoofing | Jettons out of first beta |
| Bounce/failure confusion | Activity visibility and explicit failure state where possible |
| Frontend compromise | Onchain checks, generated wrappers, raw payload preview, source verification |

Security requirements:

- Contract logic must not trust frontend/backend.
- Every payout and split execution is a financial security event.
- Unknown payloads must not be displayed as safe.
- Users must see human-readable and technical action details.
- Mainnet launch requires external security review.

## 20. Architecture Decision Matrix

The production architecture will be selected with a balanced score.

| Criterion | Weight | Evidence |
|---|---:|---|
| Security / auditability | 30% | invariant coverage, code complexity, reviewed base, audit readiness |
| User UX clarity | 20% | completion rate, confusion points, trust scores |
| Development complexity | 15% | implementation effort, wrapper friction, debugging cost |
| Gas/fees | 15% | Acton gas snapshots and fee observations |
| Acton workflow compatibility | 10% | build/test/wrapper/deploy/verify smoothness |
| Extensibility for splits/Jettons | 10% | current split fit, future Jetton path, adapter complexity |

Decision outcomes:

- Keep Track A as production base only if security review supports it.
- Choose Track B if official multisig provides stronger safety without unacceptable UX/product constraints.
- Choose hybrid if official multisig handles authorization while custom contracts handle product-specific split and metadata flows.

## 21. Beta Release Gates

| Gate | Required Before |
|---|---|
| Gate 1: Internal testnet | Contracts build/test, basic UI completes one payout |
| Gate 2: Known teams beta | Payout and splits work, feedback form active, no critical security gaps |
| Gate 3: Open beta | Source verification dry-run, public test instructions, known failure handling |
| Gate 4: Architecture decision | Balanced score completed for Track A vs Track B |
| Gate 5: Mainnet candidate | Audit/review, threat model, migration/deprecation plan |

## 22. Roadmap

Phase 0: Research and specification

- Finalize this dual-track spec.
- Review official multisig v2 mechanics.
- Define Track A and Track B implementation plans.
- Prepare threat model.

Phase 1: Contract prototypes

- Implement Track A custom Tolk prototype.
- Implement Track B adapter/prototype.
- Implement TON Splitter path.
- Generate wrappers.
- Write required Acton tests.

Phase 2: Frontend beta

- Build Telegram Mini App style frontend.
- Integrate TON Connect.
- Integrate generated wrappers.
- Build treasury, payout, proposal, split, and feedback screens.

Phase 3: Backend/indexer beta

- Index activity.
- Store metadata.
- Send basic notifications.
- Collect segmented feedback.

Phase 4: Open testnet beta

- Invite known teams.
- Publish open beta instructions.
- Collect and analyze score matrix evidence.

Phase 5: Production architecture decision

- Compare Track A and Track B.
- Write architecture decision record.
- Decide production base or hybrid model.

Phase 6: Production hardening

- Expand tests.
- Run security review/audit.
- Confirm verification.
- Prepare mainnet release checklist.

Jettons, protocol fees, advanced analytics, group binding, and automation remain MVP+.

## 23. Open Questions

Open decisions:

| Decision | Why It Remains Open |
|---|---|
| Final production base | Must follow Track A vs Track B beta evidence |
| Official multisig v2 mapping | Requires separate technical review |
| Exact Track A storage layout | Should be finalized during implementation planning |
| Owner/threshold updates in beta UI | Risky; likely disabled initially |
| Bounce/failure retry model | Needs test evidence on TON behavior |
| Bot notifications in first public beta | Useful but not required for financial correctness |
| Backend database choice | Depends on deployment constraints |
| Jetton support design | Needs separate spoofing and wallet-address spec |
| Revenue model | Should wait for product-market fit evidence |

## 24. Acceptance Criteria

Spec acceptance criteria:

- The spec explains why two architecture tracks exist.
- The beta scope is clear enough to plan implementation.
- Both tracks have comparable product operations.
- Smart contract invariants are testable.
- UX requires human-readable and technical transaction previews.
- Acton workflow is explicit.
- Test, fuzz, gas, deploy, and verify requirements are stated.
- Mainnet is blocked until review/audit.

Beta product acceptance criteria:

- User can create a testnet treasury with 2-10 owners.
- Threshold is at least 1 and no greater than owner count.
- Duplicate owners are rejected.
- Owner can create a TON payout proposal.
- Non-owner cannot create or approve financial proposals.
- Duplicate approval does not increase approval count.
- Proposal becomes executable after threshold.
- Proposal cannot execute before threshold, after expiry, or twice.
- Split recipients and weights are validated.
- Split preview matches deterministic onchain math.
- Dust remains in Treasury.
- Activity log shows deposits, proposals, approvals, executions, and known failures.
- Feedback records include user segment and architecture track.
