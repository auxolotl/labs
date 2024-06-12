let
  lib = import ./../default.nix;
in {
  "validate" = {
    "entry" = {
      "invalid value" = let
        expected = false;
        actual = lib.dag.validate.entry {};
      in
        actual == expected;

      "a manually created value" = let
        expected = true;
        actual = lib.dag.validate.entry {
          value = null;
          before = [];
          after = [];
        };
      in
        actual == expected;

      "entry.between" = let
        expected = true;
        actual = lib.dag.validate.entry (lib.dag.entry.between [] [] null);
      in
        actual == expected;

      "entry.anywhere" = let
        expected = true;
        actual = lib.dag.validate.entry (lib.dag.entry.anywhere null);
      in
        actual == expected;

      "entry.before" = let
        expected = true;
        actual = lib.dag.validate.entry (lib.dag.entry.before [] null);
      in
        actual == expected;

      "entry.after" = let
        expected = true;
        actual = lib.dag.validate.entry (lib.dag.entry.after [] null);
      in
        actual == expected;
    };

    "graph" = {
      "invalid value" = let
        expected = false;
        actual = lib.dag.validate.graph {
          x = {};
        };
      in
        actual == expected;

      "a manually created value" = let
        expected = true;
        actual = lib.dag.validate.graph {
          x = {
            value = null;
            before = [];
            after = [];
          };
        };
      in
        actual == expected;

      "entries.between" = let
        expected = true;
        graph = lib.dag.entries.between "example" [] [] [null null];
        actual = lib.dag.validate.graph graph;
      in
        actual == expected;

      "entries.anywhere" = let
        expected = true;
        graph = lib.dag.entries.anywhere "example" [null null];
        actual = lib.dag.validate.graph graph;
      in
        actual == expected;

      "entries.before" = let
        expected = true;
        graph = lib.dag.entries.before "example" [] [null null];
        actual = lib.dag.validate.graph graph;
      in
        actual == expected;

      "entries.after" = let
        expected = true;
        graph = lib.dag.entries.after "example" [] [null null];
        actual = lib.dag.validate.graph graph;
      in
        actual == expected;
    };
  };

  "sort" = {
    "topographic" = {
      "handles an empty graph" = let
        expected = [];
        actual = lib.dag.sort.topographic {};
      in
        actual.result == expected;

      "sorts a graph" = let
        expected = [
          {
            name = "a";
            value = "a";
          }
          {
            name = "b";
            value = "b";
          }
          {
            name = "c";
            value = "c";
          }
          {
            name = "d";
            value = "d";
          }
        ];
        actual = lib.dag.sort.topographic {
          a = lib.dag.entry.anywhere "a";
          b = lib.dag.entry.between ["c"] ["a"] "b";
          c = lib.dag.entry.before ["c"] "c";
          d = lib.dag.entry.after ["c"] "d";
        };
      in
        actual.result == expected;
    };
  };
}
