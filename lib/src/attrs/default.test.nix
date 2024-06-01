let
  lib = import ./../default.nix;
in {
  "select" = {
    "selects a nested value" = let
      expected = "value";
      actual =
        lib.attrs.select
        ["x" "y" "z"]
        null
        {
          x.y.z = expected;
        };
    in
      actual == expected;
  };
}
