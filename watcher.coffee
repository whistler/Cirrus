Common = require './common'

watcher = require('watch')

directory = Common.util.expand(global.config.directory)
directory = Common.path.normalize(directory)

Watcher = (synchronizer) ->

  try
    watcher.createMonitor(directory, (monitor) ->

      monitor.on("created", (file, stat) ->
        console.log(file + " created")
        synchronizer.create(relative_path(file), stat)
      )
      monitor.on("changed", (file, curr, prev) ->
        console.log(file + " changed")
        synchronizer.update(relative_path(file), stat)
      )
      monitor.on("removed", (file, stat) ->
        console.log(file + " removed")
        synchronizer.remove(relative_path(file), stat)
      )
    )
  catch
    console.log("Error reading directory: " + config.directory + 
      ". Make sure it exists.")

  console.log("Watching " + global.config.directory + "...")

module.exports = Watcher

relative_path = (file) ->
  return Common.path.relative(directory, file)
