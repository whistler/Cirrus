DBLike
======

DBLike is a file backup and sync service programmed in node.js that can be used
to create your own file cloud. [Why not to use Dropbox?](http://dumpdropbox.com/)

Requirements
------------

### High priority ###

- Client has a folder that syncs with the server
  - Any changes in local files should automatically be updated on server
  - Any changes on server should automatically be synced with local folder
- User can have multiple clients that sync with the server
- If two servers crash, service should still be available
- Client should authenticate with the server before sync
- More than one clients should be able to update a file
- If a server crashes it should be able to recover without a problem

### Not High priority ###
- Updates should be incremental
- If two clients are on a local network, they should be able to sync locally


Design
------

### Sync Algorithm ###

- Persistent Websocket connection to the server
- Async events to all clients (with same user) for each file uploaded
- Client asks for files using HTTP
- On connect send timestamp of last change and receive all updates since then
- Last sync time for folder is stored
- Last modified time on server is used to figure out whether to replace
  or create a different version

### Time Sync ###
- Use epoch time
- Server sends its times in response 
- Client stores time difference from server and uses it in time related
  calucations

### Incremental Updates ###

#### Proposal 1 ####
Use rsync algorithm: [rsync-node](https://github.com/ttezel/anchor) rync
over http using node
[Rsync Algorithm](http://www.samba.org/~tridge/phd_thesis.pdf)

#### Proposal 2 ####
- Keep diffs for last n changes on for every user on server
- Send diffs patches to client instead of complete file
- Do the same on client

### Server Setup Script ###
- Create EC2 instances and setup all required software
- Create AWS script to set up load balancing

### Server database ###
- MySQL with list of users

### Multiple servers ###
- Multiple servers have a copy of the same data
- Number of servers can be configured, AWS API can be used to create
  instances

### How sync between servers ###
- Async syncronization similar to client server
- Double writes create different versions 
- Multicast??

### Configuration file ###
- Create a json config file for client and server

### Authentication ###
- Extensible library to support differnt authentications
- Use simple auth for a start

### Protocol ###
- Use a REST API 
