import os
import json
import optparse
import utils
import arch

GIT_ROOT = utils.Popen( ["/usr/bin/git", "rev-parse", "--show-toplevel"] )
GIT_REMOTE_URL = utils.Popen( ["/usr/bin/git", "config", "--get", "remote.origin.url"] )
DIR = "."
VERBOSE = False
DISTRO_DATA_JSON = f"{GIT_ROOT}/distro-data.json"

def update_data_json(file_path: str) -> None:
    data = strip_info(file_path)
    jdata = json.load(open(DISTRO_DATA_JSON, 'r'))
    
    # resolv data
    jdata = utils.resolv_data(jdata, data[0], data[1], [data[2]])
    
    # update url
    jdata[data[0]]  \
         [data[1]]  \
         [f"{data[2]}url"] = get_release_url(RELEASE_TAG, data[3])
    
    # update sha
    jdata[data[0]] \
         [data[1]] \
         [f"{data[2]}sha"] = utils.Popen( ["sha256sum", f"{file_path}"] ).split()[0]
    
    # update DISTRO_DATA_JSON
    file = open(DISTRO_DATA_JSON, 'w')
    json.dump(jdata, file, indent=4)
    
def strip_info(file_path: str) -> list:
    basename = os.path.basename(file_path)
    name = os.path.splitext(basename)[0]
    name = os.path.splitext(name)[0]
    
    sp = name.split("-")
    StoPdict = arch.translated_arch()

    suite = sp[0]
    variant = sp[1]
    packageArchitecture = StoPdict[sp[2]]
    
    return [suite, variant, packageArchitecture, basename]

def get_release_url(release_tag: str, file_path: str) -> str:
    url = "{}/releases/download/{}/{}".format(GIT_REMOTE_URL, release_tag, file_path)
    
    return url
    
if __name__ == '__main__':
    # parse command line options
    parser = optparse.OptionParser()
    
    parser.add_option('-R', '--release-tag', dest='release_tag',
                          help='release tag', type=str)
    
    options, args = parser.parse_args()
    
    # get release tag
    RELEASE_TAG = options.release_tag
    for file_path in utils.getfilesR(DIR):
        if file_path.endswith(".tar.gz"):
            update_data_json(file_path)
            
