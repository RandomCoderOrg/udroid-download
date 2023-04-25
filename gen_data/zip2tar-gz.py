#! /usr/bin/env python

"""zip2tar """

import sys
import os
import utils
from zipfile import ZipFile
import tarfile
import time

def main(ifn, ofn):
    with ZipFile(ifn) as zipf:
        with tarfile.open(ofn, 'w:gz') as tarf:
            for zip_info in zipf.infolist():
                #print zip_info.filename, zip_info.file_size
                tar_info = tarfile.TarInfo(name=zip_info.filename)
                tar_info.size = zip_info.file_size
                tar_info.mtime = time.mktime(list(zip_info.date_time) +
                                         [-1, -1, -1])
                tarf.addfile(
                    tarinfo=tar_info,
                    fileobj=zipf.open(zip_info.filename)
                )

input_file_name = sys.argv[1]
output_file_name = os.path.splitext(input_file_name)[0] + '.tar.gz'

main(input_file_name, output_file_name)
