let
  lib = import ./../default.nix;
in {
  "withRecursion" = {
    "evaluates within a given limit" = let
      expected = {
        x = 1;
      };
      actual = lib.generators.withRecursion {limit = 100;} expected;
    in
      expected == actual;

    "fails when the limit is reached" = let
      expected = {
        x = 1;
      };
      actual = lib.generators.withRecursion {limit = -1;} expected;
      evaluated = builtins.tryEval (builtins.deepSeq actual actual);
    in
      !evaluated.success;

    "does not fail when throw is disabled" = let
      expected = {
        x = "<unevaluated>";
      };
      actual =
        lib.generators.withRecursion {
          limit = -1;
          throw = false;
        }
        {x = 1;};
      evaluated = builtins.tryEval (builtins.deepSeq actual actual);
    in
      evaluated.success
      && evaluated.value == expected;
  };

  "pretty" = {
    "formats with defaults" = let
      expected = ''
        {
          attrs = { };
          bool = true;
          float = 0.0;
          function = <function>;
          int = 0;
          list = [ ];
          string = "string";
        }'';
      actual = lib.generators.pretty {} {
        attrs = {};
        bool = true;
        float = 0.0;
        function = x: x;
        int = 0;
        list = [];
        string = "string";
        # NOTE: We are not testing `path` types because they can return out of store
        # values which are not deterministic.
        # path = ./.;
      };
    in
      actual == expected;

    "formats with custom prettifiers" = let
      expected = ''
        {
          attrs = { };
          bool = true;
          custom = <custom>;
          float = 0.0;
          function = <function>;
          int = 0;
          list = [ ];
          string = "string";
        }'';
      actual =
        lib.generators.pretty {
          allowCustomPrettifiers = true;
        } {
          attrs = {};
          bool = true;
          float = 0.0;
          function = x: x;
          int = 0;
          list = [];
          string = "string";
          custom = {
            value = 0;
            __pretty__ = value: "<custom>";
          };
        };
    in
      actual == expected;

    "formats with multiline disabled" = let
      expected = "{ attrs = { }; bool = true; float = 0.0; function = <function>; int = 0; list = [ ]; string = \"string\"; }";
      actual =
        lib.generators.pretty {
          multiline = false;
        } {
          attrs = {};
          bool = true;
          float = 0.0;
          function = x: x;
          int = 0;
          list = [];
          string = "string";
        };
    in
      actual == expected;
  };
}
