#!/bin/bash
#######################################################
# VNbenchmark.com VPS Benchmarks v1.0
# Run using `curl -s vnbenchmark.com/bash | bash`
# or `wget -qO- vnbenchmark.com | bash`
#######################################################
# Check if user is root
[ $(id -u) != "0" ] && { echo "${CFAILURE}Error: You must be root to run this script${CEND}"; exit 1; }

# Check if wget installed
if  [ ! -e '/usr/bin/wget' ]; then
    echo "Error: wget command not found. You must be install wget command at first."
    exit 1
fi

# Check release
if [ -f /etc/redhat-release ]; then
    release="centos"
elif cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
fi

rm -f /root/vnbenchmark.log

echo "Installing required packages, please wait..."

# Install Virt-what
if  [ ! -e '/usr/sbin/virt-what' ]; then
    echo "Installing Virt-What......"
    if [ "${release}" == "centos" ]; then
        yum -y install virt-what > /dev/null 2>&1
    else
        apt-get update > /dev/null 2>&1
        apt-get -y install virt-what > /dev/null 2>&1
    fi
fi



# Install uuid
if  [ ! -e '/usr/bin/uuid' ]; then
    if [ "${release}" == "centos" ]; then
        echo "Installing uuid......"
        yum -y install uuid > /dev/null 2>&1
    else
        apt-get -y install uuid > /dev/null 2>&1
    fi
fi


# Install curl
if  [ ! -e '/usr/bin/curl' ]; then
    if [ "${release}" == "centos" ]; then
        echo "Installing curl......"
        yum -y install curl > /dev/null 2>&1
    else
        apt-get -y install curl > /dev/null 2>&1
    fi
fi


# Install fio
if  [ ! -e '/usr/bin/fio' ]; then
    echo "Installing fio......"
    if [ "${release}" == "centos" ]; then
            yum install -y fio
        else
            apt-get install -y fio
    fi
fi

# Check Python
if  [ ! -e '/usr/bin/python' ]; then
    echo "Installing Python......"
    if [ "${release}" == "centos" ]; then
            yum update > /dev/null 2>&1
            yum -y install python
        else
            apt-get update > /dev/null 2>&1
            apt-get -y install python
    fi
fi

# Check bzip2
if  [ ! -e '/usr/bin/bzip2' ]; then
    echo "Installing Bzip2......"
    if [ "${release}" == "centos" ]; then
            yum -y install bzip2
        else
            apt-get -y install bzip2
    fi
fi

# Check sha256sum
if  [ ! -e '/usr/bin/sha256sum' ]; then
    echo "Installing Sha256sum......"
    if [ "${release}" == "centos" ]; then
            yum update > /dev/null 2>&1
            yum -y install sha256sum
        else
            apt-get update > /dev/null 2>&1
            apt-get -y install sha256sumsha256sum
    fi
fi

# Check openssl
if  [ ! -e '/usr/bin/openssl' ]; then
    echo "Installing Openssl......"
    if [ "${release}" == "centos" ]; then
            yum update > /dev/null 2>&1
            yum -y install openssl
        else
            apt-get update > /dev/null 2>&1
            apt-get -y install openssl
    fi
fi

# Check sysbench
if  [ ! -e '/usr/bin/sysbench' ]; then
    echo "Installing Sysbench......"
    if [ "${release}" == "centos" ]; then
            curl -s https://packagecloud.io/install/repositories/akopytov/sysbench/script.rpm.sh | bash > /dev/null 2>&1
            yum -y install sysbench > /dev/null 2>&1
        else
            curl -s https://packagecloud.io/install/repositories/akopytov/sysbench/script.deb.sh | bash > /dev/null 2>&1
            apt -y install sysbench > /dev/null 2>&1

    fi
fi

# Install Speedtest
if  [ ! -e '/tmp/speedtest.py' ]; then
    echo "Installing SpeedTest......"
    dir=$(pwd)
    cd /tmp/
    wget  -N --no-check-certificate https://raw.github.com/sivel/speedtest-cli/master/speedtest.py > /dev/null 2>&1
    cd $dir
fi
chmod a+rx /tmp/speedtest.py

sleep 1
echo "Installed required packages."
sleep 1
echo "Starting VNBenchmark..."
sleep 1

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
SKYBLUE='\033[0;36m'
PLAIN='\033[0m'

