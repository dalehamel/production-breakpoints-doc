#!/bin/bash

if [ "$1" == "CI" ];then
  mv vendor vendor.bak
fi

bundle install
bundle exec rake report:spellcheck
err=$?

if [ "$1" == "CI" ];then
  rm -rf vendor
  mv vendor.bak vendor
fi

exit $err
