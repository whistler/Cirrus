# Cirrus Server
global.app = 'server'
global.config = require('./config/server')
Common = require './common'
update = true
UPDATE_INTERVAL = 5000
global.socket = null

synchronizer = require('./server_synchronizer')
watcher = require('./watcher')
watcher.start(synchronizer, global.config.filestore)

# check if filestore is a valid location
Common.fs.exists(global.config.filestore, (exists) ->
  if exists
    console.log('Storing files in ' + global.config.filestore)
  else
    console.log('Error ' + global.config.filestore + ' does not exist')
    process.exit(-1)
)

# compares remote and local list of (file, timestamp) pairs, fetches
# the ones needing updates
# note: client can only delete files when connected, otherwise it would
# redownload from server. When a delete event is triggered a .filename.deleted
# file is created to keep track that the file was deleted and is not yet to be
# downloaded
sync = (remote, local, socket) ->
  console.log('Sync')
  console.log(remote)
  for file, mtime of remote
    if local[file]==undefined || new Date(mtime) > new Date(local[file])
      socket.emit('get', {file: file})

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
      global.socket = socket # TODO: delete this
      console.log(params.username + " logged in")
      socket.join(params.username)
      socket.emit('fetch_list')
      synchronizer.new_connection(socket, params.username)
    else 
      socket.emit('unauthorized')
  )
  
  # request from client to get a specific file
  socket.on('get', (params) ->
    if (user = Common.auth.valid(params.token))
      file_path = Common.path.join(global.config.filestore, user, params.file)
      stream = Common.stream.createStream()
      stat = Common.fs.statSync(file_path)
      Common.stream(socket).emit('update', stream, {name: params.file, token: global.auth_token, mtime: stat.mtime}) 
      Common.fs.createReadStream(file_path).pipe(stream)
      console.log("Uploading: " + file_path)
    else
      socket.emit('unauthorized')
  )
  
  # receive updated list of files on client with their timestamps
  socket.on('list', (params) ->
    if (user = Common.auth.valid(params.token))
      console.log('recieved list from ' + user)
      path = Common.path.join(config.filestore, user)
      Common.util.directory(path, (files) ->
        sync(params.list, files, socket)
      )
      # check which files need to be updated and emit 'get' on them
    else
      socket.emit('unauthorized')    
  )
  
  # send a list of files for user to client
  socket.on('fetch_list', (params) ->
    if (user = Common.auth.valid(params.token))
      path = Common.path.join(config.filestore, user)
      Common.util.directory(path, (files) ->
        socket.emit('list', {list:files})
      )
  )

  # recieve file updates from client
  Common.stream(socket).on('update', (stream, params) ->
    if (user = Common.auth.valid(params.token))
      filename = Common.path.join(global.config.filestore, user, Common.path.basename(params.name))
      Common.util.ensure_folder_exists(Common.path.join(global.config.filestore, user))
      stream.on('end', () ->
        Common.fs.open(filename, 'a', (err, fd) ->
          watcher.updated(filename, params.mtime)
          mtime = new Date(params.mtime)
          Common.fs.futimesSync(fd, mtime, mtime)
        )
      )
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
      #synchronizer.update_since(params.since, directory, user)
    else
      socket.emit('unauthorized')
  )
  
  setInterval(()->
    update = true
    socket.broadcast.emit('fetch_list')
  , UPDATE_INTERVAL
  )
)