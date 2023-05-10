#!/usr/bin/env python3
import argparse
import logging
import os
import shutil
import subprocess
import sys
import zipfile

logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] %(levelname)s - %(message)s",
    handlers=[
        logging.FileHandler("/var/log/Multitool.log"),
        logging.StreamHandler(sys.stdout),
    ],
)


def download(tv_name: str, folder: str, download_folder: str,
             download_config: str) -> None:
    """Downloads files from FTP server using lftp."""
    os.chdir(download_folder)
    command = f"lftp -f {download_config}"
    logging.info(f"Channel {tv_name} - Starting download: {command}")
    subprocess.Popen(command.split())


def decompress(tv_name: str, folder: str, zip_file: str) -> None:
    """Extracts files from zip file."""
    logging.info(f"Channel {tv_name} - Starting decompression: {zip_file}")
    with zipfile.ZipFile(zip_file, "r") as zf:
        if len(zf.namelist()) != 24:
            logging.error(
                f"Channel {tv_name} - ERROR!!! file {zip_file} does not contain"
                f" the 24 files!!")
            return
        extract_folder = os.path.join(folder, "extracted")
        os.makedirs(extract_folder, exist_ok=True)
        zf.extractall(extract_folder)
        logging.info(
            f"Channel {tv_name} - File {zip_file} uncompressed successfully")


def rename(tv_name: str, folder: str, zip_file: str, delay: int) -> None:
    """Renames files according to TV channel names."""
    logging.info(
        f"Channel {tv_name} - Starting renaming process for {zip_file}")
    hour = -1
    for file_name in sorted(os.listdir(os.path.join(folder, "extracted"))):
        if not file_name.endswith(".mp4"):
            continue
        date = zip_file.split(".")[0]
        hour += 1
        new_name = f"{date}_{hour + delay:02d}_{tv_name}.mp4"
        os.rename(
            os.path.join(folder, "extracted", file_name),
            os.path.join(folder, "uploading", new_name),
        )
        logging.info(f"Channel {tv_name} - Renamed {file_name} to {new_name}")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="FTP Downloader - Unzipper - Renamer - Uploader")
    parser.add_argument("-k", "--tv_name", help="TV Name for platform",
                        required=True)
    parser.add_argument("-i", "--folder",
                        help="Folder where the files are going to be downloaded",
                        required=True)
    parser.add_argument("-o", "--download_folder",
                        help="The main folder of the downloader", required=True)
    parser.add_argument("-d", "--download_config",
                        help="Downloading configuration for lftp tool",
                        required=True)
    parser.add_argument("-t", "--timeout",
                        help="Timeout for waiting for downloaded files",
                        type=int, required=True)
    parser.add_argument("-r", "--delay", help="Hours delayed in the final name",
                        type=int, required=True)
    args = parser.parse_args()

    tv_name = args.tv_name
    folder = args.folder
    download_folder = args.download_folder
    download_config = args.download_config
    timeout = args.timeout
    delay = args.delay
    upload_folder = os.path.join(folder, "uploading")

    logging.info(
        "Welcome to the FTP Downloader - Unzipper - Renamer - Uploader "
        "(Version 1.0)")
    logging.info("Created by the fuckin' Ka Hache\n")

    # Display help menu
    if not (tv_name and folder and download_folder and download_config and
            timeout and delay):
        parser.print_help()
        sys.exit(0)

    logging.info(
        "For more help with the usage, please add the '-h' option to see the "
        "help menu\n")

    download(tv_name, folder, download_folder, download_config)

    # Process downloaded files
    logging.info(f"Channel {tv_name} - Waiting for downloaded files...")
    while True:
        events = subprocess.check_output(
            ["inotifywait", "-m", "-q", "-e", "close_write,moved_to",
             "--format", "%f", folder],
            universal_newlines=True,
        ).strip().split("\n")

        for event in events:
            if not event.endswith(".zip"):
                continue

            zip_file = os.path.join(folder, event)
            logging.info(f"Channel {tv_name} - Downloaded file: {zip_file}")

            # Check if the file has already been processed
            downloads_log = os.path.join("/var/tmp", f"{tv_name}.download")
            with open(downloads_log, "r") as f:
                if zip_file in f.read():
                    logging.warning(
                        f"Channel {tv_name} - File {zip_file} already "
                        f"processed!")
                    os.remove(zip_file)
                    continue

            # Process the zip file
            with open(downloads_log, "a") as f:
                f.write(f"{zip_file}\n")
            decompress(tv_name, folder, zip_file)
            rename(tv_name, folder, zip_file, delay)

            # Move files to the uploading folder
            logging.info(
                f"Channel {tv_name} - Moving files to upload folder...")
            os.makedirs(upload_folder, exist_ok=True)
            for file_name in os.listdir(os.path.join(folder, "extracted")):
                if file_name.endswith(".mp4"):
                    source = os.path.join(folder, "extracted", file_name)
                    destination = os.path.join(upload_folder, file_name)
                    shutil.move(source, destination)
                    logging.info(
                        f"Channel {tv_name} - Moved {file_name} to "
                        f"{destination}")

            # Remove the processed zip file
            os.remove(zip_file)
            logging.info(f"Channel {tv_name} - Removed file: {zip_file}")

        subprocess.call(["sleep", str(timeout)])


if __name__ == "__main__":
    main()