AKEY=$( uuid )


get_opsy() {
    [ -f /etc/redhat-release ] && awk '{print ($1,$3~/^[0-9]/?$3:$4)}' /etc/redhat-release && return
    [ -f /etc/os-release ] && awk -F'[= "]' '/PRETTY_NAME/{print $3,$4,$5}' /etc/os-release && return
    [ -f /etc/lsb-release ] && awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release && return
}

next() {
    printf "%-74s\n" "-" | sed 's/\s/-/g'
}

speed_test() {
    local speedtest=$(wget -4O /dev/null -T300 $1 2>&1 | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}')
    local ipaddress=$(ping -c1 -n `awk -F'/' '{print $3}' <<< $1` | awk -F'[()]' '{print $2;exit}')
    local nodeName=$2
    local latency=$(ping $ipaddress -c 3 | grep avg | awk -F / '{print $5}')" ms"
    printf "${YELLOW}%-30s${PLAIN}${GREEN}%-36s${PLAIN}${RED}%-20s${PLAIN}${SKYBLUE}%-12s${PLAIN}\n" "${nodeName}" "${ipaddress}" "${speedtest}" "${latency}"
}

speed() {
    speed_test 'http://cachefly.cachefly.net/100mb.test' 'CacheFly'
    speed_test 'https://lax-ca-us-ping.vultr.com/vultr.com.100MB.bin' 'Vultr - Los Angeles'
    speed_test 'https://wa-us-ping.vultr.com/vultr.com.100MB.bin' 'Vultr - Seattle'
    speed_test 'http://speedtest.tokyo2.linode.com/100MB-tokyo.bin' 'Linode - Tokyo,'
    speed_test 'http://speedtest.singapore.linode.com/100MB-singapore.bin' 'Linode - Singapore'
    speed_test 'http://speedtest.hkg02.softlayer.com/downloads/test100.zip' 'Softlayer - HongKong'
    speed_test 'http://speedtest1.vtn.com.vn/speedtest/random4000x4000.jpg' 'VNPT - Ha Noi'
    speed_test 'http://speedtest5.vtn.com.vn/speedtest/random4000x4000.jpg' 'VNPT - Da Nang, VN'
    speed_test 'http://speedtest3.vtn.com.vn/speedtest/random4000x4000.jpg' 'VNPT - Ho Chi Minh'
    speed_test 'http://speedtestkv1a.viettel.vn/speedtest/random4000x4000.jpg' 'Viettel - Ha Noi'
    speed_test 'http://speed-pv1.viettelidc.com.vn/speedtest/random4000x4000.jpg' 'Viettel IDC - Ha Noi'
    speed_test 'http://speedtestkv2a.viettel.vn/speedtest/random4000x4000.jpg' 'Viettel - Da Nang'
    speed_test 'http://speedtestkv3a.viettel.vn/speedtest/random4000x4000.jpg' 'Viettel - Ho Chi Minh'
    speed_test 'http://speed-hht1.viettelidc.com.vn/speedtest/random4000x4000.jpg' 'Viettel IDC - Ho Chi Minh'
    #speed_test 'http://speedtesthn.fpt.vn:8080/speedtest/random4000x4000.jpg' 'FPT - Ha Noi'
    speed_test 'http://speedtest.fpt.vn/speedtest/random4000x4000.jpg' 'FPT - Ho Chi Minh'
}

