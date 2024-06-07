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
