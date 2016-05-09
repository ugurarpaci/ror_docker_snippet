FROM debian:wheezy
ADD https://s3.eu-west-1.amazonaws.com/sources.list /etc/apt/sources.list

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install gnupg build-essential curl procps apt-transport-https ca-certificates libcurl4-openssl-dev libmysqlclient-dev xvfb imagemagick git -y

RUN echo "deb https://oss-binaries.phusionpassenger.com/apt/passenger wheezy main" >> /etc/apt/sources.list \
  && curl -sSL https://rvm.io/mpapis.asc | gpg --import -                                                   \
  && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7                     \
  && curl -sSL https://get.rvm.io | bash -s stable                                                      

ENV PATH $PATH:/usr/local/rvm/bin
RUN rvm install ruby-2.2.1
ENV RUBY_VERSION ruby-2.2.1

ENV PATH /usr/local/rvm/gems/ruby-2.2.1/bin:/usr/local/rvm/gems/ruby-2.2.1@global/bin:/usr/local/rvm/rubies/ruby-2.2.1/bin:$PATH

# Setup Passenger + Node + Nginx Couple
RUN curl --fail -ssL -o setup-nodejs https://deb.nodesource.com/setup_0.12 && bash setup-nodejs            \      
  && apt-get update                                                                                        \
  && apt-get install -y nginx-extras passenger nodejs                                                       

ENV GEM_HOME /ruby_gems/2.2.1
ENV GEM_PATH $GEM_HOME:/usr/local/rvm/gems/ruby-2.2.1@global
ENV MY_RUBY_HOME /ruby_gems/2.2.1
ENV BUNDLE_APP_CONFIG $GEM_HOME
ENV BUNDLER_VERSION 1.11.2

ARG RAKE
ARG RAILS_ENV_VAR

ENV RAKE_COMMAND $RAKE
ENV RAILS_ENVIRON $RAILS_ENV_VAR

ENV APP_HOME /opt/app/ruby/
WORKDIR $APP_HOME
ADD . $APP_HOME
RUN mkdir -p $APP_HOME/tmp && chmod 777 -R $APP_HOME/tmp $APP_HOME/config/*yml
CMD mkdir -p $GEM_HOME                  \
  && gem install bundler                \
  && bundle install --jobs 4 --retry 3  \
  && RAILS_ENV=$RAILS_ENVIRON rake $RAKE_COMMAND   \ 
  && nginx 