fio_test() {
    if [ -e '/usr/bin/fio' ]; then
        local tmp=$(mktemp)
        fio --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=fio_test --filename=fio_test --bs=4k --numjobs=1 --iodepth=64 --size=256M --readwrite=randrw --rwmixread=75 --runtime=30 --time_based --output="$tmp"

        if [ $(fio -v | cut -d '.' -f 1) == "fio-2" ]; then
            local iops_read=`grep "iops=" "$tmp" | grep read | awk -F[=,]+ '{print $6}'`
            local iops_write=`grep "iops=" "$tmp" | grep write | awk -F[=,]+ '{print $6}'`
            local bw_read=`grep "bw=" "$tmp" | grep read | awk -F[=,B]+ '{if(match($4, /[0-9]+K$/)) {printf("%.1f", int($4)/1024);} else if(match($4, /[0-9]+M$/)) {printf("%.1f", substr($4, 0, length($4)-1))} else {printf("%.1f", int($4)/1024/1024);}}'`"MB/s"
            local bw_write=`grep "bw=" "$tmp" | grep write | awk -F[=,B]+ '{if(match($4, /[0-9]+K$/)) {printf("%.1f", int($4)/1024);} else if(match($4, /[0-9]+M$/)) {printf("%.1f", substr($4, 0, length($4)-1))} else {printf("%.1f", int($4)/1024/1024);}}'`"MB/s"

        elif [ $(fio -v | cut -d '.' -f 1) == "fio-3" ]; then
            local iops_read=`grep "IOPS=" "$tmp" | grep read | awk -F[=,]+ '{print $2}'`
            local iops_write=`grep "IOPS=" "$tmp" | grep write | awk -F[=,]+ '{print $2}'`
            local bw_read=`grep "bw=" "$tmp" | grep READ | awk -F"[()]" '{print $2}'`
            local bw_write=`grep "bw=" "$tmp" | grep WRITE | awk -F"[()]" '{print $2}'`
        fi

        echo -e "Read performance               : ${YELLOW}$bw_read${PLAIN}"
        sleep 1
        echo -e "Read IOPS                      : ${YELLOW}$iops_read${PLAIN}"
        sleep 1
        echo -e "Write performance              : ${YELLOW}$bw_write${PLAIN}"
        sleep 1
        echo -e "Write IOPS                     : ${YELLOW}$iops_write${PLAIN}"

        rm -f $tmp fio_test
    else
        echo "Fio is missing!!! Please install Fio before running test."
    fi


}

command_exists() {
    command -v "$@" > /dev/null 2>&1
}

cpu_test() {
    if [ -e '/usr/bin/sysbench' ]; then

        printf "%-20s %-12s %-15s %-15s %-22s\n" "CPU Test Name" "Total Time" "Avg Latency" "95th Latency" "CPU speed"

        sysbench --threads=1 --time=30 --cpu-max-prime=20000 cpu run | cat > /tmp/sysbench-cpu1.txt
        local total_time1=$( cat /tmp/sysbench-cpu1.txt | egrep "total time:" | cut -d: -f2 | xargs )
        local avg1=$( cat /tmp/sysbench-cpu1.txt | egrep "avg:" | cut -d: -f2 | xargs )
        local percentile1=$( cat /tmp/sysbench-cpu1.txt | egrep "95th percentile:" | cut -d: -f2 | xargs)
        local cpu_speed1=$( cat /tmp/sysbench-cpu1.txt | egrep "events per second:" | cut -d: -f2 | xargs)
        printf "${YELLOW}%-20s${PLAIN} ${SKYBLUE}%-12s${PLAIN} ${SKYBLUE}%-15s${PLAIN} ${SKYBLUE}%-15s${PLAIN} ${GREEN}%-22s${PLAIN}\n" "Single Thread" "$total_time1" "$avg1 ms" "$percentile1 ms" "$cpu_speed1 e/s"

        #echo "Single Thread"
        #cat /tmp/sysbench-cpu1.txt | egrep "CPU speed:|events per second:|General statistics:|total time|total number of events:|Latency (ms):|min:|avg:|max:|percentile:|sum:"


        sysbench --threads=4 --time=30 --cpu-max-prime=20000 cpu run | cat > /tmp/sysbench-cpu2.txt
        local total_time2=$( cat /tmp/sysbench-cpu2.txt | egrep "total time:" | cut -d: -f2 | xargs )
        local avg2=$( cat /tmp/sysbench-cpu2.txt | egrep "avg:" | cut -d: -f2 | xargs )
        local percentile2=$( cat /tmp/sysbench-cpu2.txt | egrep "95th percentile:" | cut -d: -f2 | xargs)
        local cpu_speed2=$( cat /tmp/sysbench-cpu2.txt | egrep "events per second:" | cut -d: -f2 | xargs)
        printf "${YELLOW}%-20s${PLAIN} ${SKYBLUE}%-12s${PLAIN} ${SKYBLUE}%-15s${PLAIN} ${SKYBLUE}%-15s${PLAIN} ${GREEN}%-22s${PLAIN}\n" "Multithreaded" "$total_time2" "$avg2 ms" "$percentile2 ms" "$cpu_speed2 e/s"

    else
        echo "Sysbench is missing!!! Please install Sysbench before running test."
    fi
}

