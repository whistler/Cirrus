# Sends updates to the other end of the socket
Common = require './common'

socket = null

exports.create = (file, stat, basepath) ->
  update_file(file, stat.mtime, basepath)

exports.update = (file, stat, basepath) ->
  update_file(file, stat.mtime, basepath)

exports.remove = (file, stat, basepath) ->
  console.log("Delete" + file)
    
exports.update_since = (timestamp, directory) ->
  files_updated_since(timestamp, directory)
  
exports.set_socket = (sock) ->
  socket = sock

# Send a file update to socket
#   file: relative path of file
#   basepath: path where file is stored
#   mtime: time the file was modified
update_file = (file, mtime, basepath) ->
  console.log("Uploading: " + file)
  absfile = Common.path.join(basepath,file)
  stream = Common.stream.createStream()
  Common.stream(socket).emit('update', stream, {name: file, token: global.auth_token}) 
  Common.fs.createReadStream(absfile).pipe(stream)
  
  global.config.last_updated = mtime # timestamps being stored in GMT
  Common.util.save_config(global.config)
  
# Finds files in 'directory' updated after 'timestamp' and
# sends them to 'socket'
files_updated_since = (timestamp, directory) ->
  walker = Common.walk.walk(directory,{followLinks: false})
  timestamp = new Date(timestamp)
  # for every update in file the timestamp to be stored in config should be modified time of director not files
  walker.on('file', (root,stat,next)->
    if stat.mtime > timestamp then update_file(stat.name, stat.mtime, directory) 
    next()
  )
