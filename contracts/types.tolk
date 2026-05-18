const OWNER_INDEX_0: uint8 = 0
const OWNER_INDEX_1: uint8 = 1
const OWNER_INDEX_2: uint8 = 2
const APPROVAL_KEY_VALUE: uint8 = 1
const MIN_OWNER_COUNT: uint8 = 2
const MAX_OWNER_COUNT: uint8 = 10
const MAX_RETAINED_PROPOSALS: uint16 = 100
const DEFAULT_EXPIRY_SECONDS: uint32 = 86400
const MAX_EXPIRY_SECONDS: uint32 = 2592000
const DEFAULT_FEE_RESERVE: coins = ton("0.10")
const MIN_FEE_RESERVE: coins = DEFAULT_FEE_RESERVE
const MIN_CREATE_VALUE: coins = ton("0.05")
const MIN_APPROVE_VALUE: coins = ton("0.05")
const MIN_CANCEL_VALUE: coins = ton("0.05")
const MIN_EXECUTE_VALUE: coins = ton("0.05")
const MIN_PRUNE_VALUE: coins = ton("0.05")

enum Errors {
    NotOwner = 128
    InvalidMessage = 129
    InvalidOwnerCount = 130
    DuplicateOwner = 131
    InvalidThreshold = 132
    InvalidRecipient = 133
    InvalidAmount = 134
    InvalidExpiry = 135
    ProposalNotFound = 136
    ProposalNotPending = 137
    ProposalExpired = 138
    AlreadyApproved = 139
    ThresholdNotReached = 140
    AlreadyExecutable = 141
    InsufficientBalance = 142
    NotCreator = 143
    InsufficientMessageValue = 144
    InvalidPayoutThreshold = 145
    InvalidConfigThreshold = 146
    ConfigThresholdLocked = 147
    InvalidFeeReserve = 148
    ProposalStale = 149
    InvalidProposalKind = 150
}

enum ProposalStatus: uint8 {
    Pending = 0
    Executed = 1
    Cancelled = 2
}

enum ProposalKind: uint8 {
    PayoutTon = 0
    SetTreasuryConfig = 1
}

enum ProposalViewStatus: uint8 {
    Pending = 0
    Executable = 1
    Executed = 2
    Cancelled = 3
    Expired = 4
    Stale = 5
}

struct (0x54525001) PayoutTonPayload {
    recipient: address
    amount: coins
}

struct (0x54525002) SetTreasuryConfigPayload {
    newOwnerCount: uint8
    newPayoutThreshold: uint8
    newConfigThreshold: uint8
    newFeeReserve: coins
    newOwners: map<address, uint8>
}

type ProposalPayload = PayoutTonPayload | SetTreasuryConfigPayload

struct Proposal {
    id: uint64
    kind: ProposalKind
    creator: address
    createdAt: uint32
    expiresAt: uint32
    configVersionAtCreation: uint32
    status: ProposalStatus
    approvalCount: uint8
    payload: ProposalPayload
}

struct ProposalView {
    id: uint64
    kind: ProposalKind
    creator: address
    createdAt: uint32
    expiresAt: uint32
    configVersionAtCreation: uint32
    currentConfigVersion: uint32
    status: ProposalViewStatus
    approvalCount: uint8
    requiredApprovalCount: uint8
    payoutRecipient: address
    payoutAmount: coins
    recipient: address
    amount: coins
    newOwnerCount: uint8
    newPayoutThreshold: uint8
    newConfigThreshold: uint8
    newFeeReserve: coins
}

struct Storage {
    ownerCount: uint8
    payoutThreshold: uint8
    configThreshold: uint8
    configThresholdMutable: bool
    configVersion: uint32
    proposalSeqno: uint64
    retainedProposalCount: uint16
    feeReserve: coins
    owners: map<address, uint8>
    proposals: map<uint64, Cell<Proposal>>
    approvals: map<uint256, uint8>
}

