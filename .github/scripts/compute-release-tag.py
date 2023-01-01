import os
import json, requests, re

GITHUB_ENV_PATH = os.getenv("GITHUB_ENV")

API_ENDPOINT="https://api.github.com/repos/RandomCoderOrg/udroid-download/releases"

headers = {
    "Content-Type": "application/x-www-form-urlencoded"
}

resp = requests.get(API_ENDPOINT, headers=headers)
Json_data = json.loads(resp.text)



BUILD_TYPE="AB"

# Geting the latest release tag name
lR = Json_data[0]['tag_name']
pattern = re.compile(r'V(\d+)(\D+)(\d+)')
match = pattern.findall(lR)
udroid_version, RELEASE_TYPE, udroid_download = match[0]
udroid_download = int(udroid_download) + 1

# Latest_release_tag = f"V{udroid_version}{RELEASE_TYPE}{udroid_download}"
Latest_release_tag = "V%s%s%s%s" % (udroid_version,BUILD_TYPE,RELEASE_TYPE,udroid_download)

with open(GITHUB_ENV_PATH, "a+") as f:
  f.write(Latest_release_tag)