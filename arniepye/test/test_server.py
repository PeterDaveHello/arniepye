#!/usr/bin/env python

"""
Unit tests for the arniepye.server module.
"""

import unittest
from mock import patch, Mock

import subprocess

from arniepye import server


class TestRun(unittest.TestCase):  # pylint: disable=R0904
    """Unit tests for the run function."""  # pylint: disable=C0103,W0212

    def test_serve(self):
        """Verify the server can be started and stopped."""
        self.assertTrue(server.run(forever=False))

    @patch('subprocess.Popen.poll', Mock(return_value=1))
    def test_serve_exit(self):
        """Verify the server process can exit normally."""
        self.assertTrue(server.run())

    def test_serve_interrupt(self):
        """Verify the server can be interrupted."""
        def side_effect(*args):
            """First call: None, second call, raise KeyboardIntterupt."""
            def second_call(*args):
                raise KeyboardInterrupt()
            subprocess.Popen.poll.side_effect = second_call
            return None
        with patch('subprocess.Popen.poll', Mock(side_effect=side_effect)):
            self.assertFalse(server.run())


if __name__ == '__main__':  # pragma: no cover, manual test
    unittest.main()