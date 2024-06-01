lib: {
  attrs = {
    ## Merge two attribute sets at the base level.
    ##
    ## @type Attrs a b c => a -> b -> c
    merge = x: y: x // y;

    ## Merge two attribute sets recursively until a given predicate returns true.
    ## Any values that are _not_ attribute sets will be overridden with the value
    ## from `y` first if it exists and then `x` otherwise.
    ##
    ## @type Attrs a b c => (String -> Any -> Any -> Bool) -> a -> b -> c
    mergeRecursiveUntil = predicate: x: y: let
      process = path:
        builtins.zipAttrsWith (
          key: values: let
            currentPath = path ++ [key];
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
    mergeRecursive =
      lib.attrs.mergeRecursiveUntil
      (path: x: y:
        !(builtins.isAttrs x && builtins.isAttrs y));

    ## Get a value from an attribute set by a path. If the path does not exist,
    ## a fallback value will be returned instead.
    ##
    ## @type (List String) -> a -> Attrs -> a | b
    select = path: fallback: target: let
      key = builtins.head path;
      rest = builtins.tail path;
    in
      if path == []
      then target
      else if target ? ${key}
      then lib.attrs.select rest fallback target.${key}
      else fallback;

    ## Get a value from an attribute set by a path. If the path does not exist,
    ## an error will be thrown.
    ##
    ## @type (List String) -> Attrs -> a
    selectOrThrow = path: target: let
      pathAsString = builtins.concatStringsSep "." path;
      error = builtins.throw "Path not found in attribute set: ${pathAsString}";
    in
      if lib.attrs.has path target
      then lib.attrs.select path target
      else error;

    # TODO: Document this.
    set = path: value: let
      length = builtins.length path;
      process = depth:
        if depth == length
        then value
        else {
          ${builtins.elemAt path depth} = process (depth + 1);
        };
    in
      process 0;

    ## Check if a path exists in an attribute set.
    ##
    ## @type (List String) -> Attrs -> Bool
    has = path: target: let
      key = builtins.head path;
      rest = builtins.tail path;
    in
      if path == []
      then true
      else if target ? ${key}
      then lib.attrs.has rest target.${key}
      else false;

    ## Depending on a given condition, either use the given value or an empty
    ## attribute set.
    ##
    ## @type Attrs a b => Bool -> a -> a | b
    when = condition: value:
      if condition
      then value
      else {};

    ## Map an attribute set's keys and values to a list.
    ##
    ## @type Any a => (String -> Any -> a) -> Attrs -> List a
    mapToList = f: target:
      builtins.map (key: f key target.${key}) (builtins.attrNames target);

    # TODO: Document this.
    mapRecursive = f: target:
      lib.attrs.mapRecursiveWhen (lib.fp.const true) f target;

    # TODO: Document this.
    mapRecursiveWhen = predicate: f: target: let
      process = path:
        builtins.mapAttrs (
          key: value:
            if builtins.isAttrs value && predicate value
            then process (path ++ [key]) value
            else f (path ++ [key]) value
        );
    in
      process [] target;

    # TODO: Document this.
    filter = predicate: target: let
      keys = builtins.attrNames target;
      process = key: let
        value = target.${key};
      in
        if predicate key value
        then [
          {
            name = key;
            value = value;
          }
        ]
        else [];
      valid = builtins.concatMap process keys;
    in
      builtins.listToAttrs valid;
  };
}