fun Storage.load(): Storage {
    return Storage.fromCell(contract.getData());
}

fun Storage.save(self) {
    contract.setData(self.toCell());
}

fun Storage.assertValidConfig(self) {
    assert (self.ownerCount >= MIN_OWNER_COUNT) throw Errors.InvalidOwnerCount;
    assert (self.ownerCount <= MAX_OWNER_COUNT) throw Errors.InvalidOwnerCount;
    assert (self.ownerMapCount() == self.ownerCount) throw Errors.DuplicateOwner;
    ownerIndexMask(self.owners, self.ownerCount);
    assert (self.payoutThreshold > 0) throw Errors.InvalidPayoutThreshold;
    assert (self.configThreshold > 0) throw Errors.InvalidConfigThreshold;
    assert (self.payoutThreshold <= self.configThreshold) throw Errors.InvalidConfigThreshold;
    assert (self.configThreshold <= self.ownerCount) throw Errors.InvalidConfigThreshold;
    assert (self.feeReserve >= MIN_FEE_RESERVE) throw Errors.InvalidFeeReserve;
}

fun Storage.assertValidProposedConfig(
    self,
    newOwnerCount: uint8,
    newPayoutThreshold: uint8,
    newConfigThreshold: uint8,
    newFeeReserve: coins,
    newOwners: map<address, uint8>,
) {
    assert (newOwnerCount >= MIN_OWNER_COUNT) throw Errors.InvalidOwnerCount;
    assert (newOwnerCount <= MAX_OWNER_COUNT) throw Errors.InvalidOwnerCount;
    assert (ownerMapCount(newOwners) == newOwnerCount) throw Errors.DuplicateOwner;
    ownerIndexMask(newOwners, newOwnerCount);
    assert (newPayoutThreshold > 0) throw Errors.InvalidPayoutThreshold;
    assert (newPayoutThreshold <= newConfigThreshold) throw Errors.InvalidConfigThreshold;
    assert (newConfigThreshold <= newOwnerCount) throw Errors.InvalidConfigThreshold;
    assert (newFeeReserve >= MIN_FEE_RESERVE) throw Errors.InvalidFeeReserve;
    if (!self.configThresholdMutable) {
        assert (newConfigThreshold == self.configThreshold) throw Errors.ConfigThresholdLocked;
    }
}

fun ownerMapCount(owners: map<address, uint8>): int {
    var count = 0;
    var entry = owners.findFirst();
    while (entry.isFound) {
        count += 1;
        entry = owners.iterateNext(entry);
    }
    return count;
}

fun Storage.ownerMapCount(self): int {
    return ownerMapCount(self.owners);
}

fun ownerIndexMask(owners: map<address, uint8>, ownerCount: uint8): uint16 {
    var mask: uint16 = 0;
    var entry = owners.findFirst();
    while (entry.isFound) {
        val index = entry.loadValue();
        assert (index < ownerCount) throw Errors.InvalidOwnerCount;
        val bit = (1 as uint16) << index;
        assert ((mask & bit) == 0) throw Errors.DuplicateOwner;
        mask = mask | bit;
        entry = owners.iterateNext(entry);
    }
    return mask;
}

fun Storage.isOwner(self, owner: address): bool {
    return self.owners.exists(owner);
}

fun Storage.assertOwner(self, owner: address) {
    assert (self.isOwner(owner)) throw Errors.NotOwner;
}

fun Storage.requiredThreshold(self, kind: ProposalKind): uint8 {
    if (kind == ProposalKind.PayoutTon) {
        return self.payoutThreshold;
    }
    if (kind == ProposalKind.SetTreasuryConfig) {
        return self.configThreshold;
    }
    assert (false) throw Errors.InvalidProposalKind;
    return 0;
}

