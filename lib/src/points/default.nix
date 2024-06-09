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
    ## @type (a -> a) -> a & { __unfix__ :: (a -> a) }
    fix' = f: let
      x =
        f x
        // {
          __unfix__ = f;
        };
    in
      x;

    ## Extend a function's output with an additional function. This is the basis for
    ## features like overlays.
    ##
    ## @type (a -> b -> c) -> (a -> b) -> a -> b & c
    extends = g: f: self: let
      previous = f self;
      next = g self previous;
    in
      previous // next;

    ## Add an `extend` method to the result of a function.
    ##
    ## @type (a -> b) -> b & { extend :: (a -> b -> c) -> b & c }
    withExtend = f: let
      create = self:
        (f self)
        // {
          extend = g: lib.points.withExtend (lib.points.extends g f);
        };
    in
      lib.points.fix' create;
  };
}
