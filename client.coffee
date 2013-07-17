global.app = "client"
global.config = require('./config/client')
Common = require './common'

socket = require('socket.io-client')("http://" + global.config.host + ":" + global.config.port)

# synchronizer
synchronizer = require('./synchronizer')(socket)
# start watching directory
watcher = require('./watcher')(synchronizer)

socket.on('connect', () ->

  console.log('connected')
  socket.emit('auth', {username: global.config.username, password: global.config.password})
  
  socket.on('disconnect', ()->
    console.log('Disconnected :(')
  )
  
  socket.on('error', (err)->
    console.log(err)
    console.log("TODO: Try to reconnect after timeout")
  )
  
  socket.on('unauthorized', ()->
    console.log("Unable to log in")
    process.exit(1)
  )
  
  socket.on('token', (tok)->
    global.auth_token = tok
    console.log(tok)
    synchronizer.update_since()
  )
  
)
  
fetch_updates = () ->
  socket.emit('fetch_updates', {since: global.config.last_update_time})
