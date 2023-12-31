FROM ruby:3.3

WORKDIR /app
COPY . /app

RUN bundle install

ENTRYPOINT ["ruby", "main.rb"]
