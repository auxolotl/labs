{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage1.musl;

  builders = config.aux.foundation.builders;

  stage1 = config.aux.foundation.stages.musl;
in {
  includes = [
    ./boot.nix
  ];

  options.aux.foundation.stages.stage1.musl = {
    meta = {
      description = lib.options.create {
        type = lib.types.string;
        description = "Description for the package.";
        default.value = "An efficient, small, quality libc implementation";
      };

      homepage = lib.options.create {
        type = lib.types.string;
        description = "Homepage for the package.";
        default.value = "https://musl.libc.org";
      };

      license = lib.options.create {
        # TODO: Add a proper type for licenses.
        type = lib.types.attrs.any;
        description = "License for the package.";
        default.value = lib.licenses.mit;
      };

      platforms = lib.options.create {
        type = lib.types.list.of lib.types.string;
        description = "Platforms the package supports.";
        # TODO: Support more platforms.
        default.value = ["i686-linux"];
      };
    };
  };
}
