# frozen_string_literal: true

module UPS
  PACKAGING = {
    "00" => "UNKNOWN",
    "01" => "UPS Letter",
    "02" => "Package",
    "03" => "Tube",
    "04" => "Pak",
    "21" => "Express Box",
    "24" => "25KG Box",
    "25" => "10KG Box",
    "30" => "Pallet",
    "2a" => "Small Express Box",
    "2b" => "Medium Express Box",
    "2c" => "Large Express Box"
  }.freeze
end
