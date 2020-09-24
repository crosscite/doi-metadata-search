FROM phusion/passenger-full:1.0.9
LABEL maintainer="mfenner@datacite.org"

# Set correct environment variables.
ENV HOME /home/app
ENV DOCKERIZE_VERSION v0.6.0

# Allow app user to read /etc/container_environment
RUN usermod -a -G docker_env app

# This is to ensure when mounting volumes the non root user is actually our app user.
# This ensures editing on both host/container.
RUN usermod -u 1000 app
RUN groupmod -g 1000 app

# Use baseimage-docker's init process.
CMD ["/sbin/my_init"]

# fetch node10 and yarn sources
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash && \
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

# Use Ruby 2.6.5
RUN bash -lc 'rvm --default use ruby-2.6.5'

# Set debconf to run non-interactively
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# Install Chrome for headless testing
RUN apt-get install wget && \
    wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
    sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'

# Update installed APT packages
RUN apt-get update && apt-get upgrade -y -o Dpkg::Options::="--force-confold" && \
    apt-get install wget git ntp yarn google-chrome-stable python-dev pkg-config fontconfig libpng-dev libjpeg-dev libcairo2-dev libfreetype6-dev -y && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Enable Passenger and Nginx and remove the default site
# Preserve env variables for nginx
RUN rm -f /etc/service/nginx/down && \
    rm /etc/nginx/sites-enabled/default
COPY vendor/docker/00_app_env.conf /etc/nginx/conf.d/00_app_env.conf

# Install dockerize
RUN wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz && \
    tar -C /usr/local/bin -xzvf dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz

# Use Amazon NTP servers
COPY vendor/docker/ntp.conf /etc/ntp.conf

# Copy webapp folder
COPY . /home/app/webapp/
RUN mkdir -p /home/app/webapp/vendor/bundle && \
    chown -R app:app /home/app/webapp && \
    chmod -R 755 /home/app/webapp

# Install npm packages
# build vue component
WORKDIR /home/app/webapp

# Install Ruby gems
WORKDIR /home/app/webapp
RUN gem install bundler && \
    /sbin/setuser app bundle install --path vendor/bundle

# Install javascript libraries and webpack
RUN yarn install && \
    yarn build

# Run additional scripts during container startup (i.e. not at build time)
RUN mkdir -p /etc/my_init.d
COPY vendor/docker/70_templates.sh /etc/my_init.d/70_templates.sh

# Expose web
EXPOSE 80
