App = {
  init: function() {
    console.log("Game is "+game);
    App.game = game;
    return App.render();
  },

  render: function() {
        $('#mechas').empty();
        fetch('/game/mechas?game='+App.game)
        .then(function(response) { return response.json(); })
        .then(function(data) { 
            data.mechas.forEach(function(m, index, array) {
                $('#mechas').append('<div class="well" id="mecha_' + m.name + '"></div>');
                App.renderMechaTemplate(m.name, m.faction, m.position, m.waiting);  
                App.getLastEvent(m.name);
            });
        });
  },
  renderMechaTemplate: function(name, faction, pos, waiting) {
    $('#mecha_' + name).append('<p>'+ name + ' (' + faction + ')<br />[' + pos.x +', '+pos.y +', '+pos.z + ']</p>');
    if(waiting)
    {
        $('#mecha_' + name).append(`
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
        </form>`);
    }
    else
    {
        fetch('/game/command?game='+App.game+'&mecha='+name)
        .then(function(response) { return response.json(); })
        .then(function(data) { 
            $('#mecha_' + data.command.mecha).append('<p>ORDERS GIVEN: ' + data.command.command + ' [' + data.command.params + ']</p>');
        });
        poll(function() {
                return fetch('/game/mechas?game='+App.game+'&mecha='+name)
                .then(function(response) { return response.json(); })
             },
             function(data) {
                return data.mecha.waiting == 1
             },
             3600000, 10000).then(function(data) { 
                App.refreshMecha(data.mecha.name); 
                App.getLastEvent(data.mecha.name); 
            });
    }
  },
  getLastEvent: function(name) {
    fetch('/game/event?game='+App.game+'&mecha='+name)
    .then(function(response) { return response.json(); })
    .then(function(data) { 
        if(data.event.message)
        {
            $('#events').prepend('<p>'+name+': '+data.event.message);
        }
    })
  },
  refreshMecha : function(name) {
    $('#mecha_'+name).empty();
    fetch('/game/mechas?game='+App.game+'&mecha='+name)
    .then(function(response) { return response.json(); })
    .then(function(data) { 
         App.renderMechaTemplate(data.mecha.name, data.mecha.faction, data.mecha.position, data.mecha.waiting);
    })
  },
  commandParams : function(select, name) {
    var paramDiv = $( select ).parent().next();
    paramDiv.empty();
    if(select.value == 'flywp')
    {
        paramDiv.append('<label for="waypoint">Select Waypoint</label>');
        paramDiv.append('<select class="form-control" name="waypoint" id="params_'+name+'"></select>');
        fetch('/game/waypoints?game='+App.game)
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
    var mid = $( form.children('input[name="mechaname"]')).attr('value');
    var cmd = form.find('select[name="commands"]').children('option:selected').attr('value');
    var command;
    var params;
    if(cmd == 'flywp')
    {
        var wp = form.find('select[name="waypoint"]').children('option:selected').attr('value');
        command = "FLY TO WAYPOINT";
        params = wp;
    }
    console.log("Adding command "+command+" with params "+params+" to mecha "+mid);
    fetch('/game/command', {
        method: 'post',
        body: JSON.stringify({
            'command': command,
            'params': params,
            'mecha': mid,
            'game': App.game })
    })
    .then(function(response) { return response.json(); })
    .then(function(data) { 
        App.refreshMecha(data.command.mecha)
    });
  }
};




$(function() {
//  $(window).load(function() {
  $(window).on('load', (function() {
    App.init(game);
  }));
});
