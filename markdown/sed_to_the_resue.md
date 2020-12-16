*Posted on February 24, 2013 by El Duderino — No Comments* 

# SED to the rescue

So you are sitting at your desk trying to figure out if you want to venture out into the cold and take the Silver line into South Station to go get some chinese food or walk to the food truck in front of Boston ship repair. When all of a sudden a software engineer walks up and says that they are being blocked because a small cluster(not managed by ops) can’t read files  from the repository. So with some quick digging around you discover that they had mounted the repository read only to an old  NAS that is no longer in production… What to do, what to do. By this time you’ve decided that soup dumplings and  Sichuan flounder are what’s in store for lunch. How can you leave with this fool saying they're blocked?[SED](http://www.gnu.org/software/sed/)to the rescue.

So first things first. Lets get rid of the stale NFS mount:


either use Lazy:
`umount -l /prod/repo/`


or Forceful:
`umount -f /prod/repo/`

Now we need to clean up the fstab file. So on next reboot you don’t try and mount the old export again.

Lets twist up some sed, so the first point of interest that sed offers that a lot of people over look. Is the -i(edit in place) option has a feature that allows you to make a backup to roll back too if need be while editing in place. Even though it is right there in the description under the man page so many of us including my self have over looked that description.


snippet from the man page for[sed](https://en.wikipedia.org/wiki/Sed):

```
-i extension
             Edit files in-place, saving backups with the specified extension.  If a zero-length extension is given, no backup will be saved.  It is not rec-
             ommended to give a zero-length extension when in-place editing files, as you risk corruption or partial content in situations where disk space
             is exhausted, etc.
```
So “saving backups with the specified extension.” is accomplished as following:

– lets setup an extension to use:

`MY_DATE=$(date '+%Y%m%d%H%M%S')`

– when calling sed to edit a file in place you can use an extension to make a rollback like this:

`sed -i.BAK.${MY_DATE}`


So lets get back to the problem at hand which is needing to get some awesome delicious food for lunch. So where were we? Oh yeah we need to umount the stale NFS filesystem, edit the fstab file, mount the new path and create a rollback file of our fstab.

So lets get down to business so we can go get our grub on…

We are going to need to find the line in the fstab that mounts the now defunct export and comment it out.

so we are going to want to do a search for that line with “s” & once we find that line we will want to insert a comment on the beginning of the line.

To make this easy for the sake of the exercise lets say the actual NAS is fully retired not just the export so you can just look for
the actual IP in the fstab file and comment that out:

`sed -i.BAK.${MY_DATE}  's%^.*10.50.5.50*%#&%g' /etc/fstab`

The above command will create a backup file of the fstab that we are going to edit in place named: `/etc/fstab.BAK.20130223234011` and then add a comment “`#`” to the beginning of the line with `10.50.5.50` in it.
So now where are we? oh yeah we are so close to eating awesome Chinese food… So one last thing would be to add the new mount to the fstab lets use “echo” all though we could just as easily use EOF as well to append the mounts to the file:

`echo "10.50.6.50:/volumes/production-volume/repository /prod/repo/ nfs ro,nosuid,vers=3,rsize=8192,wsize=8192,intr 0 0" >> /etc/fstab;`

So now we have all the pieces that we need to solve the problem. We just need to put them together and run them across a small cluster of systems. I will explain way to do that in another post using different tools for example ssh-agent, Python Fabric, etc…

