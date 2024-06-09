let
  lib = import ./../default.nix;
in {
  "fix" = {
    "calculates a fixed point" = let
      expected = {
        original = 0;
        calculated = 1;
      };
      actual = lib.points.fix (
        self: {
          original = 0;
          calculated = self.original + 1;
        }
      );
    in
      actual == expected;
  };

  "fix'" = {
    "allows unfixing a fixed point" = let
      expected = {
        original = 0;
        calculated = 6;
      };
      result = lib.points.fix' (
        self: {
          original = 0;
          calculated = self.original + 1;
        }
      );
      actual = result.__unfix__ {
        original = 5;
      };
    in
      actual == expected;
  };

  "extends" = {
    "overlays two functions' return values" = let
      first = self: previous: {
        z = 3;
      };

      second = self: {
        y = 2;
      };

      expected = {
        y = 2;
        z = 3;
      };

      actual = lib.points.extends first second {
        x = 1;
      };
    in
      actual == expected;
  };
}
