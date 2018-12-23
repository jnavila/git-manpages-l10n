#!/bin/sh

export PERLLIB=$(pwd)/po4a/lib
export PERL5LIB=$(pwd)/po4a/lib
export PATH=$PATH:$(pwd)/po4a
bundle exec make all
