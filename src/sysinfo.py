#!/usr/bin/env python2
import os
import json
from subprocess import check_output

def nv_id_to_name(device_id):
    return {
            '13c0':    'GM204 [GeForce GTX 980]',
            '13c2':    'GM204 [GeForce GTX 970]',
            '1401':    'GM206 [GeForce GTX 960]',
            '1407':    'GM206 [GeForce GTX 750 v2]',
            '15f7':    'GP100 [Tesla P100 PCIe 12GB]',
            '15f8':    'GP100 [Tesla P100 PCIe 16GB]',
            '15f9':    'GP100 [Tesla P100 SMX2 16GB]',
            '1b00':    'GP102 [GeForce TITAN X]',
            '1b06':    'GP102 [GeForce GTX 1080 Ti]',
            '1b30':    'GP102 [Quadro P6000]',
            '1b38':    'GP102 [Tesla P40]',
            '1b80':    'GP104 [GeForce GTX 1080]',
            '1b81':    'GP104 [GeForce GTX 1070]',
            '1b84':    'GP104 [GeForce GTX 1060 3GB]',
            '1ba0':    'GP104 [GeForce GTX 1080 Mobile]',
            '1ba1':    'GP104 [GeForce GTX 1070 Mobile]',
            '1bb0':    'GP104 [Quadro P5000]',
            '1bb3':    'GP104 [Tesla P4]',
            '1bb6':    'GP104 [Quadro P5000 Mobile]',
            '1bb7':    'GP104 [Quadro P4000 Mobile]',
            '1bb8':    'GP104 [Quadro P3000 Mobile]',
            '1be0':    'GP104 [GeForce GTX 1080 Mobile]',
            '1be1':    'GP104 [GeForce GTX 1070 Mobile]',
            '1c02':    'GP106 [GeForce GTX 1060 3GB]',
            '1c03':    'GP106 [GeForce GTX 1060 6GB]',
            '1c20':    'GP106 [GeForce GTX 1060 Mobile]',
            '1c60':    'GP106 [GeForce GTX 1060 Mobile]',
            '1c61':    'GP106 [GeForce GTX 1050 Ti Mobile]',
            '1c62':    'GP106 [GeForce GTX 1050 Mobile]',
            '1c81':    'GP107 [GeForce GTX 1050]',
            '1c82':    'GP107 [GeForce GTX 1050 Ti]',
            '1c8c':    'GP107 [GeForce GTX 1050 Ti Mobile]',
            '1c8d':    'GP107 [GeForce GTX 1050 Mobile]',
            '1d01':    'GP108 [GeForce GT 1030]',
            '1d10':    'GP108 [GeForce MX150]',
    }.get(device_id, 'NVIDIA {}'.format(device_id))


def run(x):
    try:
        return check_output(x, shell=True).replace('\t', ' ').strip('\n')
    except:
        return "<error>"

cpu_info = run('cat /proc/cpuinfo | grep "model name" | uniq')
cpu_info = cpu_info.split(':')[-1].strip()

ram_lines = run('sudo dmidecode  -t memory | egrep "[^ ](Size|Speed)." | grep -v Unknown | grep -v "No Module Installed" | paste - - -d\;')
ram_info = []
for line in ram_lines.splitlines():
    if ';' in line:
        size, speed = line.split(';')
        speed = speed.split()[-2]
        size = size.split()[-2]
        ram_info.append({'speed_mhz': speed, 'size_mb': size})

mb_info = run('sudo dmidecode -t 2 | grep "Product Name"')
mb_info = mb_info.split('Product Name: ')[-1]

nv_lines = run('sudo lspci -vv | grep -A 57 "VGA compatible controller: NVIDIA" | egrep -o "(VGA.*Device ....|LnkSta:.*Width.*,)" | paste - - -d\;')
gpu_info = []
for line in nv_lines.splitlines():
    if ';' in line:
        device_id, pci_info = line.split(';')
        device_id = device_id.split(' ')[-1]
        speed = pci_info.split(',')[0].split()[-1]
        width = pci_info.split(',')[1].split()[-1]
        gpu_info.append({
            'device_id': device_id,
            'pci_speed': speed,
            'pci_width': width,
            'name': nv_id_to_name(device_id)})

ubuntu_version = run('lsb_release -a 2>/dev/null | grep Release | grep -o [0-9].*')

info = {
    'cpu': cpu_info,
    'ram': ram_info,
    'motherboard': mb_info,
    'gpu': gpu_info,
    'ubuntu_version': ubuntu_version,
}
print(json.dumps(info, indent=2))
