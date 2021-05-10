import datetime
import os
import re
import zipfile
import xml.etree.ElementTree as ET


BACKUP_FILE_PATTERN = re.compile(".*_addin_[0-9]+[.]py$", re.IGNORECASE)
EXCLUDE = {"tests"}
CONFIG_FILE_NAME = "config.xml"


def looks_like_a_backup(file_name_to_check):
    return bool(BACKUP_FILE_PATTERN.match(file_name_to_check))


if __name__ == "__main__":
    current_path = os.path.dirname(os.path.abspath(__file__))

    # get relevant info
    tree = ET.parse(CONFIG_FILE_NAME)
    name = tree.find("{http://schemas.esri.com/Desktop/AddIns}Name").text
    version = tree.find("{http://schemas.esri.com/Desktop/AddIns}Version").text

    # set date to today
    tree.find("{http://schemas.esri.com/Desktop/AddIns}Date").text = datetime.date.today().strftime("%B %d, %Y")

    # write changes to config
    ET.register_namespace("", "http://schemas.esri.com/Desktop/AddIns")
    tree.write(CONFIG_FILE_NAME)

    output_directory = os.path.join(current_path, "../bin", name + "_v" + version)

    if not os.path.exists(output_directory):
        os.makedirs(output_directory)

    out_zip_name = os.path.join(output_directory, name + ".esriaddin")

    with zipfile.ZipFile(out_zip_name, "w", zipfile.ZIP_DEFLATED) as zip_file:

        for file_name in ("config.xml", "README.txt", "makeaddin.py"):
            zip_file.write(os.path.join(current_path, file_name), file_name)
        dirs_to_add = [("Images", False),
                       ("Install", False),
                       ("../geolog_plugins", True),
                       ("../geolog_core", True),
                       ("../pyswip", True),
                       ("../arcmap_toolbox", True)]

        for directory, copy_to_install in dirs_to_add:
            for (path, dirs, files) in os.walk(os.path.join(current_path, directory), topdown=True):
                dirs[:] = [d for d in dirs if d not in EXCLUDE]
                archive_path = os.path.relpath(path, current_path)
                if copy_to_install:
                    archive_path = os.path.join("Install", os.path.relpath(archive_path, ".."))
                found_file = False
                for file_name in (f for f in files if not looks_like_a_backup(f)):
                    archive_file = os.path.join(archive_path, file_name)
                    print(archive_file)
                    zip_file.write(os.path.join(path, file_name), archive_file)
                    found_file = True
                if not found_file:
                    zip_file.writestr(os.path.join(archive_path, "placeholder.txt"), "(Empty directory)")
