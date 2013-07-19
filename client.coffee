# Cirrus Client
global.app = "client"
global.config = require('./config/client')
global.serv = global.config.servers[global.config.current_server]
Common = require './common'

# Connect to server
client = require('socket.io-client')
socket = client.connect("http://" + global.serv.host + ":" + global.serv.port, {'transports':['websocket']})
synchronizer = require('./client_synchronizer') # sends updates to server
synchronizer.set_socket(socket)

# start watching directory
directory = Common.util.expand(global.config.directory)
watcher = require('./watcher')(synchronizer, directory)

socket.on('connect', () ->
  console.log('Connected to Server! ' + global.serv.server)
  socket.emit('auth', {username: global.config.username, password: global.config.password})
  
  # recieve file updates from client
  Common.stream(socket).on('update', (stream, params) ->
    console.log('Downloading ' + params.name)
    filename = Common.path.join(Common.util.expand(global.config.directory), params.name)
    path = Common.path.dirname(filename)
    Common.util.ensure_folder_exists(path)
    stream.pipe(Common.fs.createWriteStream(filename))
    console.log('Downloading ' + params.name)
  )

)

next_server = () ->
  if ++global.config.current_server==global.config.servers.length
    global.config.current_server = 0
  Common.util.save_config(global.config)

socket.on('disconnect', ()->
  console.log('Server Disconnected')
  next_server()
)

socket.on('error', (err)->
  console.log(err)
  console.log("TODO: Try to reconnect after timeout")
  next_server()
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
