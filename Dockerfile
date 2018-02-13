FROM argvc/pipenv-alpine-python2

USER root
RUN apk --no-cache add cmake bash automake autoconf pcre-dev bison

# number of concurrent threads during build
# usage: docker build --build-arg PARALLELISM=8 -t name/name .
ARG PARALLELISM=1

# install protobuf
RUN git clone https://github.com/google/protobuf /tmp/protobuf; \
    (cd /tmp/protobuf ; git checkout 80a37e0782d2d702d52234b62dd4b9ec74fd2c95); \
    cmake -Dprotobuf_BUILD_TESTS=OFF -Dprotobuf_BUILD_SHARED_LIBS=ON -H/tmp/protobuf/cmake -B/tmp/protobuf/.build; \
    cmake --build /tmp/protobuf/.build --target install -- -j${PARALLELISM}; \
    ldconfig; \
    rm -rf /tmp/protobuf

# install c-ares
RUN git clone https://github.com/c-ares/c-ares /tmp/c-ares; \
    (cd /tmp/c-ares ; git checkout 3be1924221e1326df520f8498d704a5c4c8d0cce); \
    cmake -H/tmp/c-ares -B/tmp/c-ares/build; \
    cmake --build /tmp/c-ares/build --target install -- -j${PARALLELISM}; \
    ldconfig; \
    rm -rf /tmp/c-ares

# needed by grpc reference to libprotoc.so
ENV LD_LIBRARY_PATH /usr/local/lib64

# install grpc
RUN git clone https://github.com/grpc/grpc /tmp/grpc; \
    (cd /tmp/grpc ; git checkout bfcbad3b86c7912968dc8e64f2121c920dad4dfb); \
    (cd /tmp/grpc ; git submodule update --init third_party/benchmark); \
    cmake -DgRPC_ZLIB_PROVIDER=package -DgRPC_CARES_PROVIDER=package -DgRPC_SSL_PROVIDER=package \
        -DgRPC_PROTOBUF_PROVIDER=package -DgRPC_GFLAGS_PROVIDER=package -DBUILD_SHARED_LIBS=ON -H/tmp/grpc -B/tmp/grpc/.build; \
    cmake --build /tmp/grpc/.build --target install -- -j${PARALLELISM}; \
    ldconfig; \
    rm -rf /tmp/grpc


# install shared_model of iroha
RUN git clone https://github.com/hyperledger/iroha.git /tmp/iroha; \
    (cd /tmp/iroha ; git checkout develop); \
    (cd /tmp/iroha/schema ; protoc -I=./ --python_out=./ ./ ; mv *_pb*.py /usr/local/lib/python2.7); \
    rm -rf /tmp/iroha

USER root
CMD ["/bin/bash"]
