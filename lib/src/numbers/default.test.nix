let
  lib = import ./../default.nix;
in {
  "into" = {
    "string" = {
      "converts an int into a string" = let
        expected = "1";
        actual = lib.numbers.into.string 1;
      in
        actual == expected;

      "converts a float into a string" = let
        expected = "1.0";
        actual = lib.numbers.into.string 1.0;
      in
        actual == expected;
    };

    "base" = {
      "converts a number into a given base" = let
        expected = [1 0 0];
        actual = lib.numbers.into.base 2 4;
      in
        actual == expected;
    };

    "hex" = {
      "converts a number into a hex string" = let
        expected = "64";
        actual = lib.numbers.into.hex 100;
      in
        (builtins.trace actual)
        actual
        == expected;
    };
  };

  "compare" = {
    "returns -1 when first is less than second" = let
      expected = -1;
      actual = lib.numbers.compare 1 2;
    in
      actual == expected;

    "returns 0 when first is equal to second" = let
      expected = 0;
      actual = lib.numbers.compare 1 1;
    in
      actual == expected;

    "returns 1 when first is greater than second" = let
      expected = 1;
      actual = lib.numbers.compare 2 1;
    in
      actual == expected;
  };
}
