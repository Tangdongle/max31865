defmodule Max31865Test do
  use ExUnit.Case, async: false
  doctest Max31865

  alias Circuits.SPI
  alias Max31865.Registers.{ConfigRegister, RTDResistanceRegister}

  test "read from device: RTDResistanceRegister.read/1 returns expected raw value" do
    {:ok, spi} = SPI.open("spidev0.0", mode: 1, speed_hz: 500_000)

    assert {:ok, 12_345} = RTDResistanceRegister.read(spi)
  end

  test "write then read: ConfigRegister.write/2 updates simulated config register" do
    {:ok, spi} = SPI.open("spidev0.0", mode: 1, speed_hz: 500_000)

    # Build a config with a known bit-pattern.
    # to_bits packs bits in order:
    # vbias, conversion_mode, one_shot, three_wire, fault_one, fault_two, fault_clear, filter_select
    cfg = %ConfigRegister{
      vbias: 1,
      conversion_mode: 1,
      one_shot: 0,
      three_wire: 1,
      fault_one: 0,
      fault_two: 0,
      fault_clear: 0,
      filter_select: 0
    }

    _resp = ConfigRegister.write(cfg, spi)

    readback = ConfigRegister.read(spi)

    assert readback.vbias == 1
    assert readback.conversion_mode == 1
    assert readback.one_shot == 0
    assert readback.three_wire == 1
    assert readback.fault_clear == 0
    assert readback.filter_select == 0
  end
end
