: ${MODE:="debug"}
: ${SYSROOT:="/home/yanfa/ubuntu20-arm64-sysroot"}

export PATH=$PATH:/opt/flutter-elinux/bin
flutter-elinux pub get
flutter-elinux build elinux \
     --target-arch=arm64 \
     --target-backend-type=gbm \
     --target-compiler-triple=aarch64-linux-gnu \
     --target-sysroot=$SYSROOT \
     --$MODE  -v
