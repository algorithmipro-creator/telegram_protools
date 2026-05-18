// AUTO-GENERATED, do not edit
// It's a TypeScript wrapper for a Treasury contract in Tolk.
/* eslint-disable */

import * as c from '@ton/core';
import { beginCell, ContractProvider, Sender, SendMode } from '@ton/core';

// ————————————————————————————————————————————
//   predefined types and functions
//

type StoreCallback<T> = (obj: T, b: c.Builder) => void
type LoadCallback<T> = (s: c.Slice) => T

export type CellRef<T> = {
    ref: T
}

function makeCellFrom<T>(self: T, storeFn_T: StoreCallback<T>): c.Cell {
    let b = beginCell();
    storeFn_T(self, b);
    return b.endCell();
}

function loadAndCheckPrefix32(s: c.Slice, expected: number, structName: string): void {
    let prefix = s.loadUint(32);
    if (prefix !== expected) {
        throw new Error(`Incorrect prefix for '${structName}': expected 0x${expected.toString(16).padStart(8, '0')}, got 0x${prefix.toString(16).padStart(8, '0')}`);
    }
}

function lookupPrefix(s: c.Slice, expected: number, prefixLen: number): boolean {
    return s.remainingBits >= prefixLen && s.preloadUint(prefixLen) === expected;
}

function throwNonePrefixMatch(fieldPath: string): never {
    throw new Error(`Incorrect prefix for '${fieldPath}': none of variants matched`);
}

function storeCellRef<T>(cell: CellRef<T>, b: c.Builder, storeFn_T: StoreCallback<T>): void {
    let b_ref = c.beginCell();
    storeFn_T(cell.ref, b_ref);
    b.storeRef(b_ref.endCell());
}

function loadCellRef<T>(s: c.Slice, loadFn_T: LoadCallback<T>): CellRef<T> {
    let s_ref = s.loadRef().beginParse();
    return { ref: loadFn_T(s_ref) };
}

function storeTolkNullable<T>(v: T | null, b: c.Builder, storeFn_T: StoreCallback<T>): void {
    if (v === null) {
        b.storeUint(0, 1);
    } else {
        b.storeUint(1, 1);
        storeFn_T(v, b);
    }
}

function createDictionaryValue<V>(loadFn_V: LoadCallback<V>, storeFn_V: StoreCallback<V>): c.DictionaryValue<V> {
    return {
        serialize(self: V, b: c.Builder) {
            storeFn_V(self, b);
        },
        parse(s: c.Slice): V {
            const value = loadFn_V(s);
            s.endParse();
            return value;
        }
    }
}

// ————————————————————————————————————————————
//   parse get methods result from a TVM stack
//

class StackReader {
    constructor(private tuple: c.TupleItem[]) {
    }

    static fromGetMethod(expectedN: number, getMethodResult: { stack: c.TupleReader }): StackReader {
        let tuple = [] as c.TupleItem[];
        while (getMethodResult.stack.remaining) {
            tuple.push(getMethodResult.stack.pop());
        }
        if (tuple.length !== expectedN) {
            throw new Error(`expected ${expectedN} stack width, got ${tuple.length}`);
        }
        return new StackReader(tuple);
    }

    private popExpecting<ItemT>(itemType: string): ItemT {
        const item = this.tuple.shift();
        if (item?.type === itemType) {
            return item as ItemT;
        }
        throw new Error(`not '${itemType}' on a stack`);
    }

    private popCellLike(): c.Cell {
        const item = this.tuple.shift();
        if (item && (item.type === 'cell' || item.type === 'slice' || item.type === 'builder')) {
            return item.cell;
        }
        throw new Error(`not cell/slice on a stack`);
    }

    readBigInt(): bigint {
        return this.popExpecting<c.TupleItemInt>('int').value;
    }

    readBoolean(): boolean {
        return this.popExpecting<c.TupleItemInt>('int').value !== 0n;
    }

    readCell(): c.Cell {
        return this.popCellLike();
    }

    readSlice(): c.Slice {
        return this.popCellLike().beginParse();
    }

    readDictionary<K extends c.DictionaryKeyTypes, V>(keySerializer: c.DictionaryKey<K>, valueSerializer: c.DictionaryValue<V>): c.Dictionary<K, V> {
        if (this.tuple[0].type === 'null') {
            this.tuple.shift();
            return c.Dictionary.empty<K, V>(keySerializer, valueSerializer);
        }
        return c.Dictionary.loadDirect<K, V>(keySerializer, valueSerializer, this.readCell());
    }
}

// ————————————————————————————————————————————
//   auto-generated serializers to/from cells
//

type coins = bigint

type uint8 = bigint
type uint16 = bigint
type uint32 = bigint
type uint64 = bigint
type uint256 = bigint

/**
 > enum ProposalStatus { 3 variants }
 */
export type ProposalStatus = bigint

