lib: {
  types = {
    ## Determine whether a given value is a certain type. Note that this is *not*
    ## the same as primitive Nix types. Types created with `lib.type` are attribute
    ## sets with a `__type__` symbol.
    ##
    ## @type String -> Attrs -> Bool
    is = name: value:
      value.__type__ or null == name;

    # TODO: Document this.
    set = name: value:
      value
      // {
        __type__ = name;
      };

    # TODO: Document this.
    functor = name: {
      inherit name;
      type =
        lib.attrs.select
        (lib.strings.split "." name)
        null
        lib.types;
      wrapped = null;
      payload = null;
      merge = null;
    };

    # TODO: Document this.
    merge = f: g: let
      wrapped = f.wrapped.mergeType g.wrapped.functor;
      payload = f.merge f.payload g.payload;
    in
      if f.name != g.name
      then null
      else if f.wrapped == null && g.wrapped == null && f.payload == null && g.payload == null
      then f.type
      else if f.wrapped != null && g.wrapped != null && wrapped != null
      then f.type wrapped
      else if f.payload != null && g.payload != null && payload != null
      then f.type payload
      else null;

    # TODO: Document this.
    create = settings @ {
      name,
      description ? name,
      fallback ? {},
      check ? lib.fp.const true,
      merge ? lib.options.merge.default,
      functor ? lib.types.functor name,
      mergeType ? lib.types.merge functor,
      getSubOptions ? lib.fp.const {},
      getSubModules ? null,
      withSubModules ? lib.fp.const null,
      children ? {},
    }: {
      __type__ = "type";
      inherit
        name
        description
        fallback
        check
        merge
        functor
        mergeType
        getSubOptions
        getSubModules
        withSubModules
        children
        ;
    };

    # TODO: Document this.
    withCheck = type: check:
      type
      // {
        check = value: type.check value && check value;
      };

    # TODO: Document this.
    raw = lib.types.create {
      name = "Raw";
      description = "raw value";
      check = lib.fp.const true;
      merge = lib.options.merge.one;
    };

    # TODO: Document this.
    any = lib.types.create {
      name = "Any";
      description = "any";
      check = lib.fp.const true;
      merge = location: definitions: let
        identifier = lib.options.getIdentifier location;
        first = builtins.elemAt definitions 0;

        files = builtins.map lib.modules.getFiles definitions;
        serializedFiles = builtins.concatStringsSep " and " files;

        getType = value:
          if builtins.isAttrs value && lib.strings.validate.stringifiable value
          then "StringifiableAttrs"
          else builtins.typeOf value;

        commonType =
          builtins.foldl' (
            type: definition:
              if getType definition.value != type
              then builtins.throw "The option `${identifier}` has conflicting definitions in ${files}"
              else type
          ) (getType first.value)
          definitions;

        mergeStringifiableAttrs = lib.options.merge.one;

        mergeSet = (lib.types.attrs.of lib.types.any).merge;

        mergeList =
          if builtins.length definitions > 1
          then builtins.throw "The option `${identifier}` has conflicting definitions in ${files}"
          else (lib.types.list.of lib.types.any).merge;

        mergeLambda = location: definitions: x: let
          resolvedLocation = location ++ ["<function body>"];
          resolvedDefinitions =
            builtins.map (definition: {
              __file__ = definition.__file__;
              value = definition.value x;
            })
            definitions;
        in
          lib.types.any.merge resolvedLocation resolvedDefinitions;

        merge =
          if commonType == "set"
          then mergeSet
          else if commonType == "list"
          then mergeList
          else if commonType == "StringifiableAttrs"
          then mergeStringifiableAttrs
          else if commonType == "lambda"
          then mergeLambda
          else lib.options.merge.equal;
      in
        merge location definitions;
    };

    # TODO: Document this.
    unspecified = lib.types.create {
      name = "Unspecified";
      description = "unspecified type";
    };

    # TODO: Document this.
    bool = lib.types.create {
      name = "Bool";
      description = "boolean";
      check = builtins.isBool;
      merge = lib.options.merge.equal;
    };

    # TODO: Document this.
    int = lib.types.create {
      name = "Int";
      description = "signed integer";
      check = builtins.isInt;
      merge = lib.options.merge.equal;
    };

    ints = let
      description = start: end: "${builtins.toString start} and ${builtins.toString end} (inclusive)";
      # TODO: Document this.
      between = start: end:
        assert lib.errors.trace (start <= end) "lib.types.ints.between start must be less than or equal to end";
          lib.types.withCheck
          lib.types.int
          (value: value >= start && value <= end)
          // {
            name = "IntBetween";
            description = "integer between ${description start end}";
          };

      # TODO: Document this.
      sign = bits: range: let
        start = 0 - (range / 2);
        end = range / 2 - 1;
      in
        between start end
        // {
          name = "IntSigned${builtins.toString bits}";
          description = "${builtins.toString bits} bit signed integer between ${description start end}";
        };

      # TODO: Document this.
      unsign = bits: range: let
        start = 0;
        end = range - 1;
      in
        between start end
        // {
          name = "IntUnsigned${builtins.toString bits}";
          description = "${builtins.toString bits} bit unsigned integer between ${description start end}";
        };
    in {
      # TODO: Document this.
      inherit between;

      # TODO: Document this.
      positive =
        lib.types.withCheck
        lib.types.int
        (value: value > 0)
        // {
          name = "IntPositive";
          description = "positive integer";
        };

      # TODO: Document this.
      unsigned =
        lib.types.withCheck
        lib.types.int
        (value: value >= 0)
        // {
          name = "IntUnsigned";
          description = "unsigned integer";
        };

      # TODO: Document this.
      u8 = unsign 8 256;
      # TODO: Document this.
      u16 = unsign 16 65536;
      # TODO: Document this.
      u32 = unsign 32 4294967296;
      # u64 = unsign 64 18446744073709551616;

      # TODO: Document this.
      s8 = sign 8 256;
      # TODO: Document this.
      s16 = sign 16 65536;
      # TODO: Document this.
      s32 = sign 32 4294967296;
    };

    # TODO: Document this.
    float = lib.types.create {
      name = "Float";
      description = "floating point number";
      check = builtins.isFloat;
      merge = lib.options.merge.equal;
    };

    # TODO: Document this.
    number = lib.types.either lib.types.int lib.types.float;

    # TODO: Document this.
    numbers = let
      description = start: end: "${builtins.toString start} and ${builtins.toString end} (inclusive)";
      # TODO: Document this.
      between = start: end:
        assert lib.errors.trace (start <= end) "lib.types.numbers.between start must be less than or equal to end";
          lib.types.withCheck
          lib.types.number
          (value: value >= start && value <= end)
          // {
            name = "NumberBetween";
            description = "numbereger between ${description start end}";
          };
    in {
      # TODO: Document this.
      inherit between;

      # TODO: Document this.
      positive =
        lib.types.withCheck
        lib.types.int
        (value: value > 0)
        // {
          name = "NumberPositive";
          description = "positive number";
        };

      # TODO: Document this.
      positiveOrZero =
        lib.types.withCheck
        lib.types.int
        (value: value >= 0)
        // {
          name = "NumberPositiveOrZero";
          description = "number that is zero or greater";
        };
    };

    # TODO: Document this.
    port = lib.types.ints.u16;

    # TODO: Document this.
    string = lib.types.create {
      name = "String";
      description = "string";
      check = builtins.isString;
      merge = lib.options.merge.equal;
    };

    strings = {
      # TODO: Document this.
      required = lib.types.create {
        name = "StringNonEmpty";
        description = "non-empty string";
        check = value: lib.types.string.check value && !(lib.strings.validate.empty value);
        merge = lib.options.merge.equal;
      };

      # TODO: Document this.
      matching = pattern:
        lib.types.create {
          name = "StringMatching ${pattern}";
          description = "string matching the pattern ${pattern}";
          check = value: lib.types.string.check value && builtins.match pattern value != null;
          merge = lib.options.merge.equal;
        };

      # TODO: Document this.
      concat = separator:
        lib.types.create {
          name = "StringConcat";
          description =
            if separator == ""
            then "concatenated string"
            else "string concatenated with ${builtins.toJSON separator}";
          check = value: lib.types.string.check value;
          merge = location: definitions:
            builtins.concatStringsSep
            separator
            (lib.options.getDefinitionValues definitions);
          functor =
            lib.types.functor "strings.concat"
            // {
              payload = separator;
              merge = x: y:
                if x == y
                then x
                else null;
            };
        };

      # TODO: Document this.
      line = let
        matcher = lib.types.strings.matching "[^\n\r]*\n?";
      in
        lib.types.create {
          name = "StringLine";
          description = "single line string with an optional new line at the end";
          check = matcher.check;
          merge = location: definitions:
            lib.strings.removeSuffix
            "\n"
            (matcher.merge location definitions);
        };

      # TODO: Document this.
      lines = lib.types.strings.concat "\n";
    };

    attrs = {
      # TODO: Document this.
      any = lib.types.create {
        name = "Attrs";
        description = "attribute set";
        fallback = {value = {};};
        check = builtins.isAttrs;
        merge = location: definitions:
          builtins.foldl'
          (result: definition: result // definition.value)
          {}
          definitions;
      };

      # TODO: Document this.
      of = type:
        lib.types.create {
          name = "AttrsOf";
          description = "AttrsOf (${type.name})";
          fallback = {value = {};};
          check = builtins.isAttrs;
          merge = location: definitions: let
            normalize = definition:
              builtins.mapAttrs
              (name: value: {
                __file__ = definition.__file__;
                value = value;
              })
              definition.value;
            normalized = builtins.map normalize definitions;
            zipper = name: definitions:
              (lib.options.merge.definitions (location ++ [name]) type definitions).optional;
            filtered =
              lib.attrs.filter
              (name: value: value ? value)
              (builtins.zipAttrsWith zipper normalized);
          in
            builtins.mapAttrs (name: value: value.value) filtered;
          getSubOptions = prefix: type.getSubOptions (prefix ++ ["<name>"]);
          getSubModules = type.getSubModules;
          withSubModules = modules: lib.types.attrs.of (type.withSubModules modules);
          functor = lib.types.functor "attrs.of" // {wrapped = type;};
          children = {
            element = type;
          };
        };

      # TODO: Document this.
      lazy = type:
        lib.types.create {
          name = "LazyAttrsOf";
          description = "LazyAttrsOf (${type.name})";
          fallback = {value = {};};
          check = builtins.isAttrs;
          merge = location: definitions: let
            normalize = definition:
              builtins.mapAttrs
              (name: value: {
                __file__ = definition.__file__;
                value = value;
              })
              definition.value;
            normalized = builtins.map normalize definitions;
            zipper = name: definitions: let
              merged = lib.options.merge.definitions (location ++ [name]) type definitions;
            in
              merged.optional.value or type.fallback.value or merged.merged;
          in
            builtins.zipAttrsWith zipper normalized;
          getSubOptions = prefix: type.getSubOptions (prefix ++ ["<name>"]);
          getSubModules = type.getSubModules;
          withSubModules = modules: lib.types.attrs.lazy (type.withSubModules modules);
          functor = lib.types.functor "attrs.lazy" // {wrapped = type;};
          children = {
            element = type;
          };
        };
    };

    # TODO: Document this.
    package = lib.types.create {
      name = "Package";
      description = "package";
      check = value: lib.packages.isDerivation value || lib.paths.validate.store value;
      merge = location: definitions: let
        merged = lib.options.merge.one location definitions;
      in
        if builtins.isPath merged || (builtins.isString merged && !(builtins.hasContext merged))
        then lib.paths.into.drv merged
        else merged;
    };

    packages = {
      # TODO: Document this.
      shell =
        lib.types.package
        // {
          check = value: lib.packages.isDerivation && builtins.hasAttr "shellPath" value;
        };
    };

    # TODO: Document this.
    path = lib.types.create {
      name = "Path";
      description = "path";
      check = value:
        lib.strings.validate.stringifiable value
        && builtins.substring 0 1 (builtins.toString value) == "/";
      merge = lib.options.merge.equal;
    };

    list = {
      # TODO: Document this.
      any = lib.types.list.of lib.types.any;

      # TODO: Document this.
      of = type:
        lib.types.create {
          name = "ListOf";
          description = "ListOf (${type.name})";
          fallback = {value = [];};
          check = builtins.isList;
          merge = location: definitions: let
            result =
              lib.lists.mapWithIndex1 (
                i: definition:
                  lib.lists.mapWithIndex1 (
                    j: value: let
                      resolved =
                        lib.options.merge.definitions
                        (location ++ ["[definition ${builtins.toString i}-entry ${j}]"])
                        type
                        [
                          {
                            file = definition.file;
                            value = value;
                          }
                        ];
                    in
                      resolved.optional
                  )
                  definition.value
              )
              definitions;
            merged = builtins.concatLists result;
            filtered = builtins.filter (definition: definition ? value) merged;
            values = lib.options.getDefinitionValues filtered;
          in
            values;
          getSubOptions = prefix: type.getSubOptions (prefix ++ ["*"]);
          getSubModules = type.getSubModules;
          withSubModules = modules: lib.types.list.of (type.withSubModules modules);
          functor = lib.types.functor "list.of" // {wrapped = type;};
          children = {
            element = type;
          };
        };

      # TODO: Document this.
      required = type:
        lib.types.withCheck
        (lib.types.list.of type)
        (value: value != [])
        // {
          description = "non-empty list of ${type.description}";
          fallback = {};
        };
    };

    # TODO: Document this.
    unique = message: type:
      lib.types.create {
        name = "Unique";
        description = type.description;
        fallback = type.fallback;
        check = type.check;
        merge = lib.options.merge.unique message;
        getSubOptions = type.getSubOptions;
        getSubModules = type.getSubModules;
        withSubModules = modules: lib.types.unique message (type.withSubModules modules);
        functor = lib.types.functor "unique" // {wrapped = type;};
        children = {
          element = type;
        };
      };

    # TODO: Document this.
    # Like unique, but does not merge.
    single = type:
      lib.types.create {
        name = "Single";
        description = type.description;
        fallback = type.fallback;
        check = type.check;
        merge = lib.options.merge.one;
        getSubOptions = type.getSubOptions;
        getSubModules = type.getSubModules;
        withSubModules = modules: lib.types.single (type.withSubModules modules);
        functor = lib.types.functor "unique" // {wrapped = type;};
        children = {
          element = type;
        };
      };

    # TODO: Document this.
    nullish = type:
      lib.types.create {
        name = "Nullish";
        description = "null or ${type.description}";
        fallback = {value = null;};
        check = value: value == null || type.check value;
        merge = location: definitions: let
          identifier = lib.options.getIdentifier location;
          files = builtins.map lib.modules.getFiles definitions;
          serializedFiles = builtins.concatStringsSep " and " files;
          totalNulls = lib.lists.count (definition: definition == null) definitions;
        in
          if totalNulls == builtins.length definitions
          then null
          else if totalNulls != 0
          then builtins.throw "The option `${identifier}` is defined as both null and not null in ${serializedFiles}"
          else type.merge location definitions;
        getSubOptions = type.getSubOptions;
        getSubModules = type.getSubModules;
        withSubModules = modules: lib.types.nullish (type.withSubModules modules);
        functor = lib.types.functor "nullish" // {wrapped = type;};
        children = {
          element = type;
        };
      };

    # TODO: Document this.
    function = type:
      lib.types.create {
        name = "Function";
        description = "function that returns ${type.description}";
        check = builtins.isFunction;
        merge = location: definitions: args: let
          normalize = definition: {
            __file__ = definition.__file__;
            value = definition.value args;
          };
          normalized = builtins.map normalize definitions;
          merged = lib.options.merge.definitions (location ++ ["<function body>"]) type normalized;
        in
          merged.merged;
        getSubOptions = prefix: type.getSubOptions (prefix ++ ["<function body>"]);
        getSubModules = type.getSubModules;
        withSubModules = modules: lib.types.function (type.withSubModules modules);
        functor = lib.types.functor "function" // {wrapped = type;};
        children = {
          element = type;
        };
      };

    # TODO: Document this.
    submodule = modules:
      lib.types.submodules.of {
        modules = lib.lists.from.any modules;
      };

    submodules = {
      # TODO: Document this.
      of = settings @ {
        modules,
        args ? {},
        description ? null,
      }: let
        getModules = builtins.map (
          definition: {
            __file__ = definition.__file__;
            includes = [definition.value];
          }
        );

        base = lib.modules.run {
          inherit args;

          modules =
            [
              {
                options.__module__.args.name = lib.options.create {
                  type = lib.types.string;
                };
                config.__module__.args.name = lib.modules.overrides.default "<name>";
              }
            ]
            ++ modules;
        };

        freeform = base.__module__.freeform;
        name = "Submodule";
      in
        lib.types.create {
          inherit name;
          description =
            if description != null
            then description
            else freeform.description or name;
          fallback = {value = {};};
          check = value: builtins.isAttrs value || builtins.isFunction value || lib.types.path.check value;
          merge = location: definitions: let
            result = base.extend {
              modules =
                [{config.__module__.args.name = lib.lists.last location;}]
                ++ getModules definitions;
            };
          in
            result.config;
          getSubOptions = prefix: let
            result = base.extend {inherit prefix;};
          in
            result.options
            // lib.attrs.when (freeform != null) {
              __freeformOptions__ = freeform.getSubOptions prefix;
            };
          getSubModules = modules;
          withSubModules = modules:
            lib.types.submodules.of {
              inherit args description modules;
            };
          children = lib.attrs.when (freeform != null) {
            inherit freeform;
          };
          functor =
            lib.types.functor "submodule"
            // {
              type = lib.types.submodules.of;
              payload = {
                inherit modules args description;
              };
              merge = x: y: {
                modules = x.modules ++ y.modules;

                args = let
                  intersection = builtins.intersectAttrs x.args y.args;
                in
                  if intersection == {}
                  then x.args // y.args
                  else builtins.throw "A submodule option is declared multiple times with the same args: ${builtins.toString (builtins.attrNames intersection)}";

                description =
                  if x.description == null
                  then y.description
                  else if y.description == null
                  then x.description
                  else if x.description == y.description
                  then x.description
                  else builtins.throw "A submodule description is declared multiple times with conflicting values";
              };
            };
        };
    };

    deferred = {
      # TODO: Document this.
      default = lib.types.deferred.of {
        modules = [];
      };

      # TODO: Document this.
      of = settings @ {modules}: let
        submodule = lib.types.submodule modules;
      in
        lib.types.create {
          name = "Deferred";
          description = "module";
          check = value: builtins.isAttrs value || builtins.isFunction value || lib.types.path.check value;
          merge = location: definitions: {
            includes =
              modules
              ++ builtins.map
              (definition: {
                __file__ = "${definition.__file__}; via ${lib.options.getIdentifier location}";
                includes = [definition.value];
              })
              definitions;
          };
          getSubOptions = submodule.getSubOptions;
          getSubModules = submodule.getSubModules;
          withSubModules = modules:
            lib.types.deferred.of {
              modules = modules;
            };
          functor =
            lib.types.functor "deferred.of"
            // {
              type = lib.types.deferred.of;
              payload = {inherit modules;};
              merge = x: y: {
                modules = x.modules ++ y.modules;
              };
            };
        };
    };

    # TODO: Document this.
    option = lib.types.create {
      name = "Option";
      description = "option";
      check = lib.types.is "option";
      merge = location: definitions: let
        first = builtins.elemAt definitions 0;
        modules =
          builtins.map (definition: {
            __file__ = definition.__file__;
            options = lib.options.create {
              type = definition.value;
            };
          })
          definitions;
        merged = lib.modules.fixup location (lib.options.merge.declarations location modules);
      in
        if builtins.length definitions == 1
        then first.value
        else merged.type;
    };

    # TODO: Document this.
    enum = values: let
      serialize = value:
        if builtins.isString value
        then ''"${value}"''
        else if builtins.isInt value
        then builtins.toString value
        else if builtins.isBool value
        then lib.bools.into.string value
        else ''<${builtins.typeOf value}>'';
    in
      lib.types.create {
        name = "Enum";
        description =
          if values == []
          then "empty enum"
          else if builtins.length values == 1
          then "value ${serialize (builtins.elemAt values 0)} (singular enum)"
          else "one of ${lib.strings.concatMapSep ", " serialize values}";
        check = value: builtins.elem value values;
        merge = lib.options.merge.equal;
        functor =
          lib.types.functor "enum"
          // {
            payload = values;
            merge = x: y: lib.lists.unique (x ++ y);
          };
      };

    # TODO: Document this.
    either = left: right: let
      name = "Either";
      functor =
        lib.types.functor name
        // {
          wrapped = [left right];
        };
    in
      lib.types.create {
        inherit name functor;
        description = "${left.description} or ${right.description}";
        check = value: left.check value || right.check value;
        merge = location: definitions: let
          values = lib.options.getDefinitionValues definitions;
          isLeft = builtins.all left.check values;
          isRight = builtins.all right.check values;
        in
          if isLeft
          then left.merge location definitions
          else if isRight
          then right.merge location definitions
          else lib.options.merge.one location definitions;
        mergeType = f: let
          mergedLeft = left.mergeType (builtins.elemAt f.wrapped 0).functor;
          mergedRight = right.mergeType (builtins.elemAt f.wrapped 1).functor;
        in
          if (f.name == name) && (mergedLeft != null) && (mergedRight != null)
          then functor.type mergedLeft mergedRight
          else null;
        children = {
          inherit left right;
        };
      };

    # TODO: Document this.
    one = types: let
      first = builtins.elemAt types 0;
      rest = lib.lists.tail types;
    in
      if types == []
      then builtins.throw "lib.types.one must be given at least one type"
      else builtins.foldl' lib.types.either first rest;

    # TODO: Document this.
    coerce = initial: transform: final: let
    in
      if initial.getSubModules != null
      then builtins.throw "lib.types.coerce's first argument may not have submodules, but got ${initial.description}"
      else
        lib.types.create {
          name = "Coerce";
          description = "${initial.description} that is transformed to ${final.description}";
          fallback = final.fallback;
          check = value: final.check value || (initial.check value && final.check (transform value));
          merge = location: definitions: let
            process = value:
              if initial.check value
              then transform value
              else value;
            normalize = definition:
              definition
              // {
                value = process definition.value;
              };
            normalized = builtins.map normalize definitions;
          in
            final.merge location normalized;
          getSubOptions = final.getSubOptions;
          getSubModules = final.getSubModules;
          withSubModules = modules:
            lib.types.coerce
            initial
            transform
            (final.withSubModules modules);
          mergeType = x: y: null;
          functor = lib.types.functor "coerce" // {wrapped = final;};
          children = {
            inherit initial final;
          };
        };
  };
}
