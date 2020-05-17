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
        poll(function() {
            return fetch('/game/traffic-light?game='+App.game)
                .then(function(response) { return response.json(); })
            },
            function(data) {
                return ! $('#trafficlight').hasClass("light"+data.status)
            },
            3600000, 10000).then(function(data) { 
                App.updateTrafficLight(data.status); 
            })
  },
  updateTrafficLight: function(status) {
    var tl = $('#trafficlight');
    tl.empty();
    tl.removeClass('lightRED');
    tl.removeClass('alert-success');
    tl.removeClass('lightYELLOW');
    tl.removeClass('alert-warning');
    tl.removeClass('lightGREEN');
    tl.removeClass('alert-danger');
    if(status == 'RED')
    {
        tl.addClass('alert-danger');
        tl.addClass('lightRED');
        tl.append("Action waited from you");
    }
    if(status == 'YELLOW')
    {
        tl.addClass('alert-warning');
        tl.addClass('lightYELLOW');
        tl.append("Action waited from other players");
    }
    if(status == 'GREEN')
    {
        tl.addClass('alert-success');
        tl.addClass('lightGREEN');
        tl.append("Elaborating...");
    }
    poll(function() {
        return fetch('/game/traffic-light?game='+App.game)
                .then(function(response) { return response.json(); })
        },
        function(data) {
            return ! $('#trafficlight').hasClass("light"+data.status)
        },
        3600000, 10000).then(function(data) { 
            App.updateTrafficLight(data.status); 
        })
  },
  renderMechaTemplate: function(m, poll_needed) {
    $('#mecha_' + m.name).append('<p id="desc_'+m.name+'">'+ App.mechaDescription(m) + '</p>');
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
                if(! c.energy_needed ||
                     m.energy > c.energy_needed)
                {
                    fetch(c.params_callback).then(function(response) { return response.json(); })
                    .then(function(data) {
                        if(data.targets.length > 0)
                        {
                            $( "#maincommands_"+m.name).append('<option value="'+c.code+'">'+c.label+'</option>');
                        }});
                }
            });
        });
        fetch('/game/command?game='+App.game+'&mecha='+m.name+'&prev=1&available=1')
        .then(function(response) { return response.json(); })
        .then(function(data) { 
            if(data.command.command)
            {
                var previous;
                var seccommand = '';
                var secparams = '';
                if(data.command.secondarycommand)
                {
                    previous = data.command.command +' '+ data.command.params+' ['+
                               data.command.secondarycommand;
                    seccomand = data.command.secondarycommand;
                    if(data.command.secondaryparams)
                    {
                        previous = previous + ' ' + data.command.secondaryparams +']';
                        secparams = data.command.secondaryparams;
                    }
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
                        <input type="hidden" name="velocity" value="${data.command.velocity}">
                        <input type="hidden" name="secondarycommand" value="${seccommand}">
                        <input type="hidden" name="secondaryparams" value="${secparams}">
                        <p><b>Previous command</b>:<br />${previous}</p>
                        <button name="resume" type="submit" class="btn btn-primary">Resume</button>
                    </form></div>`);
            }
            else
            {
               $('#mecha_' + m.name).append(`
                <div class="well">
                    <p>Impossible to resume last command</p>
                </div>`);
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
                    App.refreshMechaDescription(data.mecha.name, data.mecha);
                    return data.mecha.waiting == 1
                },
                3600000, 10000).then(function(data) { 
                    App.refreshAllMecha(); 
                    App.getLastEvent(data.mecha.name, true); 
            });
        }
    }
  },
  mechaDescription(m) {
    return m.name + ' (' + m.faction + ')<br />[' + m.position.x +', '+ m.position.y +', '+ m.position.z + ']<br />Velocity: '+m.velocity+'<br />Life: '+ m.life + '<br />Energy: '+m.energy
  },
  refreshMechaDescription(name, m) {
    console.log("Refreshing mecha "+name);
    $('#desc_'+name).empty();
    $('#desc_'+name).append(App.mechaDescription(m));
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
    fetch('/game/available-commands?game='+App.game+'&mecha='+name+'&command='+select.value)
    .then(function(response) { return response.json(); })
    .then(function(data) {
        machinegun = data.command.machinegun;
        paramDiv.append('<lable for="params_'+name+'>'+data.command.params_label+'</label>');
        paramDiv.append('<div class="form-group"><select class="form-control" name="params_'+name+'" id="params_'+name+'"></select></div>');
        fetch(data.command.params_callback).then(function(response) { return response.json(); })
        .then(function(data) {
            data.targets.forEach(function(d, index, array) {
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
        def = data.mecha.velocity;
        if(! def)
        {
            def = data.mecha.max_velocity -2;
        }
        for (i = 1; i <= data.mecha.max_velocity; i++) {
            checked = '';
            if(i == def)
            {
                checked = 'checked';
            }
            else if(i > data.mecha.available_max_velocity)
            {
                checked = 'disabled';
            }
            form = form +
                '<label class="radio-inline"> <input type="radio" name="velocity" id="velocity'+i+'" value="'+i+'" '+checked+'>'+i+'</label>';
        }
        if(data.mecha.max_velocity == data.mecha.available_max_velocity)
        {
            form = form +
                '<label class="radio-inline"> <input type="radio" name="velocity" id="velocityboost" value="boost">BOOST</label>';
        }
        form = form + '</div></div><div><input type="hidden" name="defvelocity" id="defvelocity" value="'+def+'"/></div>';
    $(form).insertAfter(div); });
  },
  machinegunForm : function(name, div) {
     fetch('/game/targets?game='+App.game+'&mecha='+name+'&filter=sighted-by-faction')
        .then(function(response) { return response.json(); })
        .then(function(data) {
            if(data.targets.length > 0)
            {
                $(`
                    <div class="form-group" id="${name}_machinegunform">
                    <div class="form-check">
                    <input type="checkbox" class="form-check-input" id="machinegun" name="machinegun">
                    <label class="form-check-label" for="machinegun">Fire machinegun</label>
                    </div>
                    <label for="target">Select Mecha</label>
                    <select class="form-control" name="secondarytarget" id="secparams_${name}"></select>
                    </div>
                `).insertAfter(div)
                data.targets.forEach(function(m, index, array) {
                    console.log("Append to "+name+" "+m.world_id);
                    $( "#secparams_"+name).append('<option value="'+m.world_id+'">'+m.label+'</option>');
                });
            }
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
    if(velocity == 'boost')
    {
        secondarycommand = 'boost';
        secondaryparams = null;
        velocity = $( form.find('input[name="defvelocity"]')).val();
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
    var velocity = $( form.children('input[name="velocity"]')).attr('value');
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
            'velocity': velocity,
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
