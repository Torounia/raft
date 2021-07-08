defmodule Raft.GetHostIP do
  def getIP do
    {type, _} = :os.type()

    case type do
      :win32 -> sysWin32()
      :unix -> sysUnix()
    end
  end

  def sysWin32 do
    {hostname, _} = System.cmd("hostname", [])
    hostname_regex = Regex.run(~r/[\S]*/, hostname)
    {res, _} = System.cmd("ping", [List.to_string(hostname_regex), "-4"])
    ip_regex = Regex.run(~r/\[(.*?)\]/, res)
    ip = Enum.at(ip_regex, 1)
  end

  def sysUnix do
    {ip_string, 0} = System.cmd("hostname", ["-I"])
    ip = Regex.run(~r/[\S]*/, ip_string)
  end
end