export const ProposalStatus = {
    Pending: 0n,
    Executed: 1n,
    Cancelled: 2n,

    fromSlice(s: c.Slice): ProposalStatus {
        return s.loadUintBig(8);
    },
    store(self: ProposalStatus, b: c.Builder): void {
        b.storeUint(self, 8);
    },
    toCell(self: ProposalStatus): c.Cell {
        return makeCellFrom<ProposalStatus>(self, ProposalStatus.store);
    }
}

/**
 > enum ProposalKind { 2 variants }
 */
export type ProposalKind = bigint

export const ProposalKind = {
    PayoutTon: 0n,
    SetTreasuryConfig: 1n,

    fromSlice(s: c.Slice): ProposalKind {
        return s.loadUintBig(8);
    },
    store(self: ProposalKind, b: c.Builder): void {
        b.storeUint(self, 8);
    },
    toCell(self: ProposalKind): c.Cell {
        return makeCellFrom<ProposalKind>(self, ProposalKind.store);
    }
}

/**
 > enum ProposalViewStatus { 6 variants }
 */
export type ProposalViewStatus = bigint

export const ProposalViewStatus = {
    Pending: 0n,
    Executable: 1n,
    Executed: 2n,
    Cancelled: 3n,
    Expired: 4n,
    Stale: 5n,

    fromSlice(s: c.Slice): ProposalViewStatus {
        return s.loadUintBig(8);
    },
    store(self: ProposalViewStatus, b: c.Builder): void {
        b.storeUint(self, 8);
    },
    toCell(self: ProposalViewStatus): c.Cell {
        return makeCellFrom<ProposalViewStatus>(self, ProposalViewStatus.store);
    }
}

/**
 > struct (0x54525001) PayoutTonPayload {
 >     recipient: address
 >     amount: coins
 > }
 */
export interface PayoutTonPayload {
    readonly $: 'PayoutTonPayload'
    recipient: c.Address
    amount: coins
}

export const PayoutTonPayload = {
    PREFIX: 0x54525001,

    create(args: {
        recipient: c.Address
        amount: coins
    }): PayoutTonPayload {
        return {
            $: 'PayoutTonPayload',
            ...args
        }
    },
    fromSlice(s: c.Slice): PayoutTonPayload {
        loadAndCheckPrefix32(s, 0x54525001, 'PayoutTonPayload');
        return {
            $: 'PayoutTonPayload',
            recipient: s.loadAddress(),
            amount: s.loadCoins(),
        }
    },
    store(self: PayoutTonPayload, b: c.Builder): void {
        b.storeUint(0x54525001, 32);
        b.storeAddress(self.recipient);
        b.storeCoins(self.amount);
    },
    toCell(self: PayoutTonPayload): c.Cell {
        return makeCellFrom<PayoutTonPayload>(self, PayoutTonPayload.store);
    }
}

/**
 > struct (0x54525002) SetTreasuryConfigPayload {
 >     newOwnerCount: uint8
 >     newPayoutThreshold: uint8
 >     newConfigThreshold: uint8
 >     newFeeReserve: coins
 >     newOwners: map<address, uint8>
 > }
 */
export interface SetTreasuryConfigPayload {
    readonly $: 'SetTreasuryConfigPayload'
    newOwnerCount: uint8
    newPayoutThreshold: uint8
    newConfigThreshold: uint8
    newFeeReserve: coins
    newOwners: c.Dictionary<c.Address, uint8>
}

export const SetTreasuryConfigPayload = {
    PREFIX: 0x54525002,

    create(args: {
        newOwnerCount: uint8
        newPayoutThreshold: uint8
        newConfigThreshold: uint8
        newFeeReserve: coins
        newOwners: c.Dictionary<c.Address, uint8>
    }): SetTreasuryConfigPayload {
        return {
            $: 'SetTreasuryConfigPayload',
            ...args
        }
    },
    fromSlice(s: c.Slice): SetTreasuryConfigPayload {
        loadAndCheckPrefix32(s, 0x54525002, 'SetTreasuryConfigPayload');
        return {
            $: 'SetTreasuryConfigPayload',
            newOwnerCount: s.loadUintBig(8),
            newPayoutThreshold: s.loadUintBig(8),
            newConfigThreshold: s.loadUintBig(8),
            newFeeReserve: s.loadCoins(),
            newOwners: c.Dictionary.load<c.Address, uint8>(c.Dictionary.Keys.Address(), c.Dictionary.Values.BigUint(8), s),
        }
    },
    store(self: SetTreasuryConfigPayload, b: c.Builder): void {
        b.storeUint(0x54525002, 32);
        b.storeUint(self.newOwnerCount, 8);
        b.storeUint(self.newPayoutThreshold, 8);
        b.storeUint(self.newConfigThreshold, 8);
        b.storeCoins(self.newFeeReserve);
        b.storeDict<c.Address, uint8>(self.newOwners, c.Dictionary.Keys.Address(), c.Dictionary.Values.BigUint(8));
    },
    toCell(self: SetTreasuryConfigPayload): c.Cell {
        return makeCellFrom<SetTreasuryConfigPayload>(self, SetTreasuryConfigPayload.store);
    }
}

