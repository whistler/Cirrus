Common = require './common'
watcher = require('watch')

# Watches file in 'directory' and notifies 'synchronizer' of
# any changes to files  
exports.start = (synchronizer, directory, file_list_path) ->

  directory = Common.path.normalize(directory)
  Common.util.ensure_file_exists(file_list_path)
  files = require (file_list_path)
  
  # returns path of file relative to 'directory'
  relative_path = (file) ->
    return Common.path.relative(directory, file)
  
  watcher.createMonitor(directory, (monitor) ->

    monitor.on("created", (file, stat) ->
      synchronizer.send(relative_path(file), directory, stat.mtime, stat.mtim)
    )
    monitor.on("changed", (file, curr, prev) ->
      rfile = relative_path(file)
      if !files[rfile] || curr.mtime > new Date(files[rfile])
        synchronizer.send(rfile, directory, curr.mtime, prev.mtime)
    )
    monitor.on("removed", (file, stat) ->
      console.log(file + " removed") if debug
      synchronizer.destroy(relative_path(file))
      set_timestamp(relative_path(file), "deleted")
    )
  )

  console.log("Watching " + directory + "...")
  
  exports.set_timestamp = (file, timestamp) ->
    files[file] = timestamp
    Common.util.save_file(file_list_path, files)
    console.log "Updated " + file + ": " + timestamp
  
  exports.get_timestamp = (file) ->
    files[file]
