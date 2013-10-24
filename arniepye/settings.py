#!/usr/bin/env python

"""
Settings for ArniePye.
"""

import os
import logging

# Server settings
SERVER_URLS = [
'http://arnie/simple/',  # main server
'http://arnie-dev/simple/',  # development server
'http://127.0.0.1:8080/simple/',  # local server
]
FALLBACK_URLS = [
'http://DW-89:8080/simple/',  # TODO: remove once arnie is working
'https://pypi.python.org/simple/',
]
PACKAGES_DIR = os.path.expanduser("~/packages")
HTACCESS = os.path.expanduser("~/.htaccess")


# Logging settings
DEFAULT_LOGGING_FORMAT = "%(message)s"
VERBOSE_LOGGING_FORMAT = "%(levelname)s: %(message)s"
VERBOSE2_LOGGING_FORMAT = "%(asctime)s: %(levelname)s: %(message)s"
VERBOSE3_LOGGING_FORMAT = "%(asctime)s: %(levelname)s: %(module)s:%(lineno)d: %(message)s"
DEFAULT_LOGGING_LEVEL = logging.INFO
VERBOSE_LOGGING_LEVEL = logging.DEBUG
