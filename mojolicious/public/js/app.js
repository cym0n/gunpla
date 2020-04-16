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
                App.renderMechaTemplate(m, true);  
                App.getLastEvent(m.name, false);
            });
        });
  },
  renderMechaTemplate: function(m, poll_needed) {
    $('#mecha_' + m.name).append('<p>'+ m.name + ' (' + m.faction + ')<br />[' + m.position.x +', '+ m.position.y +', '+ m.position.z + ']<br />Life: '+ m.life + '</p>');
    if(m.waiting)
    {
        $('#mecha_' + m.name).append(`
         <div class="well">
         <form onSubmit="App.addCommand(this); return false;" id="comms_${m.name}">
            <input type="hidden" name="mechaname" value="${m.name}">
            <div class="form-group">
                <label for="commands">Select Command</label>
                <select class="form-control" id="maincommands_${m.name}" name="commands" onchange="App.commandParams(this, '${m.name}')">
                    <option value="">Select...</option>
                </select>
            </div>
            <div class="form-group">
            </div>
            <div class="form-group">
            <button type="submit" class="btn btn-primary">Submit</button>
            </div>
        </form></div>`);
        fetch('/game/available-commands?game='+App.game+'&mecha='+m.name)
        .then(function(response) { return response.json(); })
        .then(function(data) { 
            data.commands.forEach(function(c, index, array) {
                $( "#maincommands_"+m.name).append('<option value="'+c.code+'">'+c.label+'</option>');
            });
        });
        fetch('/game/command?game='+App.game+'&mecha='+m.name+'&prev=1')
        .then(function(response) { return response.json(); })
        .then(function(data) { 
            if(data.command.command)
            {
                var previous;
                if(data.command.secondarycommand)
                {
                    previous = data.command.command +' '+ data.command.params+' ['+
                               data.command.secondarycommand + ' ' + data.command.secondaryparams +']';
                }
                else
                {
                    previous = data.command.command +' '+ data.command.params;
                }


                $('#mecha_' + m.name).append(`
                    <div class="well">
                    <form onSubmit="App.resumeCommand(this); return false;" id="prevcomms_${m.name}">
                        <input type="hidden" name="mechaname" value="${m.name}">
                        <input type="hidden" name="command" value="${data.command.command}">
                        <input type="hidden" name="params" value="${data.command.params}">
                        <input type="hidden" name="secondarycommand" value="${data.command.secondarycommand}">
                        <input type="hidden" name="secondaryparams" value="${data.command.secondaryparams}">
                        <p><b>Previous command</b>:<br />${previous}</p>
                        <button name="resume" type="submit" class="btn btn-primary">Resume</button>
                    </form></div>`);
            }
        });

    }
    else
    {
        fetch('/game/command?game='+App.game+'&mecha='+m.name)
        .then(function(response) { return response.json(); })
        .then(function(data) { 
            if(data.command.secondarycommand)
            {
                previous =  data.command.command +' '+ data.command.params+' ['+
                            data.command.secondarycommand + ' ' + data.command.secondaryparams +']';
            }
            else
            {
                previous =  data.command.command +' '+ data.command.params;
            }
            $('#mecha_' + data.command.mecha).append('<div class="well"><b>Previous command</b>:<br />'+previous+'</div>');
        });
        if(poll_needed)
        {
            poll(function() {
                return fetch('/game/mechas?game='+App.game+'&mecha='+m.name)
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
                App.renderMechaTemplate(m, poll);  
            });
        });
  },
  refreshMecha : function(name, poll) {
    $('#mecha_'+name).empty();
    fetch('/game/mechas?game='+App.game+'&mecha='+name)
    .then(function(response) { return response.json(); })
    .then(function(data) { 
         App.renderMechaTemplate(data.mecha, poll);
    })
  },
  commandParams : function(select, name) {
    var paramDiv = $( select ).parent().next();
    paramDiv.empty();
    $('#'+name+'_machinegunform').remove()
    $('#'+name+'_velocityform').remove()
    var machinegun = 0;
    var masternode = '';
    fetch('/game/command-details?game='+App.game+'&mecha='+name+'&command='+select.value)
    .then(function(response) { return response.json(); })
    .then(function(data) {
        machinegun = data.command.machinegun;
        masternode = data.command.params_masternode;
        paramDiv.append('<lable for="params_'+name+'>'+data.command.params_label+'</label>');
        paramDiv.append('<div class="form-group"><select class="form-control" name="params_'+name+'" id="params_'+name+'"></select></div>');
        fetch(data.command.params_callback).then(function(response) { return response.json(); })
        .then(function(data) {
            data[masternode].forEach(function(d, index, array) {
                $( "#params_"+name).append('<option value="'+d.world_id+'">'+d.label+'</option>');
            });
        });
        if(data.command.machinegun == 1)
        { 
            App.machinegunForm(name, paramDiv);
        }
        if(data.command.velocity == 1)
        {
            App.velocityForm(name, paramDiv);
        }
    });
  },
  velocityForm : function(name, div) {
    fetch('/game/mechas?game='+App.game+'&mecha='+name)
    .then(function(response) { return response.json(); })
    .then(function(data) { 
        var form = '<div class="form-group row" id="'+name+'_velocityform">'+
                        '<label class="col-sm-8">Velocity</label>'+
                        '<div class="col-sm-12">';
        for (i = 1; i <= data.mecha.max_velocity; i++) {
            checked = '';
            if(i == data.mecha.velocity)
            {
                checked = 'checked';
            }
            form = form +
                '<label class="radio-inline"> <input type="radio" name="velocity" id="velocity'+i+'" value="'+i+'" '+checked+'>'+i+'</label>';
        }
        form = form + '</div></div>';
    $(form).insertAfter(div); });
  },
  machinegunForm : function(name, div) {
    $(`
        <div class="form-group" id="${name}_machinegunform">
        <div class="form-check">
        <input type="checkbox" class="form-check-input" id="machinegun" name="machinegun">
        <label class="form-check-label" for="machinegun">Fire machinegun</label>
        </div>
        <label for="target">Select Mecha</label>
        <select class="form-control" name="secondarytarget" id="secparams_${name}"></select>
        </div>
    `).insertAfter(div);
     fetch('/game/sighted?game='+App.game+'&mecha='+name)
        .then(function(response) { return response.json(); })
        .then(function(data) {
            console.log("populate " + name);
            data.mechas.forEach(function(m, index, array) {
                $( "#secparams_"+name).append('<option value="'+m.name+'">'+m.name+'</option>');
            });
        });
  },
  addCommand : function(el) {
    var form = $( el )
    var mid = $( form.children('input[name="mechaname"]')).attr('value');
    var cmd = form.find('select[name="commands"]').children('option:selected').attr('value');
    var command;
    var params;
    var secondarycommand;
    var secondaryparams;
    var velocity;
    command = cmd;
    params = form.find('select[name="params_'+mid+'"]').children('option:selected').attr('value');
    if($( form.find('input[name="machinegun"]')).prop('checked'))
    {
        secondaryparams = form.find('select[name="secondarytarget"]').children('option:selected').attr('value');
        if(secondaryparams)
        {
            secondarycommand = 'machinegun';
        }
    }
    if($( form.find('input[name="velocity"]')))
    {
        velocity = $( form.find('input[name="velocity"]:checked')).val();
    }
    console.log("Adding command "+command+" with params "+params+" to mecha "+mid);
    fetch('/game/command', {
        method: 'post',
        body: JSON.stringify({
            'command': command,
            'params': params,
            'secondarycommand': secondarycommand,
            'secondaryparams': secondaryparams,
            'velocity': velocity,
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
    var command = $( form.children('input[name="command"]')).attr('value');
    var params = $( form.children('input[name="params"]')).attr('value');
    var secondarycommand = $( form.children('input[name="secondarycommand"]')).attr('value');
    var secondaryparams = $( form.children('input[name="secondaryparams"]')).attr('value');
    console.log("Adding command "+command+" with params "+params+" to mecha "+mid);
    fetch('/game/command', {
        method: 'post',
        body: JSON.stringify({
            'command': command,
            'params': params,
            'secondarycommand': secondarycommand,
            'secondaryparams': secondaryparams,
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
  $(window).on('load', (function() {
    App.init(game);
  }));
});
