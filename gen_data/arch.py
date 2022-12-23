
def translated_arch() -> dict:
    """System architectures translated to deb package architecture names

    Returns:
        dict: dictionary of arch names
    """
    # TODO Need improve above docstring
    
    # SystemArchitecture:PackageArchitecture
    return dict(
        {
            "armhf":    "armhf",
            "arm":      "armhf",
            "arm64":    "aarch64",
            "aarch64":  "aarch64",
            "amd64":    "amd64",
            "x86_64":   "amd64"
        }
    )



def ReverseTranslate() -> dict:
    StoPdict = translated_arch();
    PtoSdict = {}
    
    for SysArch,PakArch in zip(StoPdict.keys(),StoPdict.values()):
        if PakArch in PtoSdict:
            PtoSdict[PakArch] = [PtoSdict[PakArch]]
            PtoSdict[PakArch].append(SysArch)
        else:
            PtoSdict[PakArch] = SysArch

    return PtoSdict
