lib: {
  errors = {
    trace = condition: message:
      if condition
      then true
      else builtins.trace message false;
  };
}
