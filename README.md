DBLike
======
DBLike is a file backup and sync service programmed in node.js that can be used to create your own file cloud.

Requirements
============

High priority
-------------
- Client has a folder that syncs with the server
  - Any changes in local files should automatically be updated on server
  - Any changes on server should automatically be synced with local folder
- User can have multiple clients that sync with the server
- If two servers crash, service should still be available
- Client should authenticate with the server before sync
- More than one clients should be able to update a file
- If a server crashes it should be able to recover without a problem

Not High priority
-----------------
- Updates should be incremental
- If two clients are on a local network, they should be able to sync locally


Design
======

Use EC2 API to Autoscale

How do we handle last update times?
- Sync signal to client or Client requests updates?

Server has a database with user details

What kind of redundancy should be used?
- Three copies on different servers or RAID?
- How to sync between servers

Client
- Configuration
- Authentication
- Sync daemon

Handling writes by multiple clients
- create different versions & notify user to merge

