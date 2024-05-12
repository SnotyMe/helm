#!/bin/bash

docker run -v "$PWD":/site -it --rm --entrypoint bash -p 4000:4000 bretfisher/jekyll
# run this in the container: bundle exec jekyll serve --host 0.0.0.0
