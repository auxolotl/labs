lib: {
  versions = {
    ## Check if a version is greater than another.
    ##
    ## @type String -> String -> Bool
    gt = first: second: builtins.compareVersions first second == -1;

    ## Check if a version is less than another.
    ##
    ## @type String -> String -> Bool
    lt = first: second: builtins.compareVersions first second == 1;

    ## Check if a version is equal to another.
    ##
    ## @type String -> String -> Bool
    eq = first: second: builtins.compareVersions first second == 0;

    ## Get the major version from a version string.
    ##
    ## @type String -> String
    major = version: let
      parts = builtins.splitVersion version;
    in
      builtins.elemAt parts 0;

    ## Get the minor version from a version string.
    ##
    ## @type String -> String
    minor = version: let
      parts = builtins.splitVersion version;
    in
      builtins.elemAt parts 1;

    ## Get the patch version from a version string.
    ##
    ## @type String -> String
    patch = version: let
      parts = builtins.splitVersion version;
    in
      builtins.elemAt parts 2;
  };
}
