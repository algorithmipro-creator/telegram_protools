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
 >     approvalMask: uint16
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
    approvalMask: uint16
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
        approvalMask: uint16
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
            approvalMask: s.loadUintBig(16),
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
        b.storeUint(self.approvalMask, 16);
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
 >     approvalMask: uint16
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
    approvalMask: uint16
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
        approvalMask: uint16
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
            approvalMask: s.loadUintBig(16),
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
        b.storeUint(self.approvalMask, 16);
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
        const r = StackReader.fromGetMethod(19, await provider.get('proposal', [
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
            approvalMask: r.readBigInt(),
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
