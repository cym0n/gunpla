App = {
  web3Provider: null,
  contracts: {},
  account: '0x0',

  init: function() {
    return App.initWeb3();
  },

  initWeb3: function() {
    if (typeof web3 !== 'undefined') {
      // If a web3 instance is already provided by Meta Mask.
      App.web3Provider = web3.currentProvider;
      web3 = new Web3(web3.currentProvider);
    } else {
      // Specify default instance if no web3 instance provided
      App.web3Provider = new Web3.providers.HttpProvider('http://localhost:7545');
      web3 = new Web3(App.web3Provider);
    }
    return App.initContract();
  },
  initContract: function() {
    $.getJSON("NavigableMap.json", function(election) {
      // Instantiate a new truffle contract from the artifact
      App.contracts.Gunpla = TruffleContract(election);
      // Connect provider to interact with contract
      App.contracts.Gunpla.setProvider(App.web3Provider);
      console.log("Contract instantiated");
      return App.render();
    });
  },
  render: function() {
    var gunplaInstance;
    web3.eth.getCoinbase(function(err, account) {
      if (err === null) {
        App.account = account;
      }
    });
    // Load contract data
    App.contracts.Gunpla.deployed().then(function(instance) {
      gunplaInstance = instance;
    }).then(function() { $('#mechas').empty(); })
      .then(function() { return gunplaInstance.armies(0)}).then(function(mecha) {
            $('#mechas').append(App.mechaTemplate(0, mecha[0], mecha[1])); 
            return gunplaInstance.mecha_positions(mecha[0]); })
      .then(function(pos) {
            $('#mecha0').append(App.positionTemplate(pos)) })
      .then(function() { return gunplaInstance.armies(1)}).then(function(mecha) {
            $('#mechas').append(App.mechaTemplate(1, mecha[0], mecha[1])); 
            return gunplaInstance.mecha_positions(mecha[0]); })
      .then(function(pos) {
            $('#mecha1').append(App.positionTemplate(pos)) })
  },
  mechaTemplate: function(id, name, faction) {
        return  '<p id="mecha' + id + '">'+ name + ' (' + faction + ')</p>';
  },
  positionTemplate: function(pos) {
        return  '<br />[' + pos[0] +', '+pos[1] +', '+pos[2] + ']';
  }

};




$(function() {
//  $(window).load(function() {
  $(window).on('load', (function() {
    App.init();
  }));
});
