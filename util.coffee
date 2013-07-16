exports.expand = (directory) ->
  directory.replace(/^~/,process.env['HOME'])
