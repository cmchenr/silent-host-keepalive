# Silent Host Keepalive

Some network technologies require seeing traffic from a host to learn a MAC or IP address.  In data centers, hosts may be silent and consequently learned MAC/IP's may timeout.  This script is designed to ping sweep a large number of VLANs in an environment from a single VM on a periodic basis in order to continuously see traffic from silent hosts.

# Dependencies

This script is desinged to run on CentOS/RHEL virtual machine.  That machine must have a single virtual NIC attached port-group that supports 802.1q tagging and can carry all of the VLANs that the script needs to generate traffic for.  Docker must be installed.

This script leverages the following nmap container from Docker Hub.
```
docker pull uzyexe/nmap
```

After loading the required software, the OS does not need to have an IP address attached to any interfaces, and it is recommended that all IP addresses be removed.

# Usage

Create the 2 required configuration files:

***interface.conf***: This provides the name of the base linux networking interface.
Example:
```
INTERFACE=ens33
```

***networks.conf***: This is a list of the networks that will be scanned.  It is a space delimited file with the following format.
`VLAN_TAG SUBNET DEFAULT_GATEWAY PING_SOURCE_IP_IN_SUBNET`

Example:
```
10 192.168.0.0/24 192.168.0.1 192.168.0.10
20 192.168.1.0/24 192.168.1.1 192.168.1.10
30 192.168.2.0/24 192.168.2.1 192.168.2.10
```

The script runs containers sequentially, but could be altered to run the containers in parallel by adding the "-d detached" flag to the "docker run" line.

Example:
```
docker run -d --rm \
```

After loading the script.  Execute it by changing the file permissions to make it executable and launch.
```
chmod 755 ./keepalive.sh
./keepalive.sh
```

Schedule a recurring job with cron to launch the script within the timeout window.  If ICMP isn't allowed, the NMAP arguments can be modified to connect to other TCP ports such as port 22 or 3389.

# Container Networking

This script uses Docker's "macvlan" network plugin which will create a new mac address for every container and bind it to the sub-interface.  That means that ever time the script is run, the static IP assigned to the container for a specific VLAN will be created with a new MAC address.  This shouldn't be an issue as this script is designed to run periodically and infrequently.  Docker has an alternative network plugin called "ipvlan" but it is only available when running Docker in "experimental" mode (at the time of publishing).  The "ipvlan" plugin will make it so that every time a container is spun up in a specific VLAN, it inherits the MAC address of the OS interface.  Since this script leverages statically assigned IPs, that means every time it is run, the same MAC/IP combinations will be created.  While "macvlan" is generally recommended when using Docker, "ipvlan" may be more appropriate for this use case.  Since it is an experimental feature, though, it is not used.