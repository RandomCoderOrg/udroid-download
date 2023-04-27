import os
import json
import optparse
import utils
import arch

GIT_ROOT = utils.Popen("git rev-parse --show-toplevel")
GIT_REMOTE_URL = utils.Popen("git config --get remote.origin.url")
DIR = "."
VERBOSE = False
JSON_CONF = f"{GIT_ROOT}/distro-data.json"

def update_json_conf(file) -> None:
    data = strip_info(file)
    jdata = json.load(open(JSON_CONF, 'r'))
    
    # resolv data
    jdata = utils.resolv_data(jdata, data[0], data[1], [data[2]])
    
    # update url
    jdata[data[0]]  \
         [data[1]]  \
         [f"{data[2]}url"] = get_release_url(RELEASE_TAG, data[3])
    
    # update sha
    jdata[data[0]] \
         [data[1]] \
         [f"{data[2]}sha"] = os.popen(f"sha256sum {file}").read().split()[0]
    
    # update JSON_CONF
    file = open(JSON_CONF, 'w')
    json.dump(jdata, file, indent=4)
    
def strip_info(file):
    basename = os.path.basename(file)
    name = os.path.splitext(basename)[0]
    name = os.path.splitext(name)[0]
    
    sp = name.split("-")
    StoPdict = arch.translated_arch()

    suite = sp[0]
    variant = sp[1]
    packageArchitecture = StoPdict[sp[2]]
    
    return [suite, variant, packageArchitecture, basename]

def get_release_url(release_tag, file) -> str:
    url = "{}/releases/download/{}/{}".format(GIT_REMOTE_URL, release_tag, file)
    return url
    
if __name__ == '__main__':
    # parse command line options
    parser = optparse.OptionParser()
    
    parser.add_option('-R', '--release-tag', dest='release_tag',
                          help='release tag', type=str)

    options, args = parser.parse_args()
    # get release tag
    
    from utils import getfilesR
    
    RELEASE_TAG = options.release_tag
    for file in getfilesR(DIR):
            if file.endswith(".tar.gz"):
                update_json_conf(file)
                
