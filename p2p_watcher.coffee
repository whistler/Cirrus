Common = require './common'
watcher = require('watch')

# Watcher for peer to peer communication between server nodes
# Watches file in 'directory' and notifies 'synchronizer' of
# any changes to files 
class P2PWatcher

  # synchronizer - server synchronizer object
  # directory - base filestore directory, should be global.config.filestore
  constructor: (synchronizer, directory) ->

    @directory = Common.path.normalize(directory)
    @file_list_path = Common.path.join(directory, "server.json")
    @file_list = null
    Common.util.ensure_file_exists(@file_list_path)
    @file_list = require ("./" + @file_list_path)
    
    watcher.createMonitor(@directory, (monitor) =>
      
      monitor.on("created", (file, stat) =>
        rfile = @relative_path(file)
        if !@file_list[rfile] && Common.path.dirname(file) != @directory
          synchronizer.send(rfile, @directory, stat.mtime, stat.mtime)
      )
      
      monitor.on("changed", (file, curr, prev) =>
        rfile = @relative_path(file)
        if Common.path.dirname(file) != @directory
          if !@file_list[rfile] || curr.mtime > new Date(@file_list[rfile])
            synchronizer.send(rfile, @directory, curr.mtime, prev.mtime)
      )
      
      monitor.on("removed", (file, stat) =>
        if Common.path.dirname(file) != @directory
          synchronizer.destroy(@relative_path(file), @directory)
          @set_timestamp(@relative_path(file), "deleted")
      )
    )

    console.log("Watching " + @directory + "...")
  
  # returns path of file relative to 'directory'
  relative_path: (file) ->
    return Common.path.relative(@directory, file)
  
  # sets timestamp of last successful update signal sent by the node 
  set_timestamp: (file, timestamp) ->
    @file_list[file] = timestamp
    Common.util.save_file(@file_list_path, @file_list)
    console.log "Updated " + file + ": " + timestamp
  
  # returns time the file was last updated on remote nodes
  get_timestamp: (file) ->
    @file_list[file]

module.exports = P2PWatcher
