{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage1;
in {
  includes = [
    ./mes
  ];

  config = {
    exports = {
      packages = {
      };
    };
  };
}
