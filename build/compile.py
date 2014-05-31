#!/usr/bin/env python3
import os
import glob
import sys
import subprocess
import re

os.system("mkdir ../compiled")
plugins = glob.glob("*.sp")
PATTERN_REQUIREMENTS = re.compile(r'Total requirements:\s+(\d+)\sbytes')
total_bytes = 0
for plugin in plugins:  
    compiler_process = subprocess.Popen("spcomp.exe {0} -o../compiled/{1}".format(plugin, plugin.split(".")[0]), 
                                        stdout=subprocess.PIPE, stdin=subprocess.PIPE)
    stdout, stderr = compiler_process.communicate(b'\n')
    stdout = stdout.decode('ascii')
    print(stdout)
    print(stderr)
    for match in re.finditer(PATTERN_REQUIREMENTS, stdout):
        total_bytes += int(match.groups()[0])
print("Total bytes: {}".format(total_bytes))
os.system("pause")
sys.exit(0)
