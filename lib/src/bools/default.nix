lib: {
  bools = {
    into = {
      string = value:
        if value
        then "true"
        else "false";
    };

    ## Choose between two values based on a condition. When true, the first value
    ## is returned, otherwise the second value is returned.
    ##
    ## @type Bool -> a -> b -> a | b
    when = condition: x: y:
      if condition
      then x
      else y;

    ## Perform a logical AND operation on two values.
    ##
    ## @type Bool -> Bool -> Bool
    and = a: b: a && b;

    ## Perform a logical AND operation on two functions being applied to a value.
    ##
    ## @type (a -> Bool) -> (a -> Bool) -> a -> Bool
    and' = f: g: (
      x: (f x) && (g x)
    );

    ## Perform a logical OR operation on two values.
    ##
    ## @type Bool -> Bool -> Bool
    or = a: b: a || b;

    ## Perform a logical OR operation on two functions being applied to a value.
    ##
    ## @type (a -> Bool) -> (a -> Bool) -> a -> Bool
    or' = f: g: (
      x: (f x) || (g x)
    );

    ## Perform a logical NOT operation on a value.
    ##
    ## @type Bool -> Bool
    not = a: !a;
  };
}
