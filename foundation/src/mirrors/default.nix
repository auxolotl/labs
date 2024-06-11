{lib}: {
  options.aux.mirrors = {
    gnu = lib.options.create {
      type = lib.types.string;
      default.value = "https://ftp.gnu.org/gnu";
      description = "The GNU mirror to use";
    };
  };
}
