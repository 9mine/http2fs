FROM i386/ubuntu:bionic AS builder

WORKDIR /usr
RUN export DEBIAN_FRONTEND=noninteractive
RUN apt update && apt-get install -y git build-essential libfuse-dev pkg-config python3-pip jq curl


ENV INFERNO_BRANCH=master
ENV INFERNO_COMMIT=ed97654bd7a11d480b44505c8300d06b42e5fefe
  

RUN git clone --depth 1 -b ${INFERNO_BRANCH} https://bitbucket.org/inferno-os/inferno-os 
WORKDIR /usr/inferno-os


ENV PATH=$PATH:/usr/inferno-os/Linux/386/bin

RUN \
  export PATH=$PATH:/usr/inferno-os/Linux/386/bin                             \
  export MKFLAGS='SYSHOST=Linux OBJTYPE=386 CONF=emu-g ROOT='/usr/inferno-os; \
  /usr/inferno-os/Linux/386/bin/mk $MKFLAGS mkdirs                            && \
  /usr/inferno-os/Linux/386/bin/mk $MKFLAGS emuinstall                        && \
  /usr/inferno-os/Linux/386/bin/mk $MKFLAGS emunuke



RUN curl -Lo /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/3.4.0/yq_linux_386 && \
  chmod +x /usr/local/bin/yq
#RUN pip3 install jinja2-cli install jinja2-ansible-filters
WORKDIR /tmp
RUN git clone --depth 1 -b youtubefs https://github.com/metacoma/execfuse
WORKDIR /tmp/execfuse
RUN make execfuse-static
WORKDIR wrapper
#RUN cat examples/youtubefs.yml | ./wrapper.sh
WORKDIR /usr



FROM i386/ubuntu:bionic
ENV ROOT_DIR /usr/inferno-os

RUN apt-get update && apt-get install -y curl jq

COPY --from=builder /usr/inferno-os/Linux/386/bin/emu-g /usr/bin
COPY --from=builder /usr/inferno-os/dis $ROOT_DIR/dis
COPY --from=builder /usr/inferno-os/appl $ROOT_DIR/appl
COPY --from=builder /usr/inferno-os/lib $ROOT_DIR/lib
COPY --from=builder /usr/inferno-os/module $ROOT_DIR/module
COPY --from=builder /usr/inferno-os/usr $ROOT_DIR/usr

COPY --from=builder /tmp/execfuse/execfuse-static /usr/bin

RUN mkdir -p /usr/inferno-os/host/http2fs
ADD http2fs /http2fs

ADD files/inferno/profile /usr/inferno-os/lib/sh/profile
ADD entrypoint.sh /usr/local/bin/entrypoint.sh


ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
