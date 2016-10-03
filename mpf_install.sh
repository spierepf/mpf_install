# We are assuming a fresh-out-the-box Ubuntu Server 14.04 install. So there
# will be some packages that need to be added.
#   - xorg openbox pulseaudio are needed for kiosk mode
#     (see: https://thepcspy.com/read/building-a-kiosk-computer-ubuntu-1404-chrome/).
#   - git is what we use for source control. You may need something different.
#   - python-yaml and python-pygame are needed by mpf 0.21
#   - unclutter removes the mouse cursor from X
#   - build-essential is needed to build the fadecandy server from source

#sudo apt install --assume-yes --no-install-recommends lxdm
sudo apt install --assume-yes --no-install-recommends xorg openbox pulseaudio
sudo apt install --assume-yes --no-install-recommends pypy python-serial python-yaml python-pygame unclutter build-essential
sudo apt install --assume-yes --no-install-recommends linux-lowlatency linux-headers-lowlatency
sudo apt install --assume-yes --no-install-recommends alsa-utils vorbis-tools
sudo usermod -a -G audio hms
wget http://blog.ginzburgconsulting.com/wp-content/uploads/2013/02/silent.ogg

git config --global user.email "spierepf@hotmail.com"
git config --global user.name "Peter-Frank Spierenburg"

#mkdir Downloads
#pushd Downloads
#wget https://download.sublimetext.com/sublime-text_build-3126_amd64.deb
#sudo dpkg -i sublime-text_build-3126_amd64.deb
#wget http://download.nomachine.com/download/5.1/Linux/nomachine_5.1.54_1_amd64.deb
#sudo dpkg -i nomachine_5.1.54_1_amd64.deb
#popd

# Now we are getting software from our git repository
git clone https://github.com/spierepf/workspace-pinball
pushd workspace-pinball
./go.sh
popd

cat /etc/rc.local | sed "s/exit 0//" >tmp
echo "/home/hms/workspace-pinball/fadecandy/server/fcserver &" >>tmp
echo "exit 0" >>tmp
sudo mv tmp /etc/rc.local
sudo chmod u+x /etc/rc.local

# cat << EOF | sudo tee /etc/lxdm/lxdm.conf
# [base]
# ## uncomment and set autologin username to enable autologin
# autologin=hms

# ## uncomment and set timeout to enable timeout autologin,
# ## the value should >=5
# # timeout=10

# ## default session or desktop used when no systemwide config
# session=/usr/bin/openbox

# ## uncomment and set to set numlock on your keyboard
# # numlock=0

# ## set this if you don't want to put xauth file at ~/.Xauthority
# # xauth_path=/tmp

# # not ask password for users who have empty password
# # skip_password=1

# ## greeter used to welcome the user
# greeter=/usr/lib/lxdm/lxdm-greeter-gtk

# [server]
# ## arg used to start xserver, not fully function
# # arg=/usr/bin/X -background vt1
# # uncomment this if you really want xserver listen to tcp
# # tcp_listen=1
# # uncoment this if you want reset the xserver after logou
# # reset=1

# [display]
# ## gtk theme used by greeter
# gtk_theme=Clearlooks

# ## background of the greeter
# #bg=/usr/share/backgrounds/default.png
# bg=/usr/share/images/desktop-base/login-background.svg

# ## if show bottom pane
# bottom_pane=1

# ## if show language select control
# lang=1

# ## if show keyboard layout select control
# keyboard=0

# ## the theme of greeter
# theme=Industrial

# [input]

# [userlist]
# ## if disable the user list control at greeter
# disable=0

# ## whitelist user
# white=

# ## blacklist user
# black=
# EOF


echo '%hms   ALL = (ALL) NOPASSWD: /usr/bin/nice,/usr/bin/renice' | sudo tee /etc/sudoers.d/hms
sudo chmod 440 /etc/sudoers.d/hms

# This creates the /opt/kiosk.sh file that is used when starting kiosk mode
cat << EOF | sudo tee /opt/kiosk.sh
!/bin/bash

xset -dpms
xset s off
openbox-session &
start-pulseaudio-x11

amixer set Master unmute
amixer set Master 75%

MACHINE=/home/hms/workspace-pinball/nelson2
cd /home/hms/workspace-pinball/mpf

while true; do
  killall -9 python
  killall -9 pypy
  sudo nice -n -10 sudo -u hms ./mpf.sh \$MACHINE -x -v -V
done
EOF

sudo chmod +x /opt/kiosk.sh

# This creates the /etc/init/kiosk.conf task configuration
cat << EOF | sudo tee /etc/init/kiosk.conf
start on (filesystem and stopped udevtrigger)
stop on runlevel [06]

console output
emits starting-x

respawn

exec sudo -u $USER startx /etc/X11/Xsession /opt/kiosk.sh --
EOF

# This sets the kiosk task to manual startup. To start kiosk mode manually:
#
# $ sudo start kiosk
#
# And you can stop kiosk mode with:
#
# $ sudo stop kiosk
#
# When that works reliably, and you are really ready to box up your creation,
# you can remove the /etc/init/kiosk.override file. Then kiosk mode will start
# at boot time.
echo manual | sudo tee /etc/init/kiosk.override

# This bit lets you reconfigure X so it can be started by any user. Be sure
# to choose the "Anybody" option when queried.
sudo dpkg-reconfigure x11-common
