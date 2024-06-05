{
  lib,
  config,
}: let
  options = {
    packages = lib.options.create {
      default.value = {};

      type = lib.types.attrs.of lib.types.package;
    };
  };
in {
  options = {
    exports = {
      inherit (options) packages;

      resolved = {
        inherit (options) packages;
      };
    };
  };

  config = {
    exports.resolved =
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
      (builtins.removeAttrs config.exports ["resolved"]);
  };
}
