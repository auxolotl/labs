lib: {
  modules = {
    from = {
      ## Create a module from a JSON file.
      ##
      ## @type Path -> Module
      json = file: {
        __file__ = file;
        config = lib.importers.json file;
      };

      ## Create a module from a TOML file.
      ##
      ## @type Path -> Module
      toml = file: {
        __file__ = file;
        config = lib.importers.toml file;
      };
    };

    apply = {
      # TODO: Document this.
      properties = definition:
        if lib.types.is "merge" definition
        then builtins.concatMap lib.modules.apply.properties definition.content
        else if lib.types.is "when" definition
        then
          if !(builtins.isBool definition.condition)
          then builtins.throw "lib.modules.when called with a non-boolean condition"
          else if definition.condition
          then lib.modules.apply.properties definition.content
          else []
        else [definition];

      # TODO: Document this.
      overrides = definitions: let
        getPriority = definition:
          if lib.types.is "override" definition.value
          then definition.value.priority
          else lib.modules.DEFAULT_PRIORITY;
        normalize = definition:
          if lib.types.is "override" definition.value
          then
            definition
            // {
              value = definition.value.content;
            }
          else definition;
        highestPriority =
          builtins.foldl'
          (priority: definition: lib.math.min priority (getPriority definition))
          9999
          definitions;
      in {
        inherit highestPriority;
        values =
          builtins.concatMap
          (
            definition:
              if getPriority definition == highestPriority
              then [(normalize definition)]
              else []
          )
          definitions;
      };

      # TODO: Document this.
      order = definitions: let
        normalize = definition:
          if lib.types.is "order" definition
          then
            definition
            // {
              value = definition.value.content;
              priority = definition.value.priority;
            }
          else definition;
        normalized = builtins.map normalize definitions;
        compare = a: b: (a.priority or lib.modules.DEFAULT_PRIORITY) < (b.priority or lib.modules.DEFAULT_PRIORITY);
      in
        builtins.sort compare normalized;

      # TODO: Document this.
      fixup = location: option:
        if option.type.getSubModules or null == null
        then
          option
          // {
            type = option.type or lib.types.unspecified;
          }
        else
          option
          // {
            type = option.type.withSubModules option.options;
            options = [];
          };

      # TODO: Document this.
      invert = config:
        if lib.types.is "merge" config
        then builtins.concatMap lib.modules.apply.invert config.content
        else if lib.types.is "when" config
        then
          builtins.map
          (builtins.mapAttrs (key: value: lib.modules.when config.condition value))
          (lib.modules.apply.invert config.content)
        else if lib.types.is "override" config
        then
          builtins.map
          (builtins.mapAttrs (key: value: lib.modules.override config.priority value))
          (lib.modules.apply.invert config.content)
        else [config];
    };

    validate = {
      # TODO: Document this.
      keys = module: let
        invalid = builtins.removeAttrs module lib.modules.VALID_KEYS;
      in
        invalid == {};
    };

    # TODO: Document this.
    VALID_KEYS = [
      "__file__"
      "__key__"
      "includes"
      "excludes"
      "options"
      "config"
      "freeform"
      "meta"
    ];

    # TODO: Document this.
    normalize = file: key: module: let
      invalid = builtins.removeAttrs module lib.modules.VALID_KEYS;
      invalidKeys = builtins.concatStringsSep ", " (builtins.attrNames invalid);
    in
      if lib.modules.validate.keys module
      then {
        __file__ = builtins.toString module.__file__ or file;
        __key__ = builtins.toString module.__key__ or key;
        includes = module.includes or [];
        excludes = module.excludes or [];
        options = module.options or {};
        config = let
          base = module.config or {};
          withMeta = config:
            if module ? meta
            then lib.modules.merge [config {meta = module.meta;}]
            else config;
          withFreeform = config:
            if module ? freeform
            then lib.modules.merge [config {__module__.freeform = module.freeform;}]
            else config;
        in
          withFreeform (withMeta base);
      }
      else builtins.throw "Module `${key}` has unsupported attribute(s): ${invalidKeys}";

    # TODO: Document this.
    resolve = key: module: args: let
      dynamicArgs =
        builtins.mapAttrs
        (
          name: value:
            builtins.addErrorContext
            "while evaluating the module argument `${name}` in `${key}`"
            (args.${name} or args.config.__module__.args.dynamic.${name})
        )
        (lib.fp.args module);
    in
      if builtins.isFunction module
      then module (args // dynamicArgs)
      else module;

    # TODO: Document this.
    DEFAULT_PRIORITY = 100;

    ## Allow for sorting the values provided to a module by priority. The
    ## most important value will be used.
    ##
    ## @type Int -> a -> Priority a
    order = priority: value: {
      __type__ = "order";
      inherit priority value;
    };

    orders = {
      # TODO: Document this.
      before = lib.modules.order 500;
      # TODO: Document this.
      default = lib.modules.order 1000;
      # TODO: Document this.
      after = lib.modules.order 1500;
    };

    ## Extract a list of files from a list of modules.
    ##
    ## @type List Module -> List (String | Path)
    getFiles = builtins.map (module: module.__file__);

    # TODO: Document this.
    when = condition: content: {
      __type__ = "when";
      inherit condition content;
    };

    # TODO: Document this.
    merge = content: {
      __type__ = "merge";
      inherit content;
    };

    # TODO: Document this.
    override = priority: content: {
      __type__ = "override";
      inherit priority content;
    };

    overrides = {
      # TODO: Document this.
      option = lib.modules.override 1500;
      # TODO: Document this.
      default = lib.modules.override 1000;
      # TODO: Document this.
      force = lib.modules.override 50;
      # TODO: Document this.
      vm = lib.modules.override 10;
    };

    # TODO: Document this.
    combine = prefix: modules: let
      getConfig = module:
        builtins.map
        (config: {
          __file__ = module.__file__;
          inherit config;
        })
        (lib.modules.apply.invert module.config);

      configs =
        builtins.concatMap
        getConfig
        modules;

      process = prefix: options: configs: let
        # TODO: Document this.
        byName = attr: f: modules:
          builtins.zipAttrsWith
          (lib.fp.const builtins.concatLists)
          (builtins.map (
              module: let
                subtree = module.${attr};
              in
                if builtins.isAttrs subtree
                then builtins.mapAttrs (key: f module) subtree
                else builtins.throw "Value for `${builtins.concatStringsSep "." prefix} is of type `${builtins.typeOf subtree}` but an attribute set was expected."
            )
            modules);

        declarationsByName =
          byName
          "options"
          (module: option: [
            {
              __file__ = module.__file__;
              options = option;
            }
          ])
          options;

        definitionsByName =
          byName
          "config"
          (
            module: value:
              builtins.map
              (config: {
                __file__ = module.__file__;
                inherit config;
              })
              (lib.modules.apply.invert value)
          )
          configs;

        definitionsByName' =
          byName
          "config"
          (module: value: [
            {
              __file__ = module.__file__;
              inherit value;
            }
          ])
          configs;

        getOptionFromDeclaration = declaration:
          if lib.types.is "option" declaration.options
          then declaration
          else
            declaration
            // {
              options = lib.options.create {
                type = lib.types.submodule [{options = declaration.options;}];
              };
            };

        resultsByName =
          builtins.mapAttrs
          (
            name: declarations: let
              location = prefix ++ [name];
              definitions = definitionsByName.${name} or [];
              definitions' = definitionsByName'.${name} or [];
              optionDeclarations =
                builtins.filter
                (declaration: lib.types.is "option" declaration.options)
                declarations;
            in
              if builtins.length optionDeclarations == builtins.length declarations
              then let
                option =
                  lib.modules.apply.fixup
                  location
                  (lib.options.merge.declarations location declarations);
              in {
                matched = lib.options.run location option definitions';
                unmatched = [];
              }
              else if optionDeclarations != []
              then
                if builtins.all (declaration: declaration.options.type.name == "Submodule") optionDeclarations
                then let
                  option =
                    lib.modules.apply.fixup location
                    (lib.options.merge.declarations location (builtins.map getOptionFromDeclaration declarations));
                in {
                  matched = lib.options.run location option definitions';
                  unmatched = [];
                }
                else builtins.throw "The option `${lib.options.getIdentifier location}` in module `${(builtins.head optionDeclarations).__file__}` does not support nested options."
              else process location declarations definitions
          )
          declarationsByName;

        matched = builtins.mapAttrs (key: value: value.matched) resultsByName;

        unmatched =
          builtins.mapAttrs (key: value: value.unmatched) resultsByName
          // builtins.removeAttrs definitionsByName' (builtins.attrNames matched);
      in {
        inherit matched;

        unmatched =
          if configs == []
          then []
          else
            builtins.concatLists (
              lib.attrs.mapToList
              (
                name: definitions:
                  builtins.map (definition:
                    definition
                    // {
                      prefix = [name] ++ (definition.prefix or []);
                    })
                  definitions
              )
              unmatched
            );
      };
    in
      process prefix modules configs;

    # TODO: Document this.
    run = settings @ {
      modules ? [],
      args ? {},
      prefix ? [],
    }: let
      type = lib.types.submodules.of {
        inherit modules args;
      };

      extend = extensions @ {
        modules ? [],
        args ? {},
        prefix ? [],
      }:
        lib.modules.run {
          modules = settings.modules ++ extensions.modules;
          args = (settings.args or {}) // extensions.args;
          prefix = extensions.prefix or settings.prefix or [];
        };

      # TODO: Document this.
      collect = let
        load = args: file: key: module: let
          moduleFromValue = lib.modules.normalize file key (lib.modules.resolve key module args);
          moduleFromPath =
            lib.modules.normalize
            (builtins.toString module)
            (builtins.toString module)
            (lib.modules.resolve (builtins.toString module) (import module) args);
        in
          if builtins.isAttrs module || builtins.isFunction module
          then moduleFromValue
          else if builtins.isString module || builtins.isPath module
          then moduleFromPath
          else builtins.throw "The provided module must be either an attribute set, function, or path but got ${builtins.typeOf module}";

        normalize = parentFile: parentKey: modules: args: let
          normalized =
            lib.lists.mapWithIndex1
            (
              i: value: let
                module = load args parentFile "${parentKey}:unknown-${builtins.toString i}" value;
                tree = normalize module.__file__ module.__key__ module.includes args;
              in {
                inherit module;
                key = module.__key__;
                modules = tree.modules;
                excludes = module.excludes ++ tree.excludes;
              }
            )
            modules;
        in {
          modules = normalized;
          excludes = builtins.concatLists (builtins.catAttrs "excludes" normalized);
        };

        withExclusions = path: {
          modules,
          excludes,
        }: let
          getKey = module:
            if builtins.isString module && (builtins.substring 0 1 module != "/")
            then (builtins.toString path) + "/" + module
            else builtins.toString module;
          excludedKeys = builtins.map getKey excludes;
          removeExcludes =
            builtins.filter
            (value: !(builtins.elem value.key excludedKeys));
        in
          builtins.map
          (value: value.module)
          (builtins.genericClosure {
            startSet = removeExcludes modules;
            operator = value: removeExcludes value.modules;
          });

        process = path: modules: args:
          withExclusions path (normalize "<unknown>" "" modules args);
      in
        process;

      internal = {
        __file__ = "virtual:aux/internal";
        __key__ = "virtual:aux/internal";

        options = {
          __module__ = {
            args = {
              static = lib.options.create {
                type = lib.types.attrs.lazy lib.types.raw;
                writable = false;
                internal = false;
                description = "Static arguments provided to lib.modules.run which cannot be changed.";
              };

              dynamic = lib.options.create {
                type = lib.types.attrs.lazy lib.types.raw;

                ${
                  if prefix == []
                  then null
                  else "internal"
                } =
                  true;

                visible = false;

                description = "Additional arguments pased to each module.";
              };
            };

            check = lib.options.create {
              type = lib.types.bool;
              default.value = true;
              internal = true;
              description = "Whether to perform checks on option definitions.";
            };

            freeform = lib.options.create {
              type = lib.types.nullish lib.types.option;
              default.value = null;
              internal = true;
              description = "If set, all options that don't have a declared type will be merged using this type.";
            };
          };
        };

        config = {
          __module__ = {
            args = {
              static = args;

              dynamic = {
                meta = {
                  inherit extend type;
                };
              };
            };
          };
        };
      };

      merged = let
        collected =
          collect
          (args.path or "")
          (modules ++ [internal])
          ({inherit lib options config;} // args);
      in
        lib.modules.combine prefix (lib.lists.reverse collected);

      options = merged.matched;

      config = let
        declared =
          lib.attrs.mapRecursiveWhen
          (value: !(lib.types.is "option" value))
          (key: value: value.value)
          options;

        freeform = let
          definitions =
            builtins.map
            (definition: {
              __file__ = definition.__file__;
              value = lib.attrs.set definition.prefix definition.value;
            })
            merged.unmatched;
        in
          if definitions == []
          then {}
          else declared.__module__.freeform.merge prefix definitions;
      in
        if declared.__module__.freeform == null
        then declared
        else
          lib.attrs.mergeRecursive
          freeform
          declared;

      checked =
        if config.__module__.check && config.__module__.freeform == null && merged.unmatched != []
        then let
          first = builtins.head merged.unmatched;

          identifier = lib.options.getIdentifier (prefix ++ first.prefix);
          definitions =
            builtins.addErrorContext "while evaluating the error message for definitions of non-existent option `${identifier}`"
            (
              builtins.addErrorContext "while evaluating a definition from `${first.__file__}`"
              (lib.options.getDefinitions [first])
            );

          message = "The option `${identifier}` does not exist. Definitions:${definitions}";
        in
          if builtins.attrNames options == ["__module__"]
          then
            if lib.options.getIdentifier prefix == ""
            then
              builtins.throw ''
                ${message}

                You are trying to declare options in `config` rather than `options`.
              ''
            else
              builtins.throw ''
                ${message}

                There are no options defined in `${lib.options.getIdentifier prefix}`.
                Are you sure you declared your options correctly?
              ''
          else builtins.throw message
        else null;

      withCheck = builtins.seq checked;
    in {
      inherit type extend;
      options = withCheck options;
      config = withCheck (builtins.removeAttrs config ["__module__"]);
      __module__ = withCheck config.__module__;
    };
  };
}
