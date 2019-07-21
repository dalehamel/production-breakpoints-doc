#!/bin/bash
DIR=$(dirname $(cd "$(dirname "$0")"; pwd))

set -x
cd $DIR

mkdir -p output
ruby -v
gem --version
gem install bundler:2.0.1
bundle install
bundle exec rake report:init
bundle exec rake report:publish
cp output/doc.html index.html
