#!/usr/bin/env sh
# rewrite of the PHP script index.php

# determine door state
doorStatus=$(cat door_status.txt)
if [ "$doorStatus" = "open" ]; then
  isOpen=true
else
  isOpen=false
fi

# HTTP headers
printf "Content-Type: application/json; charset=utf-8\r\n"
printf "Access-Control-Allow-Origin: *\r\n"
printf "\r\n"

# JSON
printf '{'
printf '"api":"0.13",'
printf '"api_compatibility":["14"],'
printf '"space":"section77",'
printf '"logo":"https://section77.de/static/section77_logo_vector.svg",'
printf '"url":"https://section77.de/",'
printf '"location":{"address":"Hauptstraße 1, 77652 Offenburg, Germany","lat":48.4771,"lon":7.9461},'
printf '"contact":{"twitter":"@section77de","email":"info@section77.de","mastodon":"@section77@chaos.social"},'
printf '"feeds":{"calendar":{"type":"ical","url":"https://section77.de/section77.ics"}},'
printf '"issue_report_channels":["email"],'
printf '"state":{"open":%s},' "$isOpen"
printf '"ext_ccc":"chaostreff"'
printf '}\n'
