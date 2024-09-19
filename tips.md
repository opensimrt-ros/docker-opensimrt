# Tips

## You may want to install Vim instead of the appimage from neovim. 

The current version that comes with Debian doesn't run Ycm and you maybe want to use that in your regular system.

do so with

apt-get source vim --compile

sudo dpkg -i vim[tab].deb

## You may want to setup dual monitor to be detected automatically

In my pc it is just a matter of opening the terminal and typing 

    intel-virtual-output

But it bugged me that it was hard to automate this. I couldn't do this in any simple way, so I wrote down a systemd --user type service. you can find it in extras. Copy the script somewhere suitable like /usr/local/bin and fix the paths. 

It barely works and there are some video artifacts when you switch users, but it does work in my system. Maybe you can fix it and make it better. 

## You may want to run this without the router

That's one less hop and less delays. It also makes the system completely mobile. 

There is a script in extras that creates a hotspot with a fixed ip (this is how we setup the Ximus so I didn't want to change it).

You only need to run the script once (then there will be an entry in /etc/NetworkManager/), but you may want to uncomment the lines that bring it up every time you run run\_docker\_image.sh