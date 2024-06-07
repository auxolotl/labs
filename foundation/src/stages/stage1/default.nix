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
      };

      extras = {
        stage1 = {
          mes = {
            src = stage1.mes.src;
            libs = {
              prefix = stage1.mes.libs.prefix;
            };
          };
          tinycc = {
            boot = {
              src = stage1.tinycc.boot.src;
              tarball = builtins.fetchurl {
                url = "https://gitlab.com/janneke/tinycc/-/archive/${stage1.tinycc.boot.revision}/tinycc-${stage1.tinycc.boot.revision}.tar.gz";
                sha256 = "1a0cw9a62qc76qqn5sjmp3xrbbvsz2dxrw21lrnx9q0s74mwaxbq";
              };
            };
          };
        };
      };
    };
  };
}
