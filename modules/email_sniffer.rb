require 'open-uri'
require 'nokogiri'
require 'uri'
require 'securerandom'

G = "\033[1;32m"
Y = "\033[1;33m"
R = "\033[1;31m"

# 👤 E-Mail-Variationen erzeugen
def generate_email_variations(name, num_emails)
  first, last = name.strip.split
  domains = %w[
    gmail.com yahoo.com outlook.com hotmail.com icloud.com protonmail.com
    aol.com zoho.com mail.com yandex.com gmx.com tutanota.com
  ]
  variants = [
    "#{first}.#{last}", "#{first}#{last}", "#{first[0]}#{last}",
    "#{first}#{last[0]}", "#{first}_#{last}", "#{last}.#{first}",
    "#{first}#{rand(1..999)}", "#{last}#{rand(1..999)}",
    "#{first[0]}.#{last}", "#{first}-#{last}", "#{last}#{first}"
  ]

  variants.flat_map { |v| domains.map { |d| "#{v}@#{d}" } }.uniq.first(num_emails)
end

# 🔎 Google-Suche mit Dorking & HTML-Parsen
def search_email_on_websites(emails, max_results = 5)
  search_sites = %w[
    linkedin.com github.com facebook.com twitter.com gmail.com googlemail.com
    reddit.com instagram.com pinterest.com tumblr.com quora.com medium.com google.com
  ]
  found = Set.new
  user_agent = "Mozilla/5.0"

  emails.each do |email|
    search_sites.each do |site|
      query = "\"#{email}\" site:#{site}"
      url = "https://www.google.com/search?q=#{URI.encode_www_form_component(query)}"

      begin
        html = URI.open(url, "User-Agent" => user_agent, ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE).read
        doc = Nokogiri::HTML(html)
        body_text = doc.text
        matches = body_text.scan(/\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z]{2,}\b/i)
        found.merge(matches)
        puts "[ #{G}+#{R} ] Searched: #{url} | Found: #{matches.join(', ')}"

        break if found.size >= max_results
        sleep rand(1.0..2.0)
      rescue => e
        puts "[ #{Y}-#{R} ] Fehler bei Suche #{query}: #{e.message}"
      end
    end
  end

  found.to_a
end

# 🚀 Modul starten
def run_module
  puts "[ #{G}+#{R} ] Email Finder"

  print "Vollständiger Name (Vorname Nachname): "
  name = gets.strip

  print "Wie viele E-Mail-Variationen generieren? "
  num = gets.strip.to_i
  num = 20 if num <= 0

  puts "\n📧 Suche wird durchgeführt..."

  generated = generate_email_variations(name, num)
  found = search_email_on_websites(generated)

  all_emails = (generated + found).uniq

  puts "\n🔍 Gefundene E-Mails:"
  all_emails.each { |e| puts "- #{e}" }

  if all_emails.any?
    puts "\n[ #{G}+#{R} ] Erfolgreich E-Mails gefunden!"
  else
    puts "\n[ #{Y}-#{R} ] Keine E-Mails gefunden."
  end
end

run_module if __FILE__ == $0
