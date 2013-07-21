# Sends updates to the other end of the socket
Common = require './common'

sockets = {}
socket = null
# Send a file update to socket
#   file: relative path of file
#   basepath: path where file is stored
#   mtime: time the file was modified
exports.send = (file, basepath, curr_mtime, prev_mtime, callback) ->
  user = find_user(file)
  user_path = Common.path.join(basepath,user)
  complete_path = Common.path.join(basepath,file)
  relative_path = Common.path.relative(user_path, complete_path)
  absfile = Common.path.join(basepath,file)
  stream = Common.stream.createStream()
  Common.stream(global.socketio.sockets.in(user)).emit('update', stream, {name: relative_path, token: global.auth_token, curr_mtime: curr_mtime, prev_mtime: prev_mtime}) 
  Common.fs.createReadStream(absfile).pipe(stream)
  console.log "Sending " + file + " to " + user + " on socket " + socket.id


exports.destroy = (file, stat, basepath) ->
  console.log("Delete" + file)
  
exports.new_connection = (socket, user) ->
  sockets[socket.id] = user
    
exports.disconnected = (socket) ->
  delete sockets[socket.id]
  
exports.set_socket = (sock) ->
  socket = sock

# compares remote and local list of (file, timestamp) pairs, fetches
# the ones needing updates
# note: client can only delete files when connected
exports.sync = (remote, local, socket) ->
  console.log('Sync')
  console.log(remote)
  for file, mtime of remote
    if local[file]==undefined || new Date(mtime) > new Date(local[file])
      socket.emit('get', {file: file})
      
exports.get = (stream, params, user, socket) ->
  filename = Common.path.join(global.config.filestore, user, Common.path.basename(params.file))
  Common.util.ensure_folder_exists(Common.path.join(global.config.filestore, user))
  stream.on('end', () ->
    Common.fs.open(filename, 'a', (err, fd) ->
      mtime = new Date(params.mtime)
      Common.fs.futimesSync(fd, mtime, mtime)
      socket.emit('update_success', {file: params.file, mtime: mtime})
    )
  )
  stream.pipe(Common.fs.createWriteStream(filename))
  console.log("Downloading: " + filename)


# finds the sockets to which to send the updates to depending on 
# whether its the client or server. On server the right user is 
# selected from relative file path
find_sockets = (file) ->
  if config.app = 'client'
    socks = (sock for sock, user of sockets)
  else
    user = find_user(file)
    socks = find_sockets_by_user(user)
    console.log(user)
    console.log(socks)
    socks

# returns all sockets that belong to username
find_sockets_by_user = (username) ->
  socks = (sock for sock, user of sockets when user == username)

# On server files are stored under username/path/to/file. This
# function returns the username from relative file path
find_user = (file) ->
  regex = /^(.*)\//
  matches = regex.exec(file)
  matches[1]