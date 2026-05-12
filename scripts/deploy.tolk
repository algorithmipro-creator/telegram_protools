import "@acton/build"
import "@acton/io"
import "@acton/emulation/network"
import "@acton/emulation/scripts"

import "@contracts/types"

fun main() {
    val ownerA = scripts.wallet("ownerA");
    val ownerB = scripts.wallet("ownerB");

    var owners: map<address, uint8> = [];
    owners.set(ownerA.address, OWNER_KEY_VALUE);
    owners.set(ownerB.address, OWNER_KEY_VALUE);

    val ownerCount: uint8 = 2;
    val threshold: uint8 = 2;
    val stateInit = ContractState {
        code: build("Treasury"),
        data: Storage {
            ownerCount,
            threshold,
            proposalSeqno: 0,
            feeReserve: DEFAULT_FEE_RESERVE,
            owners,
            proposals: [],
            approvals: [],
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
    println("Threshold: {}", threshold);
    println("Fee reserve: {:ton}", DEFAULT_FEE_RESERVE);
}
