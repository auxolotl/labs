lib: {
  fp = {
    ## A function that returns its argument.
    ##
    ## @type a -> a
    id = x: x;

    ## Create a function that ignores its argument and returns a constant value.
    ##
    ## @type a -> b -> a
    const = x: (_: x);

    ## Compose two functions to produce a new function that applies them both
    ## from right to left.
    ##
    ## @type Function f g => (b -> c) -> (a -> b) -> a -> c
    compose = f: g: (x: f (g x));

    ## Process a value with a series of functions. Functions are applied in the
    ## order they are provided.
    ##
    ## @type (List (Any -> Any)) -> Any -> Any
    pipe = fs: (
      x: builtins.foldl' (value: f: f x) x fs
    );

    ## Reverse the order of arguments to a function that has two parameters.
    ##
    ## @type (a -> b -> c) -> b -> a -> c
    flip2 = f: a: b: f b a;
    ## Reverse the order of arguments to a function that has three parameters.
    ##
    ## @type (a -> b -> c -> d) -> c -> b -> a -> d
    flip3 = f: a: b: c: f c b a;
    ## Reverse the order of arguments to a function that has four parameters.
    ##
    ## @type (a -> b -> c -> d -> e) -> d -> c -> b -> a -> e
    flip4 = f: a: b: c: d: f d c b a;

    # TODO: Document this.
    args = f:
      if f ? __functor
      then f.__args__ or lib.fp.args (f.__functor f)
      else builtins.functionArgs f;
  };
}
