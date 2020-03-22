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
        })
    });

    it("Add an order to a mecha", function() {
        return NavigableMap.deployed().then(function(instance) {
            gunplaInstance = instance;
            gunplaInstance.addCommand(0, "FLY TO WAYPOINT Center");
            return gunplaInstance.commands(0);
        }).then(function(command) {
            assert.equal(command, "FLY TO WAYPOINT Center");
        })
    });
});

