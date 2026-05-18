import "@acton/build"
import "@acton/io"
import "@acton/emulation/network"
import "@acton/emulation/scripts"

import "@contracts/types"

fun main() {
    val ownerA = scripts.wallet("ownera");
    val ownerB = scripts.wallet("ownerb");

    var owners: map<address, uint8> = [];
    owners.set(ownerA.address, OWNER_INDEX_0);
    owners.set(ownerB.address, OWNER_INDEX_1);

    val ownerCount: uint8 = 2;
    val payoutThreshold: uint8 = 2;
    val configThreshold: uint8 = 2;
    val stateInit = ContractState {
        code: build("Treasury"),
        data: Storage {
            ownerCount,
            payoutThreshold,
            configThreshold,
            configThresholdMutable: false,
            configVersion: 0,
            proposalSeqno: 0,
            retainedProposalCount: 0,
            feeReserve: DEFAULT_FEE_RESERVE,
            owners,
            proposals: [],
        }.toCell(),
    };
    val address = AutoDeployAddress { stateInit }.calculateAddress();
    val deployMsg = createMessage({
        bounce: false,
        value: ton("1.00"),
        dest: { stateInit },
    });

    val res = net.send(ownerA.address, deployMsg);
    if (res.waitForFirstTransaction() == null) {
        println("Treasury deployment transaction was not observed");
        return;
    }

    println("TREASURY_ADDRESS={}", address);
    println("Owner count: {}", ownerCount);
    println("Payout threshold: {}", payoutThreshold);
    println("Config threshold: {}", configThreshold);
    println("Fee reserve: {:ton}", DEFAULT_FEE_RESERVE);
}
