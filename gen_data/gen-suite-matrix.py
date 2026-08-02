import glob
import json
import os

SUITES_DIR="./suites"

# ARCHITECTURE CAN BE: amd64, arm64, armhf
# it has high priority over the architecture specified in the suite
# set it to "all" to build all architectures defined in the <suite>/<varient>.sh file
# "all" is currently broken!
ARCHITECTURES = ["arm64", "armhf"]


def variant_architectures(variant_path: str) -> list[str]:
	"""Return a variant's CI architectures, or the project defaults."""
	manifest = os.path.join(variant_path, ".architectures")
	if not os.path.exists(manifest):
		return ARCHITECTURES

	with open(manifest, encoding="utf-8") as architectures_file:
		architectures = [
			word.strip()
			for line in architectures_file
			for word in line.split()
			if word.strip()
		]

	unsupported = sorted(set(architectures) - set(ARCHITECTURES))
	if unsupported:
		raise ValueError(
			f"Unsupported architecture in {manifest}: {', '.join(unsupported)}"
		)
	if not architectures:
		raise ValueError(f"No architectures declared in {manifest}")
	return architectures

# Can be moved to utils?
def generate_matrix_json() -> str:
	json_data = { "include": [ ] }

	for variantPath in sorted(glob.iglob(f"{SUITES_DIR}/*/*", recursive=False)):
		if not os.path.isdir(variantPath):
			continue

		suiteName = os.path.basename(os.path.dirname(variantPath))
		variantName = os.path.basename(variantPath)

		if os.path.exists(f"{SUITES_DIR}/{suiteName}/.no-matrix-build"):
			continue
		if os.path.exists(f"{variantPath}/.no-matrix-build"):
			continue

		for arch in variant_architectures(variantPath):
			json_data['include'].append({
				'suite': suiteName,
				'variant': variantName,
				'architecture': arch,
			})
		
	return json.dumps(json_data, indent=None)


if __name__ == '__main__':
	print(generate_matrix_json())
