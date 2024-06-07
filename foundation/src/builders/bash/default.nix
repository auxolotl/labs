{
  lib,
  config,
}: let
  system = config.aux.system;
  builders = config.aux.foundation.builders;

  stage0 = config.aux.foundation.stages.stage0;
in {
  includes = [
    ./boot.nix
  ];

  options.aux.foundation.builders.bash = {
    # TODO: Bash builder that isn't boot.
  };

  config = {
    aux.foundation.builders.bash = {
    };
  };
}