/**
 > type ProposalPayload = PayoutTonPayload | SetTreasuryConfigPayload
 */
export type ProposalPayload =
    | PayoutTonPayload
    | SetTreasuryConfigPayload

export const ProposalPayload = {
    fromSlice(s: c.Slice): ProposalPayload {
        return lookupPrefix(s, 0x54525001, 32) ? PayoutTonPayload.fromSlice(s) :
            lookupPrefix(s, 0x54525002, 32) ? SetTreasuryConfigPayload.fromSlice(s) :
            throwNonePrefixMatch('ProposalPayload');
    },
    store(self: ProposalPayload, b: c.Builder): void {
        switch (self.$) {
            case 'PayoutTonPayload':
                PayoutTonPayload.store(self, b);
                break;
            case 'SetTreasuryConfigPayload':
                SetTreasuryConfigPayload.store(self, b);
                break;
        }
    },
    toCell(self: ProposalPayload): c.Cell {
        return makeCellFrom<ProposalPayload>(self, ProposalPayload.store);
    }
}

/**
 > struct Proposal {
 >     id: uint64
 >     kind: ProposalKind
 >     creator: address
 >     createdAt: uint32
 >     expiresAt: uint32
 >     configVersionAtCreation: uint32
 >     status: ProposalStatus
 >     approvalCount: uint8
 >     payload: ProposalPayload
 > }
 */
export interface Proposal {
    readonly $: 'Proposal'
    id: uint64
    kind: ProposalKind
    creator: c.Address
    createdAt: uint32
    expiresAt: uint32
    configVersionAtCreation: uint32
    status: ProposalStatus
    approvalCount: uint8
    payload: ProposalPayload
}

export const Proposal = {
    create(args: {
        id: uint64
        kind: ProposalKind
        creator: c.Address
        createdAt: uint32
        expiresAt: uint32
        configVersionAtCreation: uint32
        status: ProposalStatus
        approvalCount: uint8
        payload: ProposalPayload
    }): Proposal {
        return {
            $: 'Proposal',
            ...args
        }
    },
    fromSlice(s: c.Slice): Proposal {
        return {
            $: 'Proposal',
            id: s.loadUintBig(64),
            kind: ProposalKind.fromSlice(s),
            creator: s.loadAddress(),
            createdAt: s.loadUintBig(32),
            expiresAt: s.loadUintBig(32),
            configVersionAtCreation: s.loadUintBig(32),
            status: ProposalStatus.fromSlice(s),
            approvalCount: s.loadUintBig(8),
            payload: ProposalPayload.fromSlice(s),
        }
    },
    store(self: Proposal, b: c.Builder): void {
        b.storeUint(self.id, 64);
        ProposalKind.store(self.kind, b);
        b.storeAddress(self.creator);
        b.storeUint(self.createdAt, 32);
        b.storeUint(self.expiresAt, 32);
        b.storeUint(self.configVersionAtCreation, 32);
        ProposalStatus.store(self.status, b);
        b.storeUint(self.approvalCount, 8);
        ProposalPayload.store(self.payload, b);
    },
    toCell(self: Proposal): c.Cell {
        return makeCellFrom<Proposal>(self, Proposal.store);
    }
}

/**
 > struct ProposalView {
 >     id: uint64
 >     kind: ProposalKind
 >     creator: address
 >     createdAt: uint32
 >     expiresAt: uint32
 >     configVersionAtCreation: uint32
 >     currentConfigVersion: uint32
 >     status: ProposalViewStatus
 >     approvalCount: uint8
 >     requiredApprovalCount: uint8
 >     payoutRecipient: address
 >     payoutAmount: coins
 >     recipient: address
 >     amount: coins
 >     newOwnerCount: uint8
 >     newPayoutThreshold: uint8
 >     newConfigThreshold: uint8
 >     newFeeReserve: coins
 > }
 */
export interface ProposalView {
    readonly $: 'ProposalView'
    id: uint64
    kind: ProposalKind
    creator: c.Address
    createdAt: uint32
    expiresAt: uint32
    configVersionAtCreation: uint32
    currentConfigVersion: uint32
    status: ProposalViewStatus
    approvalCount: uint8
    requiredApprovalCount: uint8
    payoutRecipient: c.Address
    payoutAmount: coins
    recipient: c.Address
    amount: coins
    newOwnerCount: uint8
    newPayoutThreshold: uint8
    newConfigThreshold: uint8
    newFeeReserve: coins
}