ram_test() {
    if [ -e '/usr/bin/sysbench' ]; then

        printf "%-20s %-15s %-18s %-22s %-15s\n" "Ram Test Name" "Total Time" "Transfer Rate" "Operations Rate" "Latency"

        sysbench --threads=4 --time=30 --memory-block-size=1K --memory-scope=global --memory-total-size=200G --memory-oper=read memory run | cat > /tmp/sysbench-ram1.txt
        local total_time1=$( cat /tmp/sysbench-ram1.txt | egrep "total time:" | cut -d: -f2 | xargs )
        local transfer1=$( cat /tmp/sysbench-ram1.txt | egrep "transferred \(" | cut -d"(" -f2 | cut -d" " -f1 )
        local operation1=$( cat /tmp/sysbench-ram1.txt | egrep "* per second" | cut -d: -f2 | xargs | cut -d"(" -f2- | cut -d" " -f1 )
        local latency1=$( cat /tmp/sysbench-ram1.txt | egrep "avg:" | cut -d: -f2 | xargs )
        printf "${YELLOW}%-20s${PLAIN} ${SKYBLUE}%-15s${PLAIN} ${RED}%-18s${PLAIN} ${GREEN}%-22s${PLAIN} ${SKYBLUE}%-15s${PLAIN}\n" "Read" "$total_time1" "$transfer1 MB/s" "$operation1 ops/s" "$latency1 ms"

        sysbench --threads=4 --time=30 --memory-block-size=1M --memory-scope=global --memory-total-size=1000G --memory-oper=read memory run | cat > /tmp/sysbench-ram2.txt
        local total_time2=$( cat /tmp/sysbench-ram2.txt | egrep "total time:" | cut -d: -f2 | xargs )
        local transfer2=$( cat /tmp/sysbench-ram2.txt | egrep "transferred \(" | cut -d"(" -f2 | cut -d" " -f1 )
        local operation2=$( cat /tmp/sysbench-ram2.txt | egrep "* per second" | cut -d: -f2 | xargs | cut -d"(" -f2- | cut -d" " -f1 )
        local latency2=$( cat /tmp/sysbench-ram2.txt | egrep "avg:" | cut -d: -f2 | xargs )
        printf "${YELLOW}%-20s${PLAIN} ${SKYBLUE}%-15s${PLAIN} ${RED}%-18s${PLAIN} ${GREEN}%-22s${PLAIN} ${SKYBLUE}%-15s${PLAIN}\n" "Read 1M" "$total_time2" "$transfer2 MB/s" "$operation2 ops/s" "$latency2 ms"

        sysbench --threads=4 --time=30 --memory-block-size=1K --memory-scope=global --memory-total-size=100G --memory-oper=write memory run | cat > /tmp/sysbench-ram3.txt
        local total_time3=$( cat /tmp/sysbench-ram3.txt | egrep "total time:" | cut -d: -f2 | xargs )
        local transfer3=$( cat /tmp/sysbench-ram3.txt | egrep "transferred \(" | cut -d"(" -f2 | cut -d" " -f1 )
        local operation3=$( cat /tmp/sysbench-ram3.txt | egrep "* per second" | cut -d: -f2 | xargs | cut -d"(" -f2- | cut -d" " -f1 )
        local latency3=$( cat /tmp/sysbench-ram3.txt | egrep "avg:" | cut -d: -f2 | xargs )
        printf "${YELLOW}%-20s${PLAIN} ${SKYBLUE}%-15s${PLAIN} ${RED}%-18s${PLAIN} ${GREEN}%-22s${PLAIN} ${SKYBLUE}%-15s${PLAIN}\n" "Write" "$total_time3" "$transfer3 MB/s" "$operation3 ops/s" "$latency3 ms"

        sysbench --threads=4 --time=30 --memory-block-size=1M --memory-scope=global --memory-total-size=400G --memory-oper=write memory run | cat > /tmp/sysbench-ram4.txt
        local total_time4=$( cat /tmp/sysbench-ram4.txt | egrep "total time:" | cut -d: -f2 | xargs )
        local transfer4=$( cat /tmp/sysbench-ram4.txt | egrep "transferred \(" | cut -d"(" -f2 | cut -d" " -f1 )
        local operation4=$( cat /tmp/sysbench-ram4.txt | egrep "* per second" | cut -d: -f2 | xargs | cut -d"(" -f2- | cut -d" " -f1 )
        local latency4=$( cat /tmp/sysbench-ram3.txt | egrep "avg:" | cut -d: -f2 | xargs )
        printf "${YELLOW}%-20s${PLAIN} ${SKYBLUE}%-15s${PLAIN} ${RED}%-18s${PLAIN} ${GREEN}%-22s${PLAIN} ${SKYBLUE}%-15s${PLAIN}\n" "Write 1M" "$total_time4" "$transfer4 MB/s" "$operation4 ops/s" "$latency4 ms"


    else
        echo "Sysbench is missing!!! Please install Sysbench before running test."
    fi
}

