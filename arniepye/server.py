#!/usr/bin/env python

"""
Wrapper for pypiserver to serve packages.
"""

import os
import sys
import shutil
import socket
import subprocess
import logging

from arniepye import settings

FILES = os.path.join(os.path.dirname(__file__), 'files')


def run(port=8080, path=settings.PACKAGES_DIR, forever=True, temp=False):
    """Create a packages directory and run the server forever.
    """
    # Create the server files
    _setup(path, port)

    # Start PyPI
    logging.debug("creating the pypi process...")
    process = _pypiserver(port, path)
    try:
        logging.debug("pypi server started")
        while process.poll() is None and forever:
            pass
    except KeyboardInterrupt:
        logging.warning("pypi manually terminated")
        return False
    finally:
        process.terminate()
        _teardown(path, remove=temp)  # clean up the server files
        logging.debug("pypi server stopped")

    return True


def _pypiserver(port, path):
    """Start and return a pypiserver process."""
    args = [sys.executable, '-m', 'pypiserver', '-p', str(port),
            '-P', settings.HTACCESS, path]
    logging.debug("$ {0}".format(' '.join(args)))
    return subprocess.Popen(args)


def _setup(path, port):
    """Set up the packages directory."""
    # Create the packages directory
    if not os.path.isdir(path):
        logging.info("creating packages directory at '{}'...".format(path))
        os.mkdir(path)
    # Copy the bootstrap files
    bootstrap = os.path.join(path, 'bootstrap')
    shutil.rmtree(bootstrap, ignore_errors=True)
    shutil.copytree(FILES, bootstrap)
    # Update the bootstrap script with the current hostname
    bootstrap_py = os.path.join(bootstrap, 'bootstrap.py')
    port = '' if port == 80 else ':' + str(port)
    url = "'http://{0}{1}/simple/'".format(socket.getfqdn(), port)
    with open(bootstrap_py, 'r') as infile:
        lines = infile.readlines()
    with open(bootstrap_py, 'w') as outfile:
        for line in lines:
            if line.startswith("SERVER_URL = None"):
                line = line.replace('None', url)
            outfile.write(line)
    # Move the .htaccess file into place
    htaccess = os.path.join(bootstrap, 'htaccess')
    shutil.move(htaccess, os.path.expanduser(settings.HTACCESS))


def _teardown(path, remove=False):
    """Tear down the packages directory if specified."""
    if remove or len(os.listdir(path)) <= 1:  # ignore 'bootstrap' folder
        logging.info("removing packages directory...")
        shutil.rmtree(path)


if __name__ == '__main__':  # pragma: no cover, manual test
    run(forever=False, temp=True)