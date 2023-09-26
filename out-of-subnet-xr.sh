#!/bin/bash
#
#This script is showing out of subnets Remote EPs in the fabric.
#To be used to evaluate impact from enabling Global Subnet Check.
#
#Made by Igor Derybas, in_subnet function is taken from https://unix.stackexchange.com/a/465372

function in_subnet {
    # Determine whether IP address is in the specified subnet.
    #
    # Args:
    #   sub: Subnet, in CIDR notation.
    #   ip: IP address to check.
    #
    # Returns:
    #   1|0
    #
    local ip ip_a mask netmask sub sub_ip rval start end

    # Define bitmask.
    local readonly BITMASK=0xFFFFFFFF

    # Read arguments.
    IFS=/ read sub mask <<< "${1}"
    IFS=. read -a sub_ip <<< "${sub}"
    IFS=. read -a ip_a <<< "${2}"

    # Calculate netmask.
    netmask=$(($BITMASK<<$((32-$mask)) & $BITMASK))

    # Determine address range.
    start=0
    for o in "${sub_ip[@]}"
    do
        start=$(($start<<8 | $o))
    done

    start=$(($start & $netmask))
    end=$(($start | ~$netmask & $BITMASK))

    # Convert IP address to 32-bit number.
    ip=0
    for o in "${ip_a[@]}"
    do
        ip=$(($ip<<8 | $o))
    done

    # Determine if IP in range.
    (( $ip >= $start )) && (( $ip <= $end )) && rval=1 || rval=0

    echo "${rval}"
}

#Discover Subnets deployed with VRF names
subnets=$(moquery -c ipv4Addr -f 'ipv4.Addr.ctrl=="pervasive"' | grep dn | sed 's/^.*dom-//' | sed 's/\/if-.*addr-\[/__/' | sed 's/\]//'| sort | uniq)
#subnets=$(cat subnets)

#Discover all XR EPs with VRF VNID
xr=$(moquery -c epmIpEp -f 'epm.IpEp.flags=="ip"' | grep dn | sed 's/^.*\[vxlan-//' | sed 's/\].*-\[/__/' | sed 's/\]//'| sort | uniq)
#xr=$(cat xr_u)

#Discover VRF Names and VNIDs
vrf_vnid=$(moquery -c fvCtx  | egrep "dn|scope" | sed 's/^.*uni\/tn-/ /' | sed 's/\/ctx-/:/' | sed 's/^.*: /___/' | tr -d '\n' | tr " " "\n")
#vrf_vnid=$(cat vrf1)

for i in $xr; do
        vnid=`echo $i | sed 's/__.*//'`
        xr_ip=`echo $i | sed 's/^.*__//'`
        for v in $vrf_vnid; do
            xr_vrf_temp=$(echo $v | grep $vnid | sed 's/___.*//')
            if [ "$xr_vrf_temp" != "" ]; then
                xr_vrf=$xr_vrf_temp
            fi
        done
        out_xr=1
        for s in $subnets; do
                sn=$(echo $s | grep $xr_vrf | sed 's/^.*__//')
                if [ "$sn" != "" ]; then
                        (( $(in_subnet $sn $xr_ip) )) && echo "The $xr_ip is part of $sn in VRF $xr_vrf" && out_xr=0
#                       (( $(in_subnet $sn $xr_ip) )) && out_xr=0\
                fi
        done
        if [ $out_xr == 1 ]; then
                echo "Remote EP $xr_ip is out of subnets in VRF $xr_vrf"
        fi
done
