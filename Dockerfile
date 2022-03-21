FROM ruby:3-alpine
ARG C66=true

RUN apk --update --no-cache add openssh-client postgresql-dev libffi-dev libxml2 libxml2-dev libxslt libxslt-dev

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1
RUN bundle config build.nokogiri --use-system-libraries

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

ADD Gemfile /usr/src/app/
ADD Gemfile.lock /usr/src/app/

RUN apk --update --no-cache add git build-base pkgconfig\
    && RAILS_ENV=production bundle install --deployment --frozen --clean --without development test --path vendor/bundle\
    && apk del git pkgconfig build-base

COPY . /usr/src/app
RUN rm -f /usr/src/app/config/database.yml
RUN rm -f /usr/src/app/config/secrets.yml
COPY ./config/database.docker.yml /usr/src/app/config/database.yml
COPY ./config/secrets.docker.yml /usr/src/app/config/secrets.yml

EXPOSE 3000
CMD ["./bin/rails", "server", "-b", "0.0.0.0"]
