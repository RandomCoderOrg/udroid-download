import json
import utils
import glob, os

SUITES_DIR="./suites/*"
ARCHITECTURES = [ "armhf" ] #, "arm64", "amd64" ]

def generate_matrix_json() -> None:
	json_data = { "include": [ ] }
	
	for arch in ARCHITECTURES:
		for variantPath in glob.iglob(f"{SUITES_DIR}/*", recursive=False):
			suiteName = variantPath.split('/')[2]
			variantName = variantPath.split('/')[3]
			
			element = { }
			
			element['suite'] = suiteName
			element['variants'] = variantName
			element['architecture'] = arch
			
			json_data['include'].append(element)
		
	print(json.dumps(json_data, indent=4))
	
if __name__ == '__main__':
	generate_matrix_json()