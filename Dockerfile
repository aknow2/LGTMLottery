FROM ruby:3.2.2

WORKDIR /app
COPY ["Gemfile", "Gemfile.lock", "main.rb", "images.json", "/app/"]

RUN bundle install

ENTRYPOINT ["ruby", "main.rb"]
