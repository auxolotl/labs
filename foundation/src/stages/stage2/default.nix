{
  lib,
  config,
}: let
  stage2 = config.aux.foundation.stages.stage2;
in {
  includes = [
    ./bash
    ./binutils
    ./bzip2
    ./coreutils
    ./diffutils
    ./findutils
    ./gawk
    ./gcc
    ./gnugrep
    ./gnumake
    ./gnupatch
    ./gnused
    ./gnutar
    ./gzip
  ];

  config = {
    exports = {
      packages = {
        stage2-bash = stage2.bash.package;
        stage2-binutils = stage2.binutils.package;
        stage2-bzip2 = stage2.bzip2.package;
        stage2-coreutils = stage2.coreutils.package;
        stage2-diffutils = stage2.diffutils.package;
        stage2-findutils = stage2.findutils.package;
        stage2-gawk = stage2.gawk.package;
        stage2-gcc = stage2.gcc.package;
        stage2-gnugrep = stage2.gnugrep.package;
        stage2-gnumake = stage2.gnumake.package;
        stage2-gnupatch = stage2.gnupatch.package;
        stage2-gnused = stage2.gnused.package;
        stage2-gnutar = stage2.gnutar.package;
        stage2-gzip = stage2.gzip.package;
      };
    };
  };
}
