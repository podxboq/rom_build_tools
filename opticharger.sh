#!/bin/bash
#
# Super-mega opticharger of doom
# Shrinks apks by running pngcrush or optipng or pngout on png images
#
# Point APKCERTS at the full path to a generated apkcerts.txt file, such as:
# /home/shade/dev/sources/android-cm-eclair/out/target/product/dream_sapphire/obj/PACKAGING/target_files_intermediates/cyanogen_dream_sapphire-target_files-eng.shade/META/apkcerts.txt
#
# cyanogen - shade@chemlab.org
# ChrisSoyars - me@ctso.me
# podxboq
. $SCRIPTDIR/mensajes.sh

set -e
QUIET=1
QFLAG=-q
BASE=`pwd`
BRUTECRUSH="-brute"
TMPDIR=/tmp/opticharge-$$

if [ -z "$BRUTE_PNGCRUSH" ]
then
	BRUTECRUSH=""
fi

if [ "$APKCERTS" = "" ];
then
	APKCERTS=$OUT/obj/PACKAGING/target_files_intermediates/$TARGET_PRODUCT-target_files-$TARGET_BUILD_VARIANT.$USER/META/apkcerts.txt
	if [ ! -f "$APKCERTS" ];
	then
		msgErr "No se encuentra la ruta para el fichero apkcerts.txt, configura la variable APKCERTS"
		exit 1;
	fi
fi

if [ ! -f "$APKCERTS" ];
then
	msgErr "No se encuentra la ruta para el fichero apkcerts.txt, configura la variable APKCERTS"
fi

if [ "$(which pngcrush)" != "" ];
then
	optimize_png () {
		pngcrush -q ${BRUTECRUSH} $1 ${1}.out 1> /dev/null 2> /dev/null
		mv ${1}.out ${1} 2> /dev/null
	}
elif [ "$(which optipng)" != "" ];
then
	optimize_png () {
		optipng -o7 -quiet $1 1> /dev/null 2> /dev/null
	}
elif [ "$(which pngout-static)" != "" ];
then
	optimize_png () {
		pngout-static $1
	}
elif [ "$(which pngout)" != "" ];
then
	optimize_png () {
		pngout $1
	}
else
	msgErr "Installa pngcrush, optipng o pngout"
	exit 1;
fi

if [ "`which aapt`" = "" ];
then
	msgErr "Asegurate que aapt esta en tu \$PATH"
	exit 1;
fi

if [ "`which zipalign`" = "" ];
then
	msgErr "Asegurate que zipalign esta en tu \$PATH"
	exit 1;
fi

if [ -e "$1" ];
then
	NAME=`basename $1`;
	msgList "Optimizando" $NAME

	if [ "$2" != "" ];
	then
		CERT=build/target/product/security/$2.x509.pem
		KEY=build/target/product/security/$2.pk8
		if [ ! -f "$ANDROID_BUILD_TOP/$CERT" ];
		then
			msgErr "$CERT no existe."
			exit 1;
		fi
	else
		APKINFO=`grep "name=\"$NAME\"" $APKCERTS`;
		[ $QUIET ] || $ECHO "APKINFO: $APKINFO";
		if [ "$APKINFO" = "" ];
		then
			msgErr "No apk info for $NAME"
			exit 1;
		fi
		CERT=`$ECHO $APKINFO | awk {'print $2'} | cut -f 2 -d "=" | tr -d "\""`;
		KEY=`$ECHO $APKINFO | awk {'print $3'} | cut -f 2 -d "=" | tr -d "\""`;
		if [ "$CERT" = "" ];
		then
			msgErr "Unable to find certificate for $NAME"
			exit 1;
		fi
	fi

	[ $QUIET ] || $ECHO "Certificate: $CERT";

	[ -d $TMPDIR/$NAME ] && rm -rf $TMPDIR/$NAME
	mkdir -p $TMPDIR/$NAME
	trap "rm -rf $TMPDIR; exit" INT TERM EXIT
	cd $TMPDIR/$NAME
	unzip -q $BASE/$1
	for x in `find . -name "*.png" | grep -v "\.9.png$" | tr "\n" " "`
	do
		[ $QUIET ] || $ECHO "Crushing $x"
		pngcrush $QFLAG $x $x.crushed 1>/dev/null
		if [ -e "$x.crushed" ];
		then
			mv $x.crushed $x
		fi
	done
	cp $BASE/$1 $BASE/$1.old

	[ $QUIET ] || msgStatus "Repacking apk.."
	if [ $NAME == "PinyinIME.apk" ];
	then
		aapt p -0 .dat -0 res/raw -0 res/raw-en -F $NAME .
	else
		aapt p -0 res/raw -0 res/raw-en -F $NAME .
	fi
	
	[ $QUIET ] || msgStatus "Resigning with cert: `$ECHO $CERT`"

	[ $QUIET ] || msgInfo java -jar $ANDROID_BUILD_TOP/out/host/linux-x86/framework/signapk.jar $ANDROID_BUILD_TOP/$CERT $ANDROID_BUILD_TOP/$KEY $NAME signed_$NAME
	java -jar $ANDROID_BUILD_TOP/out/host/linux-x86/framework/signapk.jar $ANDROID_BUILD_TOP/$CERT $ANDROID_BUILD_TOP/$KEY $NAME signed_$NAME
	[ $QUIET ] || msgStatus "Zipalign.."
	zipalign -f 4 signed_$NAME $BASE/$1
	if [ ! $QUIET ]; then
		ls -l $BASE/$1.old
		ls -l $BASE/$1
	fi
	rm $BASE/$1.old
else
	msgInfo "Usage: $0 [apk file]"
fi

