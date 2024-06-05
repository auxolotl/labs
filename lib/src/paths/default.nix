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

    ## Create a search path from a list of paths.
    ##
    ## @type String -> [String] -> String
    search = target: paths:
      lib.strings.concatMapSep
      ":"
      (path: path + "/" + target)
      (builtins.filter (value: value != null) paths);

    ## Create a search path from a list of packages.
    ##
    ## @type String -> [Package] -> String
    searchFromOutput = output: target: packages:
      lib.paths.search
      target
      (builtins.map (lib.packages.getOutput output) packages);

    ## Create a search path for the binary output of a package.
    ##
    ## @type [Package] -> String
    bin = lib.paths.searchFromOutput "bin" "bin";

    ## Create a search path for the library output of a package.
    ##
    ## @type [Package] -> String
    lib = lib.paths.searchFromOutput "lib" "lib";

    ## Create a search path for the include output of a package.
    ##
    ## @type [Package] -> String
    include = lib.paths.searchFromOutput "dev" "include";
  };
}
