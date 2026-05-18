import "types"

contract Treasury {
    author: "TreasuryFlow TON"
    version: "0.1.0"
    description: "Track A Treasury-first TON payout approval prototype"
    storage: Storage
    incomingMessages: TreasuryMessage
}

fun requireMinValue(value: coins, minValue: coins) {
    assert (value >= minValue) throw Errors.InsufficientMessageValue;
}

fun onInternalMessage(in: InMessage) {
    val msg = lazy TreasuryMessage.fromSlice(in.body);

    match (msg) {
        CreatePayoutProposal => {
            var storage = lazy Storage.load();
            storage.assertValidConfig();
            requireMinValue(in.valueCoins, MIN_CREATE_VALUE);
            storage.assertOwner(in.senderAddress);
            val now = blockchain.now();
            assert (msg.recipient != contract.getAddress()) throw Errors.InvalidRecipient;
            assert (msg.amount > 0) throw Errors.InvalidAmount;
            assert (msg.expiresAt > now) throw Errors.InvalidExpiry;
            assert (msg.expiresAt <= now + MAX_EXPIRY_SECONDS) throw Errors.InvalidExpiry;

            val proposalId = storage.proposalSeqno;
            val proposal = Proposal {
                id: proposalId,
                kind: ProposalKind.PayoutTon,
                creator: in.senderAddress,
                createdAt: now as uint32,
                expiresAt: msg.expiresAt,
                configVersionAtCreation: storage.configVersion,
                status: ProposalStatus.Pending,
                approvalCount: 1,
                approvalMask: storage.ownerApprovalBit(in.senderAddress),
                payload: PayoutTonPayload {
                    recipient: msg.recipient,
                    amount: msg.amount,
                },
            };

            storage.proposals.set(proposalId, proposal.toCell());
            storage.proposalSeqno = proposalId + 1;
            storage.save();
        }
        CreateConfigProposal => {
            var storage = lazy Storage.load();
            storage.assertValidConfig();
            requireMinValue(in.valueCoins, MIN_CREATE_VALUE);
            storage.assertOwner(in.senderAddress);
            val now = blockchain.now();
            assert (msg.expiresAt > now) throw Errors.InvalidExpiry;
            assert (msg.expiresAt <= now + MAX_EXPIRY_SECONDS) throw Errors.InvalidExpiry;
            storage.assertValidProposedConfig(
                msg.newOwnerCount,
                msg.newPayoutThreshold,
                msg.newConfigThreshold,
                msg.newFeeReserve,
                msg.newOwners,
            );

            val proposalId = storage.proposalSeqno;
            val proposal = Proposal {
                id: proposalId,
                kind: ProposalKind.SetTreasuryConfig,
                creator: in.senderAddress,
                createdAt: now as uint32,
                expiresAt: msg.expiresAt,
                configVersionAtCreation: storage.configVersion,
                status: ProposalStatus.Pending,
                approvalCount: 1,
                approvalMask: storage.ownerApprovalBit(in.senderAddress),
                payload: SetTreasuryConfigPayload {
                    newOwnerCount: msg.newOwnerCount,
                    newPayoutThreshold: msg.newPayoutThreshold,
                    newConfigThreshold: msg.newConfigThreshold,
                    newFeeReserve: msg.newFeeReserve,
                    newOwners: msg.newOwners,
                },
            };

            storage.proposals.set(proposalId, proposal.toCell());
            storage.proposalSeqno = proposalId + 1;
            storage.save();
        }
        ApproveProposal => {
            var storage = lazy Storage.load();
            storage.assertValidConfig();
            requireMinValue(in.valueCoins, MIN_APPROVE_VALUE);
            storage.assertOwner(in.senderAddress);

            var proposal = storage.mustGetProposal(msg.proposalId);
            assert (proposal.status == ProposalStatus.Pending) throw Errors.ProposalNotPending;
            storage.requiredThreshold(proposal.kind);
            assert (!proposal.isStale(storage.configVersion)) throw Errors.ProposalStale;
            assert (!proposal.isExpired()) throw Errors.ProposalExpired;

            val approvalBit = storage.ownerApprovalBit(in.senderAddress);
            assert ((proposal.approvalMask & approvalBit) == 0) throw Errors.AlreadyApproved;

            proposal.approvalMask = proposal.approvalMask | approvalBit;
            proposal.approvalCount = proposal.approvalCount + 1;
            storage.proposals.set(msg.proposalId, proposal.toCell());
            storage.save();
        }
        ExecuteProposal => {
            var storage = lazy Storage.load();
            storage.assertValidConfig();
            requireMinValue(in.valueCoins, MIN_EXECUTE_VALUE);
            storage.assertOwner(in.senderAddress);

            var proposal = storage.mustGetProposal(msg.proposalId);
            assert (proposal.status == ProposalStatus.Pending) throw Errors.ProposalNotPending;
            assert (!proposal.isStale(storage.configVersion)) throw Errors.ProposalStale;
            assert (!proposal.isExpired()) throw Errors.ProposalExpired;

            if (proposal.kind == ProposalKind.SetTreasuryConfig) {
                val threshold = storage.configThreshold;
                assert (proposal.approvalCount >= threshold) throw Errors.ThresholdNotReached;
                val payload = proposal.payload;
                assert (payload is SetTreasuryConfigPayload) throw Errors.InvalidProposalKind;
                storage.assertValidProposedConfig(
                    payload.newOwnerCount,
                    payload.newPayoutThreshold,
                    payload.newConfigThreshold,
                    payload.newFeeReserve,
                    payload.newOwners,
                );

                proposal.status = ProposalStatus.Executed;
                storage.proposals.set(msg.proposalId, proposal.toCell());
                storage.ownerCount = payload.newOwnerCount;
                storage.payoutThreshold = payload.newPayoutThreshold;
                storage.configThreshold = payload.newConfigThreshold;
                storage.feeReserve = payload.newFeeReserve;
                storage.owners = payload.newOwners;
                storage.configVersion = storage.configVersion + 1;
                storage.save();
                return;
            }

            if (proposal.kind == ProposalKind.PayoutTon) {
                val threshold = storage.payoutThreshold;
                assert (proposal.approvalCount >= threshold) throw Errors.ThresholdNotReached;
                val payload = proposal.payload;
                assert (payload is PayoutTonPayload) throw Errors.InvalidProposalKind;
                val availableBalance = contract.getOriginalBalance() - in.valueCoins;
                assert (
                    availableBalance >= payload.amount + storage.feeReserve
                ) throw Errors.InsufficientBalance;

                proposal.status = ProposalStatus.Executed;
                storage.proposals.set(msg.proposalId, proposal.toCell());
                storage.save();

                sendTonPayout(payload.recipient, payload.amount);
                return;
            }

            assert (false) throw Errors.InvalidProposalKind;
        }
        CancelProposal => {
            var storage = lazy Storage.load();
            storage.assertValidConfig();
            requireMinValue(in.valueCoins, MIN_CANCEL_VALUE);
            storage.assertOwner(in.senderAddress);

            var proposal = storage.mustGetProposal(msg.proposalId);
            assert (proposal.status == ProposalStatus.Pending) throw Errors.ProposalNotPending;
            assert (!proposal.isStale(storage.configVersion)) throw Errors.ProposalStale;
            assert (!proposal.isExpired()) throw Errors.ProposalExpired;
            assert (proposal.creator == in.senderAddress) throw Errors.NotCreator;
            val threshold = storage.requiredThreshold(proposal.kind);
            assert (proposal.approvalCount < threshold) throw Errors.AlreadyExecutable;

            proposal.status = ProposalStatus.Cancelled;
            storage.proposals.set(msg.proposalId, proposal.toCell());
            storage.save();
        }
        else => {
            assert (in.body.isEmpty()) throw Errors.InvalidMessage;
            val storage = lazy Storage.load();
            storage.assertValidConfig();
        }
    }
}

