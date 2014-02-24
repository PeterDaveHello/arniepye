#!/usr/bin/env python

"""
Tests for the arniepye package.
"""

import unittest
from mock import patch, Mock

import os

from arniepye.cli import main as cli
from arniepye import main

from arniepye.test import ENV, REASON


@unittest.skipUnless(os.getenv(ENV), REASON)  # pylint: disable=R0904
class TestCLI(unittest.TestCase):  # pylint: disable=R0904
    """Integration tests for the ArniePye CLI."""

    def test_main_help(self):
        """Verify the CLI help text can be requested."""
        self.assertRaises(SystemExit, cli, ['--help'])

    def test_install_error(self):
        """Verify an error occurs when no package specified to install."""
        self.assertRaises(SystemExit, cli, ['install'])

    def test_uninstall_error(self):
        """Verify an error occurs when no package specified to uninstall."""
        self.assertRaises(SystemExit, cli, ['uninstall'])

    @patch('sys.platform', 'win32')
    def test_install_uninstall(self):
        """Verify the install/uninstall CLI can be called."""
        self.assertIs(None, cli(['install', 'testpackage']))
        self.assertIs(None, cli(['uninstall', 'testpackage']))

    # TODO: mock out the server URLs?
    # TODO: should the project name be an argument?
    def test_upload(self):
        """Verify the upload CLI can be called."""
        self.assertRaises(SystemExit, cli, ['upload'])

    def test_serve(self):
        """Verify the server CLI can be called."""
        self.assertIs(None, cli(['serve', '--test']))

    def test_no_command(self):
        """Verify that a subcommand is required."""
        self.assertRaises(SystemExit, cli, [])

    @patch('arniepye.cli._run_serve', Mock(side_effect=KeyboardInterrupt))
    def test_interrupt(self):
        """Verify that a command can be cancelled."""
        self.assertRaises(SystemExit, cli, ['serve'])


@patch('arniepye.cli._run_serve', Mock(return_value=True))  # pylint: disable=R0904
class TestLogging(unittest.TestCase):  # pylint: disable=R0904
    """Integration tests for the CLI logging."""

    def test_verbose_1(self):
        """Verify verbose level 1 can be set."""
        self.assertIs(None, cli(['serve', '-v']))

    def test_verbose_2(self):
        """Verify verbose level 2 can be set."""
        self.assertIs(None, cli(['serve', '-vv']))

    def test_verbose_3(self):
        """Verify verbose level 1 can be set."""
        self.assertIs(None, cli(['serve', '-vvv']))


@unittest.skipUnless(os.getenv(ENV), REASON)  # pylint: disable=R0904
class TestMain(unittest.TestCase):  # pylint: disable=R0904
    """Integration tests for the ArniePye main entry points."""

    @patch('sys.platform', 'win32')
    def test_install_uninstall(self):
        """Verify a package can be installed."""
        self.assertTrue(main.install(['testpackage']))
        self.assertTrue(main.uninstall(['testpackage']))

    def test_serve(self):
        """Verify the server can be started."""
        self.assertTrue(main.serve(forever=False))
