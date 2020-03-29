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
    var ethereum = window.ethereum;
    ethereum.enable().then(function()  { return App.initContract() });

  },
  initContract: function() {
    $.getJSON("NavigableMap.json", function(gunpla) {
      // Instantiate a new truffle contract from the artifact
      App.contracts.Gunpla = TruffleContract(gunpla);
      // Connect provider to interact with contract
      App.contracts.Gunpla.setProvider(App.web3Provider);
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
    }).then(function() { 
            gunplaInstance.CommandReceived().watch(function(error, result){ 
                console.log("Event recieved "+result.args.mecha);
                App.buildCommandsForm(result.args.mecha);
            });
            $('#mechas').empty(); })
      .then(function() { return gunplaInstance.armies(0)}).then(function(mecha) {
            $('#mechas').append(App.mechaTemplate(0, mecha[0], mecha[1])); 
            return gunplaInstance.mecha_positions(0); })
      .then(function(pos) {
            $('#mecha0').append(App.positionTemplate(pos));
            $('#mecha0').append('<div id="commpanel0"></div>'); 
            App.buildCommandsForm(0); })
      .then(function() { return gunplaInstance.armies(1)}).then(function(mecha) {
            $('#mechas').append(App.mechaTemplate(1, mecha[0], mecha[1])); 
            return gunplaInstance.mecha_positions(1); })
      .then(function(pos) {
            $('#mecha1').append(App.positionTemplate(pos));
            $('#mecha1').append('<div id="commpanel1"></div>'); 
            App.buildCommandsForm(1); })
  },
  mechaTemplate: function(id, name, faction) {
    return  '<p id="mecha' + id + '">'+ name + ' (' + faction + ')</p>';
  },
  positionTemplate: function(pos) {
    return  '<br />[' + pos[0] +', '+pos[1] +', '+pos[2] + ']';
  },
  buildCommandsForm: function(id) {
    var mid = id;
    App.contracts.Gunpla.deployed().then(function(instance) {
        gunplaInstance = instance;
    }).then(function() { return gunplaInstance.commands(mid) }).then(function(comm) {
        $( "#commpanel"+mid ).empty();
        if(comm)
        {
            $( "#commpanel"+mid ).append('<p>ORDERS GIVEN: '+comm+'</p>');
        }
        else
        {
            $( "#commpanel"+mid ).append(App.commandsForm(mid));
        }
    });
  },
  commandsForm : function(id) {
    return `
        <form onSubmit="App.addCommand(this); return false;" id="comms${id}">
            <input type="hidden" name="mechaid" value="${id}">
            <div class="form-group">
                <label for="commands">Select Command</label>
                <select class="form-control" name="commands" onchange="App.commandParams(this, ${id})">
                    <option value="">Select...</option>
                    <option value="flywp">FLY TO WAYPOINT</option>
                </select>
            </div>
            <div class="form-group">
            </div>
            <button type="submit" class="btn btn-primary">Submit</button>
            <hr />
        </form>`;  
  },
  commandParams : function(select, id) {
    var paramDiv = $( select ).parent().next();
    paramDiv.empty();
    if(select.value == 'flywp')
    {
        paramDiv.append('<label for="waypoint">Select Waypoint</label>');
        paramDiv.append('<select class="form-control" name="waypoint" id="params'+id+'"></select>');
        App.contracts.Gunpla.deployed().then(function(instance) {
            gunplaInstance = instance;
        }).then(function() { return gunplaInstance.waypointCounter() })
        .then(function(counter) {
             for (var i = 0; i < counter; i++) {
                gunplaInstance.wps_names(i).then(function(wp) {
                    $( "#params"+id).append('<option value="'+wp+'">'+wp+'</option>');
                });
            }
        });
    }
  },
  addCommand : function(el) {
    var form = $( el )
    var mid = $( form.children('input[name="mechaid"]')).attr('value');
    var cmd = form.find('select[name="commands"]').children('option:selected').attr('value');
    if(cmd == 'flywp')
    {
        var wp = form.find('select[name="waypoint"]').children('option:selected').attr('value');
        App.contracts.Gunpla.deployed().then(function(instance) {
            gunplaInstance = instance;
        }).then(function() { var command = "FLY TO WAYPOINT "+wp;
            console.log("Adding command "+command+" to mecha "+mid);
            gunplaInstance.addCommand(mid, "FLY TO WAYPOINT ", wp) })
        .then(function(result) {
            //Nothing to do, managed by event
        }).catch(function(err) {
            console.error(err);
        });
    }
  }

};




$(function() {
//  $(window).load(function() {
  $(window).on('load', (function() {
    App.init();
  }));
});
