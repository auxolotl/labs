lib: {
  lists = {
    from = {
      # TODO: Document this.
      any = value:
        if builtins.isList value
        then value
        else [value];
    };

    sort = {
      ## Perform a natural sort on a list of strings.
      ##
      ## @type List -> List
      natural = list: let
        vectorize = string: let
          serialize = part:
            if builtins.isList part
            then lib.strings.into.int (builtins.head part)
            else part;
          parts = lib.strings.split "(0|[1-9][0-9]*)" string;
        in
          builtins.map serialize parts;
        prepared = builtins.map (value: [(vectorize value) value]) list;
        isLess = a: b: (lib.lists.compare lib.numbers.compare (builtins.head a) (builtins.head b)) < 0;
      in
        builtins.map (x: builtins.elemAt x 1) (builtins.sort isLess prepared);
    };

    # TODO: Document this.
    mapWithIndex = f: list:
      builtins.genList
      (i: f i (builtins.elemAt list i))
      (builtins.length list);

    # TODO: Document this.
    mapWithIndex1 = f: list:
      builtins.genList
      (i: f (i + 1) (builtins.elemAt list i))
      (builtins.length list);

    ## Compare two lists.
    ##
    ## @type (a -> b -> Int) -> List a -> List b -> Int
    compare = compare: a: b: let
      result = compare (builtins.head a) (builtins.head b);
    in
      if a == []
      then
        if b == []
        then 0
        else -1
      else if b == []
      then 1
      else if result == 0
      then lib.lists.compare compare (builtins.tail a) (builtins.tail b)
      else result;

    ## Get the last element of a list.
    ##
    ## @type List a -> a
    last = list:
      assert lib.assertMsg (list != []) "List cannot be empty";
        builtins.elemAt list (builtins.length list - 1);

    ## Slice part of a list to create a new list.
    ##
    ## @type Int -> Int -> List -> List
    slice = start: count: list: let
      listLength = builtins.length list;
      resultLength =
        if start >= listLength
        then 0
        else if start + count > listLength
        then listLength - start
        else count;
    in
      builtins.genList
      (i: builtins.elemAt list (start + i))
      resultLength;

    ## Take the first n elements of a list.
    ##
    ## @type Int -> List -> List
    take = lib.lists.slice 0;

    ## Drop the first n elements of a list.
    ##
    ## @type Int -> List -> List
    drop = count: list: let
      listLength = builtins.length list;
    in
      lib.lists.slice count listLength list;

    ## Reverse a list.
    ##
    ## @type List -> List
    reverse = list: let
      length = builtins.length list;
      create = i: builtins.elemAt list (length - i - 1);
    in
      builtins.genList create length;

    ## Interleave a list with a separator.
    ##
    ## @type Separator -> List -> List
    intersperse = separator: list: let
      length = builtins.length list;
    in
      if length < 2
      then list
      else
        builtins.tail (
          builtins.concatMap
          (part: [separator part])
          list
        );

    ## Create a list of integers from a starting number to an ending
    ## number. This *includes* the ending number as well.
    ##
    ## @type Int -> Int -> List
    range = start: end:
      if start > end
      then []
      else builtins.genList (i: start + i) (end - start + 1);

    ## Depending on a given condition, either use the given value (as
    ## a list) or an empty list.
    ##
    ## @type Attrs a b => Bool -> a -> a | b
    when = condition: value:
      if condition
      then
        if builtins.isList value
        then value
        else [value]
      else [];

    # TODO: Document this.
    count = predicate: list:
      builtins.foldl' (
        total: value:
          if predicate value
          then total + 1
          else total
      )
      0
      list;

    # TODO: Document this.
    unique = list: let
      filter = result: value:
        if builtins.elem value result
        then result
        else result ++ [value];
    in
      builtins.foldl' filter [] list;
  };
}
