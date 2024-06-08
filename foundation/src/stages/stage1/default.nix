{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage1;

  stage1 = config.aux.foundation.stages.stage1;
in {
  includes = [
    ./nyacc
    ./mes
    ./ln-boot
    ./tinycc
    ./gnupatch
    ./gnumake
    ./coreutils
    ./heirloom
    ./bash

    ./gnused
    ./gnugrep
    ./gnutar
    ./gzip
    ./musl
    ./gawk
    ./xz
    ./diffutils
    ./binutils
    ./findutils
    ./bzip2
    ./gcc
    ./gnum4
    ./bison
    ./linux-headers
    ./zlib
    ./python
  ];

  config = {
    exports = {
      packages = {
        # These packages are built using Kaem.
        stage1-nyacc = stage1.nyacc.package;
        stage1-mes = stage1.mes.compiler.package;
        stage1-mes-libs = stage1.mes.libs.package;
        stage1-ln-boot = stage1.ln-boot.package;
        stage1-mes-libc = stage1.mes.libc.package;
        stage1-tinycc-boot = stage1.tinycc.boot.compiler.package;
        stage1-tinycc-boot-libs = stage1.tinycc.boot.libs.package;
        stage1-tinycc-mes = stage1.tinycc.mes.compiler.package;
        stage1-tinycc-mes-libs = stage1.tinycc.mes.libs.package;
        stage1-gnupatch = stage1.gnupatch.package;
        stage1-gnumake-boot = stage1.gnumake.boot.package;
        stage1-coreutils-boot = stage1.coreutils.boot.package;
        stage1-heirloom-devtools = stage1.heirloom.devtools.package;
        stage1-bash-boot = stage1.bash.boot.package;

        # These packages are built using Bash v2.
        stage1-gnused-boot = stage1.gnused.boot.package;
        stage1-gnugrep = stage1.gnugrep.package;
        stage1-gnutar-boot = stage1.gnutar.boot.package;
        stage1-gzip = stage1.gzip.package;
        stage1-musl-boot = stage1.musl.boot.package;
        stage1-tinycc-musl = stage1.tinycc.musl.compiler.package;
        stage1-tinycc-musl-libs = stage1.tinycc.musl.libs.package;
        stage1-gawk-boot = stage1.gawk.boot.package;
        stage1-gnused = stage1.gnused.package;
        stage1-gnumake = stage1.gnumake.package;
        stage1-gnutar-musl = stage1.gnutar.musl.package;
        stage1-gawk = stage1.gawk.package;
        stage1-xz = stage1.xz.package;
        stage1-diffutils = stage1.diffutils.package;
        stage1-coreutils = stage1.coreutils.package;
        stage1-binutils = stage1.binutils.package;
        stage1-findutils = stage1.findutils.package;
        stage1-heirloom = stage1.heirloom.package;
        stage1-bash = stage1.bash.package;

        # These packages are built using Bash v5
        stage1-gcc-46 = stage1.gcc.v46.package;
        stage1-musl = stage1.musl.package;
        stage1-bzip2 = stage1.bzip2.package;
        stage1-gcc-46-cxx = stage1.gcc.v46.cxx.package;
        stage1-gnutar = stage1.gnutar.package;
        stage1-gcc-8 = stage1.gcc.v8.package;
        stage1-gcc = stage1.gcc.package;
        stage1-gnum4 = stage1.gnum4.package;
        stage1-bison = stage1.bison.package;
        stage1-linux-headers = stage1.linux-headers.package;
        stage1-zlib = stage1.zlib.package;
        stage1-python = stage1.python.package;
      };

      extras = {
        stage1 = {
          mes = {
            src = stage1.mes.src;
            libs = {
              prefix = stage1.mes.libs.prefix;
            };
          };
        };
      };
    };
  };
}
