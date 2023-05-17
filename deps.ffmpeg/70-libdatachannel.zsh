autoload -Uz log_debug log_error log_info log_status log_output

## Dependency Information
local name='libdatachannel'
local version='0.19.0'
local url='https://github.com/paullouisageneau/libdatachannel.git'
local hash='004c6b74ffa1d2718499b84d5bd7674d94b83dbc'

## Dependency Overrides
local -i shared_libs=1
local dir="${name}-${version}"

## Build Steps
setup() {
  log_info "Setup (%F{3}${target}%f)"
  setup_dep ${url} ${hash}
}

clean() {
  cd "${dir}"

  if [[ ${clean_build} -gt 0 && -d "build_${arch}" ]] {
    log_info "Clean build directory (%F{3}${target}%f)"

    rm -rf "build_${arch}"
  }
}

config() {
  autoload -Uz mkcd progress

  local _onoff=(OFF ON)

  args=(
    ${cmake_flags}
    -DENABLE_SHARED="${_onoff[(( shared_libs + 1 ))]}"
    -DUSE_MBEDTLS=1
    -DNO_WEBSOCKET=1
    -DNO_TESTS=1
    -DNO_EXAMPLES=1
  )
  case ${target} {
    windows-x*)
      args+=(
        -DCMAKE_CXX_FLAGS="-static-libgcc -static-libstdc++ -w -pipe -fno-semantic-interposition -static"
        -DCMAKE_C_FLAGS="-static-libgcc -w -pipe -fno-semantic-interposition -static"
        -DCMAKE_SHARED_LINKER_FLAGS="-static-libgcc -static-libstdc++ -L${target_config[output_dir]}/lib -Wl,--exclude-libs,ALL -static"
      )
}
  log_info "Config (%F{3}${target}%f)"
  cd "${dir}"
  log_debug "CMake configuration options: ${args}'"
  progress cmake -S . -B "build_${arch}" -G Ninja ${args}
}

build() {
  autoload -Uz mkcd progress

  log_info "Build (%F{3}${target}%f)"

  cd "${dir}"

  args=(
    --build "build_${arch}"
    --config "${config}"
  )

  if (( _loglevel > 1 )) args+=(--verbose)

  cmake ${args}
}

install() {
  autoload -Uz progress

  log_info "Install (%F{3}${target}%f)"

  args=(
    --install "build_${arch}"
    --config "${config}"
  )

  if [[ "${config}" =~ "Release|MinSizeRel" ]] args+=(--strip)
  if (( _loglevel > 1 )) args+=(--verbose)

  cd "${dir}"
  progress cmake ${args}
}

fixup() {
  cd "${dir}"

  case ${target} {
    windows*)
      log_info "Fixup (%F{3}${target}%f)"
      if (( shared_libs )) {
        autoload -Uz create_importlibs
        create_importlibs ${target_config[output_dir]}/bin/libdatachannel*.dll
        log_status "Fixing CMake for MSVC import library syntax"
        if [[ "${config}" = "Release" ]] {
          sed -i 's/libdatachannel.dll.a/libdatachannel.lib/g' ${target_config[output_dir]}/lib/cmake/LibDataChannel/LibDataChannelTargets-release.cmake
        }
        if [[ "${config}" = "RelWithDebInfo" ]] {
          sed -i 's/libdatachannel.dll.a/libdatachannel.lib/g' ${target_config[output_dir]}/lib/cmake/LibDataChannel/LibDataChannelTargets-relwithdebinfo.cmake
        }
      }

      autoload -Uz restore_dlls && restore_dlls
      ;;
  }
}

