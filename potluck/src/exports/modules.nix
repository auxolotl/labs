{
  lib,
  config,
}: let
  cfg = config.exports.modules;

  type = lib.types.one [
    lib.types.path
    (lib.types.attrs.any)
    (lib.types.function lib.types.attrs.any)
  ];
in {
  options = {
    exports = {
      modules = lib.options.create {
        type = lib.types.attrs.of type;
        default.value = {};
        description = "An attribute set of modules to export.";
      };
    };

    exported = {
      modules = lib.options.create {
        type = lib.types.attrs.of type;
        default.value = {};
        description = "An attribute set of modules to export.";
      };
    };
  };

  config = {
    exported.modules = cfg.modules;
  };
}
