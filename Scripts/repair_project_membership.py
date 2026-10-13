#!/usr/bin/env python3
"""Use Xcode's synchronized source folders; preserve signing and other user settings."""
import json, pathlib, subprocess, shutil, hashlib
root = pathlib.Path(__file__).resolve().parents[1]
path = root / 'ILand.xcodeproj/project.pbxproj'
data = json.loads(subprocess.check_output(['plutil', '-convert', 'json', '-o', '-', str(path)]))
objects = data['objects']
folders = {o.get('path'): key for key, o in objects.items() if o['isa'] in ['PBXGroup', 'PBXFileSystemSynchronizedRootGroup'] and o.get('path') in ['ILand', 'Shared', 'ILandWidgets', 'Tests', 'UITests']}
target_folders = {'ILand': ['ILand', 'Shared'], 'ILandWidgets': ['ILandWidgets', 'Shared'], 'ILandTests': ['Tests'], 'ILandUITests': ['UITests']}
for key, obj in list(objects.items()):
    if obj['isa'] != 'PBXNativeTarget' or obj.get('name') not in target_folders: continue
    paths = target_folders[obj['name']]
    obj['fileSystemSynchronizedGroups'] = [folders[p] for p in paths]
    for phase in obj['buildPhases']:
        if objects[phase]['isa'] in ['PBXSourcesBuildPhase', 'PBXResourcesBuildPhase']:
            objects[phase]['files'] = []
    for folder in paths:
        group = objects[folders[folder]]
        group['isa'] = 'PBXFileSystemSynchronizedRootGroup'
        group.pop('children', None)
        group['explicitFileTypes'] = {}
        group['explicitFolders'] = []
        if folder in ['ILand', 'ILandWidgets']:
            exception = hashlib.sha1(('ILand-sync-' + folder).encode()).hexdigest()[:24].upper()
            objects[exception] = {'isa': 'PBXFileSystemSynchronizedBuildFileExceptionSet', 'membershipExceptions': ['Info.plist'] + (['ILand.entitlements'] if folder == 'ILand' else []), 'target': key}
            group['exceptions'] = [exception]
data['objectVersion'] = '77'
objects[data['rootObject']]['preferredProjectObjectVersion'] = '77'
def serialize(value, level=0):
    pad = '\t' * level
    if isinstance(value, dict):
        return '{\n' + ''.join(pad+'\t'+json.dumps(k)+ ' = '+serialize(v, level+1)+';\n' for k,v in value.items())+pad+'}'
    if isinstance(value, list):
        return '(\n' + ''.join(pad+'\t'+serialize(v,level+1)+',\n' for v in value)+pad+')'
    return json.dumps(str(value), ensure_ascii=False)
(root/'build').mkdir(exist_ok=True)
if not (root/'build/project-before-folder-sync.pbxproj').exists():
    shutil.copy2(path, root/'build/project-before-folder-sync.pbxproj')
path.write_text('// !$*UTF8*$!\n' + serialize(data) + '\n')
print('Synchronized app, widget, shared and test folders; preserved signing settings.')
