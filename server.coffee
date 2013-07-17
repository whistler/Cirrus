global.app = 'server'
global.config = require('./config/server')
Common = require './common'

sockets = {}

Common.fs.exists(global.config.filestore, (exists) ->
  if exists
    console.log('Storing files in ' + global.config.filestore)
  else
    console.log('Error ' + global.config.filestore + ' does not exist')
    process.exit(-1)
)

# persistent connection for events
socketio = require('socket.io')(global.config.port)
console.log("Listening...")

socketio.on('connection', (socket) ->
  console.log("connected")

  socket.on('auth', (data) ->
    console.log(data)
    token = Common.auth.authenticate(data['username'], data['password'])
    if token
      sockets[socket] = data['username']
      socket.emit('token', token)
    else 
      socket.emit('unauthorized')
  )

  Common.stream(socket).on('update', (stream, data) ->
    if (user = Common.auth.valid(data.token))
      filename = Common.path.join(global.config.filestore, user, Common.path.basename(data.name))
      Common.util.ensure_folder_exists(Common.path.join(global.config.filestore, user))
      stream.pipe(Common.fs.createWriteStream(filename))
    else
      socket.emit('unauthorized')
  )
  
  socket.on('disconnect', ()->
    delete sockets[socket]
  )
 
  socket.on('update_since', (params) ->
    if user = Common.auth.valid(params.token)
      synchronizer = require('./synchronizer')(socket)
      directory = Common.path.join(global.config.filestore, user)
      console.log(directory)
      synchronizer.update_since(params.last_updated, directory)
    else
      socket.emit('unauthorized')
  )
)
