mkdirp = require('mkdirp')
fs = require('fs')

exports.ensure_folder_exists = (dir) ->
  mkdirp(dir,(err)->
    if err then console.log(err)
  )

exports.expand = (directory) ->
  directory.replace(/^~/,process.env['HOME'])
  
exports.save_config = (config) ->
  data = JSON.stringify(config,null,2);

  fs.writeFile('./config/client.json', data, (err) ->
    if err
      console.log('There has been an error saving your configuration data.')
      console.log(err.message)
      return
    console.log('Configuration saved successfully.')
  )