fun Storage.ownerApprovalBit(self, owner: address): uint16 {
    val index = self.owners.mustGet(owner, Errors.NotOwner);
    assert (index < self.ownerCount) throw Errors.InvalidOwnerCount;
    return (1 as uint16) << index;
}

fun approvalKey(kind: ProposalKind, proposalId: uint64, owner: address): uint256 {
    return beginCell()
        .storeUint(kind as int, 8)
        .storeUint(proposalId, 64)
        .storeAddress(owner)
        .endCell()
        .hash();
}

fun Storage.mustGetProposal(self, proposalId: uint64): Proposal {
    val proposalCell = self.proposals.mustGet(proposalId, Errors.ProposalNotFound);
    return proposalCell.load();
}

fun Proposal.isExpired(self): bool {
    return blockchain.now() >= self.expiresAt;
}

fun Proposal.isStale(self, currentConfigVersion: uint32): bool {
    return self.configVersionAtCreation != currentConfigVersion;
}

fun zeroAddress(): address {
    return address("0:0000000000000000000000000000000000000000000000000000000000000000");
}

fun Proposal.viewStatus(self, currentConfigVersion: uint32, threshold: uint8): ProposalViewStatus {
    if (self.status == ProposalStatus.Executed) {
        return ProposalViewStatus.Executed;
    }
    if (self.status == ProposalStatus.Cancelled) {
        return ProposalViewStatus.Cancelled;
    }
    if (self.isStale(currentConfigVersion)) {
        return ProposalViewStatus.Stale;
    }
    if (self.isExpired()) {
        return ProposalViewStatus.Expired;
    }
    if (self.approvalCount >= threshold) {
        return ProposalViewStatus.Executable;
    }
    return ProposalViewStatus.Pending;
}

fun Proposal.toView(self, currentConfigVersion: uint32, threshold: uint8): ProposalView {
    var payoutRecipient = zeroAddress();
    var payoutAmount: coins = 0;
    var newOwnerCount: uint8 = 0;
    var newPayoutThreshold: uint8 = 0;
    var newConfigThreshold: uint8 = 0;
    var newFeeReserve: coins = 0;

    val payload = self.payload;
    match (payload) {
        PayoutTonPayload => {
            payoutRecipient = payload.recipient;
            payoutAmount = payload.amount;
        }
        SetTreasuryConfigPayload => {
            newOwnerCount = payload.newOwnerCount;
            newPayoutThreshold = payload.newPayoutThreshold;
            newConfigThreshold = payload.newConfigThreshold;
            newFeeReserve = payload.newFeeReserve;
        }
    }

    return ProposalView {
        id: self.id,
        kind: self.kind,
        creator: self.creator,
        createdAt: self.createdAt,
        expiresAt: self.expiresAt,
        configVersionAtCreation: self.configVersionAtCreation,
        currentConfigVersion,
        status: self.viewStatus(currentConfigVersion, threshold),
        approvalCount: self.approvalCount,
        requiredApprovalCount: threshold,
        payoutRecipient,
        payoutAmount,
        recipient: payoutRecipient,
        amount: payoutAmount,
        newOwnerCount,
        newPayoutThreshold,
        newConfigThreshold,
        newFeeReserve,
    };
}

struct (0x54524601) CreatePayoutProposal {
    recipient: address
    amount: coins
    expiresAt: uint32
}

struct (0x54524602) ApproveProposal {
    proposalId: uint64
}

struct (0x54524603) ExecuteProposal {
    proposalId: uint64
}

struct (0x54524604) CancelProposal {
    proposalId: uint64
}

struct (0x54524605) CreateConfigProposal {
    newOwnerCount: uint8
    newPayoutThreshold: uint8
    newConfigThreshold: uint8
    newFeeReserve: coins
    newOwners: map<address, uint8>
    expiresAt: uint32
}

type TreasuryMessage =
    | CreatePayoutProposal
    | ApproveProposal
    | ExecuteProposal
    | CancelProposal
    | CreateConfigProposal