cpu_test_old() {
    if [ "$1" = "-q" ]
    then
        QUIET=1
        shift
    fi

    if command_exists "$1"
    then
        ( time "$gnu_dd" if=/dev/zero bs=1M count=10000 2> /dev/null | \
            "$@" > /dev/null ) 2>&1
    else
        if [ "$QUIET" -ne 1 ]
        then
            unset QUIET
            printf '[command `%s` not found]\n' "$1"
        fi
        return 1
    fi
}

io_test() {
    (LANG=C dd if=/dev/zero of=test_$$ bs=64k count=16k conv=fdatasync && rm -f test_$$ ) 2>&1 | awk -F, '{io=$NF} END { print io}' | sed 's/^[ \t]*//;s/[ \t]*$//'
}

calc_disk() {
    local total_size=0
    local array=$@
    for size in ${array[@]}
    do
        [ "${size}" == "0" ] && size_t=0 || size_t=`echo ${size:0:${#size}-1}`
        [ "`echo ${size:(-1)}`" == "K" ] && size=0
        [ "`echo ${size:(-1)}`" == "M" ] && size=$( awk 'BEGIN{printf "%.1f", '$size_t' / 1024}' )
        [ "`echo ${size:(-1)}`" == "T" ] && size=$( awk 'BEGIN{printf "%.1f", '$size_t' * 1024}' )
        [ "`echo ${size:(-1)}`" == "G" ] && size=${size_t}
        total_size=$( awk 'BEGIN{printf "%.1f", '$total_size' + '$size'}' )
    done
    echo ${total_size}
}

