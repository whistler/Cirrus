# Sends updates to the other end of the socket
Common = require './common'

sockets = {}

exports.create = (file, stat, basepath) ->
  # exports.update(file, stat, basepath)

exports.update = (file, stat, basepath) ->
  # console.log("yes")
  # user = find_user(file)
  # user_path = Common.path.join(basepath,user)
  # complete_path = Common.path.join(basepath,file)
  # relative_path = Common.path.relative(user_path, complete_path)
  # update_file(file, stat.mtime, basepath, user)

exports.remove = (file, stat, basepath) ->
  console.log("Delete" + file)
    
exports.update_since = (timestamp, directory, user) ->
  # files_updated_since(timestamp, directory, user)
  
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
update_file = (file, mtime, basepath, user) ->
  console.log "Sending " + file + " to " + user
  absfile = Common.path.join(basepath,file)
  sockets = global.socketio.sockets.in(user)['sockets']
  sockets = [global.socket]
  console.log(sockets)
  socks = for socket in sockets
    stream = Common.stream.createStream()
    Common.stream(socket).emit('update', stream, {name: file, token: global.auth_token, mtime: mtime}) 
    Common.fs.createReadStream(absfile).pipe(stream)
    console.log "Sending " + file + " to " + user + " on socket " + socket.id
  
# Finds files in 'directory' updated after 'timestamp' and
# sends them to 'socket'
files_updated_since = (timestamp, directory, user) ->
  console.log directory
  walker = Common.walk.walk(directory,{followLinks: false})
  timestamp = new Date(timestamp)
  # for every update in file the timestamp to be stored in config should be modified time of director not files
  walker.on('file', (root,stat,next)->
    if stat.mtime > timestamp
      update_file(stat.name, stat.mtime, directory, user) 
    next()
  )
