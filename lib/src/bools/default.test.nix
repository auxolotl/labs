let
  lib = import ./../default.nix;
in {
  "into" = {
    "string" = {
      "handles true" = let
        expected = "true";
        actual = lib.bools.into.string true;
      in
        actual == expected;

      "handles false" = let
        expected = "false";
        actual = lib.bools.into.string false;
      in
        actual == expected;
    };

    "yesno" = {
      "handles true" = let
        expected = "yes";
        actual = lib.bools.into.yesno true;
      in
        actual == expected;
      "handles false" = let
        expected = "no";
        actual = lib.bools.into.yesno false;
      in
        actual == expected;
    };
  };

  "when" = {
    "returns first value when true" = let
      expected = "foo";
      actual = lib.bools.when true expected "bar";
    in
      actual == expected;

    "returns second value when false" = let
      expected = "bar";
      actual = lib.bools.when false "foo" expected;
    in
      actual == expected;
  };

  "and" = {
    "returns true when both are true" = let
      expected = true;
      actual = lib.bools.and true true;
    in
      actual == expected;
    "returns false when first is false" = let
      expected = false;
      actual = lib.bools.and false true;
    in
      actual == expected;
    "returns false when second is false" = let
      expected = false;
      actual = lib.bools.and true false;
    in
      actual == expected;
    "returns false when both are false" = let
      expected = false;
      actual = lib.bools.and false false;
    in
      actual == expected;
  };

  "and'" = let
    getTrue = _: true;
    getFalse = _: false;
  in {
    "returns true when both are true" = let
      expected = true;
      actual = lib.bools.and' getTrue getTrue null;
    in
      actual == expected;

    "returns false when first is false" = let
      expected = false;
      actual = lib.bools.and' getFalse getTrue null;
    in
      actual == expected;

    "returns false when second is false" = let
      expected = false;
      actual = lib.bools.and' getTrue getFalse null;
    in
      actual == expected;

    "returns false when both are false" = let
      expected = false;
      actual = lib.bools.and' getFalse getFalse null;
    in
      actual == expected;
  };

  "or" = {
    "returns true when both are true" = let
      expected = true;
      actual = lib.bools.or true true;
    in
      actual == expected;
    "returns true when first is true" = let
      expected = true;
      actual = lib.bools.or true false;
    in
      actual == expected;
    "returns true when second is true" = let
      expected = true;
      actual = lib.bools.or false true;
    in
      actual == expected;
    "returns false when both are false" = let
      expected = false;
      actual = lib.bools.or false false;
    in
      actual == expected;
  };

  "or'" = let
    getTrue = _: true;
    getFalse = _: false;
  in {
    "returns true when both are true" = let
      expected = true;
      actual = lib.bools.or' getTrue getTrue null;
    in
      actual == expected;
    "returns true when first is true" = let
      expected = true;
      actual = lib.bools.or' getTrue getFalse null;
    in
      actual == expected;
    "returns true when second is true" = let
      expected = true;
      actual = lib.bools.or' getFalse getTrue null;
    in
      actual == expected;
    "returns false when both are false" = let
      expected = false;
      actual = lib.bools.or' getFalse getFalse null;
    in
      actual == expected;
  };

  "not" = {
    "returns false when true" = let
      expected = false;
      actual = lib.bools.not true;
    in
      actual == expected;

    "returns true when false" = let
      expected = true;
      actual = lib.bools.not false;
    in
      actual == expected;
  };
}
