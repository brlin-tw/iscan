# DEBUGGING

Tips to help in troubleshooting the problem.

## Enable debug messages

```bash
INSTALL_PREFIX=/opt/iscan

    SANE_DEBUG_DLL=1 \
env \
    LANG=C \
    SANE_DEBUG_EPKOWA=INFO \
    LD_LIBRARY_PATH="${INSTALL_PREFIX}/lib:${INSTALL_PREFIX}/lib/sane" \
    "${INSTALL_PREFIX}/bin/iscan" \
    2>&1 \
    | tee iscan.log
```

## Trace library

```bash
INSTALL_PREFIX=/opt/iscan

env \
    LANG=C \
    LD_LIBRARY_PATH="${INSTALL_PREFIX}/lib:${INSTALL_PREFIX}/lib/sane" \
    ltrace \
        --demangle \
        -s 1024 \
        -e '*@libesmod.*+*@libsane*' \
        "${INSTALL_PREFIX}/bin/iscan" \
        2>&1 \
    | tee ltrace.out.txt

```

## Trace system calls

```bash
INSTALL_PREFIX=/opt/iscan

#        -e 'trace=!futex,poll,sendmsg,recvmsg,rt_sigprocmask' \
env \
    LANG=C \
    LD_LIBRARY_PATH="${INSTALL_PREFIX}/lib:${INSTALL_PREFIX}/lib/sane" \
    strace \
        --decode-fds=path \
        --decode-pids=comm \
        --string-limit=64 \
        -e 'trace=access,openat,newfstatat,mmap,read,close,readlinkat,getdents64' \
        "${INSTALL_PREFIX}/bin/iscan" \
        2>&1 \
    | tee strace.out.txt
```

## References

* FILTER EXPRESSIONS | ltrace(1) manual page
