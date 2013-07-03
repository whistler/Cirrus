fs = require('fs')
path = require('path')
# load configuration file
config = require('./config/client')

Syncronizer = (net) ->
  
  create: (file) ->
    #PUT
    console.log("Create " + file)

  update: (file) ->
    #POST
    update_file(file,net)

  remove: (file) ->
    #DELETE
    console.log("Delete" + file)

module.exports = Syncronizer


update_file = (file,net) ->
  watchdir = path.normalize(config.directory)
  console.log(watchdir)
  absfile = path.join(watchdir,file)
  console.log(absfile)
  fs.readFile(absfile, "utf8", (err,data) ->
    console.log("Update " + file)
    console.log(data)
    console.log(err) if err
    post_options =
      host: config.host,
      port: config.port,
      path: path.join('/user/', file),
      method: 'POST',
      headers: [
         'Content-Type': 'application/x-www-form-urlencoded',
         'Content-Length': data.length]

    console.log(post_options)
    post_req = net.request(post_options, (res) ->
      res.setEncoding('utf8')
      res.on('data', (chunk) ->
        console.log('Response: ' + chunk)
      )
      res.on('error', (err) ->
        console.log("Error: " + err)
      )
    )

    post_req.write(data)
    post_req.end()
  )
