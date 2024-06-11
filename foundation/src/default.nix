let
  modules = {
    builderBash = builders/bash;
    builderFileText = ./builders/file/text;
    builderKaem = ./builders/kaem;
    builderRaw = ./builders/raw;
    mirrors = ./mirrors;
    exports = ./exports;
    platform = ./platform;
    stage0 = ./stages/stage0;
    stage1 = ./stages/stage1;
    stage2 = ./stages/stage2;
    system = ./system;
  };
in
  modules
