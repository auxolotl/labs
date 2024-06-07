{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage1.mes;

  system = config.aux.system;
  builders = config.aux.foundation.builders;
in {
  includes = [
    ./compiler.nix
    ./libs.nix
    ./libc.nix
  ];

  options.aux.foundation.stages.stage1.mes = {
    src = lib.options.create {
      type = lib.types.package;
      description = "Source for the package.";
    };

    version = lib.options.create {
      type = lib.types.string;
      description = "Version of the package.";
    };
  };

  config = {
    aux.foundation.stages.stage1.mes = {
      version = "0.25";

      src = builtins.fetchurl {
        url = "https://ftpmirror.gnu.org/mes/mes-${cfg.version}.tar.gz";
        sha256 = "MlJQs1Z+2SA7pwFhyDWvAQeec+vtl7S1u3fKUAuCiUA=";
      };
    };
  };
}
