# Sends updates to the other end of the socket
Common = require './common'

# Send a file update to socket
#   file: relative path of file
#   basepath: path where file is stored
#   time: time the file was modified
exports.send = (file, basepath, time, last_updated, socket, user) ->
  complete_path = Common.path.join(basepath,file)
  console.log(complete_path)
  stream = Common.stream.createStream()
  Common.stream(socket).emit('update', stream, {file: file, token: global.auth_token, time: time, last_updated: last_updated}) 
  Common.fs.createReadStream(complete_path).pipe(stream)
  console.log "Sending " + file + " to " + user + " on socket " + socket.id

# 
exports.destroy = (file, basepath, socket) ->
  socket.emit('delete', {file: file})
  console.log("Delete " + file)

# compares remote and local list of (file, timestamp) pairs, fetches
# the ones needing updates
# note: due to a bug filenames for deleted files cannot be reused at the moment
exports.sync = (remote, watcher, socket, user) ->
  console.log('Sync')
  console.log(remote)
  for file, time of remote
    filename = Common.path.join(Common.path.normalize(global.config.filestore), user, file)
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
      debugger
      console.log('Requesting ' + file)
      socket.emit('get', {file: file})
    else if server_time > last_updated && disk_time > last_updated
      new_file = Common.path.join(Common.path.dirname(filename), "conflict_" + Common.path.basename(filename))
      socket.emit('message',"Conflict: File " + file + " has also been changed on server. Renamed to " + new_file + "on server")
      Common.util.moveSync(filename, new_file)
      stat = Common.fs.statSync(new_file) if Common.fs.existsSync(new_file)
      watcher.set_timestamp(file, stat.mtime)
      socket.emit('get', {file: file})
      console.log('Requesting ' + file)
      
# recieve file from client      
exports.get = (stream, params, user, socket, watcher) ->
  filename = Common.path.join(global.config.filestore, user, Common.path.basename(params.file))
  Common.util.ensure_folder_exists(Common.path.join(global.config.filestore, user))
  my_time = new Date(watcher.get_timestamp(filename))
  recv_prev_time = new Date(params.last_updated)
  recv_time = new Date(params.time)
  if my_time > recv_prev_time
    console.log('Unhandled conflict. This should never happen')
  else if my_time == recv_time
    # already up to date
  else
    stream.on('end', () ->
      watcher.set_timestamp(params.file, params.time)
      Common.fs.open(filename, 'a', (err, fd) ->
        time = new Date(params.time)
        Common.fs.futimesSync(fd, time, time)
        socket.emit('update_success', {file: params.file, time: params.time})
      )
    )
    stream.pipe(Common.fs.createWriteStream(filename))
    console.log("Downloading: " + filename)