export const ProposalView = {
    create(args: {
        id: uint64
        kind: ProposalKind
        creator: c.Address
        createdAt: uint32
        expiresAt: uint32
        configVersionAtCreation: uint32
        currentConfigVersion: uint32
        status: ProposalViewStatus
        approvalCount: uint8
        requiredApprovalCount: uint8
        payoutRecipient: c.Address
        payoutAmount: coins
        recipient: c.Address
        amount: coins
        newOwnerCount: uint8
        newPayoutThreshold: uint8
        newConfigThreshold: uint8
        newFeeReserve: coins
    }): ProposalView {
        return {
            $: 'ProposalView',
            ...args
        }
    },
    fromSlice(s: c.Slice): ProposalView {
        return {
            $: 'ProposalView',
            id: s.loadUintBig(64),
            kind: ProposalKind.fromSlice(s),
            creator: s.loadAddress(),
            createdAt: s.loadUintBig(32),
            expiresAt: s.loadUintBig(32),
            configVersionAtCreation: s.loadUintBig(32),
            currentConfigVersion: s.loadUintBig(32),
            status: ProposalViewStatus.fromSlice(s),
            approvalCount: s.loadUintBig(8),
            requiredApprovalCount: s.loadUintBig(8),
            payoutRecipient: s.loadAddress(),
            payoutAmount: s.loadCoins(),
            recipient: s.loadAddress(),
            amount: s.loadCoins(),
            newOwnerCount: s.loadUintBig(8),
            newPayoutThreshold: s.loadUintBig(8),
            newConfigThreshold: s.loadUintBig(8),
            newFeeReserve: s.loadCoins(),
        }
    },
    store(self: ProposalView, b: c.Builder): void {
        b.storeUint(self.id, 64);
        ProposalKind.store(self.kind, b);
        b.storeAddress(self.creator);
        b.storeUint(self.createdAt, 32);
        b.storeUint(self.expiresAt, 32);
        b.storeUint(self.configVersionAtCreation, 32);
        b.storeUint(self.currentConfigVersion, 32);
        ProposalViewStatus.store(self.status, b);
        b.storeUint(self.approvalCount, 8);
        b.storeUint(self.requiredApprovalCount, 8);
        b.storeAddress(self.payoutRecipient);
        b.storeCoins(self.payoutAmount);
        b.storeAddress(self.recipient);
        b.storeCoins(self.amount);
        b.storeUint(self.newOwnerCount, 8);
        b.storeUint(self.newPayoutThreshold, 8);
        b.storeUint(self.newConfigThreshold, 8);
        b.storeCoins(self.newFeeReserve);
    },
    toCell(self: ProposalView): c.Cell {
        return makeCellFrom<ProposalView>(self, ProposalView.store);
    }
}

/**
 > struct Storage {
 >     ownerCount: uint8
 >     payoutThreshold: uint8
 >     configThreshold: uint8
 >     configThresholdMutable: bool
 >     configVersion: uint32
 >     proposalSeqno: uint64
 >     retainedProposalCount: uint16
 >     feeReserve: coins
 >     owners: map<address, uint8>
 >     proposals: map<uint64, Cell<Proposal>>
 >     approvals: map<uint256, uint8>
 > }
 */
export interface Storage {
    readonly $: 'Storage'
    ownerCount: uint8
    payoutThreshold: uint8
    configThreshold: uint8
    configThresholdMutable: boolean
    configVersion: uint32
    proposalSeqno: uint64
    retainedProposalCount: uint16
    feeReserve: coins
    owners: c.Dictionary<c.Address, uint8>
    proposals: c.Dictionary<uint64, CellRef<Proposal>>
    approvals: c.Dictionary<uint256, uint8>
}

