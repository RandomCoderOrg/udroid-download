import json
import glob

SUITES_DIR="./suites/*"

# ARCHITECTURE CAN BE: all, amd64, arm64, armhf
# it has high priority over the architecture specified in the suite
# set it to "all" to build all architectures defined in the <suite>/<varient>.sh file
ARCHITECTURES = [ "all" ]

def generate_matrix_json() -> None:
	json_data = { "include": [ ] }
	
	for arch in ARCHITECTURES:
		for variantPath in glob.iglob(f"{SUITES_DIR}/*", recursive=False):
			suiteName = variantPath.split('/')[2]
			variantName = variantPath.split('/')[3]
			
			element = { }
			
			element['suite'] = suiteName
			element['variant'] = variantName
			element['architecture'] = arch
			
			json_data['include'].append(element)
		
	print(json.dumps(json_data, sort_keys=True, indent=None, separators=(',', ':')))
	
if __name__ == '__main__':
	generate_matrix_json()
