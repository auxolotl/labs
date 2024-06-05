{
  description = "A NixPkgs library replacement containing helper functions and a module system.";

  outputs = _: {
    lib = import ./src;
  };
}
