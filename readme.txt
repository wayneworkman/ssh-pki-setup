ssh pki setup


This is a utility to quickly setup certificate based ssh authentication to many
systems at once.

Define the systems you wish to setup inside of the working directory, in hosts.csv.
Columns within this file must maintain their order. If you wish, you may leave the 
some or all of the password column blank but will have to manually key in the missing
passwords during installation. The header is required to be present, please do not
remove it.

The alias field is what will be used to define aliases for the remote systems. To use
an alias at CLI, simply type `ssh` followed by a space and then the alias and hit enter. 
If ssh pki access is setup for that remote system, you'll fall into it's CLI as root.

The account field is the account to be used for setitng up the ssh pki access. This
account must be able to become root via the command `sudo -i`.

The address field may be an IP address or a hostname, or a FQDN.

The port defines what port ssh and scp should use when trying to communicate to the 
remote system.

The optionalPass field is optional, you may place a password in this field or not. If
one is present, the program will use this to attempt to authenticate with. If it is
left blank, you will be prompted to supply the password for the remote system. The
choice is up to you. If you do define a password in the hosts.csv file, after runninng
this program, it's wise to delete the hosts.csv file, or hide it away with `500` 
permissions.

A sample hosts.csv might look like this:

alias,account,address,port,optionalPass
router,root,10.0.0.1,22,MyAwesomePassword
fog,root,10.0.0.4,22,
node,root,10.0.0.7,22,SuperSecurePassword
application,root,10.0.0.8,5698,

Or this:

alias,account,address,port,optionalPass
webserver,james,10.0.0.1,94523,
devbox,root,10.0.0.4,22,SomthingICanRemember
fileserver,root,10.0.0.7,94524,
fogserver,root,10.0.0.8,22,


