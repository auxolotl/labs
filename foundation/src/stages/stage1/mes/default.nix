{
  lib,
  config,
}: let
  system = config.aux.system;
  builders = config.aux.foundation.builders;
in {
  config = {
    aux.foundation.stages.stage0.mes = {
    };
  };
}
