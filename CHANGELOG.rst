Changes
=======

1.2.0 (2021-08-11)
------------------

New Features
~~~~~~~~~~~~

* Added a new (non-standard) method to engines, ``reg_read_batch_as()``, which
  is like ``reg_read_as()`` but allows you to efficiently read multiple registers
  at the same time. See ``docs/api.rst`` for details.
* Added ``__close`` metamethod to engines and contexts, so they can now be used
  with Lua 5.4's ``<close>`` local attribute.
* Unified installation process for all platforms; ``configure`` now generates all
  CMake stuff for you.
* The appropriate Lua installation directory is now automatically determined.
  Before, it used to install in the normal system directories which is *not* where
  Lua looks.
* Added ``--install-prefix`` to the configure script to override where the library
  is installed.

Bugfixes
~~~~~~~~

* **Potentially Breaking:** Signaling NaNs in a CPU are now passed back to Lua
  as signaling NaNs. Before, all NaNs were converted to quiet NaNs. This brings
  it in line with other bindings. Unless you do significant amounts of
  floating-point operations, this won't affect you.
* Added ``REG_TYPE_INT16_ARRAY_32``, a 32-element array of 16-bit integers.
  I'd left it out by mistake.
* Fixed a crash when if a context or engine object was explicitly freed, if it got
  garbage-collected the object may think it's a double free and throw an exception.
  This eliminates a long-standing bug in LuaJIT on Mac OS and an edge case on other
  platforms.
* Fixed crash resulting from a race condition, where if Lua schedules an engine
  to be freed before a dependent context, the context would try to release its
  resources using an invalid engine. Now the engine cleans up all contexts created
  from it and signals all remaining Lua context objects to do nothing.
* ``reg_read_as()`` truncated floats in arrays to integers due to a copy-paste error.
* All the examples were broken by the ``unicorn_const`` change in 1.0b8.
* Setting floating-point registers now (theoretically) works on a big-endian host
  machine.
* Fixed bug where the engine pointer/engine object pair wasn't removed from the C
  registry upon closing. This is because the Engine pointer gets nulled out upon
  closing, and then after closing we tried removing the pointer. It never matched
  because it was null.

Other Changes
~~~~~~~~~~~~~

* [C++] All register buffers are now zeroed out upon initialization.
* [C++] read_float80 and write_float80 now operate on ``lua_Number``
  rather than the platform-dependent 64-, 80-, or 128-bit floats.
* [C++] Removed definition of ``lua_Unsigned`` for Lua 5.1 since it was both
  wrong and unused anyway.
* [C++] The engine handle and Lua state are now private variables for UCLuaEngine.
* [C++] Overhauled implementation of contexts to avoid a race condition where
  the engine was garbage-collected before a context derived from it.
* Switched to Github Actions for CI instead of Travis.
* The Makefile now generates the build directory if you're on CMake 3.13+.
* ``make install`` now builds the library if it hasn't been built already.
* ``make clean`` now removes the virtualenv directory as well.
* ``configure`` defaults to a release build; debug builds are opt-in.
* Removed a lot of C-isms from when this library was written in C.

1.1.1 (2021-05-15)
------------------

New Features
~~~~~~~~~~~~

* Added a global constant to the ``unicorn`` module named ``UNICORNLUA_VERSION``.
  This is a three-element table giving the major, minor, and patch versions of
  the Lua binding.
* Added certain protections and better error messages in the ``configure`` script
  to aid setting up your dev environment and debugging certain problems.

1.1.0 (2021-01-18)
------------------

New Features
~~~~~~~~~~~~

* Added support for Unicorn 1.0.2.
* Context objects now have an instance method, ``free()`` which can be used to
  release the context's resources.


1.0.0 (2021-01-18)
------------------

**First stable release!**

No changes aside from updating the copyright year.


1.0rc1 (2020-09-20)
-------------------

Overhauled the build configuration system.

* This no longer relies on convoluted CMake scripts to download and install Lua
* Fixes the problem where LuaJIT had to be used in a virtual environment

If you want to install this into a virtual environment as before, you now must use the
``lua_venv.py`` script in the ``tools`` directory. See the README for more details on
how it works.

This is the first release candidate. No significant changes are likely to happen between
now and 1.0.0; I plan on it being mostly just more testing, some code cleanup, and some
bugfixes if any pop up.


1.0b9 (2020-08-22)
------------------

Added support for Lua 5.4.


1.0b8 (2020-03-09)
------------------

Breaking Changes
~~~~~~~~~~~~~~~~

* Removed the non-standard ``UC_MILLISECOND_SCALE`` constant. You must use the
  original (misspelled) constant defined in the Unicorn library's code,
  ``UC_MILISECOND_SCALE``.
* In line with the other API bindings, constants in the global ``unicorn`` namespace
  have been moved to ``unicorn.unicorn_const``.
