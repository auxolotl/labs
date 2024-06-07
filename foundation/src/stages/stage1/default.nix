{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage1;

  stage1 = config.aux.foundation.stages.stage1;
in {
  includes = [
    # These packages are built using Kaem.
    ./nyacc
    ./mes
    ./ln-boot
    ./tinycc # With the exception of `tinycc-musl` which uses Bash.
    ./gnupatch
    ./gnumake
    ./coreutils
    ./bash

    # These packages are built using Bash v2.
    ./gnused
    ./gnugrep
    ./gnutar
    ./gzip
    ./musl
  ];

  config = {
    exports = {
      packages = {
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
        stage1-gnumake = stage1.gnumake.package;
        stage1-coreutils-boot = stage1.coreutils.boot.package;
        stage1-bash-boot = stage1.bash.boot.package;

        stage1-gnused-boot = stage1.gnused.boot.package;
        stage1-gnugrep = stage1.gnugrep.package;
        stage1-gnutar-boot = stage1.gnutar.boot.package;
        stage1-gzip = stage1.gzip.package;
        stage1-musl-boot = stage1.musl.boot.package;
        stage1-tinycc-musl = stage1.tinycc.musl.compiler.package;
        stage1-tinycc-musl-libs = stage1.tinycc.musl.libs.package;
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
