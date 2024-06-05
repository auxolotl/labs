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
          name: values: let
            currentPath = path ++ [name];
            isSingleValue = builtins.length values == 1;
            isComplete =
              predicate currentPath
              (builtins.elemAt values 1)
              (builtins.elemAt values 0);
          in
            if isSingleValue
            then builtins.elemAt values 0
            else if isComplete
            then builtins.elemAt values 1
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
      name = builtins.head path;
      rest = builtins.tail path;
    in
      if path == []
      then target
      else if target ? ${name}
      then lib.attrs.select rest fallback target.${name}
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
      then lib.attrs.select path null target
      else error;

    ## Create a nested attribute set with a value as the leaf node.
    ##
    ## @type (List String) -> a -> Attrs
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
      name = builtins.head path;
      rest = builtins.tail path;
    in
      if path == []
      then true
      else if target ? ${name}
      then lib.attrs.has rest target.${name}
      else false;

    ## Depending on a given condition, either use the given value or an empty
    ## attribute set.
    ##
    ## @type Attrs a b => Bool -> a -> a | b
    when = condition: value:
      if condition
      then value
      else {};

    ## Map an attribute set's names and values to a list.
    ##
    ## @type Any a => (String -> Any -> a) -> Attrs -> List a
    mapToList = f: target:
      builtins.map (name: f name target.${name}) (builtins.attrNames target);

    ## Map an attribute set recursively. Only non-set leaf nodes will be mapped.
    ##
    ## @type (List String -> Any -> Any) -> Attrs -> Attrs
    mapRecursive = f: target:
      lib.attrs.mapRecursiveWhen (lib.fp.const true) f target;

    ## Map an attribute set recursively when a given predicate returns true.
    ## Only leaf nodes according to the predicate will be mapped.
    ##
    ## @type (Attrs -> Bool) -> (List String -> Any -> Any) -> Attrs -> Attrs
    mapRecursiveWhen = predicate: f: target: let
      process = path:
        builtins.mapAttrs (
          name: value:
            if builtins.isAttrs value && predicate value
            then process (path ++ [name]) value
            else f (path ++ [name]) value
        );
    in
      process [] target;

    ## Filter an attribute set by a given predicate. The filter is only performed
    ## on the base level of the attribute set.
    ##
    ## @type (String -> Any -> Bool) -> Attrs -> Attrs
    filter = predicate: target: let
      names = builtins.attrNames target;
      process = name: let
        value = target.${name};
      in
        if predicate name value
        then [{inherit name value;}]
        else [];
      valid = builtins.concatMap process names;
    in
      builtins.listToAttrs valid;

    ## Generate an attribute set from a list of names and a function that is
    ## applied to each name.
    ##
    ## @type (List String) -> (String -> Any) -> Attrs
    generate = names: f: let
      pairs =
        builtins.map (name: {
          inherit name;
          value = f name;
        })
        names;
    in
      builtins.listToAttrs pairs;
  };
}
