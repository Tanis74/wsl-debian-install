$distro = "debian"
$distroname = $distro.Substring(0, 1).ToUpper() + $distro.Substring(1).ToLower()
$username = "user"
$password = "password"
$WslFolder = "d:\VirtualMachines\WSL\"
$RunAnsible = $false

Write-Output "$(Get-Date) Uninstall $distroname Appx package"
Get-AppxPackage *Debian* | Remove-AppxPackage > $null 2>&1

Write-Output "$(Get-Date) Download $distroname Appx package"
Invoke-WebRequest -Uri https://aka.ms/wsl-debian-gnulinux -OutFile ./$distro.appx -UseBasicParsing > $null 2>&1

Write-Output "$(Get-Date) Install $distroname Appx package"
Add-AppxPackage -Path ./$distro.appx > $null 2>&1

Write-Output "$(Get-Date) Delete $distroname Appx package"
Remove-Item .\$distro.appx -Force > $null 2>&1

Write-Output "$(Get-Date) Install $distroname Distro"
& $distro install --root > $null 2>&1

if (Get-Variable 'WslFolder' -ErrorAction 'Ignore') {

  Write-Output "$(Get-Date) Terminate $distroname Distro in default folder"
  wsl -t $distro > $null 2>&1

  Write-Output "$(Get-Date) Export $distroname Distro from default folder"
  wsl --export $distro ./$distro.tar > $null 2>&1

  Write-Output "$(Get-Date) Unregister $distroname Distro in default folder"
  wsl --unregister $distro > $null 2>&1

  If (!(Test-Path -Path $WslFolder)) {
    New-Item -ItemType Directory -Path $WslFolder
  }
  $DistroFolder = Join-Path -Path $WslFolder -ChildPath $distro

  Write-Output "$(Get-Date) Import $distroname Distro to folder"
  wsl --import $distro $DistroFolder ./$distro.tar > $null 2>&1

  Write-Output "$(Get-Date) Delete $distroname export file"
  Remove-Item .\$distro.tar -Force
}

Write-Output "$(Get-Date) Add user"
wsl -u root -d $distro sh -c "useradd -m ${username}"
wsl -u root -d $distro sh -c "echo ${username}:${password} | chpasswd"
wsl -u root -d $distro sh -c "chsh -s /bin/bash ${username}"
wsl -u root -d $distro sh -c "usermod -a -G adm,cdrom,sudo,dip,plugdev,users ${username}"
wsl -u root -d $distro sh -c "echo '${username} ALL=(ALL:ALL) NOPASSWD:ALL' > /etc/sudoers.d/${username}"

Write-Output "$(Get-Date) Config WSL"
$wslcmd = "cat <<EOF > /etc/wsl.conf
[boot]
systemd = true
[user]
default=${username}
EOF"

$wslcmd = $wslcmd -replace "`r", ""
wsl -u root -d $distro sh -c "$wslcmd"

Write-Output "$(Get-Date) Add ssh key mount"
$SshFolder = Join-Path -Path $HOME -ChildPath ".ssh"
If (!(Test-Path -Path $SshFolder)) {
  New-Item -ItemType Directory -Path $SshFolder
}
wsl -u $username -d $distro sh -c "mkdir -p ~/.ssh"
wsl -u root -d $distro sh -c "echo '$HOME\.ssh\ /home/$username/.ssh drvfs rw,noatime,uid=1000,gid=1000,case=off,umask=0077,fmask=0177 0 0' > /etc/fstab"


Write-Output "$(Get-Date) Update $distroname Distro"
wsl -u root -d $distro sh -c "apt update && apt -y upgrade" > $null 2>&1
wsl -u root -d $distro sh -c "apt install -y ca-certificates debian-archive-keyring debconf-utils" > $null 2>&1
wsl -u root -d $distro sh -c "echo 'usrmerge usrmerge/autoconvert boolean true' | debconf-set-selections" > $null 2>&1
wsl -u root -d $distro sh -c "apt install -y usrmerge" > $null 2>&1

Write-Output "$(Get-Date) Upgrade $distroname Distro"
$sourceslistcmd = "cat <<EOF > /etc/apt/sources.list
deb https://deb.debian.org/debian trixie main contrib non-free non-free-firmware
deb https://security.debian.org/debian-security trixie-security main contrib non-free non-free-firmware
deb https://deb.debian.org/debian trixie-updates main contrib non-free non-free-firmware
EOF"
$sourceslistcmd = $sourceslistcmd -replace "`r", ""
wsl -u root -d $distro sh -c "$sourceslistcmd"

wsl -u root -d $distro sh -c "echo 'libc6 libraries/restart-without-asking boolean true' | debconf-set-selections"
wsl -u root -d $distro sh -c "apt update && apt -y upgrade --without-new-pkgs" > $null 2>&1

wsl -u root -d $distro sh -c "apt full-upgrade --autoremove -y" > $null 2>&1
wsl -u root -d $distro sh -c "apt -y --purge autoremove && apt autoclean" > $null 2>&1

Write-Output "$(Get-Date) Terminate $distroname Distro"
wsl -t $distro > $null 2>&1

if ($RunAnsible) {
  wsl -u root -d $distro sh -c "apt install ansible git -y"
  wsl -u $username -d $distro sh -c "cd ~ && git clone https://github.com/Tanis74/setup.git setup"
  wsl -u $username -d $distro sh -c "cd ~/setup && ansible-galaxy collection install -r requirements.yml -p ./collections/"
  wsl -u $username -d $distro sh -c "cd ~/setup && ansible-galaxy install -r requirements.yml --roles-path ./roles"
  wsl -u $username -d $distro sh -c "cd ~/setup && ansible-playbook playbook.yml"
}
