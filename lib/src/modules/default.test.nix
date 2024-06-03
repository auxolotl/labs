let
  lib = import ./../default.nix;
in {
  "apply" = {
    "properties" = {
      "handles normal values" = let
        expected = [{}];
        actual = lib.modules.apply.properties {};
      in
        actual == expected;

      "handles merge" = let
        expected = [{x = 1;} {x = 2;}];
        actual = lib.modules.apply.properties (lib.modules.merge [{x = 1;} {x = 2;}]);
      in
        actual
        == expected;

      "handles when" = let
        expected = [[{x = 1;}]];
        actual = lib.modules.apply.properties (lib.modules.when true [{x = 1;}]);
      in
        actual == expected;
    };

    "overrides" = {
      "handles normal values" = let
        expected = {
          highestPriority = 100;
          values = [
            {
              value = 1;
            }
          ];
        };
        actual = lib.modules.apply.overrides [
          {
            value = 1;
          }
        ];
      in
        actual == expected;

      "handles overrides" = let
        expected = {
          highestPriority = 100;
          values = [
            {value = "world";}
          ];
        };
        actual = lib.modules.apply.overrides [
          {value = "world";}
          {value = lib.modules.override 101 "hello";}
        ];
      in
        actual == expected;
    };

    "order" = {
      "handles normal values" = let
        expected = [{}];
        actual = lib.modules.apply.order [{}];
      in
        actual == expected;

      "handles priority" = let
        expected = [
          {
            value = 1;
            priority = 10;
          }
          {
            value = 3;
            priority = 50;
          }
          {value = 2;}
        ];
        actual = lib.modules.apply.order [
          {
            value = 1;
            priority = 10;
          }
          {value = 2;}
          {
            value = 3;
            priority = 50;
          }
        ];
      in
        actual == expected;
    };

    "fixup" = {
      "sets default type for option" = let
        actual = lib.modules.apply.fixup [] (
          lib.options.create {}
        );
      in
        actual.type.name == "Unspecified";
    };

    "invert" = {
      "inverts merge" = let
        expected = [{x = 1;} {x = 2;}];
        actual =
          lib.modules.apply.invert (lib.modules.merge [{x = 1;} {x = 2;}]);
      in
        actual
        == expected;

      "inverts when" = let
        expected = [
          {
            x = {
              __type__ = "when";
              condition = true;
              content = 1;
            };
            y = {
              __type__ = "when";
              condition = true;
              content = 2;
            };
          }
        ];
        actual = lib.modules.apply.invert (lib.modules.when true {
          x = 1;
          y = 2;
        });
      in
        actual == expected;

      "inverts overrides" = let
        expected = [
          {
            x = {
              __type__ = "override";
              priority = 100;
              content = 1;
            };
            y = {
              __type__ = "override";
              priority = 100;
              content = 2;
            };
          }
        ];
        actual = lib.modules.apply.invert (lib.modules.override 100 {
          x = 1;
          y = 2;
        });
      in
        actual == expected;
    };
  };

  "validate" = {
    "keys" = {
      "handles an empty set" = let
        value = lib.modules.validate.keys {};
      in
        value;

      "handles a valid module" = let
        value = lib.modules.validate.keys {
          __file__ = "virtual:aux/example";
          __key__ = "aux/example";
          includes = [];
          excludes = [];
          options = {};
          config = {};
          freeform = null;
          meta = {};
        };
      in
        value;

      "handles an invalid module" = let
        value = lib.modules.validate.keys {
          invalid = null;
        };
      in
        !value;
    };
  };

  "normalize" = {
    "handles an empty set" = let
      expected = {
        __file__ = "/aux/example.nix";
        __key__ = "example";
        config = {};
        excludes = [];
        includes = [];
        options = {};
      };
      actual = lib.modules.normalize "/aux/example.nix" "example" {};
    in
      actual == expected;

    "handles an example module" = let
      expected = {
        __file__ = "myfile.nix";
        __key__ = "mykey";
        config = {
          x = true;
        };
        excludes = [];
        includes = [];
        options = {};
      };
      actual = lib.modules.normalize "/aux/example.nix" "example" {
        __file__ = "myfile.nix";
        __key__ = "mykey";
        config.x = true;
      };
    in
      actual == expected;
  };

  "resolve" = {
    "handles an attribute set" = let
      expected = {config.x = 1;};
      actual = lib.modules.resolve "example" {config.x = 1;} {};
    in
      actual == expected;

    "handles a function" = let
      expected = {config.x = 1;};
      actual = lib.modules.resolve "example" (lib.fp.const {config.x = 1;}) {};
    in
      actual == expected;

    "handles a function with arguments" = let
      expected = {config.x = 1;};
      actual = lib.modules.resolve "example" (args: {config.x = args.x;}) {x = 1;};
    in
      actual == expected;
  };

  "getFiles" = {
    "gets the files for a list of modules" = let
      expected = ["/aux/example.nix"];
      actual = lib.modules.getFiles [{__file__ = "/aux/example.nix";}];
    in
      actual
      == expected;
  };

  "combine" = {
    "handles empty modules" = let
      expected = {
        matched = {};
        unmatched = [];
      };
      actual = lib.modules.combine [] [
        (lib.modules.normalize "/aux/example.nix" "example" {})
      ];
    in
      actual == expected;

    "handles a single module" = let
      expected = {
        matched = {};
        unmatched = [
          {
            __file__ = "/aux/example.nix";
            prefix = ["x"];
            value = 1;
          }
        ];
      };
      actual = lib.modules.combine [] [
        (lib.modules.normalize "/aux/example.nix" "example" {
          config = {
            x = 1;
          };
        })
      ];
    in
      actual == expected;

    "handles multiple modules" = let
      unmatched = [
        {
          __file__ = "/aux/example2.nix";
          prefix = ["y"];
          value = 2;
        }
      ];
      actual = lib.modules.combine [] [
        (lib.modules.normalize "/aux/example1.nix" "example2" {
          options = {
            x = lib.options.create {};
          };

          config = {
            x = 1;
          };
        })
        (lib.modules.normalize "/aux/example2.nix" "example2" {
          config = {
            y = 2;
          };
        })
      ];
    in
      (actual.unmatched == unmatched)
      && actual.matched ? x;
  };

  "run" = {
    "empty" = let
      evaluated = lib.modules.run {
        modules = [
          {
            options.aux = {
              message = lib.options.create {
                type = lib.types.string;
              };
            };

            config = {
              aux.message = "Hello, World!";
            };
          }
        ];
      };
    in
      evaluated ? config;

    "hello world" = let
      expected = "Hello, World!";

      evaluated = lib.modules.run {
        modules = [
          {
            options.aux = {
              message = lib.options.create {
                type = lib.types.string;
              };
            };

            config = {
              aux.message = "Hello, World!";
            };
          }
        ];
      };

      actual = evaluated.config.aux.message;
    in
      actual == expected;

    "recursive" = let
      expected = "Hello, World!";

      evaluated = lib.modules.run {
        modules = [
          ({config}: {
            options.aux = {
              message = lib.options.create {
                type = lib.types.string;
              };

              proxy = lib.options.create {
                type = lib.types.string;
              };
            };

            config = {
              aux = {
                proxy = "Hello, World!";
                message = config.aux.proxy;
              };
            };
          })
        ];
      };

      actual = evaluated.config.aux.message;
    in
      actual == expected;

    "conditional" = let
      expected = "Hello, World!";
      evaluated = lib.modules.run {
        modules = [
          {
            options.aux = {
              message = lib.options.create {
                type = lib.types.string;
              };
            };
            config = {
              aux = {
                message = lib.modules.when true expected;
              };
            };
          }
        ];
      };
    in
      evaluated.config.aux.message == expected;

    "conditional list" = let
      expected = ["Hello, World!"];
      evaluated = lib.modules.run {
        modules = [
          {
            options.aux = {
              message = lib.options.create {
                type = lib.types.list.of lib.types.string;
              };
            };
            config = {
              aux = {
                message = lib.modules.when true expected;
              };
            };
          }
        ];
      };
    in
      evaluated.config.aux.message == expected;
  };
}
