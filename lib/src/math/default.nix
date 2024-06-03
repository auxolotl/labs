lib: {
  math = {
    ## Return the smaller of two numbers.
    ##
    ## @type Int -> Int -> Int
    min = x: y:
      if x < y
      then x
      else y;

    ## Return the larger of two numbers.
    ##
    ## @type Int -> Int -> Int
    max = x: y:
      if x > y
      then x
      else y;
  };
}
