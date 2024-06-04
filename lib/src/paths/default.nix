lib: {
  paths = {
    into = {
      ## Convert a path into a derivation.
      ##
      ## @type Path -> Derivation
      drv = value: let
        path = builtins.storePath value;
        result = {
          type = "derivation";
          name =
            lib.packages.sanitizeDerivationName
            (builtins.substring 33 (-1) (builtins.baseNameOf path));
          outPath = path;
          outputs = ["out"];
          outputName = "out";
          out = result;
        };
      in
        result;
    };

    validate = {
      ## Check whether a path is contained within the Nix store.
      ##
      ## @type Path -> Bool
      store = value:
        if lib.strings.stringifiable value
        then
          builtins.substring 0 1 (builtins.toString value)
          == "/"
          && builtins.dirOf (builtins.toString value) == builtins.storeDir
        else false;
    };
  };
}
