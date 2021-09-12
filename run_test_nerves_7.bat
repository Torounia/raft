taskkill /IM erl.exe /F
del *.log
del *@localhost

set run_env=nerves_test_7

start cmd /c iex --name "test@Surface.local" --cookie secret -S mix