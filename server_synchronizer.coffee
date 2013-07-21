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

exports.destroy = (file, basepath, socket) ->
  socket.emit('delete', {file: file})
  console.log("Delete " + file)

# compares remote and local list of (file, timestamp) pairs, fetches
# the ones needing updates
# note: client can only delete files when connected
exports.sync = (remote, local, socket) ->
  console.log('Sync')
  console.log(remote)
  for file, time of remote
    if local[file]==undefined || new Date(time) > new Date(local[file])
      socket.emit('get', {file: file})
      
exports.get = (stream, params, user, socket, watcher) ->
  filename = Common.path.join(global.config.filestore, user, Common.path.basename(params.file))
  Common.util.ensure_folder_exists(Common.path.join(global.config.filestore, user))
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