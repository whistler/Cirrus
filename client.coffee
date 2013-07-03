# DB LIKE CLIENT

# load configuration file
config = require('./config/client')

# persistent connection
socket = require('socket.io-client')("http://" + config.host + ":" + config.port)

socket.on('connect', () ->
  console.log('connected')
  socket.on('hello', (data) ->
    console.log('hello')
  )
  socket.on('disconnect', ()->
    console.log('Disconnected :(')
  )
  socket.on('error', (err)->
    console.log(err)
    console.log("TODO: Try to reconnect after timeout")
  )
)

# synchronizer
synchronizer = require('./synchronizer')(socket)

# start watching directory
watcher = require('./watcher')(synchronizer)


