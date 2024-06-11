{
  lib,
  config,
}: let
  cfg = config.lib;
in {
  includes = [
    ./options.nix
    ./types.nix
  ];

  freeform = lib.types.any;

  options = {
    lib = lib.options.create {
      type = lib.types.attrs.any;
      default.value = {};
      description = "An attribute set of values to be added to `lib`.";
      apply = value: lib.extend (final: prev: prev.attrs.mergeRecursive prev value);
    };
  };
}
