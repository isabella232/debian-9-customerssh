#!/usr/bin/env python3

import unittest
from testpack_helper_library.unittests.dockertests import Test1and1Common


class Test1and1Image(Test1and1Common):
    def file_mode_test(self, filename: str, mode: str):
        # Compare (eg) drwx???rw- to drwxr-xrw-
        result = self.exec("ls -ld %s" % filename)
        self.assertFalse(
            result.find("No such file or directory") > -1,
            msg="%s is missing" % filename
        )
        for char_count in range(0, len(mode)):
            self.assertTrue(
                mode[char_count] == '?' or (mode[char_count] == result[char_count]),
                msg="%s incorrect mode: %s" % (filename, result)
            )

    def file_content_test(self, filename: str, content: list):
        result = self.exec("cat %s" % filename)
        self.assertFalse(
            result.find("No such file or directory") > -1,
            msg="%s is missing" % filename
        )
        for search_item in content:
            self.assertTrue(
                result.find(search_item) > -1,
                msg="Missing : %s" % search_item
            )

    # <tests to run>

    def test_lsb_release(self):
        self.file_content_test(
            "/etc/debian_version",
            [
                "9.",
            ]
        )

    def test_php71_installed(self):
        self.assertPackageIsInstalled("php7.1-cli")

    def test_php72_installed(self):
        self.assertPackageIsInstalled("php7.2-cli")

    def test_php73_installed(self):
        self.assertPackageIsInstalled("php7.3-cli")

    def test_git_installed(self):
        self.assertPackageIsInstalled("git")

    def test_telnet_installed(self):
        self.assertPackageIsInstalled("telnet")

    def test_mariadb_installed(self):
        self.assertPackageIsInstalled("mariadb-client-10.1")

    def test_python2_installed(self):
        self.assertPackageIsInstalled("python2.7")

    def test_python3_installed(self):
        self.assertPackageIsInstalled("python3")

    def test_rake_installed(self):
        self.assertPackageIsInstalled("rake")

    def test_redis_tools_installed(self):
        self.assertPackageIsInstalled("redis-tools")

    def test_ruby23_installed(self):
        self.assertPackageIsInstalled("ruby2.3")

    def test_nano_installed(self):
        self.assertPackageIsInstalled("nano")

    def test_vim_installed(self):
        self.assertPackageIsInstalled("vim")

    def test_hooks_folder(self):
        self.file_mode_test("/hooks", "drwxr-xr-x")

    def test_init_folder(self):
        self.file_mode_test("/init", "drwxr-xr-x")

    def test_init_entrypoint(self):
        self.file_mode_test("/init/entrypoint", "-rwxr-xr-x")

    def test_apt_lists_empty(self):
        self.assertEqual("total 0\n", self.exec("ls -l /var/lib/apt/lists/"))

    # </tests to run>

if __name__ == '__main__':
    unittest.main(verbosity=1)
