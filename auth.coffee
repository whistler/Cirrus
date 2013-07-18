# Module to authenticate users on the server. The authenticate
# method is called first which returns a token. This token is 
# sent to the server on subsequent calls to the server. 

users = require './config/users'
crypto = require 'crypto'
tokens = {}

# Check if user password combination is correct and 
# returns token, false if incorrect combination
exports.authenticate = (user, password) ->
  pwd = users[user]
  if pwd == password
    token = generate_token(user, password)
    tokens[token] = user
    token
  else
    console.log("[AUTH] Authentication Failed: " + user)
    false

# Returns user if token is correct, false otherwise
exports.valid = (token) ->
  user = tokens[token]
  if user
    user
  else
    console.log("[AUTH] Invalid Token: "+ token)

# Generates auth token from username and password
generate_token = (user, password) ->
  crypto.createHash("sha")
    .update(user+password+Date.now())
    .digest("hex")