# Sends updates to the other end of the socket
Common = require './common'

socket = null
watcher = null

# Send a file update to socket
#   file: relative path of file
#   basepath: path where file is stored
#   mtime: time the file was modified
exports.send = (file, basepath, curr_mtime, prev_mtime, callback) ->
  console.log("Uploading: " + file)
  absfile = Common.path.join(basepath,file)
  stream = Common.stream.createStream()
  Common.stream(socket).emit('update', stream, {file: file, token: global.auth_token, curr_mtime: curr_mtime, prev_time: prev_mtime}) 
  Common.fs.createReadStream(absfile).pipe(stream)
  stream.on('close', ()->
    callback
  )
  
exports.destroy = (file) ->
  socket.emit('delete', {file: file, token: global.auth_token})
  console.log("Delete " + file)
  
exports.get = (stream, params, socket) ->
  filename = Common.path.join(Common.util.expand(global.config.directory), params.file)
  path = Common.path.dirname(filename)
  Common.util.ensure_folder_exists(path)
  my_mtime = watcher.get_time(filename)
  
  if my_mtime==params.prev_mtime
    stream.on('close', () ->
      Common.fs.open(filename, 'a', (err, fd) ->
        watcher.updated(filename, params.curr_mtime)
        mtime = new Date(params.curr_mtime)
        Common.fs.futimesSync(fd, mtime, mtime)
      )
      socket.emit('update_success', {auth: global.auth_token, file: file, mtime: params.curr_mtime})
    )
    stream.pipe(Common.fs.createWriteStream(filename))
    console.log('Downloading ' + params.name)
  else if my_mtime > params.prev_mtime
    console.log('unhandled conflict')
    # conflict

exports.sync = (files, socket) ->
  console.log('Sync')
  console.log(files)
  for file, mtime of files
    client_mtime = watcher.get_time(file)
    if client_mtime==undefined || new Date(mtime) > new Date(client_mtime)
      socket.emit('get', {file: file, token: global.auth_token})
      
exports.set_socket = (sock) ->
  socket = sock
  
exports.set_watcher = (watch) ->
  watcher = watch
