import os
import subprocess

def add_suite(JsonFile: dict, suite: str) -> None:
    """ Add suite to the JsonFile

    Args:
        JsonFile (dict): The JsonFile
        suite (str): The suite to add
    """

    JsonFile["suites"].append(suite)
    JsonFile[suite] = {
        "varients": []
    }


def add_varient(JsonFile: dict, suite: str, varient: str, Name: str, FirendlyName: str) -> None:
    """ Add varient to the JsonFile"""
    
    JsonFile[suite]["varients"].append(varient)
    JsonFile[suite][varient] = {
        # adding default arch to the varients
        "arch": [],
        "Name": Name,
        "FirendlyName": FirendlyName
    }

def add_arch(JsonFile: dict, suite: str, varient: str, arch:list[str]) -> None:
    """ Add arch to the JsonFile

    Args:
        JsonFile (dict): The JsonFile
        suite (str): The suite to add archs
        varient (str): The varient to archs
        arch (list[str]): The arch to add
    """
    
    import arch as archAlt
    archAltName = archAlt.ReverseTranslate()
    
    #revArchLst = {'armhf': ['armhf', 'arm'], 'aarch64': ['arm64', 'aarch64'], 'amd64': ['amd64', 'x86_64']}
    revArchLst = archAltName[arch]
    for revArch in revArchLst:
        JsonFile[suite][varient]["arch"].append(revArch)
        JsonFile[suite][varient][f"{arch}url"] = ""
        JsonFile[suite][varient][f"{arch}sha"] = ""


def resolv_data(
       json_data: dict,
       suite: str,
       variant: str,
       arch: list[str],
       Name: str = ...,
       FriendlyName: str = ...,
    ) -> dict:
    """Resolvs the data and add it to the json_data

    Args:
        json_data (dict): _description_
        suite (str): _description_
        variant (str): _description_
        arch (list[str]): _description_
        Name (str, optional): _description_. Defaults to ....
        FriendlyName (str, optional): _description_. Defaults to ....

    Returns:
        dict: _description_
    """
    if Name is ...:
        Name = f"{suite}-{variant}"
    
    if FriendlyName is ...:
        FriendlyName = f"{suite} {variant}"
        
    if suite not in json_data["suites"]:
        add_suite(json_data,suite)
    
    if variant not in json_data[suite]["varients"]:
        add_varient(json_data, suite, variant, Name, FriendlyName)
    
    for arc in arch:
        if arc not in json_data[suite][variant]["arch"]:
            add_arch(json_data, suite, variant, arc)
    
    return json_data

def getfilesR(path: str) -> list:
    """Get all files in a directory recursively

    Args:
        path (str): The path to the directory

    Returns:
        list: The list of files
    """
   
    files = []
    # include depth
    for r, d, f in os.walk(path):
        for file in f:
            files.append(os.path.join(r, file))
    
    return files
    
def Popen(cmd: list) -> str:
    """Run a command and return the output as a string

    Args:
        cmd (list): The command to run

    Returns:
        str: The output of the command
    """
    return subprocess.Popen(cmd, shell=False, stdout=subprocess.PIPE).stdout.read().strip().decode('utf-8')
