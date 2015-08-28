see also [VMwareHome](VMwareHome.md)



# Setup #

## network bridge ##

**note - network bridge(this section instruction) only utilized for vmware player and server, not vmware ESXi**

[original documentation](http://code.google.com/p/xenia/wiki/XeniaUpdates#Additional_server_notes_-_static_IP,_network_bridge,_iptables)

Wanted to bridge the 'virtual' vmware player server across the 'host' server.  Established my static IP on the host using the following steps.

For the 'virtual' server on the vmplayer menu at screen top, changed the 'Devices->Network Adapter' setting to 'Bridged' which establishes network communication between the virtual server and host.

You may also need to set the radio button 'wired network' from the top menu icon(circled in red) in the following image

<img src='http://xenia.googlecode.com/files/screen_1.jpg' height='300' width='600'>

<h2>static ip</h2>

<b>required section for proper IP address bridging</b>

The <code>ifconfig</code> command will tell you which ethernet device the server is trying to communicate on(<code>ifconfig -a</code> will show all available devices).  For mine the host server was running 'eth0' and the virtual was running 'eth5'<br>
<br>
from <a href='http://forums.techarena.in/operating-systems/1106661.htm'>http://forums.techarena.in/operating-systems/1106661.htm</a>

for the host the static IP is 129.252.37.90<br>
<br>
In host file /etc/network/interfaces<br>
<pre><code>auto lo<br>
iface lo inet loopback<br>
<br>
auto eth0<br>
iface eth0 inet static<br>
address 129.252.37.90<br>
netmask 255.255.255.0<br>
gateway 192.252.37.1<br>
</code></pre>

Then restart network with<br>
<pre><code>sudo /etc/init.d/networking restart<br>
</code></pre>

Running 'ifconfig' command from virtual host listed ethernet as 'eth5' which is substituted for the 'eth0' and run in the same steps listed above for configuring the static IP for the host except now on the virtual server.<br>
<br>
I did not have to modify the defaulted dns file settings for host or virtual server files under /etc/resolv.conf<br>
<br>
<hr />

<h2>iptables</h2>

<b>optional section - this section on iptables is informational and can be skipped</b>

With the network 'bridge' setting in the vmware player, any ports on the virtual server are bridged over the host server (use 'nmap' command to see open ports).  So with the gisvm image opened on the vmplayer I was able to see the apache web server sample webpage running on port 80 and J2EE/tomcat server sample webpage running on port 8080 from other machines.<br>
<br>
Currently only have port 80 open to machines outside the university network and wanted to show the geoserver demo applications running on port 8080 so used the following iptables commands (on the virtual server) to port forward 80 to 8080.<br>
<br>
from <a href='http://www.klawitter.de/tomcat80.html'>http://www.klawitter.de/tomcat80.html</a>
<pre><code>iptables -t nat -A OUTPUT -d localhost -p tcp --dport 80 -j REDIRECT --to-ports 8080<br>
iptables -t nat -A OUTPUT -d 129.252.37.90 -p tcp --dport 80 -j REDIRECT --to-ports 8080<br>
iptables -t nat -A PREROUTING -d 129.252.37.90 -p tcp --dport 80 -j REDIRECT --to-ports 8080<br>
</code></pre>

<h2>openssh</h2>

<b>required section if ssh access from other networks/IP's is needed</b>

The initial image runs an openssh daemon which accepts no outside connects via the /etc/hosts.allow file below.  Modify the hosts.allow,hosts.deny files as necessary for access/security purposes.<br>
<br>
file /etc/hosts.allow<br>
<pre><code>#uncomment below line and add substitute your http ip below for ssh access<br>
#sshd : xxx.xxx.xxx.xxx : allow<br>
sshd : ALL : deny<br>
</code></pre>

<h2>image default users, passwords</h2>

<b>required section for security purposes</b>

#reset user passwds to public defaults - user,root,xeniaprod,postgres - as root, passwd <br>
<br>
<username><br>
<br>
<br>
<br>
The <b>root</b> user has password <b>root99</b>.  Modify this password as needed.<br>
<br>
The <b>postgres</b> user has password <b>postgres99</b>.  Modify this password as needed.<br>
<br>
The username associated with the xenia development is <b>xeniaprod</b> with password <b>xeniaprod99</b>  Modify this password as needed.<br>
<br>
The username <b>user</b> has password <b>user99</b> although this user account is not utilized.  Modify this password as needed.<br>
<br>
Both users <b>xeniaprod</b> and <b>user</b> are part of the <b>admin</b> group (<code>sudo vi /etc/group</code>) which is a 'sudo' (<code>sudo vi /etc/sudoers</code>) enabled group.<br>
<br>
<b>optional</b> see the other gisvm related passwords <a href='http://www.vmware.com/appliances/directory/55606'>here</a> and modify as needed.<br>
<br>
<h2>host substitutions, configuration</h2>

<b>Required section for configuring image to use local IP,system/database passwords and understanding data flow</b>

<i>By default as a test, on initial image startup this image will begin trying to hourly access over the web a few kmz files(usgs,nerrs,ndbc) for aggregation to the xenia database and production of several output formats and services.  Check 'flow<b>' output graphs(.png) under <a href='http://localhost/xenia/feeds'>http://localhost/xenia/feeds</a> or <a href='http://xxx.xxx.xxx.xxx/xenia/feeds'>http://xxx.xxx.xxx.xxx/xenia/feeds</a> after a few hours to verify feed processing/population.</b></i>

If you plan to run a production xenia vmware instance accessible by others on the web, search the xeniaprod code from the following directory to see the necessary localhost substitutions(for your production machine http address) or other configuration options.<br>
<br>
see also <a href='http://code.google.com/p/xenia/wiki/VMwareDesign#Checklist'>http://code.google.com/p/xenia/wiki/VMwareDesign#Checklist</a> , <a href='http://code.google.com/p/xenia/wiki/VMwareDesign##VM_CONFIG_notes'>http://code.google.com/p/xenia/wiki/VMwareDesign##VM_CONFIG_notes</a>

replace <b>your_ip</b> in the below line commands with your IP (xxx.xxx.xxx.xxx)<br>
<pre><code>cd /home/xeniaprod<br>
find . -name "*" -exec grep -H "VM_CONFIG" {} \; <br>
perl -p -i -e 's/129.252.37.90/your_ip/g' `find ./ -name "*.pl"`<br>
perl -p -i -e 's/129.252.37.90/your_ip/g' `find ./ -name "*.html"`<br>
perl -p -i -e 's/129.252.37.90/your_ip/g' `find ./ -name "*.xml"`<br>
</code></pre>

<pre><code>search for #VM_CONFIG in effected files<br>
<br>
/etc/hosts.allow  #ssh ip access<br>
/etc/exports #nfs remote mount access<br>
<br>
=<br>
#postgres<br>
optional - database size on /usr2, delete old records - vacuum<br>
<br>
user passwds - postgres,xeniaprod<br>
psql -U postgres -h xxx.xxx.xxx.xxx<br>
alter user postgres with password 'xxx';<br>
alter user xeniaprod with password 'xxx';<br>
<br>
#enable #VM_CONFIG ip addresses<br>
sudo vi /usr2/pg_data/pg_hba.conf<br>
<br>
cd /home/xeniaprod/config #database user/password<br>
  dbConfig.ini<br>
  environment_xenia_default.xml<br>
<br>
#enable feeds as needed<br>
/home/xeniaprod/cron/getObskml.sh<br>
/home/xeniaprod/cron/mk_xenia_all_latest.sh<br>
<br>
search for #VM_CONFIG in effected crons (as user 'xeniaprod', crontab -e)<br>
#start crons - root, xeniaprod<br>
<br>
check output graphs(.png) under http://xxx.xxx.xxx.xxx/xenia/feeds after a few hours to verify feed processing/population<br>
<br>
</code></pre>

<h2>postgresql or sqlite</h2>

<b>optional section - this section can be skipped if default postgresql database is acceptable</b>

The latest version of the vmware image is configured to utilize a postgresql/postgis relational database while the earlier version utilized a sqlite file-based relational database.<br>
<br>
These changes are reflected in the xeniaprod crontab with xeniaflow_postgresql.sh directing the aggregation and product generation towards the /home/xeniaprod/scripts/postgresql branch instead of the /home/xeniaprod/scripts/sqlite one.<br>
<br>
Similarly the symbolic links(time_series, sos) under /var/www/xenia are linked to postgresql branch instead of sqlite one.<br>
<br>
<h2>miscellaneous</h2>

<b>informational section</b>

<b>sudo</b> all commands that need root access.<br>
<br>
To sudo between users, use the first user password(user99 in the below example) not the target user password<br>
<pre><code>user@gisvm:~$ sudo su - xeniaprod<br>
[sudo] password for user:<br>
xeniaprod@gisvm:~$ <br>
</code></pre>

The <b>two crontabs</b> which are active are <b>root</b> which performs a nightly cleanup of files under directory /home/xeniaprod/tmp_web and <b>xeniaprod</b> which also performs file cleanup but more importantly runs the following main job hourly.<br>
<br>
The file <b>/home/xeniaprod/cron/xeniaflow.sh</b> creates all the subsequent related products and should be referenced to understand the product creation flow.<br>
<br>
Xenia related log files are at /home/xeniaprod/tmp and cleared nightly.<br>
<br>
Apache user(www-data) created related temporary files are at /home/xeniaprod/tmp_web and cleared nightly.<br>
<br>
<h2>ObsKML</h2>

<b>optional section</b>

If you are ready to start pulling new data into your system, see<br>
<a href='http://code.google.com/p/xenia/wiki/VMwareTest#Adding_a_new_ObsKML_feed'>http://code.google.com/p/xenia/wiki/VMwareTest#Adding_a_new_ObsKML_feed</a>

<hr />
<h1>VMware Server</h1>

Successfully installed VMware Server 2.0.1 on Ubuntu 8.10<br>
<br>
The vmware server is installed via the vmware-install.pl script and starts the services at the end of a successful install.  The vmware server maintenance ui is accessed via browser at <a href='http://localhost:8222'>http://localhost:8222</a> or secure port <a href='https://localhost:8333'>https://localhost:8333</a>

If accessing the terminal console from a remote desktop via the vmware browser interface, you'll need a browser plug-in - the only one of which I found that worked was for Firefox.  See this related <a href='http://www.google.com/support/forum/p/Chrome/thread?tid=1e2eceea54682f11&hl=en'>link</a> regarding the plug-in also.  The console may open to a black screen and you may need to gain window focus and press a key to see the display.<br>
<br>
All connections are 'bridged',  see <a href='http://communities.vmware.com/thread/89314'>NAT versus Bridged</a>  Note also that you can modify the 'Configuration' settings directly by modifying the .vmx file and rebooting the image.<br>
<br>
<h2>Problems, workarounds</h2>

Had a compile error on 'vmsock' but the install said this was not critical to the usual processes.  Not having it compiled does not seem to create any noticeable issue.<br>
<br>
One problem I ran into was that VMware server configured vmnet0 (only shows up in the process list 'ps -auxf' not via 'ifconfig' command) to eth0 and eth0 was not bridging ('x' symbol in the server maintenance ui).  Switched vmnet0 over to eth1 via the <code>/usr/bin/vmware-config.pl</code> script which did bridge correctly.<br>
<br>
<hr />

root@nwstwo:/usr/local/download/vmware-server-distrib/bin# vmware-config.pl<br>
<br>
#accept default until...<br>
<pre><code>The following virtual networks have been defined:<br>
<br>
. vmnet0 is bridged to eth0<br>
<br>
Do you wish to make any changes to the current virtual networks settings? <br>
(yes/no) [no] yes<br>
<br>
Which virtual network do you wish to configure? (0-254) 0<br>
<br>
The network vmnet0 has been reserved for a bridged network.  You may change it,<br>
but it is highly recommended that you use it as a bridged network.  Are you <br>
sure you want to modify it? (yes/no) [no] yes<br>
<br>
What type of virtual network do you wish to set vmnet0? <br>
(bridged,hostonly,nat,none) [bridged] <br>
<br>
Configuring a bridged network for vmnet0.<br>
<br>
Please specify a name for this network. <br>
[Bridged] <br>
<br>
Your computer has multiple ethernet network interfaces available: eth1, eth0. <br>
Which one do you want to bridge to vmnet0? [eth0] eth1<br>
<br>
The following virtual networks have been defined:<br>
<br>
. vmnet0 is bridged to eth1<br>
<br>
Do you wish to make additional changes to the current virtual networks <br>
settings? (yes/no) [yes] no<br>
</code></pre>
...<br>
accept defaults<br>
<br>
<hr />
from <a href='http://communities.vmware.com/thread/113990'>http://communities.vmware.com/thread/113990</a>

There's no vmnet0 device.<br>
To check if eth0 is bridged to vmnet0 check the output of <br />
<code>ps ax | grep bridge</code>

it should be similar to <br />
<code>3175 ?        S      0:00 /usr/bin/vmnet-bridge -d /var/run/vmnet-bridge-0.pid /dev/vmnet0 eth0</code>
<hr />
also ran into the following error/fix when trying to restart the network<br>
<br>
<code>SIOCADDRT: File exists</code>

from <a href='http://techandit.com/?p=145'>http://techandit.com/?p=145</a>

<pre><code>A common tactic used to clone a system running under VMWare, is to simply shut down the virtual server, make a copy of the files that form the virtual server, and register the copy with VMWare and boot the server, without networking and reconfigure the network interfaces.<br>
However when I clone Ubuntu 7.10 systems, I always find that the network interface doesn’t exist on the cloned machine. The fix for this problem is to delete the file /etc/udev/rules.d/70-persistent-net.rules , which is responsible for mapping network device names to physical (or virtual in this case) network devices. You then need to reboot the system to allow the change to take effect. Restarting the network service isn’t enough.<br>
I’ve also had some strange problems after trying to add persistent routes to the file /etc/network/interfaces on virtual guests, which would generate the error SIOCADDRT: File exists. Deleting the above file and restarting the system also resolves this issue.<br>
</code></pre>
<hr />

Per each virtual image instance/IP address as configured in the file /etc/network/interfaces, make sure to set your ethx (eth7,eth8,etc)  connection correctly the same as found in the 'ifconfig' listing  setting and restart via <code>/etc/init.d/networking restart</code>  See earlier notes <a href='http://code.google.com/p/xenia/wiki/VMwareInstall#static_ip'>here</a>  The correct image IP listing should also show up in the vmware server maintenance ui.  Also you may need to run your host on a separate IP than your vmware instances so there is not competition for the IP address resolution.<br>
<br>
vmware images can be referenced on the host machine vmware ui by placing or symbolically linking via the /var/lib/vmware/Virtual Machines folder<br>
<br>
Saw some notes regarding ethernet optimization/mishandling issues such as to run the command <code>ethtool -K eth1 sg off rx off tx off tso off</code> but did not utilize this command.<br>
<hr />
<h1>VMware ESXi</h1>

Dan Ramage pointed me to the following article<br>
<a href='http://bsd.slashdot.org/story/09/06/02/0043258/When-VMware-Performanc'>http://bsd.slashdot.org/story/09/06/02/0043258/When-VMware-Performanc</a>...<br>
which<br>
points out a variety of opinions comparing various virtualization issues -<br>
one point that is highlighted by the opinions is the use in regards to<br>
vmware products of the free 'ESXi' product instead of 'vmware server', the<br>
main difference being that 'ESXi' runs directly on the server(bare-metal)<br>
and does not suffer some of the performance penalties associated with<br>
running on a host OS(Operating System).  I'll try the 'ESXi' install at some<br>
point and glad to hear any feedback in regards to running 'ESXi' instead of<br>
'vmware server' in regards to server virtualization.<br>
<br>
<h2>ESXi links</h2>

<h3>Install and configure</h3>

Note that we use Dell Poweredge servers which required us to in the physical server BIOS to enable 'virtualization technology' or VT shown at the following link, we don't have/use the vMotion feature so we don't enable 'execute disable'  Your server may have similar virtualization support setting which require enabling<br>
<a href='http://www.vmwareinfo.com/2009/02/enable-vt-and-evc-in-dell-bios.html'>http://www.vmwareinfo.com/2009/02/enable-vt-and-evc-in-dell-bios.html</a>

<a href='http://www.virtualizationadmin.com/articles-tutorials/vmware-esx-articles/installation-and-deployment/10-steps-install-use-free-vmware-esxi-4.html'>http://www.virtualizationadmin.com/articles-tutorials/vmware-esx-articles/installation-and-deployment/10-steps-install-use-free-vmware-esxi-4.html</a>

<a href='http://www.virtualizationadmin.com/articles-tutorials/vmware-esx-articles/installation-and-deployment/new-vmware-esxi-server-configuration-checklist.html'>http://www.virtualizationadmin.com/articles-tutorials/vmware-esx-articles/installation-and-deployment/new-vmware-esxi-server-configuration-checklist.html</a>

Review <a href='http://windowsitpro.com/article/articleid/101039/vmware-esxi.html'>http://windowsitpro.com/article/articleid/101039/vmware-esxi.html</a> <br />

vmware resource contention(cpu,memory,etc) handling (found under image Edit Settings->Resources tab) <a href='http://vmzare.wordpress.com/2007/02/27/sharesreservationlimits-cpumemory-resource-settings'>http://vmzare.wordpress.com/2007/02/27/sharesreservationlimits-cpumemory-resource-settings</a>

<h2>VMTools - Disk, I/O optimization</h2>
Provides performance improvements for disk, I/O intensive workloads.<br />
<hr />
from <a href='http://communities.vmware.com/thread/212322'>http://communities.vmware.com/thread/212322</a>

Tools will only help I/O performance (besides generally making things like graphics and time synchronization work better). If your VM has no significant networking or storage requirements, then you probably don't need tools. I usually don't bother.<br>
<br>
If you want very good networking performance without tools, do make sure you are using e1000 virtual device. You can set ethernet0.virtualDev="e1000". This is not quite as good as real vmxnet (or new vmxnet3) but is a lot better than the default vlance. If you are regularly pushing 1Gbit or more actual traffic to your VMs, I would consider doing this.<br>
Paravirtualized SCSI is fairly new, but from benchmarks I've seen it gives a fairly significant performance boost. But again, most probably you do not need it, unless you are running a very disk I/O heavy VM, such as an Oracle database server.<br>
If you are consolidating underutilized physical machines which don't ever use 100% CPU/Network/Disk, then tools are probably a waste of time. But if you want as close as possible to native performance and CPU usage during intensive I/O, then tools are worth it.<br>
<hr />
<h2>Memory(MMU) optimization</h2>

AMD RVI(Rapid Virtualization Indexing) <br />
Intel EPT (Extended Page Tables)<br>
<br>
<hr />
from <a href='http://www.boche.net/blog/index.php/tag/esxi/page/2/'>http://www.boche.net/blog/index.php/tag/esxi/page/2/</a>

I’m mildly excited for the upcoming week. If all goes well, I’ll be upgrading to AMD Opteron processors which support a virtualization assist technology called Rapid Virtualization Indexing (or RVI for short).<br>
<br>
There is overhead introduced in VMware virtualization via the virtual machine monitor (VMM) and comes in three forms:<br>
<ul><li>Virtualization of the CPU (using software based binary translation or BT for short)<br>
</li><li>Virtualization of the MMU (using software based shadow paging)<br>
</li><li>Virtualization of the I/O devices (using software based device emulation)<br>
RVI is found in AMD’s second generation of virtualization hardware support and it incorporates MMU (Memory Management Unit) virtualization. This new technology is designed to eliminate traditional software based shadow paging methods for MMU virtualization thereby reducing the overhead in bullet #2 above. VMware lab tests show that RVI provides performance gains of up to 42% for MMU-intensive benchmarks and up to 500% for MMU-intensive microbenchmarks.</li></ul>

How it works:<br>
<br>
Software based shadow page tables store information about the guest VM’s physical memory location on the host. The VMM had to intercept guest VM page table updates to keep guest page tables and shadow page tables in sync. By now you can probably see where this is going: applications and VMs which had frequent guest page table updates were not as efficient as those with less frequent guest page table updates.<br>
<br>
The above is similar to guest VM kernel mode calls/context switching to access CPU ring 0. Previously, the architecture wouldn’t allow it directly via the hardware so the VMKernel had to intercept these calls and hand-hold each and every ring 0 transaction. Throw 10,000+ ring 0 system calls at the VMKernel per second and the experience starts to become noticeably slower. Both Intel and AMD resolved this issue specifically for virtualized platforms by introducing a ring -1 (a pseudo ring 0) which guest VMs will be able to access directly.<br>
<br>
VMware introduced support for RVI in ESX 3.5.0. RVI eliminates MMU related overhead in the VMM by relying on the technology built into the newer RVI capable processors to determine the physical location of guest memory by walking an extra level of page tables maintained by the VMM. RVI is AMD’s nested page table technology. The Intel version of the technology is called Extended Page Tables (EPT) and is expected sometime this year.<br>
One of the applications of RVI that interests me directly is Citrix XenApp (Presentation Server). XenApp receives a direct performance benefit from RVI because it is an MMU-intensive workload. VMware’s conclusion in lab testing was that XenApp performance increased by approximately 29% using RVI. By way of the performance increase, we can increase the number of concurrent users on each virtualized XenApp box. There are two wins here: We increase our consolidation ratios on XenApp and we reduce the aggregate number of XenApp boxes we have to manage due to more densely populated XenApp servers. This is great stuff!<br>
<br>
There is a caveat. VMware observed some memory access latency increases for a few workloads, however, they tell us there is a workaround. Use large pages in the guest and the hypervisor to reduce the stress on the Translation Lookaside Buffer (TLB). VMware recommends that TLB-intensive workloads make extensive use of large pages to mitigate the higher cost of a TLB miss. For optimal performance, the ESX VMM and VMKernel aggressively try to use large pages for their own memory when RVI is used.<br>
<br>
For more information and deeper technical jibber jabber, please see VMware’s white paper Performance of Rapid Virtualization Indexing (RVI). Something to note is that all testing was performed on ESX 3.5.0 Update 2 with 64 bit guest VMs. I give credit to this document for the information provided in this blog post, including two directly quoted sentences.<br>
<br>
For some more good reading, take a look at Duncan Epping’s experience with a customer last week involving MMU, RVI, and memory over commit.<br>
<hr />
<h2>Update June 19 2009</h2>
Went through the VMware ESXi install process on one of the new Secoora<br>
servers(Dell Poweredge 2950) here this week - it was very easy and<br>
straightforward.<br>
<br>
ESXi is the recommended freeware 'bare metal' server install for the vmware<br>
virtualization stuff.  <b>vSphere</b> is the related separate remote desktop<br>
client(freeware download also from the same ESXi download page) for managing the ESXi instance.  ESXi does not provide a management console <b>directly on the server</b> which means that you have to install/utilize <b>vSphere</b> to connect to and manage it.<br>
<br>
Should have a vmware image for analysis, redundancy/sharing that captures<br>
most of the earlier aggregation and products scripts developed earlier for<br>
Secoora <a href='http://code.google.com/p/xenia/wiki/VMwareProducts'>http://code.google.com/p/xenia/wiki/VMwareProducts</a> and moving<br>
forward, still need possible redevelopment in regards to the earlier<br>
'screen-scraping' moved to web-services(sara and vembu's scripts) and<br>
Jesse's latest hourly maps as provided via the more recent database schema.<br>
Also have refocused the scripts back towards a Postgresql database initial<br>
use focus(due to multi-user/developer needs in-house between Dan and myself<br>
and the popularity of Xenia/postgresql within the IOOS community) and Sqlite<br>
more as a optional secondary or file archive purpose.<br>
<br>
It was the ESXi 4.0 instance(64-bit) - after signing up with a vmware user<br>
account it will send you an email activation link with the license code.  The license code can be entered via the VSphere managment interface immediately or at the end of the 60 day evaluation (the full ESXi product I believe).<br>
<br>
The only snafus I ran into was installing ESXi to 'Disk1' controller first,<br>
the machine only wanted to boot off of 'Disk0' so reran with Disk0 as the<br>
option.<br>
<br>
Also had to work through getting the usual static IP, DNS issues<br>
and remote port access from my desktop subnet to the ESXi server IP.  Be sure to get your netmask and default gateway settings correct in the ESXi interface - I set my netmask to 255.255.0.0 so that I could manage the server(at 129.252.37.x) from a different subnet(129.252.139.x).<br>
<br>
Also be aware of the need to download/install the <b>vCenter converter</b> (VMware vCenter Converter Standalone 4.0.1 <a href='http://www.vmware.com/download/converter/'>http://www.vmware.com/download/converter/</a> ) I downloaded/installed to my windows desktop and convert my earlier vmware server image to an ESXi image (the converter application supports a variety of other conversions as well).<br>
<br>
When moving my earlier vmware image to my desktop I did run into a 2 gigabyte file size limitation with a samba mount(smbfs), which was addressed by mounting as 'cifs' instead which does not have the file size limitation<br>
<br>
#2 GB file size limit for smbfs (use cifs) <br />
<code>mount -t cifs -o username=xxx,password=xxx,workgroup=xxx //xxx.xxx.xxx.xxx/temp /temp</code>

After migrating/converting and powering on the vmware image, I had to assign the correct IP as detailed earlier <a href='http://code.google.com/p/xenia/wiki/VMwareInstall#static_ip'>here</a>   The vSphere application provides a variety of system metrics and a terminal/display console link for each vmware instance.<br>
<br>
<h2>vCenter, vSphere image transfer/startup instructions</h2>

If the downloaded vmware <a href='VMwareDownload.md'>VMwareDownload</a> .vmdk file size is correct(4236256768 bytes), the next step is to get the image onto ESXi via the vCenter desktop tool.<br>
<br>
vCenter converter - VMware vCenter Converter Standalone 4.0.1 <a href='http://www.vmware.com/download/converter/'>http://www.vmware.com/download/converter/</a>

Start the <b>vCenter</b> application (which can also be used to convert a variety of vmware products or existing windows/linux servers into vmware images)<br>
<br>
Click 'Convert Machine' button towards top of window menu<br>
<br>
<hr />
On the '<b>Specify Source</b>' tab window,<br>
<br>
'Select source type' : choose the last option 'Virtual appliance'<br>
'Location':'File System'<br>
and 'Browse' to the folder which contains both the .ovf file and .vmdk file (xeniavm20090713.ovf, xeniavm20090713.vmdk)<br>
<br>
click 'Next' button, and 'Next' again through 'Appliance details' window<br>
<br>
<hr />
On the '<b>Specify Destination</b>' tab window<br>
<br>
'Select destination type':'VMware Infrastructure virtual machine'<br>
and then choose the IP address, root login/password for the ESXi server<br>
<br>
click 'Next' button, and 'Next' again through 'Host/Resource' window(note that the image will be transferred to one of the available 'datastore's which are the ESXi servers hard drive(s).<br>
<br>
<hr />
On the '<b>View/Edit Options</b>' tab window<br>
<br>
click 'Next' but note that the processor, memory and disk options can be edited here - I'm currently still using the default '1 processor, 512 MB memory' setup although it would probably be worth experimenting with '2 processor' and larger memory,etc to see if any large improvements in the image performance.<br>
<br>
<hr />
On the '<b>Ready to Complete</b>' tab window<br>
<br>
click 'Finish' and the image transfer process begins and should take about an hour or less(progress meter is shown in vCenter application).<br>
<br>
After the transfer is complete,<br>
<br>
From the <b>vSphere</b> application, you should be able to see the new vmware image available under the server inventory list in the left-hand column drop-down.<br>
<br>
If you would like to <b>configure or need to reconfigure your image to match the host server hardware (CPU,memory,disk,network,etc)</b>, you can right-click on the image name and choose '<b>Edit Settings</b>' to change these settings to that of the host server.  You can also specify image <a href='http://vmzare.wordpress.com/2007/02/27/sharesreservationlimits-cpumemory-resource-settings'>minimum or preferred allocations</a> of CPU,memory,etc under the EditSettings->Resources tab.  The image must be in a powered off state to make these edits.<br>
<br>
If you are ready to power on(start) your image, right-click on the 'xeniavm20090713' image and 'power on'(the play symbol in the menu) the image.  Click the 'Summary' tab in the right-side pane after the image is powered on and choose the 'Open Console' option under the 'Commands' section to bring up a terminal session.  You should be able to login to the server as user 'xeniaprod' with password 'xeniaprod99'.<br>
<br>
The finishing configuration part is detailed at <a href='http://code.google.com/p/xenia/wiki/VMwareInstall#static_ip'>http://code.google.com/p/xenia/wiki/VMwareInstall#static_ip</a> (skip the sections about 'ip tables' and 'postgresql or sqlite') through the 'miscellaneous' section.<br>
<br>
After that let the server run for a day and see that you're getting data and its generating the variety of formats/services detailed at <a href='http://code.google.com/p/xenia/wiki/VMwareProducts'>http://code.google.com/p/xenia/wiki/VMwareProducts</a>

<h2>Entering vmware license key</h2>

To enter your ESXi license key (shown on the earlier vmware download page when logged into the vmware website with your vmware account)<br>
<br>
from the vSphere application:<br>
<br>
from <a href='http://communities.vmware.com/thread/220594;jsessionid=11B1C53FDBB3284777221D14AD00D6D9?tstart=0'>http://communities.vmware.com/thread/220594;jsessionid=11B1C53FDBB3284777221D14AD00D6D9?tstart=0</a>

In order to enter the serial number in your ESX4i host<br>
<br>
<pre><code>Home -&gt; Inventory -&gt; top level (your ESXi Host)<br>
Configuration Tab<br>
Left-hand side - Licensed features<br>
Edit -&gt; Assign new key to this host -&gt; Enter Key<br>
Paste your key<br>
Confirm all the rest <br>
Your ESXi Server is now fully licensed<br>
</code></pre>

Please note - you will only have the basic functionality and all the enterprise features that came with the Evaluation License are no longer valid<br>
<br>
<h2>Kernel panic</h2>

Had a development image give a kernel panic, resulting in the image not rebooting.  Trying to use knoppix boot CD to diagnose/remedy the image which is failing to boot<br>
<br>
To CD boot a knoppix or other .iso image, power off the image and under the image 'Edit Settings->Options->Boot options' tab, you can force the system BIOS to be displayed on the next boot which will allow you to configure the CD as the first option boot device and then set the start-up delay to around 20 seconds(20,000 milliseconds) to allow yourself time to connect the CD device to your desktop local .iso file copy from vSphere after powering the image back on.  The image should .iso boot off your local desktop .iso copy.<br>
<br>
It's also possible to move .iso images to vmware datastores using some third-party freeware(Veeam RootAccess, FastSCP) listed in the following link <a href='http://communities.vmware.com/message/664149#664149'>http://communities.vmware.com/message/664149#664149</a>

<h2>Amazon Web Services</h2>

Interested in converting from a vmware .vmdk server image to an amazon machine image(AMI) for running our setup on <a href='http://aws.amazon.com/'>amazon web services</a>

Initial ideas from <a href='http://thewebfellas.com/blog/2008/9/1/creating-an-new-ec2-ami-from-within-vmware-or-from-vmdk-files'>http://thewebfellas.com/blog/2008/9/1/creating-an-new-ec2-ami-from-within-vmware-or-from-vmdk-files</a> , but believe skipping qemu image conversion step based on comment section and notice that some options like --no-inherit,etc listed in the article no longer seem to be available.  Comments section also lists problem with UUID and kernel panic with no answers.<br>
<br>
<hr />
<a href='http://docs.amazonwebservices.com/AWSEC2/latest/CommandLineReference/index.html?ami-tools.html'>ec2 ami command-line tools</a> <br />
mainly interested in ec2-bundle-image for converting/uploading vmware image <br />
see <a href='http://developer.amazonwebservices.com/connect/entry.jspa?externalID=368&categoryID=88'>http://developer.amazonwebservices.com/connect/entry.jspa?externalID=368&amp;categoryID=88</a> <br />
download linux/unix command-line tools <a href='http://s3.amazonaws.com/ec2-downloads/ec2-ami-tools.zip'>zip file</a> to /home/xeniaprod/temp/ec2-ami-tools-1.3-34544<br>
<br>
installed packages(ruby,curl) to support command tools<br>
<pre><code>#see http://developer.amazonwebservices.com/connect/message.jspa?messageID=76635<br>
sudo apt-get install libruby1.8-extras<br>
<br>
#curl for image upload<br>
sudo apt-get install curl<br>
</code></pre>
<hr />

To generate pk-... and cert-... keys <br />
Goto <a href='http://aws.amazon.com/'>aws home</a>,your account->security credentials, x509, create new certificate<br>
<br>
#make sure enough space on target directory <br />
command splits given image into 10 MB partition files<br>
<br>
<code>export EC2_HOME=/home/xeniaprod/temp/ec2-ami-tools-1.3-34544</code>

<code>./ec2-bundle-image -k pk-&lt;xxx...&gt;.pem -c cert-&lt;xxx...&gt;.pem -u &lt;xxxx-xxxx-xxxx-xxxx&gt; -i /taurus/archive/vmware/xeniavm20091029/xeniavm20091029.vmdk -d /taurus/archive/aws/xeniavm -r x86_6</code>

<code>./ec2-upload-bundle -b aws-xeniavm-bucket -m /taurus/archive/aws/xeniavm/xeniavm20091029.vmdk.manifest.xml -a &lt;access_key&gt; -s &lt;secret_key&gt;</code>

Goto AWS management console->AMIs->register new AMI<br>
#enter after register <a href='http://s3'>http://s3</a>...<br>
aws-xeniavm-bucket/xeniavm20091029.vmdk.manifest.xml<br>
<br>
Start instance and mouseover 'Public DNS' field, look at 'System Log' to see kernel panic at bottom of file(can't mount os partitions)<br>
<br>
<code>Kernel panic - not syncing: VFS: Unable to mount root fs on unknown-block(8,1)</code>

<a href='http://developer.amazonwebservices.com/connect/thread.jspa?messageID=152282&#152282'>http://developer.amazonwebservices.com/connect/thread.jspa?messageID=152282&amp;#152282</a>

<i>I'm trying to convert a .vmdk file to ec2 ami and also running into issues with a kernel panic from not being able to map to devices. The .vmdk fstab file references UUID names for root and swap partitions which I've tried substituting into the block-device-mapping paramter for ec2-bundle-image, but the AMI register step does not recognize UUID as a valid device name.</i>

tried adding below parameter to ec2-bundle-image, but UUID not valid device name<br>
<code> --block-device-mapping ami=UUID=f5c2a44e-2919-4533-94a3-b40a1b4edaa1,root=UUID=f5c2a44e-2919-4533-94a3-b40a1b4edaa1,swap=UUID=9662f62e-1074-46c9-bdf5-68ba4d8971e3</code>

existing fstab for ubuntu OS on vmware<br>
<pre><code>root@gisvm:/home/xeniaprod/temp/ec2-ami-tools-1.3-34544/bin# vi /etc/fstab<br>
# /etc/fstab: static file system information.<br>
#<br>
# &lt;file system&gt; &lt;mount point&gt;   &lt;type&gt;  &lt;options&gt;       &lt;dump&gt;  &lt;pass&gt;<br>
proc            /proc           proc    defaults        0       0<br>
# /dev/sda1<br>
UUID=f5c2a44e-2919-4533-94a3-b40a1b4edaa1 /               ext3    relatime,errors=remount-ro 0       1<br>
# /dev/sda5<br>
UUID=9662f62e-1074-46c9-bdf5-68ba4d8971e3 none            swap    sw              0       0<br>
/dev/scd0       /media/cdrom0   udf,iso9660 user,noauto,exec,utf8 0       0<br>
/dev/fd0        /media/floppy0  auto    rw,user,noauto,exec,utf8 0       0<br>
# Beginning of the block added by the VMware software<br>
.host:/                 /mnt/hgfs               vmhgfs  defaults,ttl=5     0 0<br>
# End of the block added by the VMware software<br>
</code></pre>

Also tried converting the following simpler redhat 6.2 vmdk to ami<br>
<a href='http://www.vmware.com/appliances/directory/490'>http://www.vmware.com/appliances/directory/490</a> but couldn't get a System Log or connection.<br>
<br>
Connection notes: the 'Public DNS' should be accessible by port 80(http) and port 22(ssh) if enabled in the AMI security profile setup and used during the AMI launch.  See the directions under 'Connect' from the 'Public DNS' field right-click options - basically ssh command looks like following:<br>
<br>
<code>ssh -i &lt;xxx&gt;.pem root@&lt;amazon public DNS&gt;</code>

The .pem access key was also generated in an earlier step and <code>chmod 400</code> as suggested to make it readable during ssh access.<br>
<br>
<h2>Update 2009-11-18</h2>

I was able to generate an closer-to-working image I believe using the following command ec2-bundle-vol which takes a snapshot of the existing server system from which it is run and includes a --generate-fstab option.  The 'System log' showed a command prompt login.  Still unable to ssh into it which may be more related to how the original server ssh,dns,etc are configured.  Had to exclude the storage directory <code>-e /usr2</code> to allow the image to fit under the 10GB limit beyond which a rsync error is received when trying to create the image.<br>
<br>
<code>./ec2-bundle-vol -k pk-&lt;xxx...&gt;.pem -c cert-&lt;xxx...&gt;.pem -u &lt;xxxx-xxxx-xxxx-xxxx&gt; -d /taurus/archive/aws/xeniavm/try3 -r x86_64 --no-inherit --generate-fstab -e /usr2</code>

I believe the image is having issues with the filesystem and libraries still and probably the better route at this point is to use a working ubuntu ami and install on top of that(as painful as that is) - the following link contains 'canonical' ubuntu ec2 reference ami's as well as much other good information such as connectivity issues<br>
<br>
<a href='http://alestic.com/2009/08/ec2-connectivity'>http://alestic.com/2009/08/ec2-connectivity</a>

<h2>Update 2009-11-23</h2>

I was finally able to get a working AMI image from my converted VMware .vmdk file<br>
<br>
To fix an error that I was getting in the Amazon 'System Log' link after boot up about a missing xen module, I was able to find the missing module and other instructions of interest at<br>
<br>
<a href='http://www.philchen.com/2009/02/14/how-to-create-an-amazon-elastic-compute-cloud-ec2-machine-image-ami'>http://www.philchen.com/2009/02/14/how-to-create-an-amazon-elastic-compute-cloud-ec2-machine-image-ami</a>

The key lines was the download of the missing xen kernel library at <a href='http://www.philchen.com/wp-content/uploads/2009/05/kernel-modules2616-xenu.tgz'>http://www.philchen.com/wp-content/uploads/2009/05/kernel-modules2616-xenu.tgz</a>

which I simply unzipped/untarred and moved to my /lib/modules directory<br>
<br>
I also added following configuration lines to my sshd_config file<br>
<br>
<pre><code>UseDNS no<br>
PermitRootLogin without-password<br>
</code></pre>

and changed my network setting to dhcp in my /etc/network/interfaces file<br>
<br>
<pre><code># The loopback network interface<br>
auto lo<br>
iface lo inet loopback<br>
<br>
# The primary network interface<br>
auto eth0<br>
iface eth0 inet dhcp<br>
</code></pre>

Making the above fixes allowed me to successfully ssh into my Amazon server instance and see the default webserver page displayed via http at the Amazon published DNS for the instance.<br>
<br>
The next part of the puzzle involves Amazon's Elastic Block Storage (EBS) which essentially is a permanent data storage area for database or other generated data(logs,etc) which might need to persist in the event that the AMI needs to be re-booted.  The following two part article does an excellent job of walking through this process.<br>
<br>
<a href='http://deadprogrammersociety.blogspot.com/2009/08/postgresql-on-ubuntu-on-ec2.html'>http://deadprogrammersociety.blogspot.com/2009/08/postgresql-on-ubuntu-on-ec2.html</a>

<a href='http://deadprogrammersociety.blogspot.com/2009/10/postgresql-on-ubuntu-on-ec2-backing-it.html'>http://deadprogrammersociety.blogspot.com/2009/10/postgresql-on-ubuntu-on-ec2-backing-it.html</a>

<h2>P2V with vCenter</h2>

To allow remote root login from vCenter tool, made the following ssh change<br>
<br>
allow remote root login<br>
<pre><code>vi /etc/ssh/sshd_config<br>
<br>
#PermitRootLogin no<br>
PermitRootLogin yes<br>
<br>
/etc/init.d/sshd reload<br>
</code></pre>

<h2>Expanding storage partition</h2>

Currently /usr2 is the database storage partition.  On our host server, I expanded the /usr2 from 8 GB to 200 GB by the following steps<br>
<ul><li>in vSphere, edit the image->Edit settings->Hardware->Hard disk->Disk Provisioning to the desired total image size<br>
</li><li>use something like a gparted .iso file to reboot the image from your local desktop CD (in vSphere there is a menu option/icon to connect your local CD/DVD drive for reference by the image)<br>
</li><li>to reboot from CD change the image->Edit settings->Options->Boot Options->Force BIOS Setup to alter the boot-up sequence temporarily to run gparted,etc.<br>
</li><li>use gparted,etc to expand the /usr2 partition to the unallocated portion size</li></ul>


<h2>Additional links</h2>

<a href='http://www.slideshare.net/ajturner/scaling-mapufacture-on-amazon-web-services'>http://www.slideshare.net/ajturner/scaling-mapufacture-on-amazon-web-services</a> <br />
<a href='http://www.dedoimedo.com/computers/amazon-ec2.html'>http://www.dedoimedo.com/computers/amazon-ec2.html</a>

<h1>Virtualization - talking points</h1>

<ul><li>no silver bullets - but close<br>
</li><li>backup,versioning, sharing(server to desktop), scaling<br>
</li><li>removing time spent in setup/configuration for hardware/software<br>
</li><li>some separation between hardware and software concerns - maintaining portability between older software on newer hardware<br>
</li><li>dedicated server(spec) for known performance, bare-metal, low-cost($1-2K) servers<br>
</li><li>side benefits - separating software from storage, CPU/memory<br>
</li><li>keywords - turnkey,appliance,node,package<br>
<ul><li>application/appliance types/profiles<br>
</li></ul></li><li>more operationally,production,distribution focused<br>
</li><li>virtualization continues industry trend(mainframes originally) to maximize hardware usage (allow multiple workload/systems on same hardware)<br>
</li><li>hardware manufacturers better supporting virtualization technologies to help reduce virtualization performance tax/penalty - general rule of thumb is 30% cost/tax in supporting virtualization - depends on type/amount of workload<br>
</li><li>appliances/packages can be developed for multiple end purposes swiss army knife, stem cell - many end configurations/functions from single package<br>
</li><li>should be technically possible if desired or necessary to port images to other virtualization hosts/vendors(avoiding vendor lock-in) and to remote/'cloud' based servers(don't own the hardware, just payment for processing/storage/bandwidth usage) - dynamic cloud usage more appealing to workloads with highly dynamic workloads(extra servers only needed during peak workloads).<br>
</li><li>security - depends on trust/testing between provider of software/system and consumer/host, and also feedback where security or performance could be improved<br>
</li><li>possibly run appliance outside of consumer firewall(or quarantined) until level of trust/confidence established<br>
</li><li>image/virtualization use in modeling community for distributed/grid computing purposes</li></ul>

<h2>Infrastructure / Stack</h2>

A breakout(circa 2010) of some of our server layout - basically we have<br>
<ul><li>a main production server instance(Xenia - formats&services), represented by the shared server instance<br>
<ul><li>the 'application' layer might also live on this main production server instance or other servers - basically represents the possible separation of data content from more specific/custom applications<br>
</li></ul></li><li>working to also share a 'mapping' server instance for our mapping engine,tilecache,etc<br>
</li><li>an 'archival' instance which is just a larger xenia database instance where records older than 'recent'(past two-weeks) are kept<br>
</li><li>a 'squid' instance which handles internal http request rerouting by a shared IP and port references using a server name/keywords convention in the URL to route the requests - possible caching speedups eventually</li></ul>


<img src='http://xenia.googlecode.com/files/stack.jpg' />