export const Storage = {
    create(args: {
        ownerCount: uint8
        payoutThreshold: uint8
        configThreshold: uint8
        configThresholdMutable: boolean
        configVersion: uint32
        proposalSeqno: uint64
        retainedProposalCount: uint16
        feeReserve: coins
        owners: c.Dictionary<c.Address, uint8>
        proposals: c.Dictionary<uint64, CellRef<Proposal>>
        approvals: c.Dictionary<uint256, uint8>
    }): Storage {
        return {
            $: 'Storage',
            ...args
        }
    },
    fromSlice(s: c.Slice): Storage {
        return {
            $: 'Storage',
            ownerCount: s.loadUintBig(8),
            payoutThreshold: s.loadUintBig(8),
            configThreshold: s.loadUintBig(8),
            configThresholdMutable: s.loadBoolean(),
            configVersion: s.loadUintBig(32),
            proposalSeqno: s.loadUintBig(64),
            retainedProposalCount: s.loadUintBig(16),
            feeReserve: s.loadCoins(),
            owners: c.Dictionary.load<c.Address, uint8>(c.Dictionary.Keys.Address(), c.Dictionary.Values.BigUint(8), s),
            proposals: c.Dictionary.load<uint64, CellRef<Proposal>>(c.Dictionary.Keys.BigUint(64), createDictionaryValue<CellRef<Proposal>>(
                (s) => loadCellRef<Proposal>(s, Proposal.fromSlice),
                (v,b) => storeCellRef<Proposal>(v, b, Proposal.store)
            ), s),
            approvals: c.Dictionary.load<uint256, uint8>(c.Dictionary.Keys.BigUint(256), c.Dictionary.Values.BigUint(8), s),
        }
    },
    store(self: Storage, b: c.Builder): void {
        b.storeUint(self.ownerCount, 8);
        b.storeUint(self.payoutThreshold, 8);
        b.storeUint(self.configThreshold, 8);
        b.storeBit(self.configThresholdMutable);
        b.storeUint(self.configVersion, 32);
        b.storeUint(self.proposalSeqno, 64);
        b.storeUint(self.retainedProposalCount, 16);
        b.storeCoins(self.feeReserve);
        b.storeDict<c.Address, uint8>(self.owners, c.Dictionary.Keys.Address(), c.Dictionary.Values.BigUint(8));
        b.storeDict<uint64, CellRef<Proposal>>(self.proposals, c.Dictionary.Keys.BigUint(64), createDictionaryValue<CellRef<Proposal>>(
            (s) => loadCellRef<Proposal>(s, Proposal.fromSlice),
            (v,b) => storeCellRef<Proposal>(v, b, Proposal.store)
        ));
        b.storeDict<uint256, uint8>(self.approvals, c.Dictionary.Keys.BigUint(256), c.Dictionary.Values.BigUint(8));
    },
    toCell(self: Storage): c.Cell {
        return makeCellFrom<Storage>(self, Storage.store);
    }
}

/**
 > struct (0x54524601) CreatePayoutProposal {
 >     recipient: address
 >     amount: coins
 >     expiresAt: uint32
 > }
 */
export interface CreatePayoutProposal {
    readonly $: 'CreatePayoutProposal'
    recipient: c.Address
    amount: coins
    expiresAt: uint32
}

export const CreatePayoutProposal = {
    PREFIX: 0x54524601,

    create(args: {
        recipient: c.Address
        amount: coins
        expiresAt: uint32
    }): CreatePayoutProposal {
        return {
            $: 'CreatePayoutProposal',
            ...args
        }
    },
    fromSlice(s: c.Slice): CreatePayoutProposal {
        loadAndCheckPrefix32(s, 0x54524601, 'CreatePayoutProposal');
        return {
            $: 'CreatePayoutProposal',
            recipient: s.loadAddress(),
            amount: s.loadCoins(),
            expiresAt: s.loadUintBig(32),
        }
    },
    store(self: CreatePayoutProposal, b: c.Builder): void {
        b.storeUint(0x54524601, 32);
        b.storeAddress(self.recipient);
        b.storeCoins(self.amount);
        b.storeUint(self.expiresAt, 32);
    },
    toCell(self: CreatePayoutProposal): c.Cell {
        return makeCellFrom<CreatePayoutProposal>(self, CreatePayoutProposal.store);
    }
}

/**
 > struct (0x54524602) ApproveProposal {
 >     proposalId: uint64
 > }
 */
export interface ApproveProposal {
    readonly $: 'ApproveProposal'
    proposalId: uint64
}

export const ApproveProposal = {
    PREFIX: 0x54524602,

    create(args: {
        proposalId: uint64
    }): ApproveProposal {
        return {
            $: 'ApproveProposal',
            ...args
        }
    },
    fromSlice(s: c.Slice): ApproveProposal {
        loadAndCheckPrefix32(s, 0x54524602, 'ApproveProposal');
        return {
            $: 'ApproveProposal',
            proposalId: s.loadUintBig(64),
        }
    },
    store(self: ApproveProposal, b: c.Builder): void {
        b.storeUint(0x54524602, 32);
        b.storeUint(self.proposalId, 64);
    },
    toCell(self: ApproveProposal): c.Cell {
        return makeCellFrom<ApproveProposal>(self, ApproveProposal.store);
    }
}

/**
 > struct (0x54524603) ExecuteProposal {
 >     proposalId: uint64
 > }
 */
export interface ExecuteProposal {
    readonly $: 'ExecuteProposal'
    proposalId: uint64
}

export const ExecuteProposal = {
    PREFIX: 0x54524603,

    create(args: {
        proposalId: uint64
    }): ExecuteProposal {
        return {
            $: 'ExecuteProposal',
            ...args
        }
    },
    fromSlice(s: c.Slice): ExecuteProposal {
        loadAndCheckPrefix32(s, 0x54524603, 'ExecuteProposal');
        return {
            $: 'ExecuteProposal',
            proposalId: s.loadUintBig(64),
        }
    },
    store(self: ExecuteProposal, b: c.Builder): void {
        b.storeUint(0x54524603, 32);
        b.storeUint(self.proposalId, 64);
    },
    toCell(self: ExecuteProposal): c.Cell {
        return makeCellFrom<ExecuteProposal>(self, ExecuteProposal.store);
    }
}

