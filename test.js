const test = require("node:test");
const assert = require("node:assert");

test("Demo fare must be a positive amount", () => {
    const fare = 50;
    assert.ok(fare > 0);
});

test("Pickup and drop locations must be provided", () => {
    const pickup = "Bangalore";
    const drop = "Whitefield";

    assert.ok(pickup.length > 0);
    assert.ok(drop.length > 0);
});
