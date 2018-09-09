#!/bin/sh

dockerize -template /home/app/webapp/vendor/docker/robots.txt.tmpl:/home/app/webapp/public/robots.txt
dockerize -template /home/app/webapp/vendor/docker/webapp.conf.tmpl:/etc/nginx/sites-enabled/webapp.conf
