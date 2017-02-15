#!/usr/bin/env bash

#MAC address of rotating IP's interface:
#MAC=12:e4:7c:ab:99:52

case $1 in
    'start' )
        SCHEDULE='*/10 * * * *' # every 10 minutes
        (crontab -l 2> /dev/null; echo "$SCHEDULE $(pwd)/$(basename $0)") | crontab - ;;
    'stop' )
        crontab -l | grep -v $(basename $0) | crontab - ;;
    *)  
        if [[ -z $MAC ]]
            then
                OLD_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
            else
                OLD_IP=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/$MAC/public-ipv4s)
        fi
        read NPublicIp NDomain NAllocationID <<<$(aws ec2 allocate-address --domain vpc|jq ".[]" -r)
        read OAllocationID NetworkInterfaceId OAssociationId <<<$(aws ec2 describe-addresses --public-ips $OLD_IP|jq ".[][]|.AllocationId, .NetworkInterfaceId, .AssociationId" -r)
        echo ''
        echo "Old IP: $OLD_IP"
        echo "New IP: $NPublicIp"
        echo ''
        echo 'Disassociating old IP...'
        aws ec2 disassociate-address --association-id $OAssociationId
        echo 'Associating new IP...'
        aws ec2 associate-address --allocation-id $NAllocationID  --network-interface-id $NetworkInterfaceId
        echo 'Releasing old IP...'
        aws ec2 release-address --allocation-id $OAllocationID
esac
