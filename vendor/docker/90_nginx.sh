#!/bin/sh
dockerize -template /home/app/vendor/docker/webapp.conf.tmpl:/etc/nginx/sites-enabled/webapp.conf
