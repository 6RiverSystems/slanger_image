FROM ruby:2.3
MAINTAINER Nick Chistyakov "nick@6river.com"
ENV RELEASED_AT 2016-08-02

ENV APP_KEY key
ENV APP_SECRET secret
ENV SLANGER_ARGS ""

RUN apt-get update
RUN gem install bundler

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

RUN git clone -b presence_webhooks https://github.com/6RiverSystems/slanger.git /usr/src/app

RUN bundler install

RUN rake build
RUN find ./pkg -name *.gem -exec gem install {} \;


# Slanger command line params
# -k or --app_key This is the Pusher app key you want to use. This is a required argument on command line or in optional config file
# -s or --secret This is your Pusher secret. This is a required argument on command line or in optional config file
# -C or --config_file Path to Yaml file that can contain all or some of the configuration options, including required arguments
# -r or --redis_address An address where there is a Redis server running. This is an optional argument and defaults to redis://127.0.0.1:6379/0
# -a or --api_host This is the address that Slanger will bind the HTTP REST API part of the service to. This is an optional argument and defaults to 0.0.0.0:4567
# -w or --websocket_host This is the address that Slanger will bind the WebSocket part of the service to. This is an optional argument and defaults to 0.0.0.0:8080
# -i or --require Require an additional file before starting Slanger to tune it to your needs. This is an optional argument
# -p or --private_key_file Private key file for SSL support. This argument is optional, if given, SSL will be enabled
# -b or --webhook_url URL for webhooks. This argument is optional, if given webhook callbacks will be made http://pusher.com/docs/webhooks
# -c or --cert_file Certificate file for SSL support. This argument is optional, if given, SSL will be enabled
# -v or --[no-]verbose This makes Slanger run verbosely, meaning WebSocket frames will be echoed to STDOUT. Useful for debugging
# --pid_file  The path to a file you want slanger to write it's PID to. Optional.

CMD slanger --app_key=${APP_KEY} --secret=${APP_SECRET} ${SLANGER_ARGS}
