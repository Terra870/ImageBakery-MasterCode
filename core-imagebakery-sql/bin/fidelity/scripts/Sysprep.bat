regedit /E d:\mounteddevices.reg "hkey_local_machine\SYSTEM\MountedDevices"

cd C:\Windows\System32\Sysprep
sysprep.exe /quiet /generalize /unattend /oobe /quiet

regedit /S d:\mounteddevices.reg
