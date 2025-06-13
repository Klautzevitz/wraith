require 'fileutils'
require 'json'
require 'open3'
require 'yaml'

# Erstellt einen Ordner für die Person
def create_folder(name, surname)
  folder_name = "#{name}_#{surname}"
  Dir.mkdir(folder_name) unless Dir.exist?(folder_name)
  folder_name
end

# Lädt Instagram-Daten (Platzhalter)
def search_instagram(name, surname, username, password)
  puts "Simuliere Instagram-Login für #{username}..."
  puts ">>> (Ruby hat kein direktes Pendant zu instaloader)"
  puts ">>> Bitte verwende system('instaloader') in einem echten Anwendungsfall"
  puts "Suche nach Instagram-Profil: #{name}"
  sleep(1)
  puts "✓ Profil gefunden: #{name} - followers: 1234 | following: 567 | bio: Ruby rockt!"
end

# Simuliert den Download von Google-Bildern (Platzhalter)
def download_images(name, surname, folder_name)
  puts "Bilder werden gesucht für: #{name} #{surname}"
  # Realistisch müsste man z. B. `google-search-results`-Gem + Download-Logik schreiben
  fake_images = 5.times.map { |i| "#{folder_name}/#{name}_#{i + 1}.jpg" }
  fake_images.each do |img_path|
    File.write(img_path, "fake-image-content")  # Platzhalter für echten Bildinhalt
    puts "✓ Bild gespeichert: #{img_path}"
    sleep(0.2)
  end
  fake_images
end

# Hauptfunktion zur Info-Sammlung
def gather_info(full_name)
  name_parts = full_name.split
  if name_parts.length != 2
    puts "❗ Bitte gib Vorname und Nachname ein (z. B. 'John Doe')"
    return
  end

  name, surname = name_parts[0], name_parts[1]

  # Konfig auslesen (ersetze dies ggf. mit JSON/YAML in Ruby)
  config_path = 'config/credentials.yml'
  unless File.exist?(config_path)
    puts "❗ Datei #{config_path} fehlt. Bitte lege eine YAML-Datei mit Instagram-Zugangsdaten an:"
    puts "instagram:\n  username: deinuser\n  password: deinpass"
    return
  end

  config = YAML.load_file(config_path)
  insta_username = config['instagram']['username']
  insta_password = config['instagram']['password']

  puts "\n🔍 Sammle Daten zu: #{name} #{surname}"
  folder_name = create_folder(name, surname)

  puts "\n📸 Instagram durchsuchen..."
  search_instagram(name, surname, insta_username, insta_password)

  puts "\n🖼️ Bilder herunterladen..."
  images = download_images(name, surname, folder_name)

  if images.any?
    puts "\nBilder gespeichert:"
    images.each { |img| puts img }
  else
    puts "⚠️ Keine Bilder heruntergeladen."
  end

  puts "\n✅ Informationssammlung abgeschlossen!"
end
