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
}

// ————————————————————————————————————————————
//   auto-generated serializers to/from cells
//

type coins = bigint

type uint8 = bigint
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
 > enum ProposalViewStatus { 5 variants }
 */
export type ProposalViewStatus = bigint

export const ProposalViewStatus = {
    Pending: 0n,
    Executable: 1n,
    Executed: 2n,
    Cancelled: 3n,
    Expired: 4n,

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
 > struct PayoutProposal {
 >     id: uint64
 >     creator: address
 >     recipient: address
 >     amount: coins
 >     createdAt: uint32
 >     expiresAt: uint32
 >     status: ProposalStatus
 >     approvalCount: uint8
 > }
 */
export interface PayoutProposal {
    readonly $: 'PayoutProposal'
    id: uint64
    creator: c.Address
    recipient: c.Address
    amount: coins
    createdAt: uint32
    expiresAt: uint32
    status: ProposalStatus
    approvalCount: uint8
}

export const PayoutProposal = {
    create(args: {
        id: uint64
        creator: c.Address
        recipient: c.Address
        amount: coins
        createdAt: uint32
        expiresAt: uint32
        status: ProposalStatus
        approvalCount: uint8
    }): PayoutProposal {
        return {
            $: 'PayoutProposal',
            ...args
        }
    },
    fromSlice(s: c.Slice): PayoutProposal {
        return {
            $: 'PayoutProposal',
            id: s.loadUintBig(64),
            creator: s.loadAddress(),
            recipient: s.loadAddress(),
            amount: s.loadCoins(),
            createdAt: s.loadUintBig(32),
            expiresAt: s.loadUintBig(32),
            status: ProposalStatus.fromSlice(s),
            approvalCount: s.loadUintBig(8),
        }
    },
    store(self: PayoutProposal, b: c.Builder): void {
        b.storeUint(self.id, 64);
        b.storeAddress(self.creator);
        b.storeAddress(self.recipient);
        b.storeCoins(self.amount);
        b.storeUint(self.createdAt, 32);
        b.storeUint(self.expiresAt, 32);
        ProposalStatus.store(self.status, b);
        b.storeUint(self.approvalCount, 8);
    },
    toCell(self: PayoutProposal): c.Cell {
        return makeCellFrom<PayoutProposal>(self, PayoutProposal.store);
    }
}

/**
 > struct ProposalView {
 >     id: uint64
 >     creator: address
 >     recipient: address
 >     amount: coins
 >     createdAt: uint32
 >     expiresAt: uint32
 >     status: ProposalViewStatus
 >     approvalCount: uint8
 > }
 */
export interface ProposalView {
    readonly $: 'ProposalView'
    id: uint64
    creator: c.Address
    recipient: c.Address
    amount: coins
    createdAt: uint32
    expiresAt: uint32
    status: ProposalViewStatus
    approvalCount: uint8
}

export const ProposalView = {
    create(args: {
        id: uint64
        creator: c.Address
        recipient: c.Address
        amount: coins
        createdAt: uint32
        expiresAt: uint32
        status: ProposalViewStatus
        approvalCount: uint8
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
            creator: s.loadAddress(),
            recipient: s.loadAddress(),
            amount: s.loadCoins(),
            createdAt: s.loadUintBig(32),
            expiresAt: s.loadUintBig(32),
            status: ProposalViewStatus.fromSlice(s),
            approvalCount: s.loadUintBig(8),
        }
    },
    store(self: ProposalView, b: c.Builder): void {
        b.storeUint(self.id, 64);
        b.storeAddress(self.creator);
        b.storeAddress(self.recipient);
        b.storeCoins(self.amount);
        b.storeUint(self.createdAt, 32);
        b.storeUint(self.expiresAt, 32);
        ProposalViewStatus.store(self.status, b);
        b.storeUint(self.approvalCount, 8);
    },
    toCell(self: ProposalView): c.Cell {
        return makeCellFrom<ProposalView>(self, ProposalView.store);
    }
}

/**
 > struct Storage {
 >     ownerCount: uint8
 >     threshold: uint8
 >     proposalSeqno: uint64
 >     feeReserve: coins
 >     owners: map<address, uint8>
 >     proposals: map<uint64, Cell<PayoutProposal>>
 >     approvals: map<uint256, uint8>
 > }
 */
export interface Storage {
    readonly $: 'Storage'
    ownerCount: uint8
    threshold: uint8
    proposalSeqno: uint64
    feeReserve: coins
    owners: c.Dictionary<c.Address, uint8>
    proposals: c.Dictionary<uint64, CellRef<PayoutProposal>>
    approvals: c.Dictionary<uint256, uint8>
}

export const Storage = {
    create(args: {
        ownerCount: uint8
        threshold: uint8
        proposalSeqno: uint64
        feeReserve: coins
        owners: c.Dictionary<c.Address, uint8>
        proposals: c.Dictionary<uint64, CellRef<PayoutProposal>>
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
            threshold: s.loadUintBig(8),
            proposalSeqno: s.loadUintBig(64),
            feeReserve: s.loadCoins(),
            owners: c.Dictionary.load<c.Address, uint8>(c.Dictionary.Keys.Address(), c.Dictionary.Values.BigUint(8), s),
            proposals: c.Dictionary.load<uint64, CellRef<PayoutProposal>>(c.Dictionary.Keys.BigUint(64), createDictionaryValue<CellRef<PayoutProposal>>(
                (s) => loadCellRef<PayoutProposal>(s, PayoutProposal.fromSlice),
                (v,b) => storeCellRef<PayoutProposal>(v, b, PayoutProposal.store)
            ), s),
            approvals: c.Dictionary.load<uint256, uint8>(c.Dictionary.Keys.BigUint(256), c.Dictionary.Values.BigUint(8), s),
        }
    },
    store(self: Storage, b: c.Builder): void {
        b.storeUint(self.ownerCount, 8);
        b.storeUint(self.threshold, 8);
        b.storeUint(self.proposalSeqno, 64);
        b.storeCoins(self.feeReserve);
        b.storeDict<c.Address, uint8>(self.owners, c.Dictionary.Keys.Address(), c.Dictionary.Values.BigUint(8));
        b.storeDict<uint64, CellRef<PayoutProposal>>(self.proposals, c.Dictionary.Keys.BigUint(64), createDictionaryValue<CellRef<PayoutProposal>>(
            (s) => loadCellRef<PayoutProposal>(s, PayoutProposal.fromSlice),
            (v,b) => storeCellRef<PayoutProposal>(v, b, PayoutProposal.store)
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
    static CodeCell = c.Cell.fromBase64('te6ccgECHQEABH0AART/APSkE/S88sgLAQIBYgIDAgLOBAUCASAREgIBIAYHAEFGxENCHAAZNfBHLgAcACk18Dc+D4I1i+klt04LuRceBwgEUT4kZEw4CDXLCKikjAM4wLXLCKikjAU4wLXLCKikjAc4wLXLCKikjAkgCAkKCwB3BAkXwQiwgHy4IIiwQvy4IJwIYEBC/SCb6UykQGcAaRREoEBC/R0b6Uy6DAxIrry4IMgwgDy4IS+8uCEgAf4x7UTQ0wfTB9M/+gD0BPQE9AVUdlRUdlQm8AH4l4IK+vCAvvLgkPiSI4EBC/QKb6Ex8uCA+CMI+kj6ANcLH/goI8cF8tCFIcIA8uCGUwq88uCHKoIIJ40AoCG+8uCH+JIoyMs/+lIT+lIB+gIZyx8Yyx/PiAAGyVJCgED0F/iSDAH+Me1E0NMH0wfTP/oA9AT0BPQFVHZUVHZUJvAB+JeCCvrwgL7y4JD4kiOBAQv0Cm+hMfLggAfXCz9TAYBA9A/y4IjQ0z/6SPpI+gDTH9Mf0wchwgLyRdMH0SHy0In4IyO+8tCK+JIpyMs/+lL5FiBWEYMH9A5voTHy0IvIz4QGAg0B/jHtRNDTB9MH0z/6APQE9AQg9AVUZ3BUZ3BUZ3DwAfiXggr68IC+8uCQ+JIjgQEL9ApvoTHy4IAH1ws/UwGAQPQP8uCI0NM/+kj6SPoA0x/TH9MHIcIC8kXTB9EB8tCJ+CMivvLQilMMvvLgjPgnbxD4l6FTS6C+8uCOBsjLPxUOATbjAjDHAPLgge1E0NMH0wfTP/oA9AT0BPQF8AEPAFgkyMs/+lL5FsjPhAZAGIMH9EMDpAXIywcUywcUyz9QA/oC9AAS9AD0AMntVAByERGDB/RDD6QHyMs/FvpSFPpSWPoCyx/LH8sHywfJAoBA9BcFyMsHFMsHEss/AfoC9AD0APQAye1UAIb6UlIw+lIi+gLLHxPLH8+EBhPLB8lANIBA9BcHyMsHFssHFMs/WPoC9AAT9AATzsntVMjPhQj6UgH6AnDPC2rJcfsAAf4x7UTQ0wfTB9M/+gD0BPQEIPQFVGdwVGdwVGdw8AH4l4IK+vCAvvLgkPiSI4EBC/QKb6Ex8uCAB9cLP1MBgED0D/LgiNDTP/pI+kj6ANMf0x/TByHCAvJF0wfRAfLQifgjIr7y0Ir4kibHBfLgj1MMufLgjQbIyz8V+lIT+lIBEABM+gLLH8sfz4QKywfJAoBA9BcFyMsHFMsHEss/AfoC9AD0AM7J7VQCAVgTFAIBIBcYAgFIFRYAK7cbHaiaGmnmP0AGPoCwICF+gU30JjAAQ65S9qJoaaeY/QAY+gD6APoCgWRln/0pfIsAwYP6BzfQmMAAi60jdqJoaYOY6YPpn5j9ABj6APoCiUAgegf5cERoaZ/9JH0kfQBpj+mP6YOQ4QF5IumD6JOqI5gTqiOYE6ojmCkH+AEqg0AAF7prftRNDTBzHXCweAIBIBkaAgFmGxwAEbTLXaiaGuFg8AAWqf/tRNDTDzHXCz8AFqm/7UTQ008x+gAw');

    static Errors = {
        'Errors.NotOwner': 128,
        'Errors.InvalidMessage': 129,
        'Errors.InvalidOwnerCount': 130,
        'Errors.DuplicateOwner': 131,
        'Errors.InvalidThreshold': 132,
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
        threshold: uint8
        proposalSeqno: uint64
        feeReserve: coins
        owners: c.Dictionary<c.Address, uint8>
        proposals: c.Dictionary<uint64, CellRef<PayoutProposal>>
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

    async getOwnerCount(provider: ContractProvider): Promise<uint8> {
        const r = StackReader.fromGetMethod(1, await provider.get('owner_count', []));
        return r.readBigInt();
    }

    async getThreshold(provider: ContractProvider): Promise<uint8> {
        const r = StackReader.fromGetMethod(1, await provider.get('threshold', []));
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
        const r = StackReader.fromGetMethod(8, await provider.get('proposal', [
            { type: 'int', value: proposalId },
        ]));
        return ({
            $: 'ProposalView',
            id: r.readBigInt(),
            creator: r.readSlice().loadAddress(),
            recipient: r.readSlice().loadAddress(),
            amount: r.readBigInt(),
            createdAt: r.readBigInt(),
            expiresAt: r.readBigInt(),
            status: r.readBigInt(),
            approvalCount: r.readBigInt(),
        });
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
