# Google Mail Backup
### A docker based utility to backup google mail for Google Apps users.

This is a docker image that uses [gam](https://github.com/jay0lee/GAM) and [got-your-back](https://github.com/jay0lee/got-your-back) utilities.  Gam is used to download a list of users from your Google Apps domain and gyb (got-your-back) is used to download messages from the user's inboxes.  There is some setup required for gam and gyb.  You will need to see their individual pages for more details.  This docker image was built for windows native containers.  I would be open to a pull request to duplicate the functionality for Linux containers.

## Initializing the container
The gam and gyb tools need to be configured to work with your google apps instance.  There are instructions on their respective pages that we will not cover here.  To begin initilization, however, we need to start the container and initialize the folder structure.

:bell: You'll want to have persistent data volumes for **c:\data**, **c:\gam**, and **c:\gyb**

:warning: Typically in a docker image, we could pre-populate a folder like c:\gam with the data needed.  In a linux environment, if you attach a blank bind-mount to this folder, docker will copy the contents into your volume mount.  Due to a bug in windows containers & docker, you cannot start a container unless the target of a bind-mount is completely empty.  Therefore, we had to place the gam and gyb tools in a separate folder.
**After you start up the container you will need to copy these tools into place as you'll see below.**

Run the docker image interactively. Use the following examples for reference.

**Docker run examples:**

`docker run -i --name googlemailbackup -v C:\Data -v C:\gyb -v C:\gam wusa\googlemailbackup powershell`

`docker run -i --name googlemailbackup -v C:\GMail\data:C:\Data -v C:\GMail\gyb:C:\gyb -v C:\GMail\gam:C:\gam wusa\googlemailbackup powershell`


Once the container is started and you're running in the shell, copy the gam and gyb folders into place
```
Copy-Item -Recurse -Force C:\gyb-src\* c:\gyb\
Copy-Item -Recurse -Force C:\gam-src\* c:\gam\
```


### Configure [gam](https://github.com/jay0lee/GAM) & [gyb](https://github.com/jay0lee/got-your-back).
Navigate to the web pages for each of these packages.  Follow their instructions for configuration.  You may need to stay in the container's shell to access the commands.

## Post-Initialization: Running the container.
**Docker run examples:**

`docker run -d --name googlemailbackup -v C:\Data -v C:\gyb -v C:\gam wusa\googlemailbackup`


**Environment Variable options:**

`maxParallel` - Configure the maximum number of accounts to backup in parrallel.