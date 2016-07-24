ssh pki setup


This is a utility to quickly setup certificate based ssh authentication to many
systems at once.

The program will check for a public and private key in the $HOME folder of the currnet
user, and also checks that they are not empty files. If the current user is `wayne`, 
these files would be:

/home/wayne/.ssh/id_rsa
/home/wayne/.ssh/id_rsa.pub

If the current user is root, they would be:

/root/.ssh/id_rsa
/root/.ssh/id_rsa.pub

If EITHER of these files do not exist, or if EITHER of them are empty files, then both
files are DELETED automatically, and a new certificate pair is generated using 4096 bit
strength, and placed in the $HOME/.ssh directory under their correct names.

If you have a pre-existing key-pair that you would like to use, ensure these keys
are named properly and placed in the correct locations as described above, with the
correct permissions, such as 600.

Define the systems you wish to setup inside of the working directory, in hosts.csv.
Columns within this file must maintain their order, and the header must be maintained.
If you wish, you may leave the some or all of the password column blank but will have 
to manually key in the missing passwords during installation.

The alias field is what will be used to define aliases for the remote systems. To use
an alias at CLI, simply type `ssh` followed by a space and then the alias and hit enter. 
If ssh pki access is setup for that remote system, you'll fall into it's CLI.

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


