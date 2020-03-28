require('truffle-test-utils').init();
var NavigableMap = artifacts.require("./NavigableMap.sol");

contract("NavigableMap", function(accounts) {
    var gunplaInstance;

    it("initializes navigable map: two mechas, three waypoints", function() {
        return NavigableMap.deployed().then(function(instance) {
            gunplaInstance = instance;
            return instance.armyCounter();
        }).then(function(count) {
            assert.equal(count, 2);
            return gunplaInstance.waypointCounter();
        }).then(function(count) {
            assert.equal(count, 3);
            return gunplaInstance.mecha_positions(0);
        }).then(function(pos) {
            assert.equal(pos[0], -500000);
            assert.equal(pos[1], 0);
            assert.equal(pos[2], 0);
            return gunplaInstance.mecha_positions(1);
        }).then(function(pos) {
            assert.equal(pos[0], 500000);
            assert.equal(pos[1], 0);
            assert.equal(pos[2], 0);
        });
    });

    it("Add an order to a mecha", function() {
        return NavigableMap.deployed().then(function(instance) {
            gunplaInstance = instance;
            return gunplaInstance.addCommand(0, "FLY TO WAYPOINT", "Center");
        }).then(function(commandres) {
            assert.web3Event(commandres, { event: 'CommandReceived', args: { "0":0, "__length__": 1, mecha: 0 } }, 'CommandReceived event emitted');
            return gunplaInstance.commands(0);
        }).then(function(command) {
            assert.equal(command, "FLY TO WAYPOINT");
        });
    });

    it("Add an order to the second mecha - all mechas not in waiting", function() {
        return NavigableMap.deployed().then(function(instance) {
            gunplaInstance = instance;
            return gunplaInstance.addCommand(1, "FLY TO WAYPOINT", "Center");
        }).then(function(commandres) {
            assert.web3Event(commandres, { event: 'CommandReceived', args: { "0":1, "__length__": 1, mecha: 1 } }, 'CommandReceived event emitted');
            return gunplaInstance.commands(1);
        }).then(function(command) {
            assert.equal(command, "FLY TO WAYPOINT");
            return gunplaInstance.mecha_positions(0);
        }).then(function(pos) {
            assert.equal(pos[0], -499999);
            assert.equal(pos[1], 0);
            assert.equal(pos[2], 0);
            return gunplaInstance.mecha_positions(1);
        }).then(function(pos) {
            assert.equal(pos[0], 499999);
            assert.equal(pos[1], 0);
            assert.equal(pos[2], 0);
        });
    });

 
});

