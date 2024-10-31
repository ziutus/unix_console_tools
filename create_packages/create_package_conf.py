

import os
import sys

filename = '.create_package.conf'

dirname = os.getcwd().split(os.sep)[-1]

options = ["SOFTWARE_VERSION", "SOFTWARE_RELEASE", "SOFTWARE_NAME", "SOFTWARE_DEPENDS", "MAINTAINER",
           "SOFTWARE_DESCRIPTION", "SOFTWARE_DESCRIPTION_LONG", "SOFTWARE_LICENCE", "SOFTWARE_GROUP",
           "SOFTWARE_HOMEPAGE", "SOFTWARE_SEPARATE_DIR_OPT", "USR_LOCAL"]

options_env = ["MAINTAINER", "SOFTWARE_LICENCE"]

options_default = {
    "SOFTWARE_LICENCE": "GPL",
    "SOFTWARE_GROUP": "Development/Tools",
    "USR_LOCAL": "yes",
    "SOFTWARE_SEPARATE_DIR_OPT": "yes",
    "SOFTWARE_VERSION": "0.0.1",
    "SOFTWARE_RELEASE": "1",
    "SOFTWARE_DEPENDS": "base-files",
    "SOFTWARE_NAME": dirname
}


def ask_nice(message, default_value=''):
    value = input(f"{message} [{default_value}]: ").strip()
    return value if value else default_value


MYFILE = {**options_default}

# Checking environment variables
for option in options_env:
    if option in os.environ:
        MYFILE[option] = os.environ[option]

# Reading options from the configuration file
if os.path.exists(filename):
    with open(filename, 'r') as file:
        for line in file:
            if line.strip():
                key, value = line.strip().split('=', 1)
                MYFILE[key] = value.strip('"')

# Asking for options with values read from config file
OPTIONS = {option: ask_nice(option, MYFILE.get(option, '')) for option in options}

# Writing configuration file
with open(filename, 'w') as file:
    for option in options:
        file.write(f'{option}="{OPTIONS[option]}"\n')

# End of script
sys.exit(0)