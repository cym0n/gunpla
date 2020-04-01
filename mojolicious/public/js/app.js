App = {
  init: function() {
    return App.render();
  },

  render: function() {
        $('#mechas').empty();
        fetch('/game/mechas?game=autotest')
        .then(function(response) { return response.json(); })
        .then(function(data) { console.log(data.mechas[0]); 
            data.mechas.forEach(function(m, index, array) {
                $('#mechas').append(App.mechaTemplate(index, m.name, m.faction, m.position, m.command));  
            });
        });
  },
  mechaTemplate: function(id, name, faction, pos, command) {
    var mechaview = '<div id="mecha_' + name + '"><p>'+ name + ' (' + faction + ')<br />[' + pos.x +', '+pos.y +', '+pos.z + ']</p>';
    if(command == '')
    {
        mechaview = mechaview +`
         <form onSubmit="App.addCommand(this); return false;" id="comms_${name}">
            <input type="hidden" name="mechaname" value="${name}">
            <div class="form-group">
                <label for="commands">Select Command</label>
                <select class="form-control" name="commands" onchange="App.commandParams(this, '${name}')">
                    <option value="">Select...</option>
                    <option value="flywp">FLY TO WAYPOINT</option>
                </select>
            </div>
            <div class="form-group">
            </div>
            <button type="submit" class="btn btn-primary">Submit</button>
            <hr />
        </form>`
    }
    else
    {
        mechaview = mechaview + '<p>ORDERS GIVEN: '+command+'</p>';
    }
    mechaview = mechaview +'</div> ';
    return mechaview;
  },
  commandParams : function(select, name) {
    var paramDiv = $( select ).parent().next();
    paramDiv.empty();
    if(select.value == 'flywp')
    {
        paramDiv.append('<label for="waypoint">Select Waypoint</label>');
        paramDiv.append('<select class="form-control" name="waypoint" id="params_'+name+'"></select>');
        fetch('/game/waypoints?game=autotest')
        .then(function(response) { return response.json(); })
        .then(function(data) {
            data.waypoints.forEach(function(wp, index, array) {
                $( "#params_"+name).append('<option value="'+wp.name+'">'+wp.name+'</option>');
            });
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
