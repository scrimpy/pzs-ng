#!/bin/bash

###############################################################################
#
# LIBCOPY v1.8 by psxc
######################
#
# This small script (ripped from glinstall.sh ;) will copy libs used by files
# in glftpd's bin dir.
# The script should be run after the zipscript is installed.
# You should also use this script any time there is changes in your bin dir, or
# you upgrade your system.
#
###############################################################################

# a list of possible paths to glroot
possible_glroot_paths="/glftpd /jail/glftpd /usr/glftpd /usr/jail/glftpd /usr/local/glftpd /usr/local/jail/glftpd /$HOME/glftpd /glftpd/glftpd /opt/glftpd"

# bins needed for pzs-ng to run
needed_bins="sh cat grep egrep unzip wc find ls bash mkdir rmdir rm mv cp awk ln basename dirname head tail cut tr wc sed date sleep touch gzip"
zs_bins="zipscript-c postdel postunnuke racestats cleanup datacleaner rescan ng-undupe ng-deldir ng-chown audiosort"
#
###################################
# CODEPART - PLEASE DO NOT CHANGE #
###################################

version="1.6 (pzs-ng version)"

# Set system type
case $(uname -s) in
    Linux) os=linux ;;
    *[oO][pP][eE][nN][bB][sS][dD]*) os=openbsd ;;
    *[Dd][Aa][Rr][Ww][Ii][Nn]*) os=darwin ;;
    *[Nn][Ee][Tt][Bb][Ss][Dd]*) os=netbsd ;;
    *[fF][rR][eE][eE][bB][sS][dD]*)
        bsdversion=`uname -r | tr -cd '0-9' | cut -b 1-2`
        if [ $bsdversion -ge 52 ]; then
           os=freebsd5
        else
           os=freebsd4
        fi
        ;;
    *)
        echo "Sorry, but this util does not support the $(uname -s) platform."
        exit 1
        ;;
esac

if [ "$os" = "darwin" ]; then
  needed_bins="$needed_bins tcsh"
else
  needed_bins="$needed_bins ldconfig"
fi

# Ensure we have all useful paths in our $PATH
PATH="$PATH:/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin:\
/usr/libexec:/usr/compat/linux/bin:/usr/compat/linux/sbin:/usr/compat/linux/usr/bin:\
/usr/compat/linux/usr/sbin"

