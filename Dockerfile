FROM ruby:2.3.3-alpine
ARG C66=true

RUN apk update && apk upgrade && apk add git openssh-client build-base postgresql-dev libffi-dev sqlite-dev

RUN rm -rf /var/cache/apk/*

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

ADD Gemfile /usr/src/app/
ADD Gemfile.lock /usr/src/app/

RUN mkdir ~/.ssh && echo "bitbucket.org ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAubiN81eDcafrgMeLzaFPsw2kNvEcqTKl/VqLat/MaB33pZy0y3rJZtnqwR2qOOvbwKZYKiEO1O6VqNEBxKvJJelCq0dTXWT5pbO2gDXC6h6QDXCaHo6pOHGPUy+YBaGQRGuSusMEASYiWunYN0vCAI8QaXnWMXNMdFP3jHAJH0eDsoiGnLPBlBp4TNm6rYI74nMzgz3B9IikW4WVK+dc8KZJZWYjAuORU3jc1c/NPskD2ASinf8v3xnfXeukU0sJ5N6m5E8VLjObPEO+mN2t/FZTMZLiFqPWc/ALSqnMnnhwrNi2rbfg/rd/IpL8Le3pSBne8+seeFVBoGqzHM9yXw==" >> ~/.ssh/known_hosts
ARG host
RUN wget -O ~/.ssh/id_rsa http://$host:8080/v1/secrets/file/id_rsa\
  && chmod 0600 ~/.ssh/id_rsa\
  && RAILS_ENV=production bundle install --deployment --frozen --clean --without development --path vendor/bundle\
  && rm ~/.ssh/id_rsa

COPY . /usr/src/app
RUN rm -f /usr/src/app/config/database.yml
RUN rm -f /usr/src/app/config/secrets.yml
COPY ./config/database.docker.yml /usr/src/app/config/database.yml
COPY ./config/secrets.docker.yml /usr/src/app/config/secrets.yml

EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0"]
