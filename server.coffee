# Cirrus Server
global.app = 'server'
global.config = require('./config/server')
Common = require './common'

sockets = {} # stores socket ids and usernames as key values

# check if filestore is a valid location
Common.fs.exists(global.config.filestore, (exists) ->
  if exists
    console.log('Storing files in ' + global.config.filestore)
  else
    console.log('Error ' + global.config.filestore + ' does not exist')
    process.exit(-1)
)

# List for clients
socketio = require('socket.io').listen(global.config.port, {'log':false})
console.log("Listening...")

socketio.on('connection', (socket) ->
  console.log("connected")

  # authenticate user
  socket.on('auth', (params) ->
    token = Common.auth.authenticate(params.username, params.password)
    if token
      sockets[socket] = params.username
      socket.emit('authenticated', token)
      console.log(params.username + " logged in")
    else 
      socket.emit('unauthorized')
  )

  # recieve file updates from client
  Common.stream(socket).on('update', (stream, params) ->
    if (user = Common.auth.valid(params.token))
      filename = Common.path.join(global.config.filestore, user, Common.path.basename(params.name))
      Common.util.ensure_folder_exists(Common.path.join(global.config.filestore, user))
      stream.pipe(Common.fs.createWriteStream(filename))
    else
      socket.emit('unauthorized')
  )
  
  socket.on('close', () ->
#      socket.emit('close')
  )

  socket.on('disconnect', () ->
    console.log('server disconnected')
    delete sockets[socket]
  )
 
  # provide client all updates since last update
  socket.on('fetch_updates', (params) ->
    if user = Common.auth.valid(params.token)
      synchronizer = require('./synchronizer')(socket)
      directory = Common.path.join(global.config.filestore, user)
      console.log(directory)
      synchronizer.update_since(params.since, directory)
    else
      socket.emit('unauthorized')
  )
)
