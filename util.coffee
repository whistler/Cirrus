mkdirp = require('mkdirp')
exports.ensure_folder_exists = (dir) ->
  mkdirp(dir,(err)->
    if err then console.log(err)
  )

exports.expand = (directory) ->
  directory.replace(/^~/,process.env['HOME'])
  

