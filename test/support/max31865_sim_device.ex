defmodule Max31865SimDevice do
  @moduledoc """
  CircuitsSim SPI device emulating the small subset of MAX31865 behavior

  Supported transfers:
    - <<0x00, _>>         : read config -> returns <<0x00, config>>
    - <<0x80, config>>    : write config
    - <<0x01, 0x00, 0x00>>: read RTD -> returns <<0x00, raw15::15, fault::1>>

  You can mutate state in tests via handle_message/2:
    - {:set_rtd_raw, raw15}
    - {:set_fault, 0 | 1}
    - {:set_config, byte}
  """

  import Bitwise
  alias CircuitsSim.SPI.SPIDevice
  alias CircuitsSim.SPI.SPIServer

  @type t :: %__MODULE__{
          config: 0..255,
          rtd_raw: 0..0x7FFF,
          fault_bit: 0 | 1
        }

  defstruct config: 0x00,
            rtd_raw: 0,
            fault_bit: 0
  @spec child_spec(keyword()) :: Supervisor.child_spec()
  def child_spec(args) do
    device = new(args)
    SPIServer.child_spec_helper(device, args)
  end

  @doc "Convenience constructor for tests."
  def new(opts \\ []) do
    %__MODULE__{
      config: Keyword.get(opts, :config, 0x00) &&& 0xFF,
      rtd_raw: Keyword.get(opts, :rtd_raw, 0) &&& 0x7FFF,
      fault_bit: normalize_fault(Keyword.get(opts, :fault_bit, 0))
    }
  end

  defp normalize_fault(1), do: 1
  defp normalize_fault(true), do: 1
  defp normalize_fault(_), do: 0

  # MAX31865 config bits (per your ConfigRegister layout):
  # one_shot is bit 5 (0x20), fault_clear is bit 1 (0x02) and they self-clear.
  defp self_clear_bits(config_byte) do
    config_byte &&& 0xDD
  end

  defimpl SPIDevice do
    alias Max31865

    @impl SPIDevice
    def transfer(%Max31865SimDevice{} = state, data) when is_binary(data) do
      case data do
        # Config register read: library sends <<0x00, 0x00>>
        <<0x00, _dummy>> ->
          {<<0x00, state.config>>, state}

        # Config register write: library sends <<0x80, bits>>
        <<0x80, bits>> ->
        new_state = %{state | config: bits}
          # library doesn't check the response; return same length
          {<<0x00, 0x00>>, new_state}

        # RTD resistance register read: library sends <<0x01, 0x00, 0x00>>
        <<0x01, _d1, _d2>> ->
          raw = state.rtd_raw &&& 0x7FFF
          fault = state.fault_bit
          # 3 bytes total: <<0x00, 16-bit payload>>
          payload = <<raw::15, fault::1>>
          {<<0x00, payload::bitstring>>, state}

        # Default: return zeros (same size)
        _ ->
          {:binary.copy(<<0>>, byte_size(data)), state}
      end
    end

    @impl SPIDevice
    def snapshot(state), do: state

    @impl SPIDevice
    def handle_message(state, {:set_rtd_raw, raw}) when is_integer(raw) and raw >= 0 do
      {:ok, %{state | rtd_raw: raw &&& 0x7FFF}}
    end

    @impl SPIDevice
    def handle_message(state, {:set_fault, fault}) do
      fault_bit =
        case fault do
          1 -> 1
          true -> 1
          _ -> 0
        end

      {:ok, %{state | fault_bit: fault_bit}}
    end

    @impl SPIDevice
    def handle_message(state, {:set_config, byte}) when is_integer(byte) do
      {:ok, %{state | config: byte &&& 0xFF}}
    end

    @impl SPIDevice
    def handle_message(state, _message) do
      {:unimplemented, state}
    end
  end

  defimpl String.Chars do
    alias Max31865SimDevice

    def to_string(%Max31865SimDevice{} = state) do
      [
        "MAX31865 (sim)\n",
        "  config: 0x",
        Integer.to_string(state.config, 16),
        "\n",
        "  rtd_raw: ",
        Integer.to_string(state.rtd_raw),
        " (0x",
        Integer.to_string(state.rtd_raw, 16),
        ")\n",
        "  fault_bit: ",
        Integer.to_string(state.fault_bit),
        "\n"
      ]
      |> IO.iodata_to_binary()
    end
  end
end
