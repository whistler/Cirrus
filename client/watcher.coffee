Watcher = (directory) =>

  watch = require('watch')

  watch.createMonitor(directory, (monitor) ->

    monitor.on("created", (f, stat) ->
      console.log(f + " created")
    )
    monitor.on("changed", (f, curr, prev) ->
      console.log(f + " changed")
    )
    monitor.on("removed", (f, stat) ->
      console.log(f + " removed")
    )
  )

module.exports = Watcher