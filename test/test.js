var server = require('../server');
var assert = require('assert');
var http = require('http');

describe('test server', function () {
  it('should return 200', function (done) {
    console.log("Server listening on: %s", server.PORT);

    http.get('http://localhost:' + server.PORT, function (res) {
      assert.equal(200, res.statusCode);
      done();
    });
  });

  it('should say "Hello world!"', function (done) {
    http.get('http://localhost:' + server.PORT, function (res) {
      var data = '';

      res.on('data', function (chunk) {
        data += chunk;
      });

      res.on('end', function () {
        assert.equal('Hello world!\n', data);
        done();
      });
    });
  });
});
