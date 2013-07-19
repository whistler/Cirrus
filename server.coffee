# Cirrus Server
global.app = 'server'
global.config = require('./config/server')
Common = require './common'

global.socket = null

synchronizer = require('./server_synchronizer')
watcher = require('./watcher')(synchronizer, global.config.filestore)

# check if filestore is a valid location
Common.fs.exists(global.config.filestore, (exists) ->
  if exists
    console.log('Storing files in ' + global.config.filestore)
  else
    console.log('Error ' + global.config.filestore + ' does not exist')
    process.exit(-1)
)

# List for clients
global.socketio = require('socket.io').listen(global.config.port, {'log':false})
console.log("Listening...")

global.socketio.on('connection', (socket) ->
  console.log("Connected: " + socket.id)

  # authenticate user
  socket.on('auth', (params) ->
    token = Common.auth.authenticate(params.username, params.password)
    if token # successfully logged in
      socket.emit('authenticated', token)
      console.log(params.username + " logged in")
      socket.join(params.username)
      global.socket = socket # TODO: delete
      synchronizer.new_connection(socket, params.username)
    else 
      socket.emit('unauthorized')
  )
  
  # request from client to get a specific file
  socket.on('get', (params) ->
    if (user = Common.auth.valid(params.token))
      file_path = Common.path.join(global.config.filestore, user, params.file)
      stream = Common.stream.createStream()
      Common.stream(socket).emit('update', stream, {name: params.file, token: global.auth_token}) 
      Common.fs.createReadStream(file_path).pipe(stream)
      console.log("Uploading: " + file_path)
    else
      socket.emit('unauthorized')
  )
  
  # receive updated list of files on client with their timestamps
  socket.on('list', (params) ->
    if (user = Common.auth.valid(params.token))
      # check which files need to be updated and emit 'get' on them
    else
      socket.emit('unauthorized')    
  )
  
  # send a list of files for user to client
  socket.on('fetch_list', (params) ->
    if (user = Common.auth.valid(params.token))
      path = Common.path.join(config.filestore, user)
      Common.util.directory(path, (files)
        socket.emit('list', {list:files})
      )
  )

  # recieve file updates from client
  Common.stream(socket).on('update', (stream, params) ->
    if (user = Common.auth.valid(params.token))
      filename = Common.path.join(global.config.filestore, user, Common.path.basename(params.name))
      Common.util.ensure_folder_exists(Common.path.join(global.config.filestore, user))
      stream.pipe(Common.fs.createWriteStream(filename))
      console.log("Downloading: " + filename)
    else
      socket.emit('unauthorized')
  )

  # client gets disconnected
  socket.on('disconnect', () ->
    synchronizer.disconnected(socket)
  )
 
  # provide client all updates since last update
  socket.on('fetch_updates', (params) ->
    if user = Common.auth.valid(params.token)
      directory = Common.path.join(global.config.filestore, user)
      synchronizer.update_since(params.since, directory, user)
    else
      socket.emit('unauthorized')
  )
)
