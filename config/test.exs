import Config

config :circuits_spi, default_backend: CircuitsSim.SPI.Backend

config :circuits_sim,
  config: [
    {Max31865SimDevice, bus_name: "spidev0.0", rtd_raw: 12_345, fault_bit: 0, config_reg: 0x00}
  ]
