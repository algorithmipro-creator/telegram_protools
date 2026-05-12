import "types"

contract Treasury {
    author: "TreasuryFlow TON"
    version: "0.1.0"
    description: "Track A Treasury-first TON payout approval prototype"
    storage: Storage
    incomingMessages: TreasuryMessage
}

fun onInternalMessage(in: InMessage) {
    val msg = lazy TreasuryMessage.fromSlice(in.body);

    match (msg) {
        CreatePayoutProposal => {
            val storage = lazy Storage.load();
            storage.assertValidConfig();
            assert (storage.isOwner(in.senderAddress)) throw Errors.NotOwner;
            throw Errors.InvalidMessage;
        }
        ApproveProposal => {
            val storage = lazy Storage.load();
            storage.assertValidConfig();
            assert (storage.isOwner(in.senderAddress)) throw Errors.NotOwner;
            throw Errors.ProposalNotFound;
        }
        ExecuteProposal => {
            val storage = lazy Storage.load();
            storage.assertValidConfig();
            assert (storage.isOwner(in.senderAddress)) throw Errors.NotOwner;
            throw Errors.ProposalNotFound;
        }
        CancelProposal => {
            val storage = lazy Storage.load();
            storage.assertValidConfig();
            assert (storage.isOwner(in.senderAddress)) throw Errors.NotOwner;
            throw Errors.ProposalNotFound;
        }
        else => {
            assert (in.body.isEmpty()) throw Errors.InvalidMessage;
            val storage = lazy Storage.load();
            storage.assertValidConfig();
        }
    }
}

fun onBouncedMessage(_in: InMessageBounced) {}

get fun owner_count(): uint8 {
    val storage = lazy Storage.load();
    return storage.ownerCount;
}

get fun threshold(): uint8 {
    val storage = lazy Storage.load();
    return storage.threshold;
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
