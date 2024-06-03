let
  lib = import ./default.nix;

  root = ./.;

  files = [
    ./src/attrs/default.test.nix
    ./src/bools/default.test.nix
    ./src/errors/default.test.nix
    ./src/fp/default.test.nix
    ./src/generators/default.test.nix
    ./src/importers/default.test.nix
    ./src/lists/default.test.nix
    ./src/math/default.test.nix
    ./src/modules/default.test.nix
    ./src/numbers/default.test.nix
    ./src/options/default.test.nix
    ./src/packages/default.test.nix
    ./src/paths/default.test.nix
    ./src/points/default.test.nix
    ./src/strings/default.test.nix
    ./src/types/default.test.nix
    ./src/versions/default.test.nix
  ];

  resolve = file: let
    imported = import file;
    value =
      if builtins.isFunction imported
      then imported {inherit lib;}
      else imported;
    relative = lib.strings.removePrefix (builtins.toString root) (builtins.toString file);
  in {
    inherit file value;
    relative =
      if lib.strings.hasPrefix "/" relative
      then "." + relative
      else relative;
    namespace = getNamespace file;
  };

  resolved = builtins.map resolve files;

  getNamespace = path: let
    relative = lib.strings.removePrefix (builtins.toString root) (builtins.toString path);
    parts = lib.strings.split "/" relative;
  in
    if builtins.length parts > 2
    then builtins.elemAt parts 2
    else relative;

  results = let
    getTests = file: prefix: suite: let
      nested = lib.attrs.mapToList (name: value: getTests file (prefix ++ [name]) value) suite;
      relative = lib.strings.removePrefix (builtins.toString root) (builtins.toString file);
    in
      if builtins.isAttrs suite
      then builtins.concatLists nested
      else [
        {
          inherit prefix file;
          name = builtins.concatStringsSep " > " prefix;
          value = suite;
          relative =
            if lib.strings.hasPrefix "/" relative
            then "." + relative
            else relative;
        }
      ];

    base =
      builtins.map (entry: getTests entry.file [entry.namespace] entry.value) resolved;
  in
    builtins.concatLists base;

  successes = builtins.filter (test: test.value) results;
  failures = builtins.filter (test: !test.value) results;

  total = "${builtins.toString (builtins.length successes)} / ${builtins.toString (builtins.length results)}";
in
  if failures == []
  then let
    message =
      lib.strings.concatMapSep "\n"
      (test: "✅ ${test.name}")
      successes;
  in ''
    SUCCESS (${total})

    ${message}
  ''
  else let
    successMessage =
      lib.strings.concatMapSep "\n"
      (test: "✅ ${test.name}")
      successes;
    failureMessage =
      lib.strings.concatMapSep "\n\n"
      (test:
        "❎ ${test.name}\n"
        + "  -> ${test.relative}")
      failures;
  in ''
    FAILURE (${total})

    ${failureMessage}
  ''
