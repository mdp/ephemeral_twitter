FROM ruby:alpine
RUN apk add --update ruby-dev build-base

COPY . /usr/src/app
WORKDIR /usr/src/app

# rake is needed by 'unf' gem to build itself
RUN gem install rake

RUN bundle install

CMD ["ruby", "delete_tweets.rb"]

