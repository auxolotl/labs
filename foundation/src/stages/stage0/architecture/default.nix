{
  lib,
  config,
}: let
  system = config.aux.system;

  architecture =
    if system == "x86_64-linux"
    then "AMD64"
    else if system == "aarch64-linux"
    then "AArch64"
    else if system == "i686-linux"
    then "x86"
    else builtins.throw "Unsupported system for stage0: ${system}";
in {
  options.aux.foundation.stages.stage0.architecture = {
    base = lib.options.create {
      type = lib.types.string;
      description = "The architecture to use for the source.";
      default = {
        value = architecture;
        text = ''"AMD64" or "AArch64" or "x86"'';
      };
    };

    m2libc = lib.options.create {
      type = lib.types.string;
      description = "The architecture to use for the M2libc source.";
      default = {
        value = lib.strings.lower architecture;
        text = ''"amd64" or "aarch64" or "x86"'';
      };
    };
  };
}
