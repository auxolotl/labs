{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage1.musl.boot;

  platform = config.aux.platform;
  builders = config.aux.foundation.builders;

  stage1 = config.aux.foundation.stages.stage1;
in {
  options.aux.foundation.stages.stage1.musl.boot = {
    package = lib.options.create {
      type = lib.types.package;
      description = "The package to use for musl-boot.";
    };

    version = lib.options.create {
      type = lib.types.string;
      description = "Version of the package.";
    };

    src = lib.options.create {
      type = lib.types.package;
      description = "Source for the package.";
    };
  };

  config = {
    aux.foundation.stages.stage1.musl.boot = {
      version = "1.1.24";

      src = builtins.fetchurl {
        url = "https://musl.libc.org/releases/musl-${cfg.version}.tar.gz";
        sha256 = "E3DJqBKyzyp9koAlEMygBYzDfmanvt1wBR8KNAFQIqM=";
      };

      package = let
        # Thanks to the live-bootstrap project!
        # See https://github.com/fosslinux/live-bootstrap/blob/d98f97e21413efc32c770d0356f1feda66025686/sysa/musl-1.1.24/musl-1.1.24.sh
        liveBootstrap = "https://github.com/fosslinux/live-bootstrap/raw/d98f97e21413efc32c770d0356f1feda66025686/sysa/musl-1.1.24";
        patches = [
          (builtins.fetchurl {
            url = "${liveBootstrap}/patches/avoid_set_thread_area.patch";
            sha256 = "TsbBZXk4/KMZG9EKi7cF+sullVXrxlizLNH0UHGXsPs=";
          })
          (builtins.fetchurl {
            url = "${liveBootstrap}/patches/avoid_sys_clone.patch";
            sha256 = "/ZmH64J57MmbxdfQ4RNjamAiBdkImMTlHsHdgV4gMj4=";
          })
          (builtins.fetchurl {
            url = "${liveBootstrap}/patches/fenv.patch";
            sha256 = "vMVGjoN4deAJW5gsSqA207SJqAbvhrnOsGK49DdEiTI=";
          })
          (builtins.fetchurl {
            url = "${liveBootstrap}/patches/makefile.patch";
            sha256 = "03iYBAUnsrEdLIIhhhq5mM6BGnPn2EfUmIHu51opxbw=";
          })
          (builtins.fetchurl {
            url = "${liveBootstrap}/patches/musl_weak_symbols.patch";
            sha256 = "/d9a2eUkpe9uyi1ye6T4CiYc9MR3FZ9na0Gb90+g4v0=";
          })
          (builtins.fetchurl {
            url = "${liveBootstrap}/patches/set_thread_area.patch";
            sha256 = "RIZYqbbRSx4X/0iFUhriwwBRmoXVR295GNBUjf2UrM0=";
          })
          (builtins.fetchurl {
            url = "${liveBootstrap}/patches/sigsetjmp.patch";
            sha256 = "wd2Aev1zPJXy3q933aiup5p1IMKzVJBquAyl3gbK4PU=";
          })
          # FIXME: this patch causes the build to fail
          # (builtins.fetchurl {
          #   url = "${liveBootstrap}/patches/stdio_flush_on_exit.patch";
          #   sha256 = "/z5ze3h3QTysay8nRvyvwPv3pmTcKptdkBIaMCoeLDg=";
          # })
          # HACK: always flush stdio immediately
          ./patches/always-flush.patch
          (builtins.fetchurl {
            url = "${liveBootstrap}/patches/va_list.patch";
            sha256 = "UmcMIl+YCi3wIeVvjbsCyqFlkyYsM4ECNwTfXP+s7vg=";
          })
        ];
      in
        builders.bash.boot.build {
          name = "musl-boot-${cfg.version}";

          meta = stage1.musl.meta;

          deps.build.host = [
            stage1.tinycc.mes.compiler.package
            stage1.gnumake.package
            stage1.gnused.boot.package
            stage1.gnugrep.package
            stage1.gnupatch.package
            stage1.gnutar.boot.package
            stage1.gzip.package
          ];

          script = ''
            # Unpack
            tar xzf ${cfg.src}
            cd musl-${cfg.version}

            # Patch
            ${lib.strings.concatMapSep "\n" (file: "patch -Np0 -i ${file}") patches}
            # tcc does not support complex types
            rm -rf src/complex
            # Configure fails without this
            mkdir -p /dev
            # https://github.com/ZilchOS/bootstrap-from-tcc/blob/2e0c68c36b3437386f786d619bc9a16177f2e149/using-nix/2a3-intermediate-musl.nix
            sed -i 's|/bin/sh|${stage1.bash.boot.package}/bin/bash|' \
              tools/*.sh
            chmod 755 tools/*.sh
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
              --disable-shared \
              CC=tcc

            # Build
            make AR="tcc -ar" RANLIB=true CFLAGS="-DSYSCALL_NO_TLS"

            # Install
            make install
            cp ${stage1.tinycc.mes.libs.package}/lib/libtcc1.a $out/lib

          '';
        };
    };
  };
}