/**
 > struct (0x54524604) CancelProposal {
 >     proposalId: uint64
 > }
 */
export interface CancelProposal {
    readonly $: 'CancelProposal'
    proposalId: uint64
}

export const CancelProposal = {
    PREFIX: 0x54524604,

    create(args: {
        proposalId: uint64
    }): CancelProposal {
        return {
            $: 'CancelProposal',
            ...args
        }
    },
    fromSlice(s: c.Slice): CancelProposal {
        loadAndCheckPrefix32(s, 0x54524604, 'CancelProposal');
        return {
            $: 'CancelProposal',
            proposalId: s.loadUintBig(64),
        }
    },
    store(self: CancelProposal, b: c.Builder): void {
        b.storeUint(0x54524604, 32);
        b.storeUint(self.proposalId, 64);
    },
    toCell(self: CancelProposal): c.Cell {
        return makeCellFrom<CancelProposal>(self, CancelProposal.store);
    }
}

/**
 > struct (0x54524605) CreateConfigProposal {
 >     newOwnerCount: uint8
 >     newPayoutThreshold: uint8
 >     newConfigThreshold: uint8
 >     newFeeReserve: coins
 >     newOwners: map<address, uint8>
 >     expiresAt: uint32
 > }
 */
export interface CreateConfigProposal {
    readonly $: 'CreateConfigProposal'
    newOwnerCount: uint8
    newPayoutThreshold: uint8
    newConfigThreshold: uint8
    newFeeReserve: coins
    newOwners: c.Dictionary<c.Address, uint8>
    expiresAt: uint32
}

export const CreateConfigProposal = {
    PREFIX: 0x54524605,

    create(args: {
        newOwnerCount: uint8
        newPayoutThreshold: uint8
        newConfigThreshold: uint8
        newFeeReserve: coins
        newOwners: c.Dictionary<c.Address, uint8>
        expiresAt: uint32
    }): CreateConfigProposal {
        return {
            $: 'CreateConfigProposal',
            ...args
        }
    },
    fromSlice(s: c.Slice): CreateConfigProposal {
        loadAndCheckPrefix32(s, 0x54524605, 'CreateConfigProposal');
        return {
            $: 'CreateConfigProposal',
            newOwnerCount: s.loadUintBig(8),
            newPayoutThreshold: s.loadUintBig(8),
            newConfigThreshold: s.loadUintBig(8),
            newFeeReserve: s.loadCoins(),
            newOwners: c.Dictionary.load<c.Address, uint8>(c.Dictionary.Keys.Address(), c.Dictionary.Values.BigUint(8), s),
            expiresAt: s.loadUintBig(32),
        }
    },
    store(self: CreateConfigProposal, b: c.Builder): void {
        b.storeUint(0x54524605, 32);
        b.storeUint(self.newOwnerCount, 8);
        b.storeUint(self.newPayoutThreshold, 8);
        b.storeUint(self.newConfigThreshold, 8);
        b.storeCoins(self.newFeeReserve);
        b.storeDict<c.Address, uint8>(self.newOwners, c.Dictionary.Keys.Address(), c.Dictionary.Values.BigUint(8));
        b.storeUint(self.expiresAt, 32);
    },
    toCell(self: CreateConfigProposal): c.Cell {
        return makeCellFrom<CreateConfigProposal>(self, CreateConfigProposal.store);
    }
}

// ————————————————————————————————————————————
//    class Treasury
//

interface ExtraSendOptions {
    bounce?: boolean                    // default: false
    sendMode?: SendMode                 // default: SendMode.PAY_GAS_SEPARATELY
    extraCurrencies?: c.ExtraCurrency   // default: empty dict
}

interface DeployedAddrOptions {
    workchain?: number                  // default: 0 (basechain)
    toShard?: { fixedPrefixLength: number; closeTo: c.Address }
    overrideContractCode?: c.Cell
}

function calculateDeployedAddress(code: c.Cell, data: c.Cell, options: DeployedAddrOptions): c.Address {
    const stateInitCell = beginCell().store(c.storeStateInit({
        code,
        data,
        splitDepth: options.toShard?.fixedPrefixLength,
        special: null,
        libraries: null,
    })).endCell();

    let addrHash = stateInitCell.hash();
    if (options.toShard) {
        const shardDepth = options.toShard.fixedPrefixLength;
        addrHash = beginCell()
            .storeBits(new c.BitString(options.toShard.closeTo.hash, 0, shardDepth))
            .storeBits(new c.BitString(stateInitCell.hash(), shardDepth, 256 - shardDepth))
            .endCell()
            .beginParse().loadBuffer(32);
    }

    return new c.Address(options.workchain ?? 0, addrHash);
}

export class Treasury implements c.Contract {
    static CodeCell = c.Cell.fromBase64('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');

    static Errors = {
        'Errors.NotOwner': 128,
        'Errors.InvalidMessage': 129,
        'Errors.InvalidOwnerCount': 130,
        'Errors.DuplicateOwner': 131,
        'Errors.InvalidRecipient': 133,
        'Errors.InvalidAmount': 134,
        'Errors.InvalidExpiry': 135,
        'Errors.ProposalNotFound': 136,
        'Errors.ProposalNotPending': 137,
        'Errors.ProposalExpired': 138,
        'Errors.AlreadyApproved': 139,
        'Errors.ThresholdNotReached': 140,
        'Errors.AlreadyExecutable': 141,
        'Errors.InsufficientBalance': 142,
        'Errors.NotCreator': 143,
        'Errors.InsufficientMessageValue': 144,
        'Errors.InvalidPayoutThreshold': 145,
        'Errors.InvalidConfigThreshold': 146,
        'Errors.ConfigThresholdLocked': 147,
        'Errors.InvalidFeeReserve': 148,
        'Errors.ProposalStale': 149,
        'Errors.InvalidProposalKind': 150,
    }

    readonly address: c.Address
    readonly init: { code: c.Cell, data: c.Cell } | undefined

    protected constructor(address: c.Address, init?: { code: c.Cell, data: c.Cell }) {
        this.address = address;
        this.init = init;
    }

    static fromAddress(address: c.Address) {
        return new Treasury(address);
    }

    static fromStorage(emptyStorage: {
        ownerCount: uint8
        payoutThreshold: uint8
        configThreshold: uint8
        configThresholdMutable: boolean
        configVersion: uint32
        proposalSeqno: uint64
        retainedProposalCount: uint16
        feeReserve: coins
        owners: c.Dictionary<c.Address, uint8>
        proposals: c.Dictionary<uint64, CellRef<Proposal>>
        approvals: c.Dictionary<uint256, uint8>
    }, deployedOptions?: DeployedAddrOptions) {
        const initialState = {
            code: deployedOptions?.overrideContractCode ?? Treasury.CodeCell,
            data: Storage.toCell(Storage.create(emptyStorage)),
        };
        const address = calculateDeployedAddress(initialState.code, initialState.data, deployedOptions ?? {});
        return new Treasury(address, initialState);
    }

    static createCellOfCreatePayoutProposal(body: {
        recipient: c.Address
        amount: coins
        expiresAt: uint32
    }) {
        return CreatePayoutProposal.toCell(CreatePayoutProposal.create(body));
    }

    static createCellOfApproveProposal(body: {
        proposalId: uint64
    }) {
        return ApproveProposal.toCell(ApproveProposal.create(body));
    }

    static createCellOfExecuteProposal(body: {
        proposalId: uint64
    }) {
        return ExecuteProposal.toCell(ExecuteProposal.create(body));
    }

    static createCellOfCancelProposal(body: {
        proposalId: uint64
    }) {
        return CancelProposal.toCell(CancelProposal.create(body));
    }

    static createCellOfCreateConfigProposal(body: {
        newOwnerCount: uint8
        newPayoutThreshold: uint8
        newConfigThreshold: uint8
        newFeeReserve: coins
        newOwners: c.Dictionary<c.Address, uint8>
        expiresAt: uint32
    }) {
        return CreateConfigProposal.toCell(CreateConfigProposal.create(body));
    }

    async sendDeploy(provider: ContractProvider, via: Sender, msgValue: coins, extraOptions?: ExtraSendOptions) {
        return provider.internal(via, {
            value: msgValue,
            body: c.Cell.EMPTY,
            ...extraOptions
        });
    }

    async sendCreatePayoutProposal(provider: ContractProvider, via: Sender, msgValue: coins, body: {
        recipient: c.Address
        amount: coins
        expiresAt: uint32
    }, extraOptions?: ExtraSendOptions) {
        return provider.internal(via, {
            value: msgValue,
            body: CreatePayoutProposal.toCell(CreatePayoutProposal.create(body)),
            ...extraOptions
        });
    }

    async sendApproveProposal(provider: ContractProvider, via: Sender, msgValue: coins, body: {
        proposalId: uint64
    }, extraOptions?: ExtraSendOptions) {
        return provider.internal(via, {
            value: msgValue,
            body: ApproveProposal.toCell(ApproveProposal.create(body)),
            ...extraOptions
        });
    }

    async sendExecuteProposal(provider: ContractProvider, via: Sender, msgValue: coins, body: {
        proposalId: uint64
    }, extraOptions?: ExtraSendOptions) {
        return provider.internal(via, {
            value: msgValue,
            body: ExecuteProposal.toCell(ExecuteProposal.create(body)),
            ...extraOptions
        });
    }

    async sendCancelProposal(provider: ContractProvider, via: Sender, msgValue: coins, body: {
        proposalId: uint64
    }, extraOptions?: ExtraSendOptions) {
        return provider.internal(via, {
            value: msgValue,
            body: CancelProposal.toCell(CancelProposal.create(body)),
            ...extraOptions
        });
    }

