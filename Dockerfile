FROM centos:7

MAINTAINER "Michael Joseph Walsh" <walsh@nemonik.com>

ENV container docker

# Enable Extra Packages for Enterprise Linux (EPEL)
RUN yum install -y epel-release

# Install Node.js and npm
RUN yum install -y nodejs npm

# Install app dependencies
COPY src /src
RUN cd /src; npm install

# App binds to port 20080 
EXPOSE  20080

# Run the app
CMD ["node", "/src/index.js"]

