let
  lib = import ./../default.nix;
in {
  "merge" = {
    "merges two shallow sets" = let
      expected = {
        x = 1;
        y = 2;
      };

      actual = lib.attrs.merge {x = 1;} {y = 2;};
    in
      expected == actual;

    "overwrites values from the first set" = let
      expected = {
        x = 2;
      };
      actual = lib.attrs.merge {x = 1;} {x = 2;};
    in
      actual == expected;

    "does not merge nested sets" = let
      expected = {
        x.y = 2;
      };
      actual = lib.attrs.merge {x.z = 1;} {x.y = 2;};
    in
      actual == expected;
  };

  "mergeRecursiveUntil" = {
    "merges with predicate" = let
      expected = {
        x.y.z = 1;
      };
      actual =
        lib.attrs.mergeRecursiveUntil
        (path: x: y: lib.lists.last path == "z")
        {x.y.z = 2;}
        {x.y.z = 1;};
    in
      actual == expected;

    "handles shallow merges" = let
      expected = {
        x.y.z = 1;
      };
      actual =
        lib.attrs.mergeRecursiveUntil
        (path: x: y: true)
        {
          x = {
            y.z = 2;

            a = false;
          };
        }
        {x.y.z = 1;};
    in
      actual == expected;
  };

  "mergeRecursive" = {
    "merges two sets deeply" = let
      expected = {
        x.y.z = 1;
      };
      actual =
        lib.attrs.mergeRecursive
        {x.y.z = 2;}
        {x.y.z = 1;};
    in
      actual == expected;
  };

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

    "handles empty path" = let
      expected = {
        x = {
          y = {
            z = 1;
          };
        };
      };
      actual =
        lib.attrs.select
        []
        null
        {
          x = {
            y = {
              z = 1;
            };
          };
        };
    in
      actual == expected;

    "handles fallback value" = let
      expected = "fallback";
      actual =
        lib.attrs.select
        ["x" "y" "z"]
        expected
        {};
    in
      actual == expected;
  };

  "selectOrThrow" = {
    "selects a nested value" = let
      expected = "value";
      actual =
        lib.attrs.selectOrThrow
        ["x" "y" "z"]
        {
          x.y.z = expected;
        };
    in
      actual == expected;

    "handles empty path" = let
      expected = {
        x = {
          y = {
            z = 1;
          };
        };
      };
      actual =
        lib.attrs.selectOrThrow
        []
        {
          x = {
            y = {
              z = 1;
            };
          };
        };
    in
      actual == expected;

    "throws on nonexistent path" = let
      actual =
        lib.attrs.selectOrThrow
        ["x" "y" "z"]
        {};

      evaluated = builtins.tryEval (builtins.deepSeq actual actual);
    in
      !evaluated.success;
  };

  "set" = {
    "creates a nested set" = let
      expected = {
        x = {
          y = {
            z = 1;
          };
        };
      };
      actual = lib.attrs.set ["x" "y" "z"] 1;
    in
      actual == expected;

    "handles empty path" = let
      expected = 1;
      actual = lib.attrs.set [] 1;
    in
      actual == expected;
  };

  "has" = {
    "returns true for a nested value" = let
      exists = lib.attrs.has ["x" "y" "z"] {x.y.z = 1;};
    in
      exists;

    "returns false for a nonexistent value" = let
      exists = lib.attrs.has ["x" "y" "z"] {};
    in
      !exists;

    "handles empty path" = let
      exists = lib.attrs.has [] {};
    in
      exists;
  };

  "when" = {
    "returns the value when condition is true" = let
      expected = "value";
      actual = lib.attrs.when true expected;
    in
      actual == expected;

    "returns an empty set when condition is false" = let
      expected = {};
      actual = lib.attrs.when false "value";
    in
      actual == expected;
  };

  "mapToList" = {
    "converts a set to a list" = let
      expected = [
        {
          name = "x";
          value = 1;
        }
        {
          name = "y";
          value = 2;
        }
      ];
      actual =
        lib.attrs.mapToList
        (name: value: {inherit name value;})
        {
          x = 1;
          y = 2;
        };
    in
      actual == expected;
  };

  "mapRecursiveWhen" = {
    "maps a set recursively" = let
      expected = {
        x = {
          y = {
            z = 2;
          };
        };
      };
      actual =
        lib.attrs.mapRecursiveWhen
        (value: true)
        (path: value: value + 1)
        {
          x = {
            y = {
              z = 1;
            };
          };
        };
    in
      actual == expected;

    "maps a set given a condition" = let
      expected = {
        x = {
          y = {
            z = 1;
          };
        };
      };
      actual =
        lib.attrs.mapRecursiveWhen
        (value: !(value ? z))
        (path: value:
          # We map before we get to a non-set value
            if builtins.isAttrs value
            then value
            else value + 1)
        {
          x = {
            y = {
              z = 1;
            };
          };
        };
    in
      actual == expected;
  };

  "mapRecursive" = {
    "maps a set recursively" = let
      expected = {
        x = {
          y = {
            z = 2;
          };
        };
      };
      actual =
        lib.attrs.mapRecursive
        (path: value: value + 1)
        {
          x = {
            y = {
              z = 1;
            };
          };
        };
    in
      actual == expected;
  };

  "filter" = {
    "filters a set" = let
      expected = {
        y = 2;
      };
      actual =
        lib.attrs.filter
        (name: value: name == "y")
        {
          x = 1;
          y = 2;
        };
    in
      actual == expected;
  };
}
