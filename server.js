console.log("I am here");

var http = require('http');

const PORT = 20080; 
module.exports.PORT = PORT;

console.log("port = %s", PORT);

function handleRequest(req, res){
    res.writeHead(200, {'Content-Type': 'text/plain'});
    res.end('Hello world!\n');
}

var server = http.createServer(handleRequest);

server.listen(PORT, function() {
    console.log("Server listening on: http://localhost:%s", PORT);
});
