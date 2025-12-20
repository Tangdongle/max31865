defmodule Max31865.Registers.Helpers do
  def xfer(spi, data) do
    case Circuits.SPI.transfer(spi, data) do
      {:ok, resp} when is_binary(resp) -> resp
      resp when is_binary(resp) -> resp
      {:error, reason} -> raise "SPI transfer failed: #{inspect(reason)}"
    end
  end
end
