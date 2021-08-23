taskkill /IM erl.exe /F
del *.log
del *@localhost

set run_env=test_3

start cmd /c iex --sname test@localhost --cookie secret -S mix
start /min cmd /c iex --sname peer1@localhost --cookie secret -S mix
start /min cmd /c iex --sname peer2@localhost --cookie secret -S mix
start /min cmd /c iex --sname peer3@localhost --cookie secret -S mix