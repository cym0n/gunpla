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
                $('#mechas').append(App.mechaTemplate(index, m.name, m.faction, m.position, m.waiting));  
            });
        });
  },
  mechaTemplate: function(id, name, faction, pos, waiting) {
    var mechaview = '<div id="mecha_' + name + '"><p>'+ name + ' (' + faction + ')<br />[' + pos.x +', '+pos.y +', '+pos.z + ']</p>';
    if(waiting)
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
    });
  }

};




$(function() {
//  $(window).load(function() {
  $(window).on('load', (function() {
    App.init(game);
  }));
});
