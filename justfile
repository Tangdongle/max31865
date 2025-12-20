
build_deps:
  mix deps.get

test $MIX_ENV="test" $MIX_TARGET="host": build_deps
  mix test

test_shell $MIX_ENV="test" $MIX_TARGET="host":
  iex -S mix
