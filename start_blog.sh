#!/usr/bin/env bash

#####################################################
#
#	Start the blog using supervisord & virtualenv
#
#####################################################
# Source the virtualenv

source $PWD/nikola/bin/activate

# Run supervisord
 supervisord -c $PWD/supervisord.conf

exit 0

