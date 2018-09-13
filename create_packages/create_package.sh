#! /bin/bash
#set -x

##
#
# * script is creating Debain and rpm packages (in default, you can use it to create only rpm packages)
# How script is working
# * copy files for source (cvs, unpacked download directory etc) to temporary source dir (common for all targets)
# * prepare in tempoprary common directory directory structure (for example create directories like /usr/local.., copy menu entries to correct places etc)
# * copy prepared source directory to SOURCE directory for debs and rpms
# * create specific files and directories for distributions (like DEBIAN dir for deb and SPEC file for rpms)
# * create packages

CONFIG_FILE=""
CREATE_RPM=no
CREATE_DEB=no
CREATE_TARGZ=no
CREATE_IPK=no

PACKAGES_BUILD="${HOME}/PACKAGES_BUILD"
DEBIAN_REPO_DIR=$PACKAGES_BUILD/DEBS

DEFAULT_IPK_STATUS="unknown ok not-installed"

USR_LOCAL=yes
DEFAULT_SOFTWARE_LICENCE="GPL"
DEFAULT_SOFTWARE_GROUP="Development/Tools"

VENDOR_DIR="unix4you.net"

SOFTWARE_DIR_WITH_VERSION=0

SCRIPTNAME=$(basename $0)
###
# functions
##
function usage {
	echo ""
	echo "Usage of $SCRIPTNAME"
	echo "Script is creating DEB, RPM and IPK packages "
	echo " -deb|--deb - create debian package"
	echo " -rpm|--rpm - create rpm package"
	echo " -ipk|-ipk - create ipk package"
	echo " "
	echo "The temporary directory for creating packages will be $PACKAGES_BUILD"
	 

}


function find_and_copy {

	#echo "dir: $1 name: $2, target $3"
	if [ -d $1 ]; then
		if [ `find $1  -maxdepth 1 -name "$2" | wc -l` -gt 0 ]; then
			mkdir -p $3
			mv $1/$2 	$3;
		fi
	fi

}

###
#   checking the variables 
###

while [ $# -gt 0 ];
do
	case $1 in
		--conf|-conf|-c) shift; echo "Config file:$1"; CONFIG_FILE=$1; shift;;
		-h|--help) shift; echo "Now I will show you the HELP";;
		-ipk|--ipk) shift; CREATE_IPK=yes; echo "I will create IPG package"; shift;;
		-deb|--deb) shift; CREATE_DEB=yes; echo "I will create DEB  package"; shift;;
		-rpm|--rpm) shift; CREATE_RPM=yes; echo "I will create RPM  package"; shift;;
		*) echo "Wrong option $1"; exit 1;
	esac
done;


###
#  Script, 
###
if [ "$CREATE_RPM" == "yes" ] && [ ! -x /usr/bin/rpmbuild ]; 
then
    echo "Error!!!"
    echo "Please install package for creating rpm!"
    echo "On Fedora it is called: rpm-build"
    echo "exiting..."
    
    exit 1

fi


if [ "$CREATE_IPK" ==  "no" ] && [ "$CREATE_DEB"  ==  "no" ] && [ "$CREATE_RPM" == "no" ]; then
	echo "Please choose which package you want to create"
	usage
	exit 1
fi


