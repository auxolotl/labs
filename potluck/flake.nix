{
  inputs = {
    lib = {
      url = "path:../lib";
    };

    foundation = {
      url = "path:../foundation";
      inputs.lib.follows = "lib";
    };
  };

  outputs = inputs: let
    exports = import ./default.nix {
      lib = inputs.lib.lib;
      foundation = inputs.foundation.packages.i686-linux;
    };
  in
    exports;
}
