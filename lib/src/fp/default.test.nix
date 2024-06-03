let
  lib = import ./../default.nix;
in {
  "id" = {
    "returns its argument" = let
      expected = "foo";
      actual = lib.fp.id expected;
    in
      actual == expected;
  };

  "const" = {
    "creates a function that returns its argument" = let
      expected = "foo";
      actual = lib.fp.const expected "bar";
    in
      actual == expected;
  };

  "compose" = {
    "composes two functions" = let
      f = x: x + 1;
      g = x: x * 2;
      expected = 5;
      actual = lib.fp.compose f g 2;
    in
      actual == expected;
  };

  "pipe" = {
    "pipes two functions" = let
      f = x: x + 1;
      g = x: x * 2;
      expected = 5;
      actual = lib.fp.pipe [g f] 2;
    in
      actual == expected;
  };

  "flip2" = {
    "flips the arguments of a binary function" = let
      f = a: b: a - b;
      expected = 1;
      actual = lib.fp.flip2 f 1 2;
    in
      actual == expected;
  };

  "flip3" = {
    "flips the arguments of a ternary function" = let
      f = a: b: c: a - b - c;
      expected = 0;
      actual = lib.fp.flip3 f 1 2 3;
    in
      actual == expected;
  };

  "flip4" = {
    "flips the arguments of a quaternary function" = let
      f = a: b: c: d: a - b - c - d;
      expected = -2;
      actual = lib.fp.flip4 f 1 2 3 4;
    in
      actual == expected;
  };

  "args" = {
    "gets a functions attr set arguments" = let
      expected = {
        x = false;
        y = true;
      };
      actual = lib.fp.args ({
        x,
        y ? null,
      }:
        null);
    in
      actual == expected;

    "returns an empty set if the function has no attrs arguments" = let
      expected = {};
      actual = lib.fp.args (args: null);
    in
      actual == expected;

    "supports functors" = let
      expected = {
        x = false;
        y = true;
      };

      actual = lib.fp.args {
        __functor = self: {
          x,
          y ? null,
        }:
          null;
      };
    in
      actual == expected;

    "supports cached functor arguments" = let
      expected = {
        x = false;
        y = true;
      };
      actual = lib.fp.args {
        __args__ = {
          x = false;
          y = true;
        };
        __functor = self: args:
          null;
      };
    in
      actual == expected;
  };

  "withDynamicArgs" = {
    "applies a function with dynamic arguments" = let
      expected = {x = true;};
      actual = lib.fp.withDynamicArgs (args @ {x}: args) {
        x = true;
        y = true;
      };
    in
      actual == expected;

    "applies all arguments if none are specified" = let
      expected = {
        x = true;
        y = true;
      };
      actual = lib.fp.withDynamicArgs (args: args) expected;
    in
      actual == expected;
  };
}
