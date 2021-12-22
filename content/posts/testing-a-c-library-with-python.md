---
title: "Testing a C Library With Python"
date: 2021-12-22T11:45:38Z
draft: false
---

It's still common for a systems library to be written in the default lingua
franca, C, although Rust is encroaching, for good reasons.

However, when it comes to testing, things get tedious quickly: writing unit or
component tests in C is a slow, bug-prone exercise. With
[libvfio-user](https://github.com/nutanix/libvfio-user), after fixing too many
bugs that were due to the test rather than the test subject, I decided it would
be worth looking at alternative approaches. The aim was to reduce the time it
takes to develop unit/component tests.

Up until this point, we'd been using
[ctest](https://cmake.org/cmake/help/latest/manual/ctest.1.html), along with
[cmocka](https://cmocka.org/) when we needed to mock out certain functions (such
as socket handling). Leaving aside my strong feelings on these tools, this was
rather unsatisfactory: `libvfio-user` effectively implements a (UNIX) socket
server, but we weren't actually testing round-trip interactions for the most
part. In terms of code coverage, very little useful could be done via this unit
testing approach, but the "sample" client/server was tedious to work with for
testing purposes.

## Python-based testing

After a quick proof of concept, it became clear that using Python would be a
great choice to cover most of our testing needs. `libvfio-user` doesn't ship
with any client bindings, and, given that the main clients are
[qemu](https://www.qemu.org/),
[cloud-hypervisor](https://github.com/cloud-hypervisor) and
[SPDK](https://spdk.io/), Python bindings would be of dubious utility.

As a result, we decided against "proper" Python bindings, auto-generated or
otherwise, in favour of a small and simple approach. In particular, by using the
terrible magic of `ctypes`, we could easily set up both client and server test
cases that fully represent how the library works in real life.

So, instead of auto-generated bindings, we write - by hand -
simple, thin, layers of
[type wrappers](https://github.com/nutanix/libvfio-user/blob/17769cf1af093dfb4b9bc3347ae39324029989ac/test/py/libvfio_user.py#L303):

```python
class vfio_irq_info(Structure):
    _pack_ = 1
    _fields_ = [
        ("argsz", c.c_uint32),
        ("flags", c.c_uint32),
        ("index", c.c_uint32),
        ("count", c.c_uint32),
    ]
```

small harness routines for [socket handling](https://github.com/nutanix/libvfio-user/blob/17769cf1af093dfb4b9bc3347ae39324029989ac/test/py/libvfio_user.py#L644)
...


```python
def connect_client(ctx):
    sock = connect_sock()

    json = b'{ "capabilities": { "max_msg_fds": 8 } }'
    # struct vfio_user_version
    payload = struct.pack("HH%dsc" % len(json), LIBVFIO_USER_MAJOR,
                          LIBVFIO_USER_MINOR, json, b'\0')
    hdr = vfio_user_header(VFIO_USER_VERSION, size=len(payload))
    sock.send(hdr + payload)
    ...
```

... interacting with the
library [on the server
side](https://github.com/nutanix/libvfio-user/blob/17769cf1af093dfb4b9bc3347ae39324029989ac/test/py/libvfio_user.py#L739)
...

```python
def get_pci_header(ctx):
    ptr = lib.vfu_pci_get_config_space(ctx)
    return c.cast(ptr, c.POINTER(vfu_pci_hdr_t)).contents
```

... and so on.  Writing this by hand might seem immensely tedious, but in practice,
as it's pretty much all boilerplate, it's very quick to write and modify, and
easily understandable; something that can rarely be said for any kind of
auto-generated code.

## Client/server interactions

Another observation was that, for the purposes of these tests, we really didn't
need a client process and a server process: in fact, we don't even need more
than one thread of execution. If we make each test round-robin between acting as
the client, then acting as the server, it becomes trivial to follow the
control flow, and understanding logs, debugging, etc. is much easier. This is
illustrated by the
[`msg()`](https://github.com/nutanix/libvfio-user/blob/17769cf1af093dfb4b9bc3347ae39324029989ac/test/py/libvfio_user.py#L675)
helper:

```python
def msg(ctx, sock, cmd, payload=bytearray(), expect_reply_errno=0, fds=None,
        rsp=True, expect_run_ctx_errno=None):
    """
    Round trip a request and reply to the server. vfu_run_ctx will be
    called once for the server to process the incoming message,
    @expect_run_ctx_errrno checks the return value of vfu_run_ctx. If a
    response is not expected then @rsp must be set to False, otherwise this
    function will block indefinitely.
    """
    # FIXME if expect_run_ctx_errno == errno.EBUSY then shouldn't it implied
    # that rsp == False?
    hdr = vfio_user_header(cmd, size=len(payload))

    if fds:
        sock.sendmsg([hdr + payload], [(socket.SOL_SOCKET, socket.SCM_RIGHTS,
                                        struct.pack("I" * len(fds), *fds))])
    else:
        sock.send(hdr + payload)

    ret = vfu_run_ctx(ctx, expect_errno=expect_run_ctx_errno)
    if expect_run_ctx_errno is None:
        assert ret >= 0, os.strerror(c.get_errno())

    if not rsp:
        return

    return get_reply(sock, expect=expect_reply_errno)
```

We are operating as the client when we do the `sendmsg()`; the server then
processes that message via `vfu_run_ctx()`, before we "become" the client again
and receive the response via `get_reply()`.

We can then implement an individual test like this:

```python
def test_dma_region_too_big():
    global ctx, sock

    payload = vfio_user_dma_map(argsz=len(vfio_user_dma_map()),
        flags=(VFIO_USER_F_DMA_REGION_READ |
               VFIO_USER_F_DMA_REGION_WRITE),
        offset=0, addr=0x10000, size=MAX_DMA_SIZE + 4096)

    msg(ctx, sock, VFIO_USER_DMA_MAP, payload, expect_reply_errno=errno.ENOSPC)
```

which we can run via `make pytest`:

```
...
___________________________ test_dma_region_too_big ____________________________
----------------------------- Captured stdout call -----------------------------
DEBUG: quiescing device
DEBUG: device quiesced immediately
DEBUG: adding DMA region [0x10000, 0x80000011000) offset=0 flags=0x3
ERROR: DMA region size 8796093026304 > max 8796093022208
ERROR: failed to add DMA region [0x10000, 0x80000011000) offset=0 flags=0x3: No space left on device
ERROR: msg0x62: cmd 2 failed: No space left on device
...
```

This is many times easier to write and test than trying to do this in C, whether
as a client/server, or attempting to use mocking. And we can be reasonably
confident that the test is meaningful, as we are really executing all of the
library's message handling.

## Debugging/testing tools

With a little bit of tweaking, we can also use standard C-based tools like
`valgrind` and `gcov`. Code coverage is simple: after defeating the mini-boss of
`cmake`, we can run `make gcov` and get code-coverage results for all C code
invoked via the Python tests - it just works!

Running Python tests with `valgrind` was a little harder: for leak detection, we
need to make sure the tests clean up after themselves explicitly. But Python
itself also has a lot of `valgrind` noise.  Eventually we found that this [`valgrind`
invocation](https://github.com/nutanix/libvfio-user/blob/17769cf1af093dfb4b9bc3347ae39324029989ac/Makefile#L81) worked well:

```
	PYTHONMALLOC=malloc \
	valgrind \
	--suppressions=$(CURDIR)/test/py/valgrind.supp \
	--quiet \
	--track-origins=yes \
	--errors-for-leak-kinds=definite \
	--show-leak-kinds=definite \
	--leak-check=full \
	--error-exitcode=1 \
	$(PYTESTCMD)
```

We need to force Python to use the system allocator, and add a number of
suppressions for internal Python `valgrind` complaints - I was unable to find a
working standard suppression file for Python, so had to construct this myself
based upon the Python versions in our CI infrastructure.

Unfortunately, at least on our test systems, ASAN was completely incompatible,
so we couldn't directly run that for the Python tests.

## Summary

The approach I've described here has worked really well for us: it no longer
feels immensely tedious to add tests along with library changes, which can only
help improve overall code quality. They are quick to run and modify, and for the
most part easy to understand what the tests are actually doing.

There's been a few occasions where `ctypes` has been difficult to work with -
for me the documentation is particularly sparse, and callbacks from the C
library into Python are distinctly non-obvious - but we've so far always
managed to battle through, and twist it to our needs.

Doing things this way has a few other drawbacks: it's not clear, for example, how we might test
intermittent allocation failures, or other failure injection scenarios. It's
also not really suitable for any kind of performance or scalability testing.

I'm curious if others have taken a similar approach, and what their experiences
might be.
