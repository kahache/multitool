import os
import shutil
import tempfile
import unittest
from unittest.mock import patch, call

from Multitool_full import download, decompress, rename


class MyAppTestCase(unittest.TestCase):
    def setUp(self):
        self.test_dir = tempfile.mkdtemp()
        self.download_folder = os.path.join(self.test_dir, "download")
        os.makedirs(self.download_folder, exist_ok=True)

        self.tv_name = "TV1"
        self.folder = "/path/to/folder"

    def tearDown(self):
        shutil.rmtree(self.test_dir)

    @patch("subprocess.Popen")
    def test_download(self, mock_popen):
        download_config = "download.config"

        download(self.tv_name, self.folder, self.download_folder,
                 download_config)

        expected_command = f"lftp -f {download_config}"
        mock_popen.assert_called_once_with(expected_command.split(),
                                           cwd=self.download_folder)

    def test_decompress(self):
        zip_file = os.path.join(self.test_dir, "test.zip")
        extract_folder = os.path.join(self.folder, "extracted")
        os.makedirs(extract_folder, exist_ok=True)

        with open(zip_file, "w") as f:
            f.write("Test zip file")

        decompress(self.tv_name, self.folder, zip_file)

        self.assertTrue(os.path.exists(extract_folder))
        self.assertEqual(len(os.listdir(extract_folder)), 0)  # No files
        # extracted as it's a dummy zip file

    def test_rename(self):
        zip_file = os.path.join(self.test_dir, "test.zip")
        delay = 2

        with open(zip_file, "w") as f:
            f.write("Test zip file")

        with patch("os.rename") as mock_rename:
            rename(self.tv_name, self.folder, zip_file, delay)

            expected_calls = [
                call(os.path.join(self.folder, "extracted", file_name),
                     os.path.join(self.folder, "uploading", new_name))
                for file_name, new_name in [
                    ("file1.mp4", "2023-05-10_02_TV1.mp4"),
                    ("file2.mp4", "2023-05-10_03_TV1.mp4"),
                    ("file3.mp4", "2023-05-10_04_TV1.mp4"),
                ]
            ]
            mock_rename.assert_has_calls(expected_calls)

if __name__ == "__main__":
    unittest.main()
