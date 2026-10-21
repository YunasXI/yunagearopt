"""Builds the VanaCore (native) version of YunaGearOpt from the same files as the Ashita version.

    python native/build.py [target folder]

The target defaults to VanaCore's native addons folder next to this Ashita install
(..\\..\\..\\Vanacore\\addons\\vanacore\\yunagearopt). The Ashita version's yunagearopt.lua becomes core.lua; this
folder's yunagearopt.lua (the VanaCore entry) loads it. Settings and exports stay where they were: nothing in the
target's settings or generated exports is removed."""
import os
import shutil
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)                      # the Ashita version (the repo)
DEFAULT = os.path.normpath(os.path.join(ROOT, '..', '..', '..', 'Vanacore', 'addons', 'vanacore', 'yunagearopt'))

LUA = ['data.lua', 'bis.lua', 'stats.lua', 'augments.lua', 'server_stats.lua']
FOLDERS = ['images', 'fonts']
READMES = ['gearswap', 'legacyac', 'lac']


def build(target):
    os.makedirs(target, exist_ok=True)
    shutil.copyfile(os.path.join(HERE, 'yunagearopt.lua'), os.path.join(target, 'yunagearopt.lua'))
    shutil.copyfile(os.path.join(ROOT, 'yunagearopt.lua'), os.path.join(target, 'core.lua'))
    for f in LUA:
        shutil.copyfile(os.path.join(ROOT, f), os.path.join(target, f))
    for d in FOLDERS:
        shutil.copytree(os.path.join(ROOT, d), os.path.join(target, d), dirs_exist_ok=True)
    for d in READMES:
        os.makedirs(os.path.join(target, d), exist_ok=True)
        shutil.copyfile(os.path.join(ROOT, d, 'README.txt'), os.path.join(target, d, 'README.txt'))
    shutil.copyfile(os.path.join(ROOT, 'README.md'), os.path.join(target, 'README.md'))
    return target


if __name__ == '__main__':
    out = build(os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT)
    print('built', out)
