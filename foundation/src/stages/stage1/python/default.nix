{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage1.python;

  platform = config.aux.platform;
  builders = config.aux.foundation.builders;

  stage1 = config.aux.foundation.stages.stage1;
in {
  options.aux.foundation.stages.stage1.python = {
    package = lib.options.create {
      type = lib.types.package;
      description = "The package to use for python.";
    };

    version = lib.options.create {
      type = lib.types.string;
      description = "Version of the package.";
    };

    src = lib.options.create {
      type = lib.types.package;
      description = "Source for the package.";
    };

    meta = {
      description = lib.options.create {
        type = lib.types.string;
        description = "Description for the package.";
        default.value = "A high-level dynamically-typed programming language.";
      };

      homepage = lib.options.create {
        type = lib.types.string;
        description = "Homepage for the package.";
        default.value = "https://www.python.org";
      };

      license = lib.options.create {
        # TODO: Add a proper type for licenses.
        type = lib.types.attrs.any;
        description = "License for the package.";
        default.value = lib.licenses.psfl;
      };

      platforms = lib.options.create {
        type = lib.types.list.of lib.types.string;
        description = "Platforms the package supports.";
        default.value = ["i686-linux"];
      };
    };
  };

  config = {
    aux.foundation.stages.stage1.python = {
      version = "3.12.0";

      src = builtins.fetchurl {
        url = "https://www.python.org/ftp/python/${cfg.version}/Python-${cfg.version}.tar.xz";
        sha256 = "eVw09E30Wg6blxDIxxwVxnGHFSTNQSyhTe8hLozLFV0=";
      };

      package = let
        patches = [
          # Disable the use of ldconfig in ctypes.util.find_library (since
          # ldconfig doesn't work on NixOS), and don't use
          # ctypes.util.find_library during the loading of the uuid module
          # (since it will do a futile invocation of gcc (!) to find
          # libuuid, slowing down program startup a lot).
          ./patches/no-ldconfig.patch
        ];
      in
        builders.bash.build {
          name = "python-${cfg.version}";
          meta = cfg.meta;

          deps.build.host = [
            stage1.gcc.package
            stage1.musl.package
            stage1.binutils.package
            stage1.gnumake.package
            stage1.gnupatch.package
            stage1.gnused.package
            stage1.gnugrep.package
            stage1.gawk.package
            stage1.diffutils.package
            stage1.findutils.package
            stage1.gnutar.package
            stage1.xz.package
          ];

          script = ''
            # Unpack
            tar xf ${cfg.src}
            cd Python-${cfg.version}

            # Patch
            ${lib.strings.concatMapSep "\n" (file: "patch -Np1 -i ${file}") patches}

            # Configure
            export CC=musl-gcc
            export C_INCLUDE_PATH="${stage1.zlib.package}/include"
            export LIBRARY_PATH="${stage1.zlib.package}/lib"
            export LD_LIBRARY_PATH="$LIBRARY_PATH"
            bash ./configure \
              --prefix=$out \
              --build=${platform.build} \
              --host=${platform.host}

            # Build
            make -j $NIX_BUILD_CORES

            # Install
            make -j $NIX_BUILD_CORES install
          '';
        };
    };
  };
}
