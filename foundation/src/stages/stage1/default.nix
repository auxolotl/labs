{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage1;
in {
  includes = [
    ./nyacc
    # ./mes
  ];

  config = {
    exports = {
      packages = {
        stage1-nyacc = config.aux.foundation.stages.stage1.nyacc.package;
      };
    };
  };
}
