// The polling function
// Modified from https://gist.githubusercontent.com/twmbx/2321921670c7e95f6fad164fbdf3170e/raw/a34df76d47503f1deb8542c7149f4fb2ae924db5/vanilla-ajax-poll.js
function poll(fn, fn_check, timeout, interval) {
    var endTime = Number(new Date()) + (timeout || 2000);
    interval = interval || 100;

    var checkCondition = function(resolve, reject) { 
        console.log("Polling");
        var ajax = fn();
        // dive into the ajax promise
        ajax.then( function(response){
            // If the condition is met, we're done!
            if(fn_check(response)) {
                resolve(response);
            }
            // If the condition isn't met but the timeout hasn't elapsed, go again
            else if (Number(new Date()) < endTime) {
                setTimeout(checkCondition, interval, resolve, reject);
            }
            // Didn't match and too much time, reject!
            else {
                reject(new Error('timed out for ' + fn + ': ' + arguments));
            }
        });
    };

    return new Promise(checkCondition);
}

// Usage: get something via ajax
//poll(function() {
//	return axios.get('something.json');
//}, 2000, 150).then(function() {
//    // Polling done, now do something else!
//}).catch(function() {
//    // Polling timed out, handle the error!
//});
