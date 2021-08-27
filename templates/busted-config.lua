return {
  _all = {
    cpath = "$<TARGET_FILE_DIR:unicornlua_library>/?@LUA_CLIB_EXTENSION@;;",
    lua = "@LUA_EXE@",
    verbose = true,
    shuffle = true,
    directory = "@CMAKE_CURRENT_SOURCE_DIR@",
  },
  default = {
    pattern = "lua",
    ROOT = {"@CMAKE_CURRENT_SOURCE_DIR@"},
  }
}
