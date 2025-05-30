require 'phonelib'

# Farbdefinitionen
R = "\033[1;31m"
O = "\033[38;5;214m"

def phone_number_info(phone_number)
  Phonelib.default_country = 'US'  # Fallback
  parsed = Phonelib.parse(phone_number)

  unless parsed.valid?
    return "The phone number #{phone_number} is not valid."
  end

  info = {
    "Phone Number"      => parsed.international,
    "Valid"             => parsed.valid?,
    "Region"            => parsed.country,
    "Carrier"           => parsed.carrier || "Not found",
    "Timezones"         => parsed.timezone || "N/A",
    "Country Code"      => parsed.country_code,
    "National Number"   => parsed.national
    # "Region Code"     => parsed.region  ❌ entfernen, da Methode nicht existiert
  }

  info
end


def display_phone_info(info)
  if info.is_a?(Hash)
    puts "\n======================= INFORMATION FOR PHONE NUMBER: #{info["Phone Number"]} ========================"
    puts ""
    puts "#{R}Valid:                   #{O}:           #{R}#{info['Valid'] ? 'Yes' : 'No'}"
    puts "#{R}Region:                  #{O}:           #{R}#{info['Region']}"
    puts "#{R}Carrier:                 #{O}:           #{R}#{info['Carrier']}"
    puts "#{R}Timezones:               #{O}:           #{R}#{info['Timezones']}"
    puts "#{R}Country Code:            #{O}:           #{R}#{info['Country Code']}"
    puts "#{R}National Number:         #{O}:           #{R}#{info['National Number']}"
    puts "#{R}Region Code:             #{O}:           #{R}#{info['Region Code']}"
  else
    puts info
  end
end

# Optional für Einzelstart
if __FILE__ == $0
  print "Enter the phone number (with country code, e.g., +1 800 555 5555): "
  number = gets.strip
  info = phone_number_info(number)
  display_phone_info(info)
end
