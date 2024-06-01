lib: {
  numbers = {
    into = {
      ## Convert a number into a string.
      ##
      ## @type Int | Float -> String
      string = value:
        if builtins.isInt value
        then builtins.toString value
        else builtins.toJSON value;

      ## Convert a number into a list of digits in the given base.
      ##
      ## @type Int -> Int -> List Int
      base = base: target: let
        process = value: let
          r = value - ((value / base) * base);
          q = (value - r) / base;
        in
          if value < base
          then [value]
          else [r] ++ process q;
        result = process target;
      in
        assert lib.errors.trace (builtins.isInt base) "Base must be an integer.";
        assert lib.errors.trace (builtins.isInt target) "Target must be an integer.";
        assert lib.errors.trace (base >= 2) "Base must be at least 2.";
        assert lib.errors.trace (target >= 0) "Target cannot be negative.";
          lib.lists.reverse result;

      ## Convert a number into a hexadecimal string.
      ##
      ## @type Int -> String
      hex = value: let
        serialize = part:
          if part < 10
          then builtins.toString part
          else if part == 10
          then "A"
          else if part == 11
          then "B"
          else if part == 12
          then "C"
          else if part == 13
          then "D"
          else if part == 14
          then "E"
          else if part == 15
          then "F"
          else builtins.throw "Invalid hex digit.";
      in
        lib.strings.concatMapSep
        serialize
        (lib.numbers.into.base 16 value);
    };

    ## Compare two numbers. When the first number is less than the second, -1
    ## is returned. When the first number is greater than the second, 1 is
    ## returned. When the numbers are equal, 0 is returned.
    ##
    ## @type Int -> Int -> Int
    compare = a: b:
      if a < b
      then -1
      else if a > b
      then 1
      else 0;
  };
}
