Common = require './common'

watcher = require('watch')

# Watches file in 'directory' and notifies 'synchronizer' of
# any changes to files
Watcher = (synchronizer, directory) ->

  try
    directory = Common.path.normalize(directory)
    watcher.createMonitor(directory, (monitor) ->

      monitor.on("created", (file, stat) ->
        console.log(file + " created")
        synchronizer.create(relative_path(file), stat, directory)
      )
      monitor.on("changed", (file, curr, prev) ->
        console.log(file + " changed " + curr)
        synchronizer.update(relative_path(file), curr, directory)
      )
      monitor.on("removed", (file, stat) ->
        console.log(file + " removed")
        synchronizer.remove(relative_path(file), stat, directory)
      )
    )
  catch
    console.log("Error reading directory: " + global.config.directory + 
      ". Make sure it exists.")

  console.log("Watching " + global.config.directory + "...")

module.exports = Watcher

relative_path = (file) ->
  return Common.path.relative(directory, file)