if [ $# -eq 0 ] && [ -r .create_package.conf ]; then
	CONFIG_FILE=".create_package.conf"
fi

if  [ -z "$CONFIG_FILE" ] || [ ! -r $CONFIG_FILE ]; then
	echo "The config file $CONFIG_FILE doesn't exist, exitinig..."
	create_package_conf.pl
	CONFIG_FILE=".create_package.conf"
#	exit 2
fi

# loading config data
. $CONFIG_FILE

if [ -z "$SOFTWARE_DESCRIPTION" ]; then
    echo "The short description of software is needed"
    echo "Please setup it! "
    exit 3
fi


if [ -z $SOFTWARE_DEPENDS ]; then
	echo "The variable SOFTWARE_DEPENDS can not be empty!"
	echo "The apt tools have problems with empty dependences, will be reporting errors"
	echo "Please setup it!"
	echo "exiting..."
	exit 1
fi

[ -z $SOFTWARE_LICENCE ] && SOFTWARE_LICENCE=$DEFAULT_SOFTWARE_LICENCE
[ -z $SOFTWARE_GROUP ]   && SOFTWARE_GROUP=$DEFAULT_SOFTWARE_GROUP
[ -z $SOURCE_DIR ]	&& SOURCE_DIR=$PWD


if [ $SOFTWARE_DIR_WITH_VERSION -eq 0 ]; then
	SOFTWARE_DIR=${SOFTWARE_NAME}
else
	SOFTWARE_DIR=${SOFTWARE_NAME}-${SOFTWARE_VERSION}
fi

### real script
## creating the RPM's directories (from standard)
if [ "$CREATE_RPM" == "yes" ]; then 
    mkdir -p $PACKAGES_BUILD/{SOURCES,SRPMS,SPECS,BUILD,RPMS}
fi

## creating the DEB directories (our idea)
if [ "$CREATE_DEB" == "yes" ]; then
    mkdir -p $PACKAGES_BUILD/SOURCES_DEB
    mkdir -p $DEBIAN_REPO_DIR
fi

if [ "$CREATE_IPK"  == "yes" ]; then
    mkdir -p $PACKAGES_BUILD/SOURCES_IPK
    mkdir -p $PACKAGES_BUILD/IPK
fi

## creating common dir for common source version, then it will be copy to separate dirs for all types
mkdir -p $PACKAGES_BUILD/SOURCES_COMMON


## cleaning the common source dir directory
if [ -d $PACKAGES_BUILD/SOURCES_COMMON/$SOFTWARE_DIR ]; then
	rm -rf $PACKAGES_BUILD/SOURCES_COMMON/$SOFTWARE_DIR
fi
mkdir -p $PACKAGES_BUILD/SOURCES_COMMON/$SOFTWARE_DIR


### copy data from CVS DIR and removing CVS subdirs
cp -a ${SOURCE_DIR}/* $PACKAGES_BUILD/SOURCES_COMMON/$SOFTWARE_DIR
find $PACKAGES_BUILD/SOURCES_COMMON/$SOFTWARE_DIR -type d -name CVS  | xargs rm -rf 
find $PACKAGES_BUILD/SOURCES_COMMON/$SOFTWARE_DIR -type d -name .svn  | xargs rm -rf 
find $PACKAGES_BUILD/SOURCES_COMMON/$SOFTWARE_DIR -type d -name .git  | xargs rm -rf 


# creating subdirectories for packages, coping files depends on file extension
#
if [ "$USR_LOCAL" == "yes" ]; then

	## creating the doc directory
	find_and_copy $PACKAGES_BUILD/SOURCES_COMMON/$SOFTWARE_DIR/doc/ "*" 	$PACKAGES_BUILD/SOURCES_COMMON/$SOFTWARE_DIR/usr/share/doc/$SOFTWARE_NAME/
	[ -d $PACKAGES_BUILD/SOURCES_COMMON/$SOFTWARE_DIR/doc/ ] && rm -rf  $PACKAGES_BUILD/SOURCES_COMMON/$SOFTWARE_DIR/doc/


	# copying the execute files 
	find_and_copy $PACKAGES_BUILD/SOURCES_COMMON/$SOFTWARE_DIR/ "*.jar" 	$PACKAGES_BUILD/SOURCES_COMMON/$SOFTWARE_DIR/usr/local/bin/
	find_and_copy $PACKAGES_BUILD/SOURCES_COMMON/$SOFTWARE_DIR/ "*.sh" 		$PACKAGES_BUILD/SOURCES_COMMON/$SOFTWARE_DIR/usr/local/bin/
	find_and_copy $PACKAGES_BUILD/SOURCES_COMMON/$SOFTWARE_DIR/ "*.pl" 		$PACKAGES_BUILD/SOURCES_COMMON/$SOFTWARE_DIR/usr/local/bin/

	# coping the config files 
	if  [ "$SOFTWARE_SEPARATE_DIR_OPT" == "yes" ]; then
		find_and_copy $PACKAGES_BUILD/SOURCES_COMMON/$SOFTWARE_DIR/ "*.cfg" 	$PACKAGES_BUILD/SOURCES_COMMON/$SOFTWARE_DIR/opt/$VENDOR_DIR/$SOFTWARE_DIR/etc/
		find_and_copy $PACKAGES_BUILD/SOURCES_COMMON/$SOFTWARE_DIR/ "*.conf" 	$PACKAGES_BUILD/SOURCES_COMMON/$SOFTWARE_DIR/opt/$VENDOR_DIR/$SOFTWARE_DIR/etc/
 	else
		find_and_copy $PACKAGES_BUILD/SOURCES_COMMON/$SOFTWARE_DIR/ "*.cfg" 	$PACKAGES_BUILD/SOURCES_COMMON/$SOFTWARE_DIR/usr/local/etc/
		find_and_copy $PACKAGES_BUILD/SOURCES_COMMON/$SOFTWARE_DIR/ "*.conf" 	$PACKAGES_BUILD/SOURCES_COMMON/$SOFTWARE_DIR/usr/local/etc/
	fi

	## creating menus settins
	echo ">> Analyzing menu entires <<"
	find_and_copy $PACKAGES_BUILD/SOURCES_COMMON/$SOFTWARE_DIR/ "*.directory" 	$PACKAGES_BUILD/SOURCES_COMMON/$SOFTWARE_DIR/usr/share/desktop-directories/
	find_and_copy $PACKAGES_BUILD/SOURCES_COMMON/$SOFTWARE_DIR/ "*.menu" 		$PACKAGES_BUILD/SOURCES_COMMON/$SOFTWARE_DIR/etc/xdg/menus/applications-merged/
	find_and_copy $PACKAGES_BUILD/SOURCES_COMMON/$SOFTWARE_DIR/ "*.desktop" 	$PACKAGES_BUILD/SOURCES_COMMON/$SOFTWARE_DIR/usr/share/applications/
fi

###
#  DEBIAN Packages Part 
###

if [ "$CREATE_DEB" == "yes" ]; then

	echo ">>>> Creating DEB package <<<<"

	echo ">Removing old directory if exist <"
	rm -rf $PACKAGES_BUILD/SOURCES_DEB/$SOFTWARE_DIR/ 

	# coping files from COMMON directory
	echo "Coping files to SROUCE_DEB directory"
	cp -a $PACKAGES_BUILD/SOURCES_COMMON/$SOFTWARE_DIR/  $PACKAGES_BUILD/SOURCES_DEB/$SOFTWARE_DIR; 
	# creating the DEBIAN control directory
	echo "Creating Debian control directory and file"
	mkdir -p $PACKAGES_BUILD/SOURCES_DEB/$SOFTWARE_DIR/DEBIAN

	if [ ! -z "$SOFTWARE_DEPENDS_DEBIAN" ]; then
		SOFTWARE_DEPENDS=${SOFTWARE_DEPENDS}","${SOFTWARE_DEPENDS_DEBIAN}
	fi
	
    if [ ! -z "$SOFTWARE_CONFLICT"  ]; then
            SOFTWARE_REPLACE="Replaces: $SOFTWARE_REPLACE $SOFTWARE_CONFLICT"
    fi

echo "Replaces: $SOFTWARE_REPLACE \n"

if [ ! -z "$SOFTWARE_REPLACE" ]; then

# control file
cat > $PACKAGES_BUILD/SOURCES_DEB/$SOFTWARE_DIR/DEBIAN/control << OEF
Package: $SOFTWARE_NAME
Version: ${SOFTWARE_VERSION}-${SOFTWARE_RELEASE}
Section: main
Priority: optional
Architecture: all
Depends: $SOFTWARE_DEPENDS
Installed-Size:
Maintainer: $MAINTAINER
$SOFTWARE_REPLACE 
Description: $SOFTWARE_DESCRIPTION
 $SOFTWARE_DESCRIPTION_LONG 
OEF

else

# control file
cat > $PACKAGES_BUILD/SOURCES_DEB/$SOFTWARE_DIR/DEBIAN/control << OEF
Package: $SOFTWARE_NAME
Version: ${SOFTWARE_VERSION}-${SOFTWARE_RELEASE}
Section: main
Priority: optional
Architecture: all
Depends: $SOFTWARE_DEPENDS
Installed-Size:
Maintainer: $MAINTAINER
Description: $SOFTWARE_DESCRIPTION
 $SOFTWARE_DESCRIPTION_LONG 
OEF

fi


if [ ! -z $SOFTWARE_CONFIG_FILES ]; then
cat > $PACKAGES_BUILD/SOURCES_DEB/$SOFTWARE_DIR/DEBIAN/conffiles << OEF
$SOFTWARE_CONFIG_FILES
OEF
fi

	# md5sum for package
	SOFTWARE_DIR2=$( echo "$PACKAGES_BUILD/SOURCES_DEB/$SOFTWARE_DIR" | sed "s/\//\\\\\\//g"  )

	md5sum `find $PACKAGES_BUILD/SOURCES_DEB/$SOFTWARE_DIR -type f ` | grep -v DEBIAN | sed "s/$SOFTWARE_DIR2//g" > $PACKAGES_BUILD/SOURCES_DEB/$SOFTWARE_DIR/DEBIAN/md5sums
	dpkg --build $PACKAGES_BUILD/SOURCES_DEB/$SOFTWARE_DIR  $DEBIAN_REPO_DIR

fi

if [ "$CREATE_RPM" == "yes" ]; then

	echo ">>>> Creating RPM package <<<<"

	echo "> Remonivg old RPM software SOURCE directory <"
	if [ -d $PACKAGES_BUILD/SOURCES/$SOFTWARE_DIR ]; then
		rm -rf $PACKAGES_BUILD/SOURCES/$SOFTWARE_DIR
		mkdir -p $PACKAGES_BUILD/SOURCES/$SOFTWARE_DIR
	else
		mkdir -p $PACKAGES_BUILD/SOURCES/$SOFTWARE_DIR
	fi


	RPM_SPEC_DIR="${PACKAGES_BUILD}/SPECS"
	RPM_BUILD_SED=$(echo $PACKAGES_BUILD | sed "s/\//\\\ \//g" | sed "s/ //g")
#	echo "Debug: $RPM_BUILD_SED"

	#

	echo ">Copying data to RPM source directory <"
	cp -a ${PACKAGES_BUILD}/SOURCES_COMMON/$SOFTWARE_DIR/* ${PACKAGES_BUILD}/SOURCES/$SOFTWARE_DIR

	#setuping the directory for building the the rpm packages
	echo ">backuping originial .rpmmacros and creating new one<"
	[ -r ${HOME}/.rpmmacros  ] &&  cp ${HOME}/.rpmmacros ${HOME}/.rpmmacros.save  && echo "backuping  .rpmrc file [ DONE ] "
	echo -e "%_topdir ${PACKAGES_BUILD}\n%_builddir %{_topdir}/BUILD" > ${HOME}/.rpmmacros


	#### creating the SPEC file ####
	# preparing list of DIRS of SPEC file
	echo -e "\n\n"
	PACKAGES_BUILD2=$(echo ${PACKAGES_BUILD} | sed "s/\//\\\\\\//g")
	for DIR in `find ${PACKAGES_BUILD}/SOURCES/$SOFTWARE_DIR -type d | sed "s/${PACKAGES_BUILD2}\/SOURCES\/${SOFTWARE_DIR}//g" | egrep -v "^$|^/usr$|^/usr/local$" `; do
		[ ! -z $DIR ] && MKDIR="$MKDIR\nmkdir -p  \$RPM_BUILD_ROOT${DIR}"
	done


	# preparing list of config files
	for CONFILE in  $SOFTWARE_CONFIG_FILES; do
		[ ! -z $CONFILE ] && CONFILES="$CONFILES\n%config $CONFILE"
	done

	# prepring list of files for SPEC file
	FILES=`find ${PACKAGES_BUILD}/SOURCES/$SOFTWARE_DIR -type f | sed "s/$RPM_BUILD_SED\/SOURCES\/${SOFTWARE_DIR}//g" `

	touch $RPM_SPEC_DIR/${SOFTWARE_NAME}.spec 

cat > $RPM_SPEC_DIR/${SOFTWARE_NAME}.spec << EOF
Summary: $SOFTWARE_DESCRIPTION
Name: $SOFTWARE_NAME
Version: $SOFTWARE_VERSION
Release: $SOFTWARE_RELEASE
License: $SOFTWARE_LICENCE
Group: $SOFTWARE_GROUP
URL: ${SOFTWARE_HOMEPAGE:-"none"}

BuildRoot: %{_tmppath}/%{name}-%{version}-root
BuildArch: noarch


%description
$SOFTWARE_DESCRIPTION_LONG

%install
rm -rf \$RPM_BUILD_ROOT

$(echo -e $MKDIR)

cp -a ../SOURCES/$SOFTWARE_DIR/* \$RPM_BUILD_ROOT/

%clean
rm -rf \$RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
$FILES

%changelog
EOF

    rpmbuild --quiet  -ba $RPM_SPEC_DIR/${SOFTWARE_NAME}.spec 


	# coping back the rpm config file
#	[ -r ${HOME}/.rpmmacros.save  ] &&  mv ${HOME}/.rpmrc.save ${HOME}/.rpmmacros

    echo "The RPM has been put into directory: $PACKAGES_BUILD/RPMS/"

fi


if [ "$CREATE_IPK" == "yes" ]; then

	[ -z $IPK_STATUS ] && IPK_STATUS=$IPK_STATUS_DEFAULT

        echo ">>>> Creating IPK package <<<<"

        echo ">Removing old directory if exist <"
        rm -rf $PACKAGES_BUILD/SOURCES_IPK/$SOFTWARE_DIR/

        mkdir  $PACKAGES_BUILD/SOURCES_IPK/$SOFTWARE_DIR/


        # coping files from COMMON directory
        echo "Coping files to SROUCE_IPK directory"
        cp -a $PACKAGES_BUILD/SOURCES_COMMON/$SOFTWARE_DIR/  $PACKAGES_BUILD/SOURCES_IPK/

	cd $PACKAGES_BUILD/SOURCES_IPK/$SOFTWARE_DIR
	tar -zcvf data.tar.gz ./*

        # creating the (IPK) control directory
        echo "Creating IPK control file"

	echo "2.0" > $PACKAGES_BUILD/SOURCES_IPK/$SOFTWARE_DIR/debian-binary 


	IPK_INSTALLED_SIZE=$(ls -l $PACKAGES_BUILD/SOURCES_IPK/$SOFTWARE_DIR/data.tar.gz | awk '{ print $5}')


# control file
cat > $PACKAGES_BUILD/SOURCES_IPK/$SOFTWARE_DIR/control << OEF
Package: $SOFTWARE_NAME
Version: ${SOFTWARE_VERSION}-${SOFTWARE_RELEASE}
Depends: $SOFTWARE_DEPENDS
Providers:
Source: $SOFTWARE_HOME_PAGE
Status: $IPK_STATUS
Essential: $IPK_ESSENTIAL
Section: main
Priority: optional
Architecture: all
Installed-Size: $IPK_INSTALLED_SIZE
Maintainer: $MAINTAINER
Description: $SOFTWARE_DESCRIPTION
OEF


 
	tar -zcvf control.tar.gz control


	tar -zcvf ${SOFTWARE_NAME}.ipk control.tar.gz data.tar.gz debian-binary
	mv ${SOFTWARE_NAME}.ipk $PACKAGES_BUILD/IPK/ 

	rm -rf $PACKAGES_BUILD/SOURCES_IPK/$SOFTWARE_DIR
fi

exit 0