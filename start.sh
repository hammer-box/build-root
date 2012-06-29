#!/bin/bash
source /etc/lsb-release
source $DISTRIB_ID.dep
BASE_DIR=$(pwd)
PACKAGES_CONFIG_FILE=packages.config
PREVIOUS_REVISION=32467
LOCAL_REVISION=
CURRENT_REVISION=32520
SELECTED_REVISION=$CURRENT_REVISION
MODEL=false
YES=false

CONFIGS=$( ls *.model | cut -d'.' -f1 )
(( J=$(cat /proc/cpuinfo | grep processor | wc -l ) +1 ))
function usage()
{
	echo "
usage: $0 options
This scripts helps you set up your build environment.
Do not use the -y option unless you really know what you do.
NOTE: Its important that you execute this file in the git root directory
HELP: Please help supply lists of dependencies for your system.

OPTIONS:
	-h			Show this message
	-m			model name, bypasses the main menu
	-r			openwrt svn revision
	-j			Number of make threads. Defaults to number of cpus + 1
	-d			install dependencies 
	-y			Assume yes on all questions
	-v			Verbose 
"
}
function create_model()
{
	local -i line=$( cat $MODEL/.config | grep -n "# Package features" | cut -d':' -f1 )
	(( line++ ))
	head -n $line $MODEL/.config > $MODEL.model	
}
function create_package_conf()
{
	local -i totLines=$( wc -l $MODEL/.config | cut -d' ' -f1 )
	local -i line=$( cat $MODEL/.config | grep -n "# Package features" | cut -d':' -f1 )
	local -i tailAt=0
	(( tailAt=$totLines - $line +1 ))
	tail -n $tailAt $MODEL/.config > packages.config

}
function search_patches()
{
	local files=( $(find patches -iname *.patch -type f | cut -d'/' -f2-99 ) )

	for f in ${files[@]}
	do
		if [ -d $BASE_DIR/$MODEL/${f%\/*} ]
		then
			cd $BASE_DIR/$MODEL/${f%\/*}
			patch -sN -p0 < $BASE_DIR/patches/$f
			cd $BASE_DIR
		fi
	done
	
}
function search_copy()
{
	local files=( $(find copy  -type f | cut -d'/' -f2-99 ) )

	for f in ${files[@]}
	do
		mkdir -p $BASE_DIR/$MODEL/${f%\/*}
		cp -av $BASE_DIR/copy/$f $BASE_DIR/$MODEL/$f
	done
}
function install_dependencies()
{
	echo "installing dependencies"
	if [ $DISTRIB_ID = "Ubuntu" ]
	then
		echo "Found $DISTRIB_DESCRIPTION"
		echo "trying to install $DEPS"
		if [[ $YES == true ]]
		then
			sudo apt-get -y install $DEPS
		else
			sudo apt-get install $DEPS
		fi
	else
		echo "Found $DISTRIB_ID. Manua install of the following dependencies is needed"
		echo $DEPS
	fi
}
function checkout_source()
{
	mkdir -p $MODEL
	svn co -r $SELECTED_REVISION svn://svn.openwrt.org/openwrt/trunk $MODEL
	copy_essentials
}
function update_source()
{
	svn update -r $SELECTED_REVISION $MODEL
	copy_essentials
}

function copy_config()
{
	if [[ $YES == true ]]
	then
		cp -fa $MODEL.model $MODEL/.config
	else
		cp -ia $MODEL.model $MODEL/.config
	fi
}

function copy_essentials()
{
	mkdir -p $MODEL/files
	if [[ $YES == true ]]
	then
		cp -f feeds.conf $MODEL/
		cp -fa scripts/* $MODEL/scripts
		cp -fa files/* $MODEL/files
	else
		cp -i feeds.conf $MODEL/
		cp -ia scripts/* $MODEL/scripts
		cp -ia files/* $MODEL/files
	fi
	if [ -f $MODEL.model ]
	then
		copy_config
	fi
	
	cd $MODEL
	scripts/feeds update -a
	cd ..
	search_patches
	cd $MODEL
	scripts/feeds install -a
	scripts/feeds install -p hammer nginx
	cd ..
	search_copy
}
function start_build()
{
	cd $MODEL
	if [[ $VERBOSE == 1  ]]
		then
			make -j$J  V=99
		else
			make -j$J
	fi
	cd ..
}
function custom_build()
{
		read -p "Enter your model name: " MODEL
		checkout_source
		echo ""
		echo ""
		echo ""
		echo "---- When you press enter menuconfig will appear. Select your cpu
architecture, then your model. After that exit and save your configuration"
		cd $MODEL
		make menuconfig
		make defconfig
		cd ..
		create_model
		copy_config
		start_build
		

}
function main_menu()
{
	while true
	PS3="Main Menu: "
	do
		select conf in "Custom" ${CONFIGS[@]} "Install dependencies" "toggle verbose" "help" "quit"
		do
			case $conf in 
			"Custom" )
				echo "Disabled"
				return 1
				custom_build
			break
			;;
		"toggle verbose" )
			VERBOSE=1
			break
			;;
			"Install dependencies" )
				install_dependencies
				break 
				;;
			"quit" )
			 echo "Bye bye"
				return 0
				;;
			"help" )
				usage
				break 
				;;
			*)
				local found=false
				for conf2 in ${CONFIGS[@]}
				do
					if [ $conf = $conf2 ]
					then
						MODEL=$conf
						model_menu
						found=true
					fi
				done
				if [[ $found == false ]]
				then
					echo "Invalid choice "
				fi
				break
				;;
			esac
		done
	done
	return 0
}
function model_menu()
{
	while true 
			do
				PS3="$MODEL@$SELECTED_REVISION >"
				select opt in "Full Build" "Update" "Patch" "copy stuff" "Clean" "Select Revision" "set J" "Advanced" "Set packages.config" "Back"
				do
					case $opt in 
					"Set packages.config" )
						echo "disabled"
						break
						;;
						create_package_conf
						break
						;;
					"copy stuff" )
						search_copy
						break
						;;
					"set J" )
						read -p "Set the number of make threads, 1 is safe 2+ is faster but can fail. Current value is $J: "  J
						break
						;;
					"Full Build" )
						svn_status=$( svn info $MODEL )
						if [ $? = 0 ]
						then
							LOCAL_REVISION=$( echo "$svn_status"  | grep Revision | cut -d" " -f2 )
							if [[ $LOCAL_REVISION != $SELECTED_REVISION ]]
							then
								echo "Notice: Your local openwrt revision ( $LOCAL_REVISION ) does not match the selected revision ( $SELECTED_REVISION )"
								while true
								do
									if [[ $YES == true ]]
									then
										update_source
										start_build
									else
										read -i "y" -p "Do you want to update to $SELECTED_REVISION ? [y/n]: " answer
										if [ $answer = "y" ]
										then
											update_source
											start_build
										fi
									fi
									break
								done
							else
								start_build
							fi
						else
							echo "Notice $(pwd)/$MODEL does not contain openwrt source"
							while true
							do
								if [[ $YES == true ]]
								then
									checkout_source
							#		search_copy
									start_build
								else
									read -i "y" -p "Do you want to checkout openwrt source tree ? [y/n]: " answer
									if [ $answer = "y" ]
									then
										checkout_source
								#		search_copy
										start_build
									fi
								fi
								break
							done
						fi
						
					break 
					;;
					"Select Revision" )
						read -i "y" -p "Type in the openwrt svn revision you want: " SELECTED_REVISION
						break
						;;
					"Patch" )
						search_patches
						break
						;;
					"Update" )
						svn_status=$( svn info $MODEL )
						if [ $? = 0 ]
						then 
							while true
							do
								if [[ $YES == true ]]
								then
									update_source
								else
									read -i "y" -p "Do you want to update openwrt source tree ? [y/n]: " answer
									if [ $answer = "y" ]
									then
										update_source
									fi
								fi
								break
							done
						else
							echo "Notice $(pwd)/$MODEL does not contain openwrt source"
							checkout_source
						fi
						break
						;;
					"Clean" )
						read -i "y" -p "Do you want permanently remove $( pwd )/$MODEL ? [y/n]: " answer
						if [ $answer = "y" ]
						then
							rm -rf $( pwd )/$MODEL 
						fi
						;;
					"Advanced" )
						cd $MODEL 
						make menuconfig
						cd ..
						break 
						;;
					"Back" )
						return 0 
						;;
					*)
						echo "invalid choice"
						break 
						;;
					esac
				done
			done
			return 0
}
while getopts "hm:r:j:ydv?" OPTION
do
	case $OPTION in
		h)
			usage
			exit 1
			;;
		m)
			MODEL=$OPTARG
			;;
		r)
			SELECTED_REVISION=$OPTARG
			;;
		j)
			J=$OPTARG
			;;
		v)
			VERBOSE=1
			;;
		d)
			install_dependencies
			;;
		y)
			YES=true
			;;
		?)
			usage
			exit
			;;
	esac
done
if [[ $MODEL == false ]]
then
	main_menu
else
	model_menu
	if [ $? = 0 ]
	then
		main_menu
	fi
fi
echo "Bye bye"
exit $?
