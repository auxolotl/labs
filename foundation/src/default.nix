let
  modules = {
    builderFileText = ./builders/file/text;
    builderKaem = ./builders/kaem;
    builderRaw = ./builders/raw;
    exports = ./exports;
    platform = ./platform;
    stage0 = ./stages/stage0;
    system = ./system;
  };
in
  modules
