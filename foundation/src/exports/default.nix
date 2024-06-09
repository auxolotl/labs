{
  lib,
  config,
}: let
  options = {
    packages = lib.options.create {
      default.value = {};

      type = lib.types.attrs.of lib.types.derivation;
    };

    extras = lib.options.create {
      default.value = {};
      type = lib.types.attrs.any;
    };
  };
in {
  options = {
    exports = {
      inherit (options) packages extras;

      resolved = {
        inherit (options) packages extras;
      };
    };
  };

  config = {
    exports.resolved = {
      packages =
        builtins.mapAttrs (
          name: value:
            lib.attrs.filter
            (
              name: value:
                if value ? meta && value.meta ? platforms
                then builtins.elem config.aux.system value.meta.platforms
                else true
            )
            value
        )
        config.exports.packages;

      extras = config.exports.extras;
    };
  };
}
