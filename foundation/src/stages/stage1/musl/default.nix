{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage1.musl;

  platform = config.aux.platform;
  builders = config.aux.foundation.builders;

  stage1 = config.aux.foundation.stages.stage1;
in {
  includes = [
    ./boot.nix
  ];

  options.aux.foundation.stages.stage1.musl = {
    package = lib.options.create {
      type = lib.types.package;
      description = "The package to use for musl.";
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
        default.value = "An efficient, small, quality libc implementation";
      };

      homepage = lib.options.create {
        type = lib.types.string;
        description = "Homepage for the package.";
        default.value = "https://musl.libc.org";
      };

      license = lib.options.create {
        # TODO: Add a proper type for licenses.
        type = lib.types.attrs.any;
        description = "License for the package.";
        default.value = lib.licenses.mit;
      };

      platforms = lib.options.create {
        type = lib.types.list.of lib.types.string;
        description = "Platforms the package supports.";
        # TODO: Support more platforms.
        default.value = ["i686-linux"];
      };
    };
  };

  config = {
    aux.foundation.stages.stage1.musl = {
      version = "1.2.4";

      src = builtins.fetchurl {
        url = "https://musl.libc.org/releases/musl-${cfg.version}.tar.gz";
        sha256 = "ejXq4z1TcqfA2hGI3nmHJvaIJVE7euPr6XqqpSEU8Dk=";
      };

      package = builders.bash.build {
        name = "musl-${cfg.version}";

        meta = cfg.meta;

        deps.build.host = [
          stage1.gcc.v46.package
          stage1.binutils.package
          stage1.gnumake.package
          stage1.gnused.package
          stage1.gnugrep.package
          stage1.gnutar.musl.package
          stage1.gzip.package
        ];

        script = ''
          # Unpack
          tar xzf ${cfg.src}
          cd musl-${cfg.version}

          # Patch
          # https://github.com/ZilchOS/bootstrap-from-tcc/blob/2e0c68c36b3437386f786d619bc9a16177f2e149/using-nix/2a3-intermediate-musl.nix
          sed -i 's|/bin/sh|${stage1.bash.package}/bin/bash|' \
            tools/*.sh
          # patch popen/system to search in PATH instead of hardcoding /bin/sh
          sed -i 's|posix_spawn(&pid, "/bin/sh",|posix_spawnp(\&pid, "sh",|' \
            src/stdio/popen.c src/process/system.c
          sed -i 's|execl("/bin/sh", "sh", "-c",|execlp("sh", "-c",|'\
            src/misc/wordexp.c

          # Configure
          bash ./configure \
            --prefix=$out \
            --build=${platform.build} \
            --host=${platform.host} \
            --syslibdir=$out/lib \
            --enable-wrapper

          # Build
          make -j $NIX_BUILD_CORES

          # Install
          make -j $NIX_BUILD_CORES install
          sed -i 's|/bin/sh|${stage1.bash.package}/bin/bash|' $out/bin/*
          ln -s ../lib/libc.so $out/bin/ldd
        '';
      };
    };
  };
}
