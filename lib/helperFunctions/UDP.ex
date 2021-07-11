defmodule UDP do
  def init do
    {:ok, socket} = :gen_udp.open(8680, [:binary, {:active, false}, broadcast: true])
    IO.inspect(socket, label: "Init done with socket")
    IO.inspect(:inet.getif(), label: "my ip is")
    receiver(socket)
  end

  def receiver(socket) do
    {:ok, {ip, port, data}} = :gen_udp.recv(socket, 0)
    IO.puts("received message #{data}")
    IO.inspect(ip)
    receiver(socket)
  end
end
