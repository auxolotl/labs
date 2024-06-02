let
  lib = import ./../default.nix;
in {
  examples = {
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
  };
}
