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
    printf "${YELLOW}%-26s${GREEN}%-18s${RED}%-20s${SKYBLUE}%-12s${PLAIN}\n" "${nodeName}" "${ipaddress}" "${speedtest}" "${latency}"
}

speed() {
    rm -rf /tmp/speed.txt && touch /tmp/speed.txt
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
    rm -rf /tmp/fio.txt && touch /tmp/fio.txt
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

        printf "%-20s %-15s %-18s %-15s\n" "Ram Test Name" "Total Time" "Transfer Rate" "Operations Rate"

        sysbench --threads=4 --time=30 --memory-block-size=1K --memory-scope=global --memory-total-size=200G --memory-oper=read memory run | cat > /tmp/sysbench-ram1.txt
        local total_time1=$( cat /tmp/sysbench-ram1.txt | egrep "total time:" | cut -d: -f2 | xargs )
        local transfer1=$( cat /tmp/sysbench-ram1.txt | egrep "transferred \(" | cut -d"(" -f2 | cut -d" " -f1 )
        local operation1=$( cat /tmp/sysbench-ram1.txt | egrep "* per second" | cut -d: -f2 | xargs | cut -d"(" -f2- | cut -d" " -f1 )
        printf "${YELLOW}%-20s${PLAIN} ${SKYBLUE}%-15s${PLAIN} ${RED}%-18s${PLAIN} ${GREEN}%-15s${PLAIN}\n" "Read" "$total_time1" "$transfer1 MB/s" "$operation1 ops/s"

        sysbench --threads=4 --time=30 --memory-block-size=1M --memory-scope=global --memory-total-size=1000G --memory-oper=read memory run | cat > /tmp/sysbench-ram2.txt
        local total_time2=$( cat /tmp/sysbench-ram2.txt | egrep "total time:" | cut -d: -f2 | xargs )
        local transfer2=$( cat /tmp/sysbench-ram2.txt | egrep "transferred \(" | cut -d"(" -f2 | cut -d" " -f1 )
        local operation2=$( cat /tmp/sysbench-ram2.txt | egrep "* per second" | cut -d: -f2 | xargs | cut -d"(" -f2- | cut -d" " -f1 )
        printf "${YELLOW}%-20s${PLAIN} ${SKYBLUE}%-15s${PLAIN} ${RED}%-18s${PLAIN} ${GREEN}%-15s${PLAIN}\n" "Read 1M" "$total_time2" "$transfer2 MB/s" "$operation2 ops/s"

        sysbench --threads=4 --time=30 --memory-block-size=1K --memory-scope=global --memory-total-size=100G --memory-oper=write memory run | cat > /tmp/sysbench-ram3.txt
        local total_time3=$( cat /tmp/sysbench-ram3.txt | egrep "total time:" | cut -d: -f2 | xargs )
        local transfer3=$( cat /tmp/sysbench-ram3.txt | egrep "transferred \(" | cut -d"(" -f2 | cut -d" " -f1 )
        local operation3=$( cat /tmp/sysbench-ram3.txt | egrep "* per second" | cut -d: -f2 | xargs | cut -d"(" -f2- | cut -d" " -f1 )
        printf "${YELLOW}%-20s${PLAIN} ${SKYBLUE}%-15s${PLAIN} ${RED}%-18s${PLAIN} ${GREEN}%-15s${PLAIN}\n" "Write" "$total_time3" "$transfer3 MB/s" "$operation3 ops/s"

        sysbench --threads=4 --time=30 --memory-block-size=1M --memory-scope=global --memory-total-size=400G --memory-oper=write memory run | cat > /tmp/sysbench-ram4.txt
        local total_time4=$( cat /tmp/sysbench-ram4.txt | egrep "total time:" | cut -d: -f2 | xargs )
        local transfer4=$( cat /tmp/sysbench-ram4.txt | egrep "transferred \(" | cut -d"(" -f2 | cut -d" " -f1 )
        local operation4=$( cat /tmp/sysbench-ram4.txt | egrep "* per second" | cut -d: -f2 | xargs | cut -d"(" -f2- | cut -d" " -f1 )
        printf "${YELLOW}%-20s${PLAIN} ${SKYBLUE}%-15s${PLAIN} ${RED}%-18s${PLAIN} ${GREEN}%-15s${PLAIN}\n" "Write 1M" "$total_time4" "$transfer4 MB/s" "$operation4 ops/s"


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
    printf 'VNbenchmark.com v2021.06.24\n'
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
    export TIMEFORMAT='%3R seconds'
    cpu1=$( cpu_test_old -q sha256sum || cpu_test_old -q sha256 || printf '[no SHA256 command found]\n' )
    echo -e "CPU: SHA256-hashing 10GB      : ${YELLOW}$cpu1${PLAIN}"
    cpu2=$( cpu_test_old bzip2 )
    echo -e "CPU: bzip2-compressing 10GB   : ${YELLOW}$cpu2${PLAIN}"
    cpu3=$( cpu_test_old openssl enc -e -aes-256-cbc -pass pass:12345678 | sed '/^\*\*\* WARNING : deprecated key derivation used\.$/d;/^Using -iter or -pbkdf2 would be better\.$/d' )
    echo -e "CPU: AES-encrypting 10GB      : ${YELLOW}$cpu3${PLAIN}"
    echo ""
    cpu_test
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
    printf "%-26s%-18s%-20s%-12s\n" "Node Name" "IP Address" "Download" "Latency"
    speed
    next

) | tee /root/vnbenchmark.log

echo "VNBenchmark is now complete! Bench data is saved to /root/vnbenchmark.log"

# Check share report
echo ""
echo "Upload your Benchmark to VNBenchmark.com"
IKEY=$(curl -sS --data "result=$(cat /root/vnbenchmark.log)" https://vnbenchmark.com/share-ket-qua/?AKEY=$AKEY 2>/dev/null)
echo "Result Address:https://vnbenchmark.com/ket-qua/$IKEY"
