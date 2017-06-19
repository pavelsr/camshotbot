# NAME

Telegram::CamshotBot - Telegram bot that send you a snapshot from IP camera using ffmpeg (don't forget to install it!)

# VERSION

version 0.01

# ENVIRONMENT VARIABLES

To get list of all environment variables:

    grep -o -P "CAMSHOTBOT_\w+" lib/Telegram/CamshotBot.pm | sort -u

List (useful for Docker):

    CAMSHOTBOT_CONFIG
    CAMSHOTBOT_DOMAIN
    CAMSHOTBOT_FFMPEG_DOCKER
    CAMSHOTBOT_LAST_SHOT_FILENAME
    CAMSHOTBOT_POLLING
    CAMSHOTBOT_STREAM_URL
    CAMSHOTBOT_TELEGRAM_API_TOKEN

To check which variables are set you can run

printenv | grep CAMSHOTBOT\_\* | sort -u

# RUNNING

1) Place .camshotbot file in home user directory or camshotbot.conf.json in directory from what you will run camshotbot
Add all est

2) As alternative you can set all CAMSHOTBOT\_\* environment variables

3) run camshotbot daemon or docker-compose up

# DEVELOPMENT

If you want to run unit test without dzil test

    prove -l -v t  or perl -Ilib

# AUTHOR

Pavel Serikov <pavelsr@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Pavel Serikov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
