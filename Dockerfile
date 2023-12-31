FROM ruby:3.2.2

WORKDIR /app
COPY . /app

RUN gem install octokit

ENTRYPOINT ["ruby", "main.rb"]
