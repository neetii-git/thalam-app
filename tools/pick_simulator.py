"""Prints the UDID of an available simulator (newest OS first). Used by the CI workflow.

Usage:  python3 tools/pick_simulator.py iOS iPhone
        python3 tools/pick_simulator.py watchOS "Apple Watch"
"""
import json
import re
import subprocess
import sys

platform, name_prefix = sys.argv[1], sys.argv[2]
devices = json.loads(subprocess.check_output(["xcrun", "simctl", "list", "devices", "available", "-j"]))["devices"]


def version(runtime_key):
    return [int(n) for n in re.findall(r"\d+", runtime_key.split(".")[-1])]


runtimes = sorted((key for key in devices if f".{platform}-" in key), key=version, reverse=True)
for runtime in runtimes:
    for device in devices[runtime]:
        if device["name"].startswith(name_prefix):
            print(device["udid"])
            sys.exit(0)
sys.exit(f"No {name_prefix} simulator found for {platform}")
