{
  lib,
  config,
}: let
  stage2 = config.aux.foundation.stages.stage2;
in {
  includes = [
    ./bash
    ./gnumake
    ./binutils
    ./coreutils
    ./bzip2
    ./diffutils
    ./findutils
    ./gawk
    ./gnugrep
    ./gnupatch
  ];

  config = {
    exports = {
      packages = {
        stage2-bash = stage2.bash.package;
        stage2-gnumake = stage2.gnumake.package;
        stage2-binutils = stage2.binutils.package;
        stage2-coreutils = stage2.coreutils.package;
        stage2-bzip2 = stage2.bzip2.package;
        stage2-diffutils = stage2.diffutils.package;
        stage2-findutils = stage2.findutils.package;
        stage2-gawk = stage2.gawk.package;
        stage2-gnugrep = stage2.gnugrep.package;
        stage2-gnupatch = stage2.gnupatch.package;
      };
    };
  };
}