    async sendCreateConfigProposal(provider: ContractProvider, via: Sender, msgValue: coins, body: {
        newOwnerCount: uint8
        newPayoutThreshold: uint8
        newConfigThreshold: uint8
        newFeeReserve: coins
        newOwners: c.Dictionary<c.Address, uint8>
        expiresAt: uint32
    }, extraOptions?: ExtraSendOptions) {
        return provider.internal(via, {
            value: msgValue,
            body: CreateConfigProposal.toCell(CreateConfigProposal.create(body)),
            ...extraOptions
        });
    }

    async getOwnerCount(provider: ContractProvider): Promise<uint8> {
        const r = StackReader.fromGetMethod(1, await provider.get('owner_count', []));
        return r.readBigInt();
    }

    async getPayoutThreshold(provider: ContractProvider): Promise<uint8> {
        const r = StackReader.fromGetMethod(1, await provider.get('payout_threshold', []));
        return r.readBigInt();
    }

    async getConfigThreshold(provider: ContractProvider): Promise<uint8> {
        const r = StackReader.fromGetMethod(1, await provider.get('config_threshold', []));
        return r.readBigInt();
    }

    async getConfigThresholdMutable(provider: ContractProvider): Promise<boolean> {
        const r = StackReader.fromGetMethod(1, await provider.get('config_threshold_mutable', []));
        return r.readBoolean();
    }

    async getConfigVersion(provider: ContractProvider): Promise<uint32> {
        const r = StackReader.fromGetMethod(1, await provider.get('config_version', []));
        return r.readBigInt();
    }

    async getProposalSeqno(provider: ContractProvider): Promise<uint64> {
        const r = StackReader.fromGetMethod(1, await provider.get('proposal_seqno', []));
        return r.readBigInt();
    }

    async getFeeReserve(provider: ContractProvider): Promise<coins> {
        const r = StackReader.fromGetMethod(1, await provider.get('fee_reserve', []));
        return r.readBigInt();
    }

    async getIsOwner(provider: ContractProvider, owner: c.Address): Promise<boolean> {
        const r = StackReader.fromGetMethod(1, await provider.get('is_owner', [
            { type: 'slice', cell: makeCellFrom<c.Address>(owner,
                (v,b) => b.storeAddress(v)
            ) },
        ]));
        return r.readBoolean();
    }

    async getProposal(provider: ContractProvider, proposalId: uint64): Promise<ProposalView> {
        const r = StackReader.fromGetMethod(18, await provider.get('proposal', [
            { type: 'int', value: proposalId },
        ]));
        return ({
            $: 'ProposalView',
            id: r.readBigInt(),
            kind: r.readBigInt(),
            creator: r.readSlice().loadAddress(),
            createdAt: r.readBigInt(),
            expiresAt: r.readBigInt(),
            configVersionAtCreation: r.readBigInt(),
            currentConfigVersion: r.readBigInt(),
            status: r.readBigInt(),
            approvalCount: r.readBigInt(),
            requiredApprovalCount: r.readBigInt(),
            payoutRecipient: r.readSlice().loadAddress(),
            payoutAmount: r.readBigInt(),
            recipient: r.readSlice().loadAddress(),
            amount: r.readBigInt(),
            newOwnerCount: r.readBigInt(),
            newPayoutThreshold: r.readBigInt(),
            newConfigThreshold: r.readBigInt(),
            newFeeReserve: r.readBigInt(),
        });
    }

    async getProposalKind(provider: ContractProvider, proposalId: uint64): Promise<ProposalKind> {
        const r = StackReader.fromGetMethod(1, await provider.get('proposal_kind', [
            { type: 'int', value: proposalId },
        ]));
        return r.readBigInt();
    }

    async getProposalRequiredThreshold(provider: ContractProvider, proposalId: uint64): Promise<uint8> {
        const r = StackReader.fromGetMethod(1, await provider.get('proposal_required_threshold', [
            { type: 'int', value: proposalId },
        ]));
        return r.readBigInt();
    }

    async getProposalConfigOwners(provider: ContractProvider, proposalId: uint64): Promise<c.Dictionary<c.Address, uint8>> {
        const r = StackReader.fromGetMethod(1, await provider.get('proposal_config_owners', [
            { type: 'int', value: proposalId },
        ]));
        return r.readDictionary<c.Address, uint8>(c.Dictionary.Keys.Address(), c.Dictionary.Values.BigUint(8));
    }

    async getHasApproval(provider: ContractProvider, proposalId: uint64, owner: c.Address): Promise<boolean> {
        const r = StackReader.fromGetMethod(1, await provider.get('has_approval', [
            { type: 'int', value: proposalId },
            { type: 'slice', cell: makeCellFrom<c.Address>(owner,
                (v,b) => b.storeAddress(v)
            ) },
        ]));
        return r.readBoolean();
    }
}
