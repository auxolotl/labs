{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage1.gnutar;

  builders = config.aux.foundation.builders;

  stage1 = config.aux.foundation.stages.gnutar;
in {
  includes = [
    ./boot.nix
  ];

  options.aux.foundation.stages.stage1.gnutar = {
    meta = {
      description = lib.options.create {
        type = lib.types.string;
        description = "Description for the package.";
        default.value = "GNU implementation of the `tar' archiver";
      };

      homepage = lib.options.create {
        type = lib.types.string;
        description = "Homepage for the package.";
        default.value = "https://www.gnu.org/software/tar";
      };

      license = lib.options.create {
        # TODO: Add a proper type for licenses.
        type = lib.types.attrs.any;
        description = "License for the package.";
        default.value = lib.licenses.gpl3Plus;
      };

      platforms = lib.options.create {
        type = lib.types.list.of lib.types.string;
        description = "Platforms the package supports.";
        default.value = ["x86_64-linux" "aarch64-linux" "i686-linux"];
      };

      mainProgram = lib.options.create {
        type = lib.types.string;
        description = "The main program of the package.";
        default.value = "tar";
      };
    };
  };
}