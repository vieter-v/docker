# Roadmap

This file keeps track of which parts of the Docker Engine API v1.41 are
currently supported. Note that in-development support is not listed here, so as
long as the full functionality isn't supported, it won't be noted.

This list was taking from the [API
reference](https://docs.docker.com/engine/api/v1.41/).

* Containers
    - [ ] List containers
    - [ ] Create a container
    - [ ] Inspect a container
    - [ ] List processes running inside a container
    - [ ] Get container logs
    - [ ] Get changes on a container’s filesystem
    - [ ] Export a container
    - [ ] Get container stats based on resource usage
    - [ ] Resize a container TTY
    - [ ] Start a container
    - [ ] Stop a container
    - [ ] Restart a container
    - [ ] Kill a container
    - [ ] Update a container
    - [ ] Rename a container
    - [ ] Pause a container
    - [ ] Unpause a container
    - [ ] Attach to a container
    - [ ] Attach to a container via a websocket
    - [ ] Wait for a container
    - [ ] Remove a container
    - [ ] Get information about files in a container
    - [ ] Get an archive of a filesystem resource in a container
    - [ ] Extract an archive of files or folders to a directory in a container
    - [ ] Delete stopped containers

* Images
    - [ ] List images
    - [ ] Build an image
    - [ ] Delete builder cache
    - [ ] Create an image
    - [ ] Inspect an image
    - [ ] Get the history of an image
    - [ ] Push an image
    - [ ] Tag an image
    - [ ] Remove an image
    - [ ] Search images
    - [ ] Delete unused images
    - [ ] Create a new image from a container
    - [ ] Export an image
    - [ ] Export several images
    - [ ] Import images

* Networks
    - [ ] List networks
    - [ ] Inspect a network
    - [ ] Remove a network
    - [ ] Create a network
    - [ ] Connect a container to a network
    - [ ] Disconnect a container from a network
    - [ ] Delete unused networks

* Volumes
    - [*] List volumes
    - [ ] Create a volume
    - [ ] Inspect a volume
    - [ ] Remove a volume
    - [ ] Delete unused volumes

* Exec
    - [ ] Create an exec instance
    - [ ] Start an exec instance
    - [ ] Resize an exec instance
    - [ ] Inspect an exec instance

* Swarm
    - [ ] Inspect swarm
    - [ ] Initialize a new swarm
    - [ ] Join an existing swarm
    - [ ] Leave a swarm
    - [ ] Update a swarm
    - [ ] Get the unlock key
    - [ ] Unlock a locked manager

* Nodes
    - [ ] List nodes
    - [ ] Inspect a node
    - [ ] Delete a node
    - [ ] Update a node

* Services
    - [ ] List services
    - [ ] Create a service
    - [ ] Inspect a service
    - [ ] Delete a service
    - [ ] Update a service
    - [ ] Get service logs

* Tasks
    - [ ] List tasks
    - [ ] Inspect a task
    - [ ] Get task logs

* Secrets
    - [ ] List secrets
    - [ ] Create a secret
    - [ ] Inspect a secret
    - [ ] Delete a secret
    - [ ] Update a secret

* Configs
    - [ ] List configs
    - [ ] Create a config
    - [ ] Inspect a config
    - [ ] Delete a config
    - [ ] Update a config

* Plugins
    - [ ] List plugins
    - [ ] Get plugin privileges
    - [ ] Install a plugin
    - [ ] Inspect a plugin
    - [ ] Remove a plugin
    - [ ] Enable a plugin
    - [ ] Disable a plugin
    - [ ] Upgrade a plugin
    - [ ] Create a plugin
    - [ ] Push a plugin
    - [ ] Configure a plugin

* System
    - [ ] Check auth configuration
    - [ ] Get system information
    - [ ] Get version
    - [ ] Ping
    - [ ] Monitor events
    - [ ] Get data usage information

* Distribution
    - [ ] Get image information from the registry

* Session
    - [ ] Initialize interactive session
