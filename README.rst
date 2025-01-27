unicorn-lua
===========

|build-status| |lua-versions| |platforms|

.. |build-status| image:: https://travis-ci.com/dargueta/unicorn-lua.svg?branch=master
   :alt: Build status
   :target: https://travis-ci.com/dargueta/unicorn-lua

.. |lua-versions| image:: https://img.shields.io/badge/lua-5.1%20%7C%205.2%20%7C%205.3%20%7C%205.4%20%7C%20LuaJIT2.0-blue
   :alt: Lua versions
   :target: https://www.lua.org

.. |platforms| image:: https://img.shields.io/badge/platform-linux%20%7C%20macos-lightgrey
   :alt: Supported platforms

Lua bindings for the `Unicorn CPU Emulator`_.

This is still in beta. While the Lua-facing API is relatively stable, some changes
may be made here and there. The C API is currently subject to change without
warning.

At the moment I'm only testing this on unmodified Lua 5.1 - 5.4 and LuaJIT 2.0
on Linux and OSX. I cannot guarantee the library will behave as expected on all
host platforms, though I will try. (LuaJIT on OSX is particularly finicky.)

Known Limitations
-----------------

The following are some limitations that are either impossible to work around due
to the nature of Lua, or I haven't gotten around to fixing yet.

64-bit Integers
~~~~~~~~~~~~~~~

64-bit integers *do not* fully work on Lua 5.2 or 5.1. This is because Lua only
added direct support for integers in 5.3; Lua 5.1 and 5.2 use floating-point
numbers, which provide at most 17 `digits of precision`_. Thus, values over 53
bits cannot be represented accurately before 5.3.

We can work around this limitation by:

* Using libraries such as `BigInt`_. This could quickly become cumbersome, and
  the performance impact is unknown.
* Providing special read and write functions for 64-bit integers. This is the
  least disruptive but also makes the API irregular.

I don't intend to fix this at the moment, as I want to focus on getting the API
complete first.

.. _BigInt: https://luarocks.org/modules/jorj/bigint
.. _digits of precision: https://en.wikipedia.org/wiki/Double-precision_floating-point_format

Signedness
~~~~~~~~~~

Because numbers in Lua are always signed, values above ``LUA_MAXINTEGER`` [1]_
such as addresses or register values will be returned from functions as negative
numbers, e.g.

.. code-block:: lua

    uc:reg_write(x86.UC_X86_REG_RAX, 0xffffffffffffffff)

    -- Returns -1 not 2^64 - 1
    uc:reg_read(x86.UC_X86_REG_RAX)

This doesn't affect how arguments are passed *to* the library, only values returned
*from* the library.

Floating-point Registers
~~~~~~~~~~~~~~~~~~~~~~~~

The 80-bit ST(x) registers on x86 architectures can't be read from or written to
properly; a bug in the current encoding/decoding code gives garbage values so I've
disabled it for the time being. Even if it did work, because Lua's floating-point
numbers are by default at most 64 bits, you're still going to lose precision when
reading the registers.


Emergency Collection and Memory Leaks
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If Lua doesn't have enough available memory to do a proper garbage collection
cycle, the collector will run in "emergency mode." [2]_ In this mode, finalizers
are *not* run, so you could end up in a situation where hooks, contexts, and
other resources held by a disused engine aren't released and never can be.

This rarely happens and most user code will probably be able to let the library
do its own memory management. If you like to be safe, call the ``close()`` method
on an engine after you're done using it to reduce the risk of an emergency
collection leaking resources.

General Usage
-------------

``unicorn`` tries to mirror the organization and naming conventions of the
`Python binding`_ as much as possible. For example, architecture-specific
constants are defined in submodules like ``unicorn.x86``; a few global functions
are defined in ``unicorn``, and the rest are instance methods of the engine.

.. _Python binding: http://www.unicorn-engine.org/docs/tutorial.html

Quick Example
~~~~~~~~~~~~~

This is a short example to show how a some of the features can be used to emulate
the BIOS setting up a system when booting.

.. code-block:: lua

    local unicorn = require 'unicorn'
    local uc_const = require 'unicorn.unicorn_const'

    local uc = unicorn.open(uc_const.UC_ARCH_X86, uc_const.UC_MODE_32)

    -- Map in 1 MiB of RAM for the processor with full read/write/execute
    -- permissions. We could pass permissions as a third argument if we want.
    uc:mem_map(0, 0x100000)

    -- Revoke write access to the VGA and BIOS ROM shadow areas.
    uc:mem_protect(0xC0000, 32 * 1024, uc_const.UC_PROT_READ|uc_const.UC_PROT_EXEC)
    uc:mem_protect(0xF0000, 64 * 1024, uc_const.UC_PROT_READ|uc_const.UC_PROT_EXEC)

    -- Create a hook for the VGA driver that's called whenever VGA memory is
    -- written to by client code.
    uc:hook_add(uc_const.UC_MEM_WRITE, vga_write_callback, 0xA0000, 0xBFFFF)

    -- Install interrupt hooks so the CPU can perform I/O and other operations.
    -- We'll handle all of that in Lua. Only one interrupt hook can be set at a
    -- time.
    uc:hook_add(uc_const.UC_HOOK_INTR, interrupt_dispatch_hook)

    -- Load the boot sector of the hard drive into 0x7C000
    local fdesc = io.open('hard-drive.img')
    local boot_sector = fdesc:read(512)
    uc:mem_write(0x7C000, boot_sector)
    fdesc:close()

    -- Start emulation at the boot sector we just loaded, stopping if execution
    -- hits the address 0x100000. Since this is beyond the range we have mapped
    -- in, the CPU will run forever until the code shuts it down, just like a
    -- real system.
    uc:emu_start(0x7C000, 0x100000)


