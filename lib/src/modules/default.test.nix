let
  lib = import ./../default.nix;
in {
  examples = {
    "empty" = let
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
  };
}
