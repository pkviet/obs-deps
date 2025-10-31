autoload -Uz log_debug log_error log_info log_status log_output

## Dependency Information
local name='vst3sdk'
local version='3.8.0'
local url='https://github.com/steinbergmedia/vst3sdk.git'
local hash="9fad9770f2ae8542ab1a548a68c1ad1ac690abe0"

## Build Steps
setup() {
  log_info "Setup (${target})"
  if [[ -d "${dir}" ]]; then
    rm -rf "${dir}"
  fi
  mkcd "${dir}"
  git clone --filter=blob:none --sparse --recurse-submodules=no "${url}" .
  git checkout "${hash}"
  git submodule update --init base pluginterfaces public.sdk
  rm -rf .git
}

install() {
  log_info "Install (%F{3}${target}%f)"
  cd "${dir}"

  mkdir -p \
    "${target_config[output_dir]}/include" \
    "${target_config[output_dir]}/licenses/vst3sdk"

  mkdir -p "${target_config[output_dir]}/include/vst3sdk"
  cp -R base "${target_config[output_dir]}/include/vst3sdk/"
  cp -R pluginterfaces "${target_config[output_dir]}/include/vst3sdk/"

  mkdir -p "${target_config[output_dir]}/include/vst3sdk/public.sdk"
  cp -R public.sdk/source "${target_config[output_dir]}/include/vst3sdk/public.sdk/"

  if [[ -f "LICENSE.txt" ]]; then
    cp LICENSE.txt "${target_config[output_dir]}/licenses/vst3sdk/"
  fi

  log_info "${name} ${version} installation complete."
}
