require 'json'
require 'net/http'
require 'uri'

module ReverseIPLookup
  # Konfiguration laden
  def self.load_config
    config_path = 'config/config.json'
    unless File.exist?(config_path)
      puts "❗ Konfigurationsdatei #{config_path} nicht gefunden."
      return [nil, nil]
    end

    config_data = JSON.parse(File.read(config_path))
    api_key = config_data[0]['api_key']
    url = config_data[0]['url']
    [api_key, url]
  end

  # Reverse-IP-Lookup durchführen
  def self.run(ip)
    if ip.nil? || ip.strip.empty?
      puts "\n🔍 IP-Adresse wird benötigt."
      return
    end

    puts "\n🔍 Suche nach Domains, die auf #{ip} gehostet werden..."

    api_key, base_url = load_config
    return if api_key.nil? || base_url.nil?

    full_url = "#{base_url}?apiKey=#{api_key}&ip=#{ip}"
    uri = URI(full_url)

    begin
      puts "→ Anfrage an API: #{uri}"
      response = Net::HTTP.get_response(uri)

      if response.code.to_i != 200
        puts "❗ Fehlerhafte Antwort: HTTP #{response.code}"
        return
      end

      data = JSON.parse(response.body)
      puts "\n🌐 Antwort empfangen: #{data}"

      if data['result'].is_a?(Array)
        domains = data['result']
        if domains.empty?
          puts "⚠️ Keine Domains gefunden für diese IP."
        else
          puts "\n🔎 Gefundene Domains für IP #{ip}:"
          puts "=========================================="
          domains.each do |entry|
            puts "  • #{entry['name'] || 'Unbekannter Domainname'}"
          end
        end
      else
        puts "❗ 'result' ist kein Array oder fehlt."
      end

      if data['result'].is_a?(Array)
        return data['result']
      end
      return nil

    rescue => e
      puts "❗ Fehler beim API-Aufruf: #{e.message}"
    end
  end
end
    # Falls das Skript direkt mit Argument aufgerufen wird
    if __FILE__ == $0
      ip = ARGV[0]
      ReverseIPLookup.run(ip)
    end