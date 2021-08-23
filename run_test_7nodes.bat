taskkill /IM erl.exe /F

set run_env=test_7

start cmd /c iex --sname test@localhost --cookie secret -S mix
start /min cmd /c iex --sname peer1@localhost --cookie secret -S mix
start /min cmd /c iex --sname peer2@localhost --cookie secret -S mix
start /min cmd /c iex --sname peer3@localhost --cookie secret -S mix
start /min cmd /c iex --sname peer4@localhost --cookie secret -S mix
start /min cmd /c iex --sname peer5@localhost --cookie secret -S mix
start /min cmd /c iex --sname peer6@localhost --cookie secret -S mix
start /min cmd /c iex --sname peer7@localhost --cookie secret -S mix