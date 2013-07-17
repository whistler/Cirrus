Common = require './common'

Syncronizer = (socket) ->
  
  create: (file, stat) ->
    update_file(file, socket, stat.mtime)
    console.log("Create " + file)

  update: (file, stat) ->
    update_file(file, socket, stat.mtime)

  remove: (file, stat) ->
    console.log("Delete" + file)
    
  update_since: () ->
    directory = Common.util.expand(config.directory)
    console.log(global.config.last_updated)
    files_updated_since(global.config.last_updated,directory, socket)

module.exports = Syncronizer


update_file = (file,socket, mtime) ->
  watchdir = Common.util.expand(config.directory)
  absfile = Common.path.join(watchdir,file)
  
  stream = Common.stream.createStream()
  Common.stream(socket).emit('update', stream, {name: file, token: global.auth_token})
  Common.fs.createReadStream(absfile).pipe(stream)
  global.config.last_updated = mtime
  Common.util.save_config(global.config)
  console.log(absfile)  
# timestamps being stored in GMT

server_files_updated_since = (timestamp, user, socket) ->
  directory = Common.path.join(global.config.filestore,user)
  files_updated_since(timestamp,directory,socket)
  
files_updated_since = (timestamp,directory,socket) ->
  walker = Common.walk.walk(directory,{followLinks: false})
  timestamp = new Date(timestamp)
  console.log(timestamp)
  walker.on('file', (root,stat,next)->
    update_file(stat.name, socket, stat.mtime) if stat.mtime > timestamp
    next()
  )
