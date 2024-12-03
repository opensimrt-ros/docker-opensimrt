#!/usr/bin/env bash
set -e
git clone -b aarch64 https://github.com/mysablehats/x-IMU3-Software.git ximu3
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
export PATH=$HOME/.cargo/bin:$PATH

##did they change this or did it never work?
rm -f /usr/bin/cc /usr/bin/c++ && \
ln -s /usr/bin/clang /usr/bin/cc && \
ln -s /usr/bin/clang++ /usr/bin/c++

pushd ximu3/x-IMU3-API/Rust
cargo build --release
# actually from here all we care about is the library which is at
# /ximu3/x-IMU3-API/Rust/target/release
#
# libximu3.a
#sleep 10
#ls -laR /ximu3/x-IMU3-API/Rust/target/release
#cp /ximu3/x-IMU3-API/Rust/target/release/libximu3.a /libximu3.a

#find /ximu -name "*.a" 
#mv /ximu3/x-IMU3-API/Rust/target/release/libximu3.a /libximu3.a
#rm -rf /ximu3

