#!/bin/bash
DIR=$(dirname $(cd "$(dirname "$0")"; pwd))

cd $DIR

mkdir -p output
gem install bundler -v 1.17.3 || true
bundle install
bundle exec rake report:init
bundle exec rake report:publish

if [ "$1" == "CI" ];then
  ebook-convert output/doc.epub output/doc.mobi
  rm .gitignore
  mv output/doc.html index.html
fi
