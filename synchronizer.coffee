Common = require './common'
client_config = require('./config/client')
# Sends updates to the other end of the socket
Syncronizer = (socket) ->
  
  create: (file, stat, basepath) ->
    update_file(file, socket, stat.mtime, basepath)
    console.log("Create " + file)

  update: (file, stat, basepath) ->
    update_file(file, socket, stat.mtime, basepath)

  remove: (file, stat, basepath) ->
    console.log("Delete" + file)
    
  update_since: (timestamp, directory) ->
    files_updated_since(timestamp, directory, socket)

module.exports = Syncronizer

# Send a file update to socket
#   file: relative path of file
#   basepath: path where file is stored
#   mtime: time the file was modified
#   I think server is not updating client
update_file = (file, socket, mtime, basepath) ->
  absfile = Common.path.join(basepath,file)
  stream = Common.stream.createStream()
  Common.stream(socket).emit('update', stream, {name: file, token: global.auth_token})
  Common.fs.createReadStream(absfile).pipe(stream)
  client_config.last_updated = mtime # timestamps being stored in GMT
  console.log(file + " file updated from " + app)
  Common.util.save_config(client_config)
  
# Finds files in 'directory' updated after 'timestamp' and
# sends them to 'socket'
files_updated_since = (timestamp, directory, socket) ->
  walker = Common.walk.walk(directory,{followLinks: false})
  timestamp = new Date(timestamp)
  # for every update in file the timestamp to be stored in config should be modified time of director not files
  walker.on('file', (root,stat,next)->
    if stat.mtime > timestamp then update_file(stat.name, socket, stat.mtime, directory)
    next()
  )