launch_geekbench() {
	VERSION=$1

	# create a temp directory to house all geekbench files
	GEEKBENCH_PATH=/tmp/geekbench_$VERSION
	mkdir -p $GEEKBENCH_PATH

	# check for curl vs wget
	[[ ! -z $LOCAL_CURL ]] && DL_CMD="curl -s" || DL_CMD="wget -qO-"

	if [[ $VERSION == *4* && ($ARCH = *aarch64* || $ARCH = *arm*) ]]; then
		echo -e "\nARM architecture not supported by Geekbench 4, use Geekbench 5."
	elif [[ $VERSION == *4* && $ARCH != *aarch64* && $ARCH != *arm* ]]; then # Geekbench v4
		echo -n "\nRunning Geekbench 4 benchmark test..."
		# download the latest Geekbench 4 tarball and extract to geekbench temp directory
		$DL_CMD https://cdn.geekbench.com/Geekbench-4.4.4-Linux.tar.gz  | tar xz --strip-components=1 -C $GEEKBENCH_PATH &>/dev/null

		if [[ "$ARCH" == *"x86"* ]]; then
			# check if geekbench file exists
			if test -f "geekbench.license"; then
				$GEEKBENCH_PATH/geekbench_x86_32 --unlock `cat geekbench.license` > /dev/null 2>&1
			fi

			# run the Geekbench 4 test and grep the test results URL given at the end of the test
			GEEKBENCH_TEST=$($GEEKBENCH_PATH/geekbench_x86_32 --upload 2>/dev/null | grep "https://browser")
		else
			# check if geekbench file exists
			if test -f "geekbench.license"; then
				$GEEKBENCH_PATH/geekbench4 --unlock `cat geekbench.license` > /dev/null 2>&1
			fi
			
			# run the Geekbench 4 test and grep the test results URL given at the end of the test
			GEEKBENCH_TEST=$($GEEKBENCH_PATH/geekbench4 --upload 2>/dev/null | grep "https://browser")
		fi
	fi

	if [[ $VERSION == *5* ]]; then # Geekbench v5
		if [[ $ARCH = *x86* && $GEEKBENCH_4 == *False* ]]; then # don't run Geekbench 5 if on 32-bit arch
			echo -e "\nGeekbench 5 cannot run on 32-bit architectures. Re-run with -4 flag to use"
			echo -e "Geekbench 4, which can support 32-bit architectures. Skipping Geekbench 5."
		elif [[ $ARCH = *x86* && $GEEKBENCH_4 == *True* ]]; then
			echo -e "\nGeekbench 5 cannot run on 32-bit architectures. Skipping test."
		else
			echo -n "\nRunning Geekbench 5 benchmark test..."
			# download the latest Geekbench 5 tarball and extract to geekbench temp directory
			if [[ $ARCH = *aarch64* || $ARCH = *arm* ]]; then
				$DL_CMD https://cdn.geekbench.com/Geekbench-5.4.4-LinuxARMPreview.tar.gz  | tar xz --strip-components=1 -C $GEEKBENCH_PATH &>/dev/null
			else
				$DL_CMD https://cdn.geekbench.com/Geekbench-5.4.4-Linux.tar.gz | tar xz --strip-components=1 -C $GEEKBENCH_PATH &>/dev/null
			fi

			# check if geekbench file exists
			if test -f "geekbench.license"; then
				$GEEKBENCH_PATH/geekbench5 --unlock `cat geekbench.license` > /dev/null 2>&1
			fi

			GEEKBENCH_TEST=$($GEEKBENCH_PATH/geekbench5 --upload 2>/dev/null | grep "https://browser")
		fi
	fi

	# ensure the test ran successfully
	if [ -z "$GEEKBENCH_TEST" ]; then
		if [[ -z "$IPV4_CHECK" ]]; then
			# Geekbench test failed to download because host lacks IPv4 (cdn.geekbench.com = IPv4 only)
			echo -e "\r\033[0KGeekbench releases can only be downloaded over IPv4. FTP the Geekbench files and run manually."
		elif [[ $ARCH != *x86* ]]; then
			# if the Geekbench test failed for any reason, exit cleanly and print error message
			echo -e "\r\033[0KGeekbench $VERSION test failed. Run manually to determine cause."
		fi
	else
		# if the Geekbench test succeeded, parse the test results URL
		GEEKBENCH_URL=$(echo -e $GEEKBENCH_TEST | head -1)
		GEEKBENCH_URL_CLAIM=$(echo $GEEKBENCH_URL | awk '{ print $2 }')
		GEEKBENCH_URL=$(echo $GEEKBENCH_URL | awk '{ print $1 }')
		# sleep a bit to wait for results to be made available on the geekbench website
		sleep 20
		# parse the public results page for the single and multi core geekbench scores
		[[ $VERSION == *5* ]] && GEEKBENCH_SCORES=$($DL_CMD $GEEKBENCH_URL | grep "div class='score'") ||
			GEEKBENCH_SCORES=$($DL_CMD $GEEKBENCH_URL | grep "span class='score'")
		GEEKBENCH_SCORES_SINGLE=$(echo $GEEKBENCH_SCORES | awk -v FS="(>|<)" '{ print $3 }')
		GEEKBENCH_SCORES_MULTI=$(echo $GEEKBENCH_SCORES | awk -v FS="(>|<)" '{ print $7 }')
	
		# print the Geekbench results
		echo -en "\r\033[0K"
		printf "%-15s ${RED}%-30s${PLAIN}\n" "CPU Test Name" "Score"
		printf "%-15s ${RED}%-30s${PLAIN}\n" "Single Core" "$GEEKBENCH_SCORES_SINGLE"
		printf "%-15s ${RED}%-30s${PLAIN}\n" "Multi Core" "$GEEKBENCH_SCORES_MULTI"
		printf "%-15s ${GREEN}%-30s${PLAIN}\n" "Full Test" "$GEEKBENCH_URL"

		# write the geekbench claim URL to a file so the user can add the results to their profile (if desired)
		[ ! -z "$GEEKBENCH_URL_CLAIM" ] && echo -e "$GEEKBENCH_URL_CLAIM" >> geekbench_claim.url 2> /dev/null
	fi
}