fun onBouncedMessage(_in: InMessageBounced) {}

fun sendTonPayout(recipient: address, amount: coins) {
    val payout = createMessage({
        bounce: false,
        dest: recipient,
        value: amount,
    });
    payout.send(SEND_MODE_PAY_FEES_SEPARATELY);
}

get fun owner_count(): uint8 {
    val storage = lazy Storage.load();
    return storage.ownerCount;
}

get fun payout_threshold(): uint8 {
    val storage = lazy Storage.load();
    return storage.payoutThreshold;
}

get fun config_threshold(): uint8 {
    val storage = lazy Storage.load();
    return storage.configThreshold;
}

get fun config_threshold_mutable(): bool {
    val storage = lazy Storage.load();
    return storage.configThresholdMutable;
}

get fun config_version(): uint32 {
    val storage = lazy Storage.load();
    return storage.configVersion;
}

get fun proposal_seqno(): uint64 {
    val storage = lazy Storage.load();
    return storage.proposalSeqno;
}

get fun fee_reserve(): coins {
    val storage = lazy Storage.load();
    return storage.feeReserve;
}

get fun is_owner(owner: address): bool {
    val storage = lazy Storage.load();
    return storage.isOwner(owner);
}

get fun proposal(proposalId: uint64): ProposalView {
    val storage = lazy Storage.load();
    val proposal = storage.mustGetProposal(proposalId);
    return proposal.toView(storage.configVersion, storage.requiredThreshold(proposal.kind));
}

get fun proposal_kind(proposalId: uint64): ProposalKind {
    val storage = lazy Storage.load();
    val proposal = storage.mustGetProposal(proposalId);
    return proposal.kind;
}

get fun proposal_required_threshold(proposalId: uint64): uint8 {
    val storage = lazy Storage.load();
    val proposal = storage.mustGetProposal(proposalId);
    return storage.requiredThreshold(proposal.kind);
}

get fun proposal_config_owners(proposalId: uint64): map<address, uint8> {
    val storage = lazy Storage.load();
    val proposal = storage.mustGetProposal(proposalId);
    assert (proposal.kind == ProposalKind.SetTreasuryConfig) throw Errors.InvalidProposalKind;
    val payload = proposal.payload;
    assert (payload is SetTreasuryConfigPayload) throw Errors.InvalidProposalKind;
    return payload.newOwners;
}

get fun has_approval(proposalId: uint64, owner: address): bool {
    val storage = lazy Storage.load();
    val proposal = storage.mustGetProposal(proposalId);
    val approvalBit = storage.ownerApprovalBit(owner);
    return (proposal.approvalMask & approvalBit) != 0;
}
