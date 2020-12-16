 *Posted on March 25, 2013 by El Duderino — 1 Comment ↓*

# Using Associative arrays in bash for an[apache cassandra](http://cassandra.apache.org/)deployment

Lets say engineering dictates that they will need you to re purpose 10 servers for a new cassandra ring/cluster and it needs to be done before the weekend so they can start replaying data into it for a new project.

So you have some spit & glue to stand up the systems fairly quickly and in an automated fashion. So you pixie boot the systems and install a them via kickstart config and you have all the systems up & running in 15 minutes.

You are going over the README file for installing the cassandra software & realize that post installation of it each node will need to have specific content in the cassandra.yaml file. One thing you realize is that you will not be sneaker netting this. Who has time for editing 10 configs on 10 different severs with specific content? for one it is error prone and two is also a fools errand.

One way to do this is through config mngt. tools like[Puppet](https://puppet.com/)or[chef](https://www.chef.io/products/chef-infra/)& you proceed by putting together a recipe for this which are pretty high level and get the software on each node in the directory structure you need but to edit the configs seems to be a bit more complicated.

**NOTE:** *So here is ware Bash can be used and incorporated into your recipe or puppet script. I am sure there are people who have some ruby-foo and could pull this off quickly but I tend to build on top of readymade recipes & am much more proficient in BASH.* 

So stacking the deck for a quick deploy.

We are going to want to edit all the global setting in the cassandra.yaml ahead of time and build a template file for deployment.
– unpack the cassandra software and open the default cassandra.yaml file in your favorite editor:
vi cassandra.yaml

populate the templates variables to your liking(these are the vars I pre-populated):

Note: the initial_token variable I populate with something to be changed later on.
```
– cluster_name
– initial_token: XXXCHANGETHISTOKENXXX
– partitioner
– data_file_directories
– commitlog_directory
– saved_caches_directory
– commitlog_segment_size_in_mb
– seed_provider
— seeds
– concurrent_reads
– concurrent_writes
```
Ok so now we’ve got a template file we can use to populate via chef.

Now lets say the software is installed with your cassandra.yaml template we need to create a step to run a small bash script that will edit the template file with specifics about each node.

So at this point you realize that to key the data for the replication you need to generate a token/key specific to each node. you run the python script(`<INSTALL DIR>/tools/bin/token-generator`) the apache Cassandra project provides for keying your data & generate the keys for each node.
We are now going to take those keys and build an Associated array with them in bash.

The keys we have generated:
```
0
17014118346046923173168730371588410572
34028236692093846346337460743176821145
51042355038140769519506191114765231718
68056473384187692692674921486353642291
85070591730234615865843651857942052864
102084710076281539039012382229530463436
119098828422328462212181112601118874009
136112946768375385385349842972707284582
153127065114422308558518573344295695155
```


So before we start in on building the associated array to use lets define some vars we will need in the process of using the array:

```
MYIP=$(/bin/hostname -i)                        # current servers ip address
MYHOST=$(/bin/hostname -a)                      # current servers host name
MYDATE=$(/bin/date '+%Y%m%d%H%M%S')             # current date "formatted"
MYSED="/bin/sed -i.BAK-${MYDATE}"               # sed app "rollback enabled"
MYBASEDIR="/opt/deps/"                          # base directory
MYPACKAGEDIR="${MYBASEDIR}packages/"            # dir to store downloads
MYAPPDIR="${MYBASEDIR}apache-cassandra"         # the running application dir
TEMPLATENAME="cassandra-1.2.0-template.yaml"    # config template name
```

Now we want to associate these keys to hosts:

- to create an associated array use the -A flag with declare

```
### TOKENS for the Cassandra Ring: #
declare -A TOKENS_MAP
TOKENS_MAP["cass-20"]="0"
TOKENS_MAP["cass-21"]="17014118346046923173168730371588410572"
TOKENS_MAP["cass-22"]="34028236692093846346337460743176821145"
TOKENS_MAP["cass-23"]="51042355038140769519506191114765231718"
TOKENS_MAP["cass-24"]="68056473384187692692674921486353642291"
TOKENS_MAP["cass-25"]="85070591730234615865843651857942052864"
TOKENS_MAP["cass-26"]="102084710076281539039012382229530463436"
TOKENS_MAP["cass-27"]="119098828422328462212181112601118874009"
TOKENS_MAP["cass-28"]="136112946768375385385349842972707284582"
TOKENS_MAP["cass-29"]="153127065114422308558518573344295695155"
###
```

OK, so now lets get ready to edit the cassandra.yaml file. we are going to move the default one that comes with the installation out of the way and replace it with our template:
```
if [[ -f ${MYAPPDIR}/conf/cassandra.yaml ]]; then
    mv ${MYAPPDIR}/conf/cassandra.yaml ${MYAPPDIR}/conf/cassandra.yaml.ORIG-${MYDATE}
    cp ${MYPACKAGEDIR}${TEMPLATENAME} ${MYAPPDIR}/conf/cassandra.yaml
else
    echo -e "\t ${DATE} ERROR: Could not swap in the ${TEMPLATENAME} ";
    exit 1;
fi
```

Now comes for the good stuff, lets set the token to be populated in the newly created template:
```
### Lets set the token in the cassandra.yaml config...
MY_TOKEN=${TOKENS_MAP[${MYHOST}]}
```

In our template we need to do several things that are specific to each host besides setting the token.

- set the token
- set the listen_address
- set the rpc_address

Lets twist up a little sed to swap out these variables in our template:
```
# set the token, Listen adress & rpc address:
${SED} "s%XXXCHANGETHISTOKENXXX%$MY_TOKEN%; s%listen_address: localhost%listen_address: ${MYIP}%; s%rpc_address: localhost%rpc_address: ${MYIP}%" ${MYAPPDIR}/conf/cassandra.yaml
```

Now we have one last thing we need to do with sed before we tie this all together. we now need to set the logging path in our log4j properties file.

```
# set the logging path...
${SED} 's%log4j\.appender\.R\.File=/var/log/cassandra/system\.log%log4j\.appender\.R\.File=/home/cassandra/logs/system\.log%' ${MYAPPDIR}/conf/log4j-server.properties
```

So if we pull this all together here is what your script would look like to be incorporated with your chef/puppet receipts:

```
#!/bin/bash
#
# cassandra_1.2.0_config_update.sh
###

### VARS:
MYIP=$(/bin/hostname -i)                     # current servers ip address
MYHOST=$(/bin/hostname -a)                   # current servers host name
MYDATE=$(/bin/date '+%Y%m%d%H%M%S')          # current date "formatted"
MYSED="/bin/sed -i.BAK-${MYDATE}"            # sed app "rollback enabled"
MYBASEDIR="/opt/deps/"                       # base directory
MYPACKAGEDIR="${MYBASEDIR}packages/"           # dir to store downloads
MYAPPDIR="${MYBASEDIR}apache-cassandra"        # the running application dir
TEMPLATENAME="cassandra-1.2.0-template.yaml" # config template name
###

### TOKENS for the Cassandra Ring: #
declare -A TOKENS_MAP
TOKENS_MAP["cass-20"]="0"
TOKENS_MAP["cass-21"]="17014118346046923173168730371588410572"
TOKENS_MAP["cass-22"]="34028236692093846346337460743176821145"
TOKENS_MAP["cass-23"]="51042355038140769519506191114765231718"
TOKENS_MAP["cass-24"]="68056473384187692692674921486353642291"
TOKENS_MAP["cass-25"]="85070591730234615865843651857942052864"
TOKENS_MAP["cass-26"]="102084710076281539039012382229530463436"
TOKENS_MAP["cass-27"]="119098828422328462212181112601118874009"
TOKENS_MAP["cass-28"]="136112946768375385385349842972707284582"
TOKENS_MAP["cass-29"]="153127065114422308558518573344295695155"
###

### Check that the orig config is there and swap it our for the template
if [[ -f ${MYAPPDIR}/conf/cassandra.yaml ]]; then
    mv ${MYAPPDIR}/conf/cassandra.yaml ${MYAPPDIR}/conf/cassandra.yaml.ORIG-${MYDATE}
    cp ${MYPACKAGEDIR}${TEMPLATENAME} ${MYAPPDIR}/conf/cassandra.yaml
else
    echo -e "\t ${DATE} ERROR: Could not swap in the ${TEMPLATENAME} ";
    exit 1;
fi

### Lets set the token in the cassandra.yaml config...
MY_TOKEN=${TOKENS_MAP[${MYHOST}]}

# set the token, Listen adress & rpc address:
${SED} "s%XXXCHANGETHISTOKENXXX%$MY_TOKEN%; s%listen_address: localhost%listen_address: ${MYIP}%; s%rpc_address: localhost%rpc_address: ${MYIP}%" ${MYAPPDIR}/conf/cassandra.yaml

# set the logging path...
${SED} 's%log4j\.appender\.R\.File=/var/log/cassandra/system\.log%log4j\.appender\.R\.File=/home/cassandra/logs/system\.log%' ${MYAPPDIR}/conf/log4j-server.properties
```

Boom & your done so you can hand this beast off to engineering and relax…

