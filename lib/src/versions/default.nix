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
  };
}