Detailed Examples
~~~~~~~~~~~~~~~~~

More real-world examples can be found in the ``docs/examples`` directory. To run
them, make sure you do ``make examples`` to generate the required resources.


Deviations from the Python Library
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Because ``end`` is a Lua keyword, ``mem_regions()`` returns tables whose record
names are ``begins``, ``ends``, and ``perms`` rather than ``begin``, ``end``,
``perms``.

Requirements
------------

This project has the following dependencies. Ensure you have them installed
before using.

* Configuration: Python 3.3 or higher

* For building and running:

  * `cmake`_ 3.12 or higher. Run ``cmake --version`` if you're not sure what version you have.
  * `Unicorn CPU Emulator`_ library must be installed or at least built.

* Some examples have additional dependencies; see their READMEs for details.

Just Installing?
----------------

If you just want to install this library, open a terminal, navigate to the root
directory of this repository, and run the following:

.. code-block:: sh

    python3 configure
    make install

You may need superuser privileges to install. If installation fails, try
``sudo make install``.

Development
-----------

Configuration
~~~~~~~~~~~~~

Using a virtual environment for Lua is strongly recommended. You'll want to avoid
using your OS's real Lua, and using virtual environments allows you to test with
multiple versions of Lua.

With a Virtual Environment
^^^^^^^^^^^^^^^^^^^^^^^^^^

To create a separate execution environment, you can use
the ``lua_venv.py`` script.

.. code-block:: sh

    python3 tools/lua_venv.py --config-out settings.json  \
                              5.3                         \
                              ~/my-virtualenvs/5.3/

This will download Lua 5.3, install it in a directory named ``~/my-virtualenvs/5.3``,
and write all the configuration information needed by ``configure`` into a file
named ``settings.json``. *It is important that the directory you install Lua into
doesn't already exist.*

If you're running MacOS and encounter a linker error with LuaJIT, check out
`this ticket <https://github.com/LuaJIT/LuaJIT/issues/449>`_.

Using Your OS's Lua
^^^^^^^^^^^^^^^^^^^

It will probably suffice to run the configure script by itself:

.. code-block:: sh

    python3 configure

You may encounter problems with GCC claiming Lua's headers are missing, or it can't
find the Lua library. In this case you'll need to find them yourself, and pass
them to the configure script. For example:

.. code-block:: sh

    make clean
    python3 configure --lua-headers /usr/include/lua        \
                      --lua-library /lib/lua/5.3/liblua.a


Setting Up the Build Environment
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

After running the ``configure`` script there'll be a new empty directory in the
repo called ``build``. Change over to this directory and run ``cmake ..``. It'll
create the build system for you, including creating the Lua virtual environment
if you requested it.

Building and Testing
~~~~~~~~~~~~~~~~~~~~

Here are a few commands you may find useful during development. This isn't a
script, just a list.

.. code-block:: sh

    make            # Build the project, including libraries and examples
    make clean      # Delete all build artifacts
    make docs       # Build the documentation pages
    make examples   # Build but do not run examples (that must be done manually)
    make test       # Run all unit tests

Build artifacts will appear in the ``build`` directory:

* ``build/lib`` contains the built Lua library for Unicorn; ``unicorn.dll`` if
  you're running Windows, ``unicorn.so`` otherwise.
* ``build/docs`` contains the HTML documentation

Everything else in there isn't of much interest unless you're directly modifying
the CMake configuration.

Examples
~~~~~~~~

There are some example programs you can use to see how this library (and Unicorn
in general) works. You can run an example with

.. code-block:: sh

    make run_example EXAMPLE=name

``name`` is the name of the directory the example is in, e.g. ``disk_io`` or
``cmos_time``.

License
-------

I'm releasing this under the terms of the `New BSD License`_. For the full legal
text, see ``LICENSE.txt``.


**Footnotes**

.. [1] Typically 2\ :sup:`63` - 1 on 64-bit machines and 2\ :sup:`31` - 1 on
       32-bit machines.
.. [2] *Programming in Lua*, 4th Edition. Forgot the page.

.. _cmake: https://cmake.org
.. _Unicorn CPU Emulator: http://www.unicorn-engine.org
.. _New BSD License: https://opensource.org/licenses/BSD-3-Clause
.. _pyenv: https://github.com/pyenv/pyenv
.. _pipenv: https://docs.pipenv.org/en/latest
