let
  lib = import ./../default.nix;
in {
  "from" = {
    "any" = {
      "returns a list containing the value" = let
        expected = [1];
        actual = lib.lists.from.any 1;
      in
        actual == expected;

      "returns the value if the value was already a list" = let
        expected = [1];
        actual = lib.lists.from.any expected;
      in
        actual == expected;
    };
  };

  "sort" = {
    "natural" = {
      "sorts a list of strings" = let
        expected = ["1" "a" "a0" "a1" "b" "c"];
        actual = lib.lists.sort.natural ["c" "a" "b" "a1" "a0" "1"];
      in
        actual == expected;
    };
  };

  "mapWithIndex" = {
    "maps a list using index 0" = let
      expected = ["0: a" "1: b" "2: c"];
      actual = lib.lists.mapWithIndex (i: v: "${builtins.toString i}: ${v}") ["a" "b" "c"];
    in
      actual == expected;
  };

  "mapWithIndex1" = {
    "maps a list using index 1" = let
      expected = ["1: a" "2: b" "3: c"];
      actual = lib.lists.mapWithIndex1 (i: v: "${builtins.toString i}: ${v}") ["a" "b" "c"];
    in
      actual == expected;
  };

  "compare" = {
    "compares two lists" = {
      "returns -1 if the first list is smaller" = let
        expected = -1;
        actual = lib.lists.compare lib.numbers.compare [1 2 3] [1 2 4];
      in
        actual == expected;
      "returns 1 if the first list is larger" = let
        expected = 1;
        actual = lib.lists.compare lib.numbers.compare [1 2 4] [1 2 3];
      in
        actual == expected;
      "returns 0 if the lists are equal" = let
        expected = 0;
        actual = lib.lists.compare lib.numbers.compare [1 2 3] [1 2 3];
      in
        actual == expected;
    };
  };

  "last" = {
    "returns the last element of a list" = let
      expected = 3;
      actual = lib.lists.last [1 2 3];
    in
      actual == expected;

    "fails if the list is empty" = let
      actual = lib.lists.last [];
      evaluated = builtins.tryEval actual;
    in
      !evaluated.success;
  };

  "slice" = {
    "slices a list" = {
      "slices a list from the start" = let
        expected = [1 2];
        actual = lib.lists.slice 0 2 [1 2 3];
      in
        actual == expected;
      "slices a list from the end" = let
        expected = [2 3];
        actual = lib.lists.slice 1 3 [1 2 3];
      in
        actual == expected;
      "slices a list from the middle" = let
        expected = [2];
        actual = lib.lists.slice 1 1 [1 2 3];
      in
        actual == expected;
    };
  };

  "take" = {
    "takes the first n elements" = let
      expected = [1 2];
      actual = lib.lists.take 2 [1 2 3];
    in
      actual == expected;
  };

  "drop" = {
    "drops the first n elements" = let
      expected = [3];
      actual = lib.lists.drop 2 [1 2 3];
    in
      actual == expected;
  };

  "reverse" = {
    "reverses a list" = let
      expected = [3 2 1];
      actual = lib.lists.reverse [1 2 3];
    in
      actual == expected;
  };

  "intersperse" = {
    "intersperses a list with a separator" = let
      expected = [1 "-" 2 "-" 3];
      actual = lib.lists.intersperse "-" [1 2 3];
    in
      actual == expected;

    "handles lists with less than 2 elements" = let
      expected = [1];
      actual = lib.lists.intersperse "-" [1];
    in
      actual == expected;
  };

  "range" = {
    "returns a range of numbers" = let
      expected = [1 2 3 4 5];
      actual = lib.lists.range 1 5;
    in
      actual == expected;
  };

  "when" = {
    "returns the list if the condition is true" = let
      expected = [1 2 3];
      actual = lib.lists.when true [1 2 3];
    in
      actual == expected;
    "returns an empty list if the condition is false" = let
      expected = [];
      actual = lib.lists.when false [1 2 3];
    in
      actual == expected;
  };

  "count" = {
    "counts the number of elements in a list" = let
      expected = 2;
      actual = lib.lists.count (value: value < 3) [1 2 3];
    in
      actual == expected;
  };

  "unique" = {
    "removes duplicate elements" = let
      expected = [1 2 3];
      actual = lib.lists.unique [1 2 3 1 2 3];
    in
      actual == expected;
  };
}
