# This file handles creating all of the exports for this project and is not
# exported itself.
{
  lib,
  config,
}: let
in {
  config = {
    exports = {
      modules = import ./modules.nix;
    };
  };
}
