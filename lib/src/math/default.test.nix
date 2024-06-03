let
  lib = import ./../default.nix;
in {
  "min" = {
    "returns the smaller number" = let
      expected = 1;
      actual = lib.math.min 1 2;
    in
      actual == expected;
  };

  "max" = {
    "returns the larger number" = let
      expected = 2;
      actual = lib.math.max 1 2;
    in
      actual == expected;
  };
}
