# DB LIKE CLIENT

# load configuration file

config = require('./config/client')
socket = require('socket.io-client')("http://" + config.host + ":" + config.port)
stream = require('socket.io-stream')

# synchronizer
synchronizer = require('./synchronizer')(socket)

socket.on('connect', () ->

  console.log('connected')
  socket.emit('auth', {username: config.username, password: config.password})
  
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

# start watching directory
watcher = require('./watcher')(synchronizer)

  
fetch_updates = () ->
  socket.emit('fetch_updates', {since: config.last_update_time})
