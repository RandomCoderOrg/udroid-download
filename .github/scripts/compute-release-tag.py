import os
import json, requests, re

GITHUB_ENV_PATH = os.getenv("GITHUB_ENV")

headers = {
    "Content-Type": "application/x-www-form-urlencoded"
}

API_ENDPOINT_UOA="https://api.github.com/repos/RandomCoderOrg/ubuntu-on-android/releases"
resp_uoa = requests.get(API_ENDPOINT_UOA, headers=headers)
Json_data2 = json.loads(resp_uoa.text)

# uV = ["v3.1-alpha"][0]   # For testing
udroid_version = Json_data2[0]['tag_name'].replace("v","")

API_ENDPOINT_UA="https://api.github.com/repos/RandomCoderOrg/udroid-download/releases"
resp_ud = requests.get(API_ENDPOINT_UA, headers=headers)
Json_data = json.loads(resp_ud.text)


match = re.compile(r'V(\d+)(\D+)(\d+)').findall(Json_data[0]['tag_name'])
_, RELEASE_TYPE, IterationNumber = match[0]
IterationNumber = int(IterationNumber) + 1

BUILD_TYPE="AB"

Latest_release_tag = "V-%s-%s%s%s" % (udroid_version,BUILD_TYPE,RELEASE_TYPE,IterationNumber)

with open(GITHUB_ENV_PATH, "a+") as f:
  f.write(Latest_release_tag)

print(Latest_release_tag)