lib: {
  points = {
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

    ## Calculate the fixed point of a function. This will evaluate the function `f`
    ## until its result settles (or Nix's recursion limit is reached). This allows
    ## us to define recursive functions without worrying about the order of their
    ## definitions. Unlike `fix`, the resulting value is also given a `__unfix__`
    ## attribute that is set to the original function passed to `fix'`.
    ##
    ## FIXME: The below type annotation should include a mention of the `__unfix__`
    ## value.
    ##
    ## @type (a -> a) -> a
    fix' = f: let
      x =
        f x
        // {
          __unfix__ = f;
        };
    in
      x;
  };
}
