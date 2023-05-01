import json
import glob

SUITES_DIR="./suites/*"

# ARCHITECTURE CAN BE: amd64, arm64, armhf
# it has high priority over the architecture specified in the suite
# set it to "all" to build all architectures defined in the <suite>/<varient>.sh file
# "all" is currently broken!
ARCHITECTURES = [ "all" ] #, "arm64", "armhf" ]

# Can be moved to utils?
def generate_matrix_json() -> str:
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
		
	return json.dumps(json_data, indent=None)
	
if __name__ == '__main__':
	print(generate_matrix_json())
