: ${MODE:="debug"}
: ${SYSROOT:="/home/yanfa/ubuntu21-arm64-sysroot"}
# TOOLCHAIN_FILE="$(cd "$(dirname "$0")" && pwd)/arm64-toolchain.cmake"
# export CMAKE_SYSROOT="$SYSROOT"
# export CMAKE_C_COMPILER_TARGET="$TRIPLE"
# export CMAKE_CXX_COMPILER_TARGET="$TRIPLE"
# export CMAKE_ASM_COMPILER_TARGET="$TRIPLE"
# export CMAKE_FIND_ROOT_PATH="$SYSROOT"
# export CMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER
# export CMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY
# export CMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY
# export CC=clang
# export CXX=clang
# export CMAKE_TOOLCHAIN_FILE="$TOOLCHAIN_FILE"  
export CMAKE_GENERATOR=Ninja
export PATH=$PATH:/opt/flutter-elinux/bin
flutter-elinux pub get
flutter-elinux build elinux \
     --target-arch=arm64 \
     --target-backend-type=gbm \
     --target-compiler-triple=aarch64-linux-gnu \
     --target-sysroot=$SYSROOT \
     --$MODE  -v
     #--target-compiler-flags=--sysroot=$SYSROOT \
     #--system-include-directories=/usr/aarch64-linux-gnu/include/c++/10/aarch64-linux-gnu \
#修复sysroot绝对路径软连接问题
#python3 sysroot-relativelinks.py /home/yanfa/ubuntu21-arm64-sysroot