markdown
Copy code
# FTP Downloader - Unzipper - Renamer - Uploader

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

This is a Python script that facilitates the process of downloading files from an FTP server, extracting them from zip archives, renaming the files based on TV channel names, and uploading them to another location. It is designed to automate the workflow for TV content processing.

## Features

- Downloads files from an FTP server using the `lftp` command-line tool.
- Extracts files from zip archives.
- Renames files according to TV channel names and adds a configurable delay.
- Moves the renamed files to an "uploading" folder.
- Supports configurable timeouts for waiting for downloaded files.

## Installation

1. Clone the repository:

   ```shell
   git clone https://github.com/your-username/ftp-downloader.git
Install the required dependencies:
shell
Copy code
pip install -r requirements.txt
Usage

Configure the FTP connection and download settings in download.config.
Run the script with the desired command-line arguments:
shell
Copy code
python my_app.py -k TV1 -i /path/to/folder -o /path/to/download -d download.config -t 60 -r 2
-k/--tv_name: The TV name for the platform (required).
-i/--folder: The folder where the files are downloaded (required).
-o/--download_folder: The main folder of the downloader (required).
-d/--download_config: The downloading configuration for the lftp tool (required).
-t/--timeout: Timeout (in seconds) for waiting for downloaded files (required).
-r/--delay: Hours delayed in the final file name (required).

## Unit Tests

The project includes a comprehensive set of unit tests to ensure the correctness of the functionality. To run the unit tests, execute the following command:

shell
Copy code
python -m unittest discover
Contributing

Contributions are welcome! If you have any suggestions, bug reports, or feature requests, please open an issue or submit a pull request.

## License

This project is licensed under the MIT License. See the LICENSE file for details.

Feel free to customize the content as per your project's specific details and requirements.
