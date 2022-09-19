FROM ruby:3.1.2-alpine3.16

RUN apk update
RUN apk add --no-cache build-base

RUN gem install slack-ruby-client -v 1.1.0
RUN gem install crack -v 0.4.5

RUN mkdir /app
COPY aws-status-to-slack.rb /app

CMD [ "/app/aws-status-to-slack.rb" ]
