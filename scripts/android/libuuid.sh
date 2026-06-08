#!/bin/bash

# ALWAYS CLEAN THE PREVIOUS BUILD
make distclean 2>/dev/null 1>/dev/null

# REGENERATE BUILD FILES IF NECESSARY OR REQUESTED
if [[ ! -f "${BASEDIR}"/src/"${LIB_NAME}"/configure ]] || [[ ${RECONF_libuuid} -eq 1 ]]; then
  autoreconf_library "${LIB_NAME}" 1>>"${BASEDIR}"/build.log 2>&1 || return 1
fi

./configure \
  --prefix="${LIB_INSTALL_PREFIX}" \
  --with-pic \
  --with-sysroot="${ANDROID_SYSROOT}" \
  --enable-static \
  --disable-shared \
  --disable-fast-install \
  --host="${HOST}" || return 1


# Patch gen_uuid.c to remove flock which is not available on Android NDK
find "${BASEDIR}/src/${LIB_NAME}" -name "gen_uuid.c" -exec sed -i 's/while (flock(state_fd, LOCK_EX) < 0)/while (0)/g' {} \;
find "${BASEDIR}/src/${LIB_NAME}" -name "gen_uuid.c" -exec sed -i 's/flock(state_fd, LOCK_UN);//g' {} \;
echo "INFO: gen_uuid.c flock patch applied" 1>>"${BASEDIR}"/build.log 2>&1

make -j$(get_cpu_count) || return 1



make install || return 1

# CREATE PACKAGE CONFIG MANUALLY
create_uuid_package_config "1.0.3" || return 1