* All register type constants have been moved to ``unicorn.registers_const`` and
  have lost their ``UL_`` prefix. The example given for 1.0b6 below will now need
  to be:

.. code-block:: lua

    local regs_const = require "unicorn.registers_const"

    local regs = engine:reg_read_as(
        x86_const.UC_X86_REG_MM0,
        regs_const.REG_TYPE_INT32_ARRAY_2
    )


1.0b7 (2020-02-25)
------------------

* Added a lot of documentation. See the ``docs`` directory.
* Updated issues list in README
* Updated copyright years in license file
* Minor code cleanup


1.0b6 (2020-02-17)
------------------

New Features
~~~~~~~~~~~~

When reading or writing a register you can now specify how the register should be
interpreted, e.g. as a 64-bit float or a pair of 32-bit floats, and so on. (Closes
`issue #2`_, `issue #6`_ and `issue #5`_ *except* for the x87 ST(x) registers.)

.. code-block:: lua

    -- Read register MM0 as an array of two 32-bit integers
    local regs = engine:reg_read_as(x86_const.UC_X86_REG_MM0, unicorn.UL_REG_TYPE_INT32_ARRAY_2)

Note: you cannot read/write multiple registers at the same time with this feature.

A variety of register types have been implemented, pretty much entirely based on what
the x86 instruction set and its extensions support, so they may not all be appropriate
for the architecture your Unicorn engine is running. These constants start with
``UL_REG_TYPE_`` and can be found in the main ``unicorn`` module.

Bugfixes
~~~~~~~~

Completely fixed buffer overflow when reading registers over 64 bits. (Closes
`issue #3`_)

.. _issue #2: https://github.com/dargueta/unicorn-lua/issues/2
.. _issue #3: https://github.com/dargueta/unicorn-lua/issues/3
.. _issue #5: https://github.com/dargueta/unicorn-lua/issues/5
.. _issue #6: https://github.com/dargueta/unicorn-lua/issues/6


1.0b5 (2019-10-23)
------------------

* Switch build system to CMake

  * C++ documentation is now generated in the ``build/docs`` directory
  * Library binary is now generated in ``build/lib``

* Moved examples to root directory of repo instead of as a subdirectory of ``docs``
* Add unit tests to C++ code directly, not just from Lua
* Fix wrong destructor being called on Context objects
* Fix wrong library file extension on OSX -- should be ``.so`` not ``.dylib``
* Fix buffer overflow when reading 64-bit register on a 32-bit architecture
* Fixed wrong installation directory -- library should go to Lua's `lib` dir, not LuaRocks
* Removed some dead code
* Fixed odd bug in backport of ``lua_seti()`` that coincidentally worked, but only when
  the Lua stack was small.


1.0b4 (2019-09-23)
------------------

**Official support for OSX!**

* Fix memory leak when writing multiple registers
* Made creating hooks and contexts the responsibility of the UCLuaEngine class, so
  they're always destroyed when the engine is closed, and no other functions are allowed
  to create them without the Engine's knowledge. This eliminates some kinds of memory
  leaks.
* Fixed bug where ``engine:query(SOME_QUERY_TYPE)`` would look at the first argument (the
  engine) for the query type, instead of the second argument.
* Removed a number of unused or nearly-unused functions, made some others static that
  didn't need to be/probably shouldn't be shared.


1.0b3 (2019-09-18)
------------------

* Changed MIPS file extension from ``*.S`` to ``*.s``.
* Documented floating-point limitation in repo's README.
* Overhauled ``configure`` script to allow using the operating system's Lua installation.
  Using a virtual environment is no longer forced.
* Hooks are now always destroyed along with the engine they're attached to. This solves
  a race condition on LuaJIT where the garbage collector sometimes deletes the hook *after*
  its engine got destroyed.

Move to C++
~~~~~~~~~~~

This is now a C++ project coded to be compatible with C++11 and higher. I did this because
managing an engine's hooks using a Lua table instead of inside the library was unwieldy
and prone to memory leaks or spurious crashes, especially in low-memory situations.
Moving to C++ and using template containers sounded like the least amount of work.

Significant refactor
~~~~~~~~~~~~~~~~~~~~

All files from ``src/constants`` and their corresponding headers were removed. The
constants files are now autogenerated from the installed Unicorn headers, as done in the
Python binding.

**Breaking**: The constants submodules now have ``_const`` suffixed to them. For example,
``unicorn.x86`` is now ``unicorn.x86_const``. This'll allow us to create submodules with
additional architecture-specific functionality, and mirrors the Python binding's structure
more closely.


1.0b2 (2019-08-21)
------------------

* Better documentation
* Add support for MIPS examples, describe cross-compilation toolchain
* Error handling for when memory allocation fails


1.0b1 (2019-06-27)
------------------

Minor change -- all X86 binaries for the examples are included, so you only need
``nasm`` if you're going to modify them.


1.0b0 (2019-04-13)
------------------

Initial release
