{
  lib,
  config,
}: let
  lib' = config.lib;
in {
  lib.types = {
    license = let
      type = lib.types.submodule ({config}: {
        options = {
          name = {
            full = lib.options.create {
              type = lib.types.string;
              description = "The full name of the license.";
            };

            short = lib.options.create {
              type = lib.types.string;
              description = "The short name of the license.";
            };
          };

          spdx = lib.options.create {
            type = lib.types.nullish lib.types.string;
            default.value = null;
            description = "The SPDX identifier for the license.";
          };

          url = lib.options.create {
            type = lib.types.nullish lib.types.string;
            description = "The URL for the license.";
          };

          free = lib.options.create {
            type = lib.types.bool;
            default.value = true;
            description = "Whether the license is free.";
          };

          redistributable = lib.options.create {
            type = lib.types.bool;
            default = {
              text = "config.free";
              value = config.free;
            };
            description = "Whether the license is allows redistribution.";
          };
        };
      });
    in
      lib.types.either type (lib.types.list.of type);

    meta = lib.types.submodule {
      options = {
        name = lib.options.create {
          type = lib.types.string;
          description = "The name of the package.";
        };

        description = lib.options.create {
          type = lib.types.nullish lib.types.string;
          default.value = null;
          description = "The description for the package.";
        };

        homepage = lib.options.create {
          type = lib.types.nullish lib.types.string;
          default.value = null;
          description = "The homepage for the package.";
        };

        license = lib.options.create {
          type = config.lib.types.license;
          description = "The license for the package.";
        };

        free = lib.options.create {
          type = lib.types.bool;
          default.value = true;
          description = "Whether the package is free.";
        };

        insecure = lib.options.create {
          type = lib.types.bool;
          default.value = false;
          description = "Whether the package is insecure.";
        };

        broken = lib.options.create {
          type = lib.types.bool;
          default.value = false;
          description = "Whether the package is broken.";
        };

        main = lib.options.create {
          type = lib.types.nullish lib.types.string;
          default.value = null;
          description = "The main entry point for the package.";
        };

        platforms = lib.options.create {
          type = lib.types.list.of lib.types.string;
          default.value = [];
          description = "The platforms the package supports.";
        };
      };
    };

    package = lib.types.submodule ({config}: {
      freeform = lib.types.any;

      options = {
        name = lib.options.create {
          type = lib.types.string;
          default = {
            value = "${config.pname}-${config.version or "unknown"}";
            text = "\${config.pname}-\${config.version}";
          };
          description = "The name of the package.";
        };

        pname = lib.options.create {
          type = lib.types.nullish lib.types.string;
          default.value = null;
          description = "The name of the package.";
        };

        version = lib.options.create {
          type = lib.types.nullish lib.types.string;
          default.value = null;
          description = "The version of the package.";
        };

        meta = lib.options.create {
          type = lib'.types.meta;
          default = {
            text = "{ name = <package>.pname; }";
            value = {
              name = config.pname;
            };
          };
          description = "The metadata for the package.";
        };

        env = lib.options.create {
          type = lib.types.attrs.of lib.types.string;
          default.value = {};
          description = "Environment variables for the package's builder to use.";
        };

        phases = lib.options.create {
          type = lib.types.dag.of (
            lib.types.either
            lib.types.string
            (lib.types.function lib.types.string)
          );
          default.value = {};
          description = "Phases for the package's builder to use.";
        };

        platform = {
          build = lib.options.create {
            type = lib.types.string;
            description = "The platform the package is built on.";
          };

          host = lib.options.create {
            type = lib.types.string;
            description = "The platform the package is run on.";
          };

          target = lib.options.create {
            type = lib.types.string;
            description = "The platform the package generates code for.";
          };
        };

        builder = lib.options.create {
          type = lib'.types.builder;
          description = "The builder for the package.";
        };

        package = lib.options.create {
          type = lib.types.derivation;
          default = {
            value = config.builder.build config.builder config;
            text = "<derivation>";
          };
          description = "The package derivation.";
        };

        deps = {
          build = {
            only = lib.options.create {
              type = lib'.types.dependencies;
              default.value = {};
              description = "Dependencies which are only used in the build environment.";
            };

            build = lib.options.create {
              type = lib'.types.dependencies;
              default.value = {};
              description = "Dependencies which are created in the build environment and are run in the build environment.";
            };

            host = lib.options.create {
              type = lib'.types.dependencies;
              default.value = {};
              description = "Dependencies which are created in the build environment and are run in the host environment.";
            };

            target = lib.options.create {
              type = lib'.types.dependencies;
              default.value = {};
              description = "Dependencies which are created in the build environment and are run in the target environment.";
            };
          };

          host = {
            only = lib.options.create {
              type = lib'.types.dependencies;
              default.value = {};
              description = "Dependencies which are only used in the host environment.";
            };

            host = lib.options.create {
              type = lib'.types.dependencies;
              default.value = {};
              description = "Dependencies which are run in the host environment.";
            };

            target = lib.options.create {
              type = lib'.types.dependencies;
              default.value = {};
              description = "Dependencies which are run in the host environment which produces code for the target environment.";
            };
          };

          target = {
            only = lib.options.create {
              type = lib'.types.dependencies;
              default.value = {};
              description = "Dependencies which are only used in the target environment.";
            };

            target = lib.options.create {
              type = lib'.types.dependencies;
              default.value = {};
              description = "Dependencies which are run in the target environment.";
            };
          };
        };

        versions = lib.options.create {
          type = lib.types.attrs.of lib'.types.package;
          default.value = {};
          description = "Available versions of the package.";
        };
      };
    });

    dependencies = lib.types.attrs.of (lib.types.nullish lib'.types.package);

    packages = lib.types.attrs.of (lib.types.submodule {
      freeform = lib.types.nullish lib'.types.package;
    });

    builder = lib.types.submodule {
      freeform = lib.types.any;

      options = {
        build = lib.options.create {
          type = lib.types.function lib.types.derivation;
          description = "The function that creates the package derivation.";
        };
      };
    };
  };
}