(
    next

    vname=$( awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
    cores=$( awk -F: '/model name/ {core++} END {print core}' /proc/cpuinfo )
    freq=$( awk -F: '/cpu MHz/ {freq=$2} END {print freq}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
    tram=$( free -m | awk '/Mem/ {print $2}' )
    uram=$( free -m | awk '/Mem/ {print $3}' )
    swap=$( free -m | awk '/Swap/ {print $2}' )
    uswap=$( free -m | awk '/Swap/ {print $3}' )
    up=$( awk '{a=$1/86400;b=($1%86400)/3600;c=($1%3600)/60} {printf("%d days, %d hour %d min\n",a,b,c)}' /proc/uptime )
    load=$( w | head -1 | awk -F'load average:' '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//' )
    opsy=$( get_opsy )
    arch=$( uname -m )
    lbit=$( getconf LONG_BIT )
    kern=$( uname -r )
    ipv6=$( wget -qO- -t1 -T2 ipv6.icanhazip.com )
    disk_size1=($( LANG=C df -hPl | grep -wvE '\-|none|tmpfs|devtmpfs|by-uuid|chroot|Filesystem' | awk '{print $2}' ))
    disk_size2=($( LANG=C df -hPl | grep -wvE '\-|none|tmpfs|devtmpfs|by-uuid|chroot|Filesystem' | awk '{print $3}' ))
    disk_total_size=$( calc_disk ${disk_size1[@]} )
    disk_used_size=$( calc_disk ${disk_size2[@]} )


    clear

    sleep 1

    printf '%s\n'
    printf 'VNbenchmark.com v2022.06.17\n'
    date -u '+Benchmark time:    %F %T UTC/GMT+7'
    printf '%s\n'

    sleep 1

    next
    echo ""
    echo "System Info"
    echo -e "CPU model                     : ${SKYBLUE}$vname${PLAIN}"
    echo -e "Number of cores               : ${SKYBLUE}$cores${PLAIN}"
    echo -e "CPU frequency                 : ${SKYBLUE}$freq MHz${PLAIN}"
    echo -e "Total size of Disk            : ${SKYBLUE}$disk_total_size GB ($disk_used_size GB Used)${PLAIN}"
    echo -e "Total amount of Mem           : ${SKYBLUE}$tram MB ($uram MB Used)${PLAIN}"
    echo -e "Total amount of Swap          : ${SKYBLUE}$swap MB ($uswap MB Used)${PLAIN}"
    echo -e "System uptime                 : ${SKYBLUE}$up${PLAIN}"
    echo -e "Load average                  : ${SKYBLUE}$load${PLAIN}"
    echo -e "OS                            : ${SKYBLUE}$opsy${PLAIN}"
    echo -e "Arch                          : ${SKYBLUE}$arch ($lbit Bit)${PLAIN}"
    echo -e "Kernel                        : ${SKYBLUE}$kern${PLAIN}"
    echo -ne "Virt                          : "
    virtua=$(virt-what) 2>/dev/null

    if [[ ${virtua} ]]; then
        echo -e "${SKYBLUE}$virtua${PLAIN}"
    else
        virtua="No Virt"
        echo -e "${SKYBLUE}No Virt${PLAIN}"
    fi
    echo ""
    next

    sleep 1

    echo ""
    echo "CPU Test"
    launch_geekbench 5
    echo ""
    next

    sleep 1

    echo ""
    echo "RAM Test"
    ram_test
    echo ""
    next

    sleep 1

    echo ""
    echo "I/O Test"
    io1=$( io_test )
    echo -e "I/O speed(1st run)            : ${YELLOW}$io1${PLAIN}"
    sleep 1
    io2=$( io_test )
    echo -e "I/O speed(2nd run)            : ${YELLOW}$io2${PLAIN}"
    sleep 1
    io3=$( io_test )
    echo -e "I/O speed(3rd run)            : ${YELLOW}$io3${PLAIN}"
    echo ""
    next

    sleep 1

    echo ""
    echo "Fio Test"
    fio_test $cores
    echo ""
    next

    echo ""
    echo "Speedtest"
    printf "%-30s%-36s%-20s%-12s\n" "Node Name" "IP Address" "Download" "Latency"
    speed
    next

) | tee /root/vnbenchmark.log

echo "VNBenchmark is now complete! Bench data is saved to /root/vnbenchmark.log"
