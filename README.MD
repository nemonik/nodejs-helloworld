## Overview

This project contains everything needed to set up a **Consul**, **Registrator**, **Gogs**, **Drone**, and then use the source of the nodejs-helloworld of this project to exercise.

This following badge is an indicator whether or not the public drone.io build for the GitHub project was last successful:

[![Build Status](https://drone.io/github.com/nemonik/nodejs-helloworld/status.png)](https://drone.io/github.com/nemonik/nodejs-helloworld/latest)

The second badge indicates whether or the private drone you've set up is working.  If you are viewing this _README.MD_ in the **Gogs** you've spun was last successful: 

[![Build Status](http://drone.service.consul:8000/api/badges/nemonik/nodejs-helloworld/status.svg)](http://drone.service.consul:8000/nemonik/nodejs-helloworld)

## Spinning up Consul, Registrator, Gogs, and Drone

### <a name="installing_docker"></a>Install Docker

Follow the instructions for installing Docker.  As I'm on OS X, I use `brew` and performed the following:

    brew install docker docker-machine docker-compose

### <a name="create_the_consul_docker_machine"></a>Create the consul docker machine

You'll need to create a docker-machine to host **Consul**, **Registrator**, **Gogs**, and **Drone**, you accomplish this via

    docker-machine create --driver virtualbox --virtualbox-memory 8192 consul

Then determine the IP of the machine:

    docker-machine ip consul

### <a name="DNSMASQ_for_dev_dns"></a>DNSMASQ for dev DNS

I'm using **dnsmasq** so I can access the _consul_ docker machine via a name vice an IP. There are a number of ways to do this like adding a _consul_ entry to the `/etc/host` and optionally further configuring `dnsmasq`, but I simply added the following line to to `/usr/local/etc/dnsmasq.conf`:

    address=/consul/192.168.99.109

You'll need to use the IP that the `docker-machine ip consul` command returns.

Then create a docker-compose.yml file with these contents:

    consul:
      container_name: consul
      image: gliderlabs/consul-server:latest
          ports:
        - "8300:8300"
        - "8400:8400"
        - "8500:8500"
        - "53:8600/udp"
      command: -bootstrap -client 0.0.0.0
    
    registrator:
      container_name: registrator
      restart: on-failure
      links:
        - consul:consul
      image: gliderlabs/registrator
      command: consul://consul:8500
      volumes:
        - /var/run/docker.sock:/tmp/docker.sock
    
    drone:
      container_name: drone
      image: drone/drone:latest
      ports:
        - "8000:8000"
      environment:
    - GIN_MODE=release
    - SERVER_ADDR=:8000
    - REMOTE_DRIVER=gogs
    - REMOTE_CONFIG=http://gogs-3000.service.consul:3000?skip_verify=true
    - DATABASE_DRIVER=mysql
    - DATABASE_CONFIG=root:drone@tcp(mysql.service.consul:33060)/drone?parseTime=true
      volumes:
        - /var/run/docker.sock:/var/run/docker.sock
      volumes_from:
        - drone-data
    
    gogs:
      container_name: gogs
      image: gogs/gogs
      ports:
        - "3000:3000"
        - "22022:22"
      volumes_from:
        - gogs-data
    
    gogs-data:
      container_name: gogs-data
      image: busybox
      net: none
      command: /bin/sh
      volumes:
        - /data
    
    gogs-db:
      container_name: gogs-db
      image: mysql:5.6
      ports:
        - "33061:3306"
      environment:
        - MYSQL_ALLOW_EMPTY_PASSWORD=false
        - MYSQL_ROOT_PASSWORD=gogs
        - MYSQL_DATABASE=gogs
    
    drone-data:
      container_name: drone-data
      image: busybox
      net: none
      command: /bin/sh
      volumes:
        - /var/lib/drone
    
    drone-db:
      container_name: drone-db
      image: mysql:5.6
      ports:
        - "33060:3306"
      environment:
        - MYSQL_ALLOW_EMPTY_PASSWORD=false
        - MYSQL_ROOT_PASSWORD=drone
        - MYSQL_DATABASE=drone

Then spin these described containers in the `consul` machine with:

    docker-compose up -d

Then point your browser to:

1.  **Consul** <http://consul.service.consul:8500/ui/#/dc1/services> 
    
    **Registrator** registers each container to Consul as they spin up with service names using this pattern:

    <base(container-image)>[-<exposed-port> if >1 ports] 
    
    To query the services **Consul** is aware of in your browser, hit <http://consul.service.consul:8500/v1/catalog/services> and it will return:  
     
        {"consul":[],"consul-server-8300":[],"consul-server-8400":[],"consul-server-8500":[],"consul-server-8600":["udp"],"drone":[],"gogs-22":[],"gogs-3000":[],"mysql":[]}
     
    To query details for the known **mysql** services, hit <http://consul.service.consul:8500/v1/catalog/service/mysql> and it will return:
     
        [{"Node":"e9cba74266b5","Address":"172.17.0.2","ServiceID":"bb5464671cf5:drone-db:3306","ServiceName":"mysql","ServiceTags":null,"ServiceAddress":"172.17.0.3","ServicePort":33060},{"Node":"e9cba74266b5","Address":"172.17.0.2","ServiceID":"bb5464671cf5:gogs-db:3306","ServiceName":"mysql","ServiceTags":null,"ServiceAddress":"172.17.0.3","ServicePort":33061}]

2.   **Gogs** <http://gogs-3000.service.consul:3000/> and complete the configuration by submitting:
 
     *   _MySQL_ database type.
     *   `mysql.service.consul:33061` for the host.
     *   `gogs` for the password.
     *   `22022` for the SSH port.
     *   `http://gogs-3000.service.consul:3000` for the application URL.
     *   Under advanced, enable offline mode and enable captcha.   
      
     If everything goes well the configuration of *Gogs* will be complete.  Add a new account, add this project, and push into `gogs`.

3.   **Drone** <http://drone.service.consul:8000/> and enter the account credentials you created in **Gogs**.  **Drone** will register a webhook in **Gogs**, and then click **ACTIVATE NOW**.  

      If you add a repo to your account afterward, you may have access drone like so:
     
         http://drone.service.consul:8000/<Gogs account>/<project name>
     
      For **Drone** deploy of the nodej-helloworld project to the computer hosting *VirtualBox* to work, you will need to do the following:
     
      a.   In **Drone** click the settings tab for the project, 
      
      b.   Copy-and-paste the public key into your _~/.ssh/authorized_keys file of the box hosting the **consul** docker machine.
      
      c.   You will also need to retrieve the host only IPv4 Address for your computer's  _vboxnet1_ host only network adapter created and managed by **VirtualBox** and modify the project's _.drone.yml_ at line 13.  Doing so will allow **Drone** to execute the **rsync** and **ssh** commands to deploy and execute the node server on your box.
     
      Then make a change to the source of nodejs-helloworld, like in the _README.MD_ and push th change to *Gogs*.  Doing so should trigger a build and deploy.
     
## <a name="debugging"></a>Debugging

I'd advise secure shelling into your **consul** docker machine and monitor the logs on **Gogs**, and **Drone**. It is possible to mistakenly think webhook **Drone** registers with **Gogs** has failed, when you really have introduced an issue with your _.drone.yml_ file.  For example, if you've broke the yaml format.  

You can secure shell into the _consul_ docker machine via:

    docker-machine ssh consul

Once logged in you'll see something like:

                            ##         .
                      ## ## ##        ==
                       ## ## ## ## ##    ===
               /"""""""""""""""""\___/ ===
          ~~~ {~~ ~~~~ ~~~ ~~~~ ~~~ ~ /  ===- ~~~
               \______ o           __/
                 \    \         __/
                  \____\_______/
     _                 _   ____     _            _
    | |__   ___   ___ | |_|___ \ __| | ___   ___| | _____ _ __
    | '_ \ / _ \ / _ \| __| __) / _` |/ _ \ / __| |/ / _ \ '__|
    | |_) | (_) | (_) | |_ / __/ (_| | (_) | (__|   <  __/ |
    |_.__/ \___/ \___/ \__|_____\__,_|\___/ \___|_|\_\___|_|
    Boot2Docker version 1.9.1, build master : cef800b - Fri Nov 20 19:33:59 UTC 2015
    Docker version 1.9.1, build a34a1d5
    docker@consul:~$

Then list containers via:

    docker ps

to return something like:

    CONTAINER ID        IMAGE                             COMMAND                  CREATED             STATUS              PORTS                                                                                                                                  NAMES
    070d338dbc13        mysql:5.6                         "/entrypoint.sh mysql"   18 hours ago        Up 11 hours         0.0.0.0:33061->3306/tcp                                                                                                                gogs-db
    91945dfb4591        drone/drone                       "/drone_static"          18 hours ago        Up 11 hours         0.0.0.0:8000->8000/tcp                                                                                                                 drone
    871474eebc51        mysql:5.6                         "/entrypoint.sh mysql"   18 hours ago        Up 11 hours         0.0.0.0:33060->3306/tcp                                                                                                                drone-db
    ae9e524de226        gogs/gogs                         "docker/start.sh /bin"   18 hours ago        Up 11 hours         0.0.0.0:3000->3000/tcp, 0.0.0.0:22022->22/tcp                                                                                          gogs
    bb5464671cf5        gliderlabs/registrator            "/bin/registrator con"   18 hours ago        Up 11 hours                                                                                                                                                registrator
    e9cba74266b5        gliderlabs/consul-server:latest   "/bin/consul agent -s"   18 hours ago        Up 11 hours         0.0.0.0:8300->8300/tcp, 0.0.0.0:8400->8400/tcp, 8301-8302/tcp, 0.0.0.0:8500->8500/tcp, 8600/tcp, 8301-8302/udp, 0.0.0.0:53->8600/udp   consul

Then tail the **Gogs** logs via:

    drone logs -f gogs

In other terminal or tab secure shell back into the _consul_ docker machine and then tail **Drone**'s log via:

    drone logs -f drone










