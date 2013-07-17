Common = {}

if global.app == "server"
  Common['auth'] = require('./auth')
  
Common['util'] = require('./util')
Common['path'] = require('path')
Common['fs'] = require('fs')
Common['walk'] = require('walk')
Common['stream'] = require('socket.io-stream')

module.exports = Common