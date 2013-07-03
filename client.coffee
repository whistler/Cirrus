# DB LIKE CLIENT

# load configuration file
config = require('./config/client')

# persistent connection
socket = require('socket.io-client')(config.host)

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

# http connection for updates
client = require('http')
address = "http://" + config.host + ":" + config.port
console.log(address)
client.get(address, (res)->
  output = ''
  res.on('data', (data)->
    output += data
  )
  res.on('end', ()->
    console.log(output)
  )
).on('error', (e)->
  console.log("Error: " + e.message)
)

# synchronizer
synchronizer = require('./synchronizer')(client)

# start watching directory
watcher = require('./watcher')(synchronizer)


