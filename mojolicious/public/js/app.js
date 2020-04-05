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
                App.renderMechaTemplate(m.name, m.faction, m.position, m.waiting, true);  
                App.getLastEvent(m.name, false);
            });
        });
  },
  renderMechaTemplate: function(name, faction, pos, waiting, poll_needed) {
    $('#mecha_' + name).append('<p>'+ name + ' (' + faction + ')<br />[' + pos.x +', '+pos.y +', '+pos.z + ']</p>');
    if(waiting)
    {
        $('#mecha_' + name).append(`
         <div class="well">
         <form onSubmit="App.addCommand(this); return false;" id="comms_${name}">
            <input type="hidden" name="mechaname" value="${name}">
            <div class="form-group">
                <label for="commands">Select Command</label>
                <select class="form-control" name="commands" onchange="App.commandParams(this, '${name}')">
                    <option value="">Select...</option>
                    <option value="flywp">FLY TO WAYPOINT</option>
                    <option value="flymec">FLY TO MECHA</option>
                </select>
            </div>
            <div class="form-group">
            </div>
            <button type="submit" class="btn btn-primary">Submit</button>
        </form></div>`);
        fetch('/game/command?game='+App.game+'&mecha='+name+'&prev=1')
        .then(function(response) { return response.json(); })
        .then(function(data) { 
            if(data.command.command)
            {
                $('#mecha_' + name).append(`
                    <div class="well">
                    <form onSubmit="App.resumeCommand(this); return false;" id="prevcomms_${name}">
                        <input type="hidden" name="mechaname" value="${name}">
                        <input type="hidden" name="commands" value="${data.command.command}">
                        <input type="hidden" name="params" value="${data.command.params}">
                        <label for="resume">Previous command: ${data.command.command} [${data.command.params}]</label>
                        <button name="resume" type="submit" class="btn btn-primary">Resume</button>
                    </form></div>`);
            }
        });

    }
    else
    {
        fetch('/game/command?game='+App.game+'&mecha='+name)
        .then(function(response) { return response.json(); })
        .then(function(data) { 
            $('#mecha_' + data.command.mecha).append('<p>ORDERS GIVEN: ' + data.command.command + ' [' + data.command.params + ']</p>');
        });
        if(poll_needed)
        {
            poll(function() {
                return fetch('/game/mechas?game='+App.game+'&mecha='+name)
                .then(function(response) { return response.json(); })
                },
                function(data) {
                    return data.mecha.waiting == 1
                },
                3600000, 10000).then(function(data) { 
                    App.refreshAllMecha(); 
                    App.getLastEvent(data.mecha.name, true); 
            });
        }
    }
  },
  getLastEvent: function(name, highlight) {
    fetch('/game/event?game='+App.game+'&mecha='+name)
    .then(function(response) { return response.json(); })
    .then(function(data) { 
        var highlightclass="";
        if(highlight)
        {
            $('#events p').each(function(index) { $(this).removeClass("alert-danger").addClass("alert-secondary"); });
            highlightclass='class="alert alert-danger"';
        }
        else
        {
            highlightclass='class="alert alert-secondary"';
        }
        data.events.forEach(function(e, index, array) {
            var event_node = '<p '+highlightclass+'>'+name+': '+e.message+'</p>';
            console.log("Appending "+event_node);
            $('#events').prepend(event_node);
        })
    })
  },
  refreshAllMecha : function(to_poll) {
        fetch('/game/mechas?game='+App.game)
        .then(function(response) { return response.json(); })
        .then(function(data) { 
            data.mechas.forEach(function(m, index, array) {
                $('#mecha_'+m.name).empty();
                var poll = false;
                if(m.name == to_poll)
                {
                    poll = true;
                }
                App.renderMechaTemplate(m.name, m.faction, m.position, m.waiting, poll);  
            });
        });
  },
  refreshMecha : function(name, poll) {
    $('#mecha_'+name).empty();
    fetch('/game/mechas?game='+App.game+'&mecha='+name)
    .then(function(response) { return response.json(); })
    .then(function(data) { 
         App.renderMechaTemplate(data.mecha.name, data.mecha.faction, data.mecha.position, data.mecha.waiting, poll);
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
    else if(select.value == 'flymec')
    {
        paramDiv.append('<label for="target">Select Mecha</label>');
        paramDiv.append('<select class="form-control" name="target" id="params_'+name+'"></select>');
        fetch('/game/sighted?game='+App.game+'&mecha='+name)
        .then(function(response) { return response.json(); })
        .then(function(data) {
            data.mechas.forEach(function(m, index, array) {
                $( "#params_"+name).append('<option value="'+m.name+'">'+m.name+'</option>');
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
    else if(cmd == 'flymec')
    {
        var m = form.find('select[name="target"]').children('option:selected').attr('value');
        command = "FLY TO MECHA";
        params = m;
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
        App.refreshMecha(data.command.mecha, true)
    });
  },
  resumeCommand : function(el) {
    var form = $( el )
    var mid = $( form.children('input[name="mechaname"]')).attr('value');
    var command = $( form.children('input[name="commands"]')).attr('value');
    var params = $( form.children('input[name="params"]')).attr('value');
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
        App.refreshMecha(data.command.mecha, true)
    });
  } 
};




$(function() {
//  $(window).load(function() {
  $(window).on('load', (function() {
    App.init(game);
  }));
});
