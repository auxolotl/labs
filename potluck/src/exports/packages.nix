{
  config,
  lib,
}: let
in {
  options = {
    exports.packages = lib.options.create {
      default.value = {};
    };

    exported.packages = lib.options.create {
      default.value = {};
    };
  };

  config = {
    exported.packages = {};
  };
}
