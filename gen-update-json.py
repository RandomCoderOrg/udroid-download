import os
import json
import optparse

GIT_ROOT        = os.popen("git rev-parse --show-toplevel").read().strip()
DIR             = "."
VERBOSE         = False
JSON_CONF       = f"{GIT_ROOT}/distro-data.json"

def update_json_conf(file) -> None:
    data = strip_info(file)
    jdata = json.load(open(JSON_CONF, 'r'))
    
    # update url
    jdata[data[0]][data[1]][f"{data[2]}Url"] = get_release_url(
                                                RELEASE_TAG, data[3])
    
    # update sha
    jdata[data[0]][data[1]][f"{data[2]}sha"] = os.popen(
        f"sha256sum {DIR}/{data[3]}").read().split()[0]
    
    # update JSON_CONF
    file = open(JSON_CONF, 'w')
    json.dump(jdata, file, indent=4)
    

def strip_info(file):
    basename = os.path.basename(file)
    name = os.path.splitext(basename)[0]
    name = os.path.splitext(name)[0]
    
    sp = name.split("-")
    ar = {
        "armhf":    "armhf",
        "arm":      "armhf",
        "arm64":    "aarch64",
        "aarch64":  "aarch64",
        "amd64":    "amd64",
        "x86_64":   "amd64"
    }

    suite   = sp[0]
    variant = sp[1]
    arch    = ar[sp[2]]
        
    return [suite, variant, arch, basename]

def get_release_url(release_tag, file) -> str:
    repo="https://github.com/RandomCoderOrg/udroid-download"
    url="{}/releases/download/{}/{}".format(repo, release_tag, file)
    return url
    
if __name__ == '__main__':
    # parse command line options
    parser = optparse.OptionParser()
    
    parser.add_option('-R', '--release-tag', dest='release_tag',
                          help='release tag', type=str)

    options, args = parser.parse_args()
    # get release tag
    
    RELEASE_TAG = options.release_tag
    for file in os.listdir(DIR):
            if file.endswith(".tar.gz"):
                update_json_conf(file)
                
