
test $MIX_ENV="test" $MIX_TARGET="host":
  mix test

test_shell $MIX_ENV="test" $MIX_TARGET="host":
  iex -S mix
