users = require './config/users'
crypto = require 'crypto'
tokens = {}

exports.authenticate = (user, password) ->
  # Check if user password combination is correct and 
  # returns token, false if incorrect combination
  pwd = users[user]
  if pwd == password
    token = generate_token(user, password)
    tokens[token] = user
    token
  else
    console.log("Failed Authentication: " + user)
    false

exports.valid = (token) ->
  # Returns user if token is correct, false otherwise
  user = tokens[token]
  if user
    user
  else
    console.log("Invalid token: "+ token)

generate_token = (user, password) ->
  crypto.createHash("sha")
    .update(user+password+Date.now())
    .digest("hex")