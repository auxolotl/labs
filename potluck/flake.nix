{
  inputs = {
    # TODO: When this project is moved to its own repository we will want to add
    # inputs for the relevant dependencies.
    # lib = {
    #   url = "path:../lib";
    # };
    # foundation = {
    #   url = "path:../foundation";
    #   inputs.lib.follows = "lib";
    # };
  };

  outputs = inputs: let
    exports = import ./default.nix {
      # lib = inputs.lib.lib;
      # foundation = inputs.foundation.packages.i686-linux;
    };
  in
    exports;
}
