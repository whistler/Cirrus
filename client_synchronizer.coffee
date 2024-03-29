# Processes synchronization for the client program
Common = require './common'

socket = null
watcher = null

# Send a file update to socket
#   file: relative path of file
#   basepath: path where file is stored
#   time: time the file was modified
exports.send = (file, basepath, time, last_updated) ->
  console.log("Uploading Requested File: " + file)
  absfile = Common.path.join(basepath,file)
  stream = Common.stream.createStream()
  Common.stream(socket).emit('update', stream, {file: file, token: global.auth_token, time: time, last_updated: last_updated}) 
  Common.fs.createReadStream(absfile).pipe(stream)

# Tell the server that a file has been deleted
exports.destroy = (file) ->
  socket.emit('delete', {file: file, token: global.auth_token})
  console.log("Delete " + file)
  
# Recieve file from server
exports.get = (stream, params, socket) ->
  filename = Common.path.join(Common.util.expand(global.config.directory), params.file)
  path = Common.path.dirname(filename)
  Common.util.ensure_folder_exists(path)
  my_time = new Date(watcher.get_timestamp(filename))
  recv_prev_time = new Date(params.last_updated)
  recv_time = new Date(params.time)
  if my_time > recv_prev_time
    console.log('Unhandled conflict. This should never happen')
  else if my_time == recv_time
    # already up to date
  else
    stream.on('end', () ->
      watcher.set_timestamp(params.file, params.last_updated)
      Common.fs.open(filename, 'a', (err, fd) ->
        time = new Date(params.last_updated)
        Common.fs.futimesSync(fd, time, time)
        socket.emit('update_success', {token: global.auth_token, file: params.file, time: params.last_updated})
      )
    )
    stream.pipe(Common.fs.createWriteStream(filename))
    console.log('Downloading ' + params.file)

# From a list of files on the server request the ones not up to date
# Rename file if there is a conflict
exports.sync = (remote, watcher, socket) ->
  console.log('Sync')
  for file, time of remote
    filename = Common.path.join(Common.util.expand(global.config.directory), file)
    last_updated = new Date(watcher.get_timestamp(file))
    server_time = new Date(time)
    if Common.fs.existsSync(filename)
      stats = Common.fs.statSync(filename) 
      disk_time = stats.mtime
    else
      disk_time = 0
    if watcher.get_timestamp(file) == "deleted"
      if Common.fs.existsSync(filename) then Common.fs.unlinkSync(filename)
    else if disk_time == 0 || watcher.get_timestamp(file)==false || (server_time > last_updated && disk_time <= last_updated)
      console.log('Requesting ' + file)
      socket.emit('get', {file: file, token: global.auth_token})
    else if server_time > last_updated && disk_time > last_updated
      new_file = Common.path.join(Common.path.dirname(filename), "conflict_" + Common.path.basename(filename))
      console.log("Conflict: File " + file + "has also been changed on server. Renamed to " + new_file)
      Common.util.moveSync(filename, new_file)
      stat = Common.fs.statSync(new_file)
      watcher.set_timestamp(file, stat.mtime)
      console.log('Requesting ' + file)
      socket.emit('get', {file: file, token: global.auth_token})

# Set the socket to use 
exports.set_socket = (sock) ->
  socket = sock

# Set the watcher to use
exports.set_watcher = (watch) ->
  watcher = watch
