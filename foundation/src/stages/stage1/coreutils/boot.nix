{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage1.coreutils.boot;

  builders = config.aux.foundation.builders;

  stage1 = config.aux.foundation.stages.stage1;
in {
  options.aux.foundation.stages.stage1.coreutils.boot = {
    package = lib.options.create {
      type = lib.types.derivation;
      description = "The package to use for coreutils-boot.";
    };

    version = lib.options.create {
      type = lib.types.string;
      description = "Version of the package.";
    };

    src = lib.options.create {
      type = lib.types.derivation;
      description = "Source for the package.";
    };
  };

  config = {
    aux.foundation.stages.stage1.coreutils.boot = {
      version = "5.0";

      src = builtins.fetchurl {
        url = "${config.aux.mirrors.gnu}/coreutils/coreutils-${cfg.version}.tar.gz";
        sha256 = "10wq6k66i8adr4k08p0xmg87ff4ypiazvwzlmi7myib27xgffz62";
      };

      package = let
        # Thanks to the live-bootstrap project!
        # See https://github.com/fosslinux/live-bootstrap/blob/a8752029f60217a5c41c548b16f5cdd2a1a0e0db/sysa/coreutils-5.0/coreutils-5.0.kaem
        liveBootstrap = "https://github.com/fosslinux/live-bootstrap/raw/a8752029f60217a5c41c548b16f5cdd2a1a0e0db/sysa/coreutils-5.0";

        makefile = builtins.fetchurl {
          url = "${liveBootstrap}/mk/main.mk";
          sha256 = "0njg4xccxfqrslrmlb8ls7h6hlnfmdx42nvxwmca8flvczwrplfd";
        };

        patches = [
          # modechange.h uses functions defined in sys/stat.h, so we need to move it to
          # after sys/stat.h include.
          (builtins.fetchurl {
            url = "${liveBootstrap}/patches/modechange.patch";
            sha256 = "04xa4a5w2syjs3xs6qhh8kdzqavxnrxpxwyhc3qqykpk699p3ms5";
          })
          # mbstate_t is a struct that is required. However, it is not defined by mes libc.
          (builtins.fetchurl {
            url = "${liveBootstrap}/patches/mbstate.patch";
            sha256 = "0rz3c0sflgxjv445xs87b83i7gmjpl2l78jzp6nm3khdbpcc53vy";
          })
          # strcoll() does not exist in mes libc, change it to strcmp.
          (builtins.fetchurl {
            url = "${liveBootstrap}/patches/ls-strcmp.patch";
            sha256 = "0lx8rz4sxq3bvncbbr6jf0kyn5bqwlfv9gxyafp0541dld6l55p6";
          })
          # getdate.c is pre-compiled from getdate.y
          # At this point we don't have bison yet and in any case getdate.y does not
          # compile when generated with modern bison.
          (builtins.fetchurl {
            url = "${liveBootstrap}/patches/touch-getdate.patch";
            sha256 = "1xd3z57lvkj7r8vs5n0hb9cxzlyp58pji7d335snajbxzwy144ma";
          })
          # touch: add -h to change symlink timestamps, where supported
          (builtins.fetchurl {
            url = "${liveBootstrap}/patches/touch-dereference.patch";
            sha256 = "0wky5r3k028xwyf6g6ycwqxzc7cscgmbymncjg948vv4qxsxlfda";
          })
          # strcoll() does not exist in mes libc, change it to strcmp.
          (builtins.fetchurl {
            url = "${liveBootstrap}/patches/expr-strcmp.patch";
            sha256 = "19f31lfsm1iwqzvp2fyv97lmqg4730prfygz9zip58651jf739a9";
          })
          # strcoll() does not exist in mes libc, change it to strcmp.
          # hard_LC_COLLATE is used but not declared when HAVE_SETLOCALE is unset.
          (builtins.fetchurl {
            url = "${liveBootstrap}/patches/sort-locale.patch";
            sha256 = "0bdch18mpyyxyl6gyqfs0wb4pap9flr11izqdyxccx1hhz0a2i6c";
          })
          # don't assume fopen cannot return stdin or stdout.
          (builtins.fetchurl {
            url = "${liveBootstrap}/patches/uniq-fopen.patch";
            sha256 = "0qs6shyxl9j4h34v5j5sgpxrr4gjfljd2hxzw416ghwc3xzv63fp";
          })
        ];
      in
        builders.kaem.build {
          name = "coreutils-boot-${cfg.version}";

          meta = stage1.coreutils.meta;

          deps.build.host = [
            stage1.tinycc.mes.compiler.package
            stage1.gnumake.boot.package
            stage1.gnupatch.package
          ];

          script = ''
            # Unpack
            ungz --file ${cfg.src} --output coreutils.tar
            untar --file coreutils.tar
            rm coreutils.tar
            cd coreutils-${cfg.version}

            # Patch
            ${lib.strings.concatMapSep "\n" (file: "patch -Np0 -i ${file}") patches}

            # Configure
            catm config.h
            cp lib/fnmatch_.h lib/fnmatch.h
            cp lib/ftw_.h lib/ftw.h
            cp lib/search_.h lib/search.h
            rm src/dircolors.h

            # Build
            make -f ${makefile} \
              CC="tcc -B ${stage1.tinycc.mes.libs.package}/lib" \
              PREFIX=''${out}

            # Check
            ./src/echo "Hello coreutils!"

            # Install
            ./src/mkdir -p ''${out}/bin
            make -f ${makefile} install PREFIX=''${out}

          '';
        };
    };
  };
}
