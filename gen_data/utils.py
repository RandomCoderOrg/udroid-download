import json

def resolv_data(file,
                    suite:      str,
                    varients:   list,
                    Name:       str,
                    FriendlyName: str,
                    arch: list = ["aarch64", "armv7l", "armhf", "amd64", "x86_64"]
                    ):
    file = json.load(open(file, 'r'))
    
    # update suites list
    file["suites"].append(suite)
    
    # [WIP] create new suite
    new_suite = {
        f"{suite}" : {
            "variants" : varients,
        }
    }
    
    # register varients
    for variant in varients:
        new_suite[f"{suite}"][f"{variant}"] = {
            "arch" : arch,
        }
        
    # exp1
    # create new data(">/file", "sai", ["raw"], )
    
    
