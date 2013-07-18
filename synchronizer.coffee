# Sends updates to the other end of the socket
Common = require './common'

sockets = {}

exports.create = (file, stat, basepath) ->
  update_file(file, stat.mtime, basepath)
  console.log("Create " + file)

exports.update = (file, stat, basepath) ->
  update_file(file, stat.mtime, basepath)

exports.remove = (file, stat, basepath) ->
  console.log("Delete" + file)
    
exports.update_since = (timestamp, directory) ->
  files_updated_since(timestamp, directory)
  
exports.new_connection = (socket, user) ->
  sockets[socket.id] = user
    
exports.disconnected = (socket) ->
  delete sockets[socket.id]

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


# Send a file update to socket
#   file: relative path of file
#   basepath: path where file is stored
#   mtime: time the file was modified
update_file = (file, mtime, basepath) ->
  absfile = Common.path.join(basepath,file)
  sockets = find_sockets(file)
  console.log(JSON.stringify(sockets))
  socks = for socket_id in sockets
    stream = Common.stream.createStream()
    console.log(socket_id)
    socket = global.socketio.sockets(socket_id)
    console.log(socket)
    Common.stream(socket).emit('update', stream, {name: file, token: global.auth_token}) 
    Common.fs.createReadStream(absfile).pipe(stream)
  
  global.config.last_updated = mtime # timestamps being stored in GMT
  Common.util.save_config(global.config)
  console.log(absfile)  
  
# Finds files in 'directory' updated after 'timestamp' and
# sends them to 'socket'
files_updated_since = (timestamp, directory) ->
  walker = Common.walk.walk(directory,{followLinks: false})
  timestamp = new Date(timestamp)
  console.log(timestamp)
  walker.on('file', (root,stat,next)->
    update_file(stat.name, stat.mtime, directory) if stat.mtime > timestamp
    next()
  )
