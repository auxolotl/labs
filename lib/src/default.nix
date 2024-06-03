let
  files = [
    ./attrs
    ./bools
    ./errors
    ./fp
    ./generators
    ./importers
    ./lists
    ./math
    ./modules
    ./numbers
    ./options
    ./packages
    ./paths
    ./points
    ./strings
    ./types
    ./versions
  ];

  libs = builtins.map (f: import f) files;

  ## Calculate the fixed point of a function. This will evaluate the function `f`
  ## until its result settles (or Nix's recursion limit is reached). This allows
  ## us to define recursive functions without worrying about the order of their
  ## definitions.
  ##
  ## @type (a -> a) -> a
  fix = f: let
    x = f x;
  in
    x;

  ## Merge two attribute sets recursively until a given predicate returns true.
  ## Any values that are _not_ attribute sets will be overridden with the value
  ## from `y` first if it exists and then `x` otherwise.
  ##
  ## @type Attrs a b c => (String -> Any -> Any -> Bool) -> a -> b -> c
  mergeAttrsRecursiveUntil = predicate: x: y: let
    process = path:
      builtins.zipAttrsWith (
        name: values: let
          currentPath = path ++ [name];
          isSingleValue = builtins.length values == 1;
          isComplete =
            predicate currentPath
            (builtins.elemAt values 1)
            (builtins.elemAt values 0);
        in
          if isSingleValue || isComplete
          then builtins.elemAt values 0
          else process currentPath values
      );
  in
    process [] [x y];

  ## Merge two attribute sets recursively. Any values that are _not_ attribute sets
  ## will be overridden with the value from `y` first if it exists and then `x`
  ## otherwise.
  ##
  ## @type Attrs a b c => a -> b -> c
  mergeAttrsRecursive =
    mergeAttrsRecursiveUntil
    (path: x: y:
      !(builtins.isAttrs x && builtins.isAttrs y));

  lib = fix (
    self: let
      merge = acc: create:
        mergeAttrsRecursive acc (create self);
    in
      builtins.foldl' merge {} libs
  );
in
  lib
