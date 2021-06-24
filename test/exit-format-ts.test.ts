const { expect } = require("chai");
import { encodeAllocations, encodeExit } from "../src/coders";
import { Allocation, Exit } from "../src/types";

describe("ExitFormat (typescript)", function () {
  it("Can encode an allocation", async function () {
    const allocation: Allocation = {
      destination: "0x96f7123E3A80C9813eF50213ADEd0e4511CB820f",
      amount: "0x01",
      callTo: "0x0000000000000000000000000000000000000000",
      metadata: "0x",
    };
    const encodedAllocation = encodeAllocations(allocation);
    // console.log(`Encoded Allocation: ${encodedAllocation}`)


    expect(encodedAllocation).to.eq(
      "0x000000000000000000000000000000000000000000000000000000000000002000000000000000000000000096f7123e3a80c9813ef50213aded0e4511cb820f0000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000000"
    );
  });

  it("Can encode an exit", async function () {
    const exit: Exit = [
      {
        asset: "0x0000000000000000000000000000000000000000",
        metadata: "0x",
        allocations: [
          {
            destination: "0x96f7123E3A80C9813eF50213ADEd0e4511CB820f",
            amount: "0x01",
            callTo: "0x0000000000000000000000000000000000000000",
            metadata: "0x",
          },
        ],
      },
    ];
    const encodedExit = encodeExit(exit);
    // console.log(`Encoded Exit: ${encodedExit}`)

    expect(encodedExit).to.eq(
      "0x00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000096f7123e3a80c9813ef50213aded0e4511cb820f0000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000000"
    );
  });
});
