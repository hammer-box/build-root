HAMMER
==========

The hammer is based on openwrt attitude adjustment trunk. Openwrt trunk doesnt
always build, but if you use this repo and the start.sh script your chances are
to complete the build is more likely, because we use only working revisions. 
That means we will most of the time be a few days behind openwrt and its only
the buffalo wzr-hp-ag300h router we test on.

Files and Folders
----------
copy - contains files that will be copied before a build to the target folder.
The entire structure is copied.
feeds.conf - Contains openwrt feeds, meaning source of third party packages
packages.conf - contains a default .config ( except target specific things ) 
for building a basic hammer system. 
patches - contains patches to openwrt build environment and feeds. Its most 
likely patches to Make files that have been commited but not working 100%. 
i.e. md5sum or source url updates.
scripts - contains extenstions to the normal openwrt build root scripts
start.sh - A menu for making it easier to set up the build-root
*.dep - Lists of build dependency packages. They are named after
DISTRIB_ID in /etc/lsb-release.
*.model - contains target specific config, its merged with packages.conf before
building. If you set up a new model using custom in the menu, a .model file will
also be created with the name of your custom build.


GOALS
----------
The purpose of the hammer is to make advanced networking easy and transparent
as well as providing a private, free and low cost alternative to popular cloud
services, such as google music, dropbox , google docs etc.

WARNINGS
----------
This project is still under development so make sure you have router that you 
wont brick.

Make sure you run start.sh from the build root, meaning ./start.sh

THE MENU ( start.sh )
----------
Use this to make it easier to maintain and set up your builds. Note that the 
menu script might contain bugs, it has not been thouroghly tested so use it with
care.

Sometimes Build might fail because of  -j parameter. By default the menu sets 
it to number of cpus +1, this can be modified via the menu or by using -j n 
argument when starting the script. If the build fails try it again without 
changing j , it will probably recover.

SETUP GUIDE
----------
mkdir hammer
cd hammer
git clone git://github.com/hammer-box/build-root.git
./start.sh

select Install dependencies
If you are on ubuntu the build dependencies will be installed using sudo apt-get
So you will have to enter your password.

If your router model is listed select it.

If your router model is not listed select custom and put in the name of your
router. Openwrt source will checkout and then menuconfig appears.

Target System -> Select the architecture of your router
Target Profile -> Select the your router model
exit and save

Select Full Build and answer yes to any questions
Your binaries will end up in <model>/bin

To flash the router follow the instructions on the openwrt 
wiki http://wiki.openwrt.org/toh/start

After flashing your router will be accessible on 192.168.11.1:80 on the lan 
ports

Click login and set the password. 


