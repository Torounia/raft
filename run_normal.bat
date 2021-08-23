taskkill /IM erl.exe /F

set run_env=normal

start /min cmd /c iex --sname test@localhost --cookie secret -S mix
start /min cmd /c iex --sname peer1@localhost --cookie secret -S mix
start /min cmd /c iex --sname peer2@localhost --cookie secret -S mix
start /min cmd /c iex --sname peer3@localhost --cookie secret -S mix

