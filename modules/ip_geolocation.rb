require 'net/http'
require 'json'
require 'erb'
require 'uri'

def get_ip_geolocation(ip = "")
  url = URI("http://ip-api.com/json/#{ip}?fields=61439")
  begin
    res = Net::HTTP.get_response(url)
    data = JSON.parse(res.body)
    return nil if data["status"] == "fail"
    data
  rescue => e
    puts "ERR!: #{e.message}"
    nil
  end
end

def display_location_on_map(lat, lon)
  template = <<~HTML
    <!DOCTYPE html>
    <html>
    <head>
        <title>IP Geolocation Map</title>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
        <style> #map { height: 100vh; } </style>
    </head>
    <body>
        <div id="map"></div>
        <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
        <script>
            var map = L.map('map').setView([<%= lat %>, <%= lon %>], 12);
            L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                maxZoom: 18,
                attribution: '© OpenStreetMap contributors'
            }).addTo(map);
            L.marker([<%= lat %>, <%= lon %>]).addTo(map)
              .bindPopup('Zielort')
              .openPopup();
        </script>
    </body>
    </html>
  HTML

  renderer = ERB.new(template)
  File.write("location.html", renderer.result_with_hash(lat: lat, lon: lon))
  system("xdg-open location.html") || system("open location.html") || system("start location.html")
end

# Nur bei direkter Ausführung
if __FILE__ == $0
  print "Enter target IP: "
  ip = gets.strip
  geo = get_ip_geolocation(ip)

  if geo
    puts JSON.pretty_generate(geo)
    lat, lon = geo["lat"], geo["lon"]
    if lat && lon
      display_location_on_map(lat, lon)
    end
  else
    puts "Geolocation failed."
  end
end
