# NAME

Telegram::CamshotBot - Telegram bot that send you a snapshot from IP camera using ffmpeg (don't forget to install it!)

# VERSION

version 0.01

# ENVIRONMENT VARIABLES

Environment variables are always checked firstly, before any config files

To get list of all available environment variables:

    grep -o -P "CAMSHOTBOT_\w+" lib/Telegram/CamshotBot.pm | sort -u

Actual List (useful for Docker deployment):

    CAMSHOTBOT_CONFIG
    CAMSHOTBOT_DOMAIN
    CAMSHOTBOT_FFMPEG_DOCKER
    CAMSHOTBOT_LAST_SHOT_FILENAME
    CAMSHOTBOT_POLLING
    CAMSHOTBOT_STREAM_URL
    CAMSHOTBOT_TELEGRAM_API_TOKEN

To check which variables are set you can run

    printenv | grep CAMSHOTBOT_* | sort -u

For setting environment variable you can use

    export CAMSHOTBOT_POLLING=1

# RUNNING

Docker way

    wget https://raw.githubusercontent.com/pavelsr/camshotbot/master/docker-compose.yml.example > docker-compose.yml

then edit CAMSHOTBOT\_\* variables

    docker-compose up

Standalone way

1) Place .camshotbot file in home user directory or camshotbot.conf.json in directory from what you will run camshotbot
Add all essential variables:  telegram\_api\_token, stream\_url, bot\_domain

2) As alternative to (1) you can set all CAMSHOTBOT\_\* environment variables (see ENVIRONMENT VARIABLES section)

3) run

    camshotbot daemon

You can run ffmpeg in a separate docker container.
String below will output a single image that is continuously overwritten with new images

docker run -d -it -v $(pwd):/tmp/workdir --network=host jrottenberg/ffmpeg:3.3-alpine -hide\_banner -loglevel error -i rtsp://10.132.193.9//ch0.h264 -f image2 -vf fps=1/3 -y -update 1 latest.jpg

# DEVELOPMENT

If you want to run unit test without dzil test

    prove -l -v t  or perl -Ilib

# AUTHOR

Pavel Serikov <pavelsr@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Pavel Serikov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
