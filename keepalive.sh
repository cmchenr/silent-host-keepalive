#/bin/bash
#Copyright (c) 2018 Cisco and/or its affiliates.
#This software is licensed to you under the terms of the Cisco Sample
#Code License, Version 1.0 (the "License"). You may obtain a copy of the
#License at
#               https://developer.cisco.com/docs/licenses
#All use of the material herein must be in accordance with the terms of
#the License. All rights not expressly granted by the License are
#reserved. Unless required by applicable law or agreed to separately in
#writing, software distributed under the License is distributed on an "AS
#IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
#or implied.

#__author__ = "Chris McHenry"
#__copyright__ = "Copyright (c) 2019 Cisco and/or its affiliates."
#__license__ = "Cisco Sample Code License, Version 1.0"

source interface.conf
echo $INTERFACE
while read -r vlan subnet gateway address; do
    #Create VLAN sub-interface
	ip link add link $INTERFACE name $INTERFACE.$vlan type vlan id $vlan
	ip link set dev $INTERFACE.$vlan up
    #Create Docker Network interface attached to the VLAN subinterface
    docker network rm vlan$vlan
	docker network create -d macvlan \
    --subnet=$subnet \
    --gateway=$gateway \
    -o parent=$INTERFACE.$vlan vlan$vlan
    # Run Docker NMAP container to ping sweep local subnet from the VLAN subinterface
	docker run --rm \
    --net=vlan$vlan \
    --ip=$address \
    --name ping-sweep-vlan$vlan \
    uzyexe/nmap -sP $subnet
done < networks.conf
