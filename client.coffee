# Cirrus Client

global.app = "client"
global.config = require('./config/client')
Common = require './common'

# Connect to server
client = require('socket.io-client')
socket = client.connect("http://" + global.config.host + ":" + global.config.port, {'transports':['websocket']})

synchronizer = require('./synchronizer')(socket) # sends updates to server
# start watching directory
directory = Common.util.expand(global.config.directory)
watcher = require('./watcher')(synchronizer, directory)

socket.on('connect', () ->

  console.log('Connected to Server!')
  socket.emit('auth', {username: global.config.username, password: global.config.password})
)

socket.on('disconnect', ()->
  console.log('Disconnected')
)

socket.on('error', (err)->
  console.log(err)
  console.log("TODO: Try to reconnect after timeout")
)

# Event triggered if username/password or token provided was invalid
socket.on('unauthorized', ()->
  console.log("Unable to log in")
  process.exit(1)
)

# Event triggered on successful authentication, send and recieve updates during downtime
socket.on('authenticated', (token)->
  global.auth_token = token
  console.log("Successfully logged in!")
  synchronizer.update_since(global.config.last_updated, Common.util.expand(global.config.directory))
  socket.emit('fetch_updates', {'since': global.config.last_updated, 'token' : global.auth_token})
)