if [ $# -eq 0 ]; then
	for possible_glroot in $possible_glroot_paths; do
		if [ -e ${possible_glroot}/bin/glftpd ]; then
		glroot=${possible_glroot}
		break
		fi
	done

	if [ -z ${glroot} ]; then
		echo ""
		echo "This util will try to copy the necessary libs into your"
		echo "glftpd environment."
		echo ""
		echo "Usage: $0 /path/to/glftpd-root-dir"
		echo ""
		exit 0
	fi
else
	glroot=$1
	if [ ! -e /$glroot/bin/glftpd ]; then
		echo ""
		echo "Oops! I think you wrote wrong path. I can't find"
		echo "$glroot/bin/glftpd - Exiting."
		exit 0
	fi
fi

lddsequence() {
    echo -n "   $(basename $lib): "
    libdir="$(dirname $lib)"
    if [ -f "$lib" ]; then
       mkdir -p "$glroot$libdir"
       rm -f "$glroot$lib"
       cp -fRH "$lib" "$glroot$libdir"
       echo "$libdir" >> "$glroot/etc/ld.so.conf"
       echo "OK"
    elif [ -f "/usr/compat/linux/$lib" ]; then
       mkdir -p "$glroot/usr/compat/linux"
       rm -f "$glroot/usr/compat/linux/$(basename $lib)"
       cp -fRH "/usr/compat/linux/$lib" "$glroot/usr/compat/linux/"
       echo "$libdir" >> "$glroot/etc/ld.so.conf"
       echo "OK"
    else
       echo -e '\033[1;31mFailed!\033[0m'" You must find & copy $(basename $lib) to $glroot$libdir manually."
    fi
}

# homemade 'which' command by js
mywhich() {
  unset binname; for p in `echo $PATH | tr -s ':' '\n'`; do test -x $p/$bin && { binname=$p/$bin; break; }; done;
}

if [ -z "$1" ]; then
  clear 2>/dev/null
fi
echo -e "\n"'\033[1;31m'"LibCopy v$version"'\033[0m'"\n\nUsing glroot: $glroot\n\nMaking sure all bins are present:"
for bin in $needed_bins; do
  echo -n "$bin:"
  mywhich
  if [ ! -z $binname ]; then
    if [ -e ${binname}.real ]; then
      rm -f "$glroot/bin/$bin"
      cp ${binname}.real "$glroot/bin/$bin"
    else
      rm -f "$glroot/bin/$(basename $binname)"
      cp ${binname} $glroot/bin/
    fi
    echo -n "COPIED  "
  else
    echo -en '\033[1;31mNOT FOUND!!!  \033[0m'
  fi
done
for bin in $zs_bins; do
  echo -n "$bin:"
  if [ ! -e $glroot/bin/$bin ]; then
      echo -en '\033[1;31mNOT FOUND!!!  \033[0m'
  else
   echo -n "OK  "
  fi
done

echo -e "\n\nCopying required shared library files:"
echo -n "" > "$glroot/etc/ld.so.conf"
case $os in
    openbsd)
      openrel=`uname -r | tr -cd '0-9' | cut -b 1-2`
      if [ $openrel -ge 40 ]; then
        ldd $glroot/bin/* 2>/dev/null | awk '{print $7, $1}' | grep -e "^/" | grep -v "00000000$" | awk '{print $1}' | sort | uniq | while read lib; do
          lddsequence
        done
      elif [ $openrel -ge 34 ]; then
        ldd $glroot/bin/* 2>/dev/null | awk '{print $5, $1}' | grep -e "^/" | grep -v "00000000$" | awk '{print $1}' | sort | uniq | while read lib; do
          lddsequence
        done
      else
        ldd $glroot/bin/* 2>/dev/null | awk '{print $3, $4}' | grep -e "^/" | grep -v "00000000)$" | awk '{print $1}' | sort | uniq | while read lib; do
          lddsequence
        done
      fi
    ;;
    darwin)
        otool -L $glroot/bin/* 2>/dev/null | awk '{print $1}' | grep -e "^/" | grep -v "$glroot/bin/" | sort | uniq | while read lib; do
          lddsequence
        done
    ;;
    *)
	bindir="`echo $glroot/bin | tr -s '/'`"
	ldd $bindir/* 2>/dev/null | grep -v "^$bindir" | tr ' \t' '\n' | grep -e "^/" | sort | uniq | while read lib; do
          lddsequence
        done
esac

case $os in
	freebsd4)
		bsdlibs="/usr/libexec/ld-elf.so.1"
		;;
	freebsd5)
		bsdlibs="/libexec/ld-elf.so.1"
		;;
	openbsd)
		bsdlibs="/usr/libexec/ld.so"
		;;
	netbsd)
		bsdlibs="/usr/libexec/ld.so /usr/libexec/ld.elf_so"
		;;
	linux)
		bsdlibs="/lib/ld-linux.so.2"
		echo -e "\nCopying needed resolv-libs (if needed)..."
		for linuxlib in /lib/libnss_dns* /lib/libresolv* ; do
		  [[ -e "$linuxlib" ]] && {
		    echo -n "   $(basename $linuxlib)"
		    rm -f "$glroot/lib/$(basename $linuxlib)"
		    cp -fRH $linuxlib $glroot/lib/
		    echo " OK"
		  }
		done
		for linuxlib in /lib/i386-linux-gnu/libnss_dns* /lib/i386-linux-gnu/libresolv* ; do
		  [[ -e "$linuxlib" ]] && {
		    echo -n "   $(basename $linuxlib)"
		    rm -f "$glroot/lib/i386-linux-gnu/$(basename $linuxlib)"
		    [[ ! -e $glroot/lib/i386-linux-gnu/ ]] && mkdir $glroot/lib/i386-linux-gnu/
		    cp -fRH $linuxlib $glroot/lib/i386-linux-gnu/
		    echo " OK (32bit)"
		  }
		done
		for linuxlib in /lib/x86_64-linux-gnu/libnss_dns* /lib/i386-linux-gnu/libresolv* ; do
		  [[ -e "$linuxlib" ]] && {
		    echo -n "   $(basename $linuxlib)"
		    rm -f "$glroot/lib/x86_64-linux-gnu/$(basename $linuxlib)"
		    [[ ! -e $glroot/lib/x86_64-linux-gnu/ ]] && mkdir $glroot/lib/x86_64-linux-gnu/
		    cp -fRH $linuxlib $glroot/lib/x86_64-linux-gnu/
		    echo " OK (64bit)"
		  }
		done
		echo -n "   resolvconf"
		[[ -d /etc/resolvconf ]] && {
		  cp -fRp /etc/resolvconf $glroot/etc/
		  echo " OK"
		} || {
		  echo " NOT NEEDED"
		}
		echo ""
		;;
	darwin)
		bsdlibs="/usr/lib/dyld /usr/lib/dylib1.o /usr/lib/system/libmathCommon.A.dylib"
		;;
	*)
		echo "No special library needed on this platform."
		bsdlibs=""
		;;
esac

echo -e "\nCopying your system's run-time library linker(s):"
echo "(NOTE: Searches can take a couple of minutes, please be patient.)"
libfailed=0

if [ ! -z "$bsdlibs" ]; then
        for bsdlib in $bsdlibs; do
            bsdlibdir=${bsdlib%/*}
            mkdir -p "$glroot$bsdlibdir"
            echo -n "   $(basename $bsdlib): "
            if [ -e "$bsdlib" ]; then
		rm -f "$glroot$bsdlibdir$(basename $bsdlib)"
                cp -fRH "$bsdlib" "$glroot$bsdlibdir"
                echo "OK"
            else
                echo -n "Searching . . . " 
                file=$(find / -name $(basename $bsdlib) | head -1)
                if [ -n "$file" ]; then
		    rm -f "$glroot$bsdlibdir$(basename $file)"
                    cp -fRH "$file" "$glroot$bsdlibdir"
                    echo "OK"
                else
                    echo -e '\033[1;31mFailed!\033[0m'
                    libfailed="1"
                fi
            fi
        done
        [ $libfailed -eq 1 ] && echo "You must install and copy the missing libraries to $glroot$bsdlibdir manually." 
fi

echo -ne "\nConfiguring the shared library cache . . . "
sort "$glroot/etc/ld.so.conf" | uniq >"$glroot/etc/ld.so.temp" && mv "$glroot/etc/ld.so.temp" "$glroot/etc/ld.so.conf"
lddlist="`cat $glroot/etc/ld.so.conf | tr '\n' ' '`"
case $os in
    linux)
        chroot "$glroot" /bin/ldconfig
        ;;
    *bsd*)
        mkdir -p "$glroot/usr/lib"
        mkdir -p "$glroot/var/run"
        chroot "$glroot" /bin/ldconfig $lddlist
        ;;
    esac
echo "Done."

echo
echo "If you got errors, please fix them and re-run the program."
echo "If you didn't get any errors - have phun!"
echo

exit 0

