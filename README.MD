## Overview

This project contains everything needed to set up a **Consul**, **Registrator**, **Gogs**, **Drone**, and then use the source of the nodejs-helloworld of this project to exercise.

This following badge is an indicator whether or not the public drone.io build for the GitHub project was last successful:

[![Build Status](https://drone.io/github.com/nemonik/nodejs-helloworld/status.png)](https://drone.io/github.com/nemonik/nodejs-helloworld/latest)

The second badge indicates whether or the private drone you've set up is working.  If you are viewing this _README.MD_ in the **Gogs** you've spun was last successful:

[![Build Status](http://drone.service.consul:8000/api/badges/nemonik/nodejs-helloworld/status.svg)](http://drone.service.consul:8000/nemonik/nodejs-helloworld)

## <a name="DNSMASQ-for-dev-dns"></a>DNSMASQ for dev DNS

The `docker-machine` command explained in the next section will create a VM to host your docker containers with `Network Adpater 1` attached to `NAT`, and `Adapter 2` attached as a `Host-only Adapter` to `vboxnet1`.  You can view this VirtualBox by opening the `Settings` window for the VM, and then clicking on `Network`.  The `vboxnet1` is described under VirtualBoxe's `Preferences`.  Once opened, click `Network`  and then `Host-only Networks`.  In this case highlight `vboxnet1` and then the little screw driver to the right, and you can view the `Adapter` settings.

I'm using **dnsmasq** so I can access my dev VMs via a name vice an IP. There are a number of ways to do this like adding a machine's entry to the `/etc/host` and optionally further configuring `dnsmasq`.

Install `dnsmasq` via brew:

    brew install dnsmasq

I then simply added the following lines to to `/usr/local/etc/dnsmasq.conf`:

    # dnsmasq will listen for DHCP and DNS requests on this
    # interface and loopback:
    # interface=vboxnet1
    bind-interfaces
    
    # The address of your host on the vboxnet1 network
    address=/consul.dev/192.168.99.100
    address=/centos7-docker.dev/192.168.99.101
    address=/dockerhost.dev/192.168.99.1

The _consul.dev_ entry is for the docker-machine created VM used to host Docker containers on OS X.

The _centos7-docker.dev_ entry is for a VirtualBox hosted CentOS 7 VM configured to run Docker.

The  _dockerhost.dev_ is so I can easily ssh/scp out of either  _consul.dev_ or _centos7-docker.dev_ to my MBPro.

To start `dnsmasq` now:

    sudo launchctl load -w /Library/LaunchDaemons/homebrew.mxcl.dnsmasq.plist

To autostart `dnsmasq` after rebooting your OS X box:

    sudo cp -v $(brew --prefix dnsmasq)/homebrew.mxcl.dnsmasq.plist /Library/LaunchDaemons

So you can `nslookup`, `ping`, and `ssh` into your VMs you will need to complete this last steps:

    sudo mkdir -v /etc/resolver
    sudo bash -c 'echo "nameserver 192.168.99.1" > /etc/resolver/dev'

the `192.168.99.1` IP address is VirtualBox's `vboxnet1` `Host-only Networks` adapter's `IPv4 address` retrieved through tromping through the panels as I described at the start of this section. If you don't do this step, but the previous and the one immediately following you will be able `nslookup` your VMs, but not `ssh` nor `ping` into them.

The last step is to to add the ip address of the `dnsmasq` DNS server to the list utilized by the network interface your OS X box uses under `System Preferences` > `Network`.   Pick the correct interface and then click `Advanced...`, then `DNS`, and then add `vboxnet1` `Host-only Networks` adapter's `IPv4 address` (Mine was 192.168.99.1) to top of the list.  I've had to add this to every interface I use (e.g., Wi-Fi, Thunderbolt).

## Spinning up Consul, Registrator, Gogs, and Drone on OS X

### <a name="installing-docker-on-osx"></a>Install Docker

Install docker using `brew` by performing the following:

    brew install docker docker-machine docker-compose

### <a name="create-consul-docker-machine"></a>Create the consul docker machine

You'll need to create a docker-machine to host **Consul**, **Registrator**, **Gogs**, and **Drone**, you accomplish this via

    docker-machine create --driver virtualbox --virtualbox-memory 8192 consul

To Determine the IP of the machine enter on the command-line:

    docker-machine ip consul

Again, I'm using **dnsmasq** so I can access the _consul.dev_ docker machine via a name vice an IP, so I added the following line to

    address=/consul.dev/192.168.99.100

to /usr/local/etc/dnsmasq.conf`.

### <a name="docker-compose-consul">Spinning up the containers

Use the [./docker-compose.yml](./docker-compose.yml) contained in this project to spin up its described containers on the `consul.dev` machine with:

    eval $(docker-machine env consul)
    docker-compose up -d

To see all the logging from each container drop the `-d` parameter.

Then point your browser to:

1.  **Consul** <http://consul.service.consul.dev:8500/ui/#/dc1/services>

    **Registrator** registers each container to Consul as they spin up with service names using this pattern:

    <base(container-image)>[-<exposed-port> if >1 ports]

    To query the services **Consul** is aware of in your browser, hit <http://consul.service.consul.dev:8500/v1/catalog/services> and it will return:

        {"consul":[],"consul-server-8300":[],"consul-server-8400":[],"consul-server-8500":[],"consul-server-8600":["udp"],"drone":[],"gogs-22":[],"gogs-3000":[],"mysql":[]}

    To query details for the known **mysql** services, hit <http://consul.service.consul.dev:8500/v1/catalog/service/mysql> and it will return:

        [{"Node":"e9cba74266b5","Address":"172.17.0.2","ServiceID":"bb5464671cf5:drone-db:3306","ServiceName":"mysql","ServiceTags":null,"ServiceAddress":"172.17.0.3","ServicePort":33060},{"Node":"e9cba74266b5","Address":"172.17.0.2","ServiceID":"bb5464671cf5:gogs-db:3306","ServiceName":"mysql","ServiceTags":null,"ServiceAddress":"172.17.0.3","ServicePort":33061}]

2.   **Gogs** <http://gogs-3000.service.consul.dev:3000/> and complete the configuration by submitting:

     *   _MySQL_ database type.
     *   `mysql.service.consul.dev:33061` for the host.
     *   `gogs` for the password.
     *   `22022` for the SSH port.
     *   `http://gogs-3000.service.consul.dev:3000` for the application URL.
     *   Under `Advanced`, enable `Offline mode`,  checkoff `Disable Gravatar Service` and uncheck `Enable Captcha`.
     *   Complete the fields under `Admin Account`, if you want to create accounts through an admin account.

     If everything goes well the configuration of *Gogs* will be complete.  Add a new account, add this project, and push into `gogs`.

3.   **Drone** <http://drone.service.consul.dev:8000/> and enter the account credentials you created in **Gogs**.  **Drone** will register a webhook in **Gogs**, and then click **ACTIVATE NOW**.

      If you add a repo to your account afterward, you may have access drone like so:

         http://drone.service.consul.dev:8000/<Gogs account>/<project name>

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

Then tail the **Gogs** logs via:

    docker logs -f gogs

In other terminal or tab secure shell back into the _consul_ docker machine and then tail **Drone**'s log via:

    docker logs -f drone

## Spinning up Consul, Registrator, Gogs, and Drone on CentOS 7


### <a name="installing-docker-centos7-docker"></a>Installing

I retrieved a [CentOS 7 Minimal ISO](http://isoredirect.centos.org/centos/7/isos/x86_64/), and while that is downloading created a VM in VirtualBox w/ 4086 MB of base memory, 20 GBs of dynamically allocated storage.

Set the VM's network `Adapter 1` to `NAT`, and `Adapter 2` to `Host-only Adapter` and select `vboxnet1` or adapt the prior section describing how to configure `dnsmasq` to fit whatever you selected.

Mount the ISO as a CDROM, and start up the VM.

Do the minimal install. Create a admin account. Under networking, check `Automatically connect to this network when it is available`, check `All users may connect to this network`, and then select `IPv4 Settings` tab/panel and select `Require IPv4 address for this connection to complete`. The hover says, "When connecting to IPv6 capable networks, allows the connection to complete if IPv4 configuration fails, but IPv6 succeeds".  If you don't do this your networking won't be configured correctly...

Once, up make sure hostname is `centos7-docker`, if not edit `/etc/hostname` to set it.  Also, add `centos7-docker.dev` to `/etc/hosts`.

When the install finishes follow Docker's instructions to install Docker.  Either the steps under `Install with yum` or via `Install with the script`.  I did the later.

After that install few other things as root.

    yum -y install nano git ntp bind-utils git

Follow these instructions to install Docker and docker-compose:

https://docs.docker.com/engine/installation/linux/centos/

https://docs.docker.com/compose/install/

Also, make sure to complete the steps for creating a docker group, and start the docker daemon at boot, etc.

### <a name="docker-compose-centos7-docker">Spinning up the containers

Then ssh into the VM, and clone this project:

    git clone https://github.com/nemonik/nodejs-helloworld.git

Use the [./docker-compose.yml](./docker-compose.yml) contained in this project to spin uo its described containers on the `centos7-docker.dev` machine with:

    cd nodejs-helloworld
    docker-compose up -d

This will cache Docker images, and spin up the containers. Once complete, Gogs should be reachable via [http://gogs-3000.service.centos7-docker.dev:3000/](http://gogs-3000.service.centos7-docker.dev:3000/).

Complete the configuration by submitting:

*   _MySQL_ database type.
*   `mysql.service.centos7-docker.dev:33061` for the host.
*   `gogs` for the password.
*   `22022` for the SSH port.
*   `http://gogs-3000.service.centos7-docker.dev:3000` for the application URL.
*   Under `Advanced`, enable `Offline mode`,  checkoff `Disable Gravatar Service` and uncheck `Enable Captcha`.
*   Complete the fields under `Admin Account`, if you want to create accounts through an admin account.

If everything goes well the configuration of *Gogs* will be complete.  Add a new account, add this project, and push into `gogs`.

### <a name="systemd-start-containers">Systemd start containers

Lets place them all under systemd, so that the automatically start at the boot of the Centos 7 VM.

Execute the following as root:

    cd ../systemd
    cp docker-*.service /etc/systemd/system/.

To start, run as root:

    systemctl start docker-consul.service
    systemctl start docker-registrator.service
    systemctl start docker-gogs-db.service
    systemctl start docker-gogs.service
    systemctl start docker-drone-db.service
    systemctl start docker-drone.service

To enable on boot, run as root:

    systemctl enable docker-consul.service
    systemctl enable docker-registrator.service
    systemctl enable docker-gogs-db.service
    systemctl enable docker-gogs.service
    systemctl enable docker-drone-db.service
    systemctl enable docker-drone.service

Then check to see if they've all come up:

    docker ps

and you should see the containers have started.

### <a name="systemd-started-container-monitoring">Systemd started container monitoring

To monitor the container through systems as you would via docker-compose in debug use the following command:

    journalctl -u docker-gogs -u docker-drone -u docker-gogs-db -u docker-drone-db -u docker-consul -u docker-registrator -f

To check on how the Gogs container is running today through systemd, enter the following on the cmd-line:

    journalctl -u docker-gogs --since today

To check on how both the Gog and Drones container is running today through systemd, enter the following on the cmd-line:

    journalctl -u docker-gogs docker-drone --since today

Instead of today, you can check both since an hour ago like so:

    journalctl -u docker-gog docker-drone --since "1 hour ago"

You can also still monitor individual containers through docker as you described before:

    docker logs -f gogs

## <a name="backing-up-the-containers">Backing up the containers

We're going to have to create an image from the [Dockerfile](./backup/Dockerfile)  in this project's backup folder in order to create the container utilized to back up both **Gogs** and **Drone**.

    cd backup
    docker build -t nemonik/gogs-drone-backup .

Once you've create the image you will use it to backup the CI/CD pipeline.

First install the aws cli

    pip install awscli

As root configure AWS via

    aws configure

To run the back up container, execute:

    docker run --rm --net="host" -e AWS_ACCESS_KEY_ID=`aws configure get aws_access_key_id` -e AWS_SECRET_ACCESS_KEY=`aws configure get aws_secret_access_key` -e AWS_DEFAULT_REGION=`aws configure get region` --volumes-from drone-data --volumes-from gogs-data --name gogs-drone-backup nemonik/gogs-drone-backup

To debug, you can run via:

    docker run --rm --net="host"  -i -e AWS_ACCESS_KEY_ID=`aws configure get aws_access_key_id` -e AWS_SECRET_ACCESS_KEY=`aws configure get aws_secret_access_key` -e AWS_DEFAULT_REGION=`aws configure get region` --volumes-from drone-data --volumes-from gogs-data --name gogs-drone-backup nemonik/gogs-drone-backup /bin/bash

`S3_BUCKET_NAME` in backup.sh will be set to `docker-backups.`+ the hostname + `dev`, if you want something else change the script an recreate the image.

## <a name="systems-timer-backup">Auto backing up containers

The following is only relevant to backing the CentOS 7 Docker host.

Add the image as described in the prior section.

As root,execute the following:

Install the backup script:

    cd ../systemd/timer/scripts
    cp docker-gogs-drone-backup.sh /usr/local/bin/.
    chmod +x /usr/local/bin/docker-gogs-drone-backup.sh
    chmod o-r /usr/local/bin/docker-gogs-drone-backup.sh

Edit the script entering you AWS credentials.

Install the backup service and timer:

    cd ..
    cp docker-gogs-drone-backup.* /etc/systemd/system/.

The timer can run a multitude of ways, edit `docker-gogs-drone-backup.timer` and specify when you want the backup to occur.  As it is the present timer will create a backup ten minutes after start and at midnight every day after.  If you change the backup frequency, make sure to enter the following as root:

    systemctl daemon-reload

Start the timer:

    systemctl enable docker-gogs-drone-backup
    systemctl start docker-gogs-drone-backup

To check if the time has been added and when it will next run:

    systemctl list-timers docker-gogs-drone-backup.timer

To view the logging for the unit executed by the timer:

    journalctl -u docker-gogs-drone-backup


