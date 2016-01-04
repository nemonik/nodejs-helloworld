FROM centos:7

MAINTAINER "Michael Joseph Walsh" <walsh@nemonik.com>

ENV container docker

# Enable Extra Packages for Enterprise Linux (EPEL)
RUN yum install -y epel-release

# Install Node.js and npm
RUN yum install -y nodejs npm

# Install app dependencies
RUN mkdir -p /app
COPY server.js /app
COPY package.json /server 
RUN cd /server; npm install

# App binds to port 20080 
EXPOSE  20080

# Run the app
CMD ["node", "/app/server.js"]

