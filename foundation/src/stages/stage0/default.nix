{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage0;

  system = config.aux.system;
  builders = config.aux.foundation.builders;

  architecture =
    if system == "x86_64-linux"
    then "AMD64"
    else if system == "aarch64-linux"
    then "AArch64"
    else if system == "i686-linux"
    then "x86"
    else builtins.throw "Unsupported system for stage0: ${system}";
in {
  includes = [
    ./phases/phase00.nix
    ./phases/phase01.nix
    ./phases/phase02.nix
    ./phases/phase03.nix
    ./phases/phase04.nix
    ./phases/phase05.nix
    ./phases/phase06.nix
    ./phases/phase07.nix
    ./phases/phase08.nix
    ./phases/phase09.nix
    ./phases/phase10.nix
    ./phases/phase11.nix
    ./phases/phase12.nix

    ./mescc-tools
    ./mescc-tools-extra
    ./kaem
  ];

  config = {
    exports = {
      packages = {
        stage0-hex0 = cfg.hex0.package;

        stage0-hex1 = cfg.hex1.package;

        stage0-hex2-0 = cfg.hex2-0.package;

        stage0-catm = cfg.catm.package;

        stage0-M0 = cfg.M0.package;

        stage0-cc_arch = cfg.cc_arch.package;

        stage0-M2 = cfg.M2.package;

        stage0-blood-elf = cfg.blood-elf.package;

        stage0-M1-0 = cfg.M1-0.package;

        stage0-hex2-1 = cfg.hex2-1.package;

        stage0-M1 = cfg.M1.package;

        stage0-hex2 = cfg.hex2.package;

        stage0-kaem-unwrapped = cfg.kaem-unwrapped.package;

        stage0-mescc-tools = cfg.mescc-tools.package;

        stage0-mescc-tools-extra = cfg.mescc-tools-extra.package;

        stage0-kaem = cfg.kaem.package;
      };
    };
  };
}
