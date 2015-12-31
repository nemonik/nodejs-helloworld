var express = require('express');

var PORT = 20080;

var app = express();

app.get('/', function (req, res) {
  res.send('Hello world!\n');
});

app.listen(PORT);

console.log('Running on http://localhost:' + PORT);
