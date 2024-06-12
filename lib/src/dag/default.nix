lib: {
  dag = {
    validate = {
      ## Check that a value is a DAG entry.
      ##
      ## @type a -> Bool
      entry = value:
        (value ? value)
        && (value ? before)
        && (value ? after);

      ## Check that a value is a DAG.
      ##
      ## @type a -> Bool
      graph = value: let
        isContentsValid = builtins.all lib.dag.validate.entry (builtins.attrValues value);
      in
        builtins.isAttrs value
        && isContentsValid;
    };

    sort = {
      ## Apply a topological sort to a DAG.
      ##
      ## @type Dag a -> { result :: List a } | { cycle :: List a, loops :: List a }
      topographic = graph: let
        getEntriesBefore = graph: name: let
          before =
            lib.attrs.filter
            (key: value: builtins.elem name value.before)
            graph;
        in
          builtins.attrNames before;

        normalize = name: value: {
          inherit name;
          value = value.value;
          after = value.after ++ (getEntriesBefore graph name);
        };

        normalized = builtins.mapAttrs normalize graph;

        entries = builtins.attrValues normalized;

        isBefore = a: b: builtins.elem a.name b.after;

        sorted = lib.lists.sort.topographic isBefore entries;
      in
        if sorted ? result
        then {
          result =
            builtins.map (value: {
              name = value.name;
              value = value.value;
            })
            sorted.result;
        }
        else sorted;
    };

    ## Map over the entries in a DAG and modify their values.
    ##
    ## @type (String -> a -> b) -> Dag a -> Dag b
    map = f:
      builtins.mapAttrs
      (name: value:
        value
        // {
          value = f name value.value;
        });

    entry = {
      ## Create a new DAG entry.
      ##
      ## @type List String -> List String -> a -> { before :: List String, after :: List String, value :: a }
      between = before: after: value: {
        inherit before after value;
      };

      ## Create a new DAG entry with no dependencies.
      ##
      ## @type a -> { before :: List String, after :: List String, value :: a }
      anywhere = lib.dag.entry.between [] [];

      ## Create a new DAG entry that occurs before other entries.
      ##
      ## @type List String -> a -> { before :: List String, after :: List String, value :: a }
      before = before: lib.dag.entry.between before [];

      ## Create a new DAG entry that occurs after other entries.
      ##
      ## @type List String -> a -> { before :: List String, after :: List String, value :: a }
      after = lib.dag.entry.between [];
    };

    entries = {
      ## Create a DAG from a list of entries, prefixed with a tag.
      ##
      ## @type String -> List String -> List String -> List a -> Dag a
      between = tag: let
        process = i: before: after: entries: let
          name = "${tag}-${builtins.toString i}";
          entry = builtins.head entries;
          rest = builtins.tail entries;
        in
          if builtins.length entries == 0
          then {}
          else if builtins.length entries == 1
          then {
            "${name}" = lib.dag.entry.between before after entry;
          }
          else
            {
              "${name}" = lib.dag.entry.after after entry;
            }
            // (
              process (i + 1) before [name] rest
            );
      in
        process 0;

      ## Create a DAG from a list of entries, prefixed with a tag, that can occur anywhere.
      ##
      ## @type String -> List a -> Dag a
      anywhere = tag: lib.dag.entries.between tag [] [];

      ## Create a DAG from a list of entries, prefixed with a tag, that occurs before other entries.
      ##
      ## @type String -> List String -> List a -> Dag a
      before = tag: before: lib.dag.entries.between tag before [];

      ## Create a DAG from a list of entries, prefixed with a tag, that occurs after other entries.
      ##
      ## @type String -> List String -> List a -> Dag a
      after = tag: lib.dag.entries.between tag [];
    };
  };
}
