require 'open-uri'
require 'nokogiri'
require 'uri'
require 'securerandom'

module GoogleDorking
  USER_AGENTS = [
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)",
    "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:89.0)",
    "Mozilla/5.0 (iPhone; CPU iPhone OS 13_5 like Mac OS X)",
    "Mozilla/5.0 (Linux; Android 10; SM-G970F)"
  ]

  def self.google_dork(query, max_results = 10)
    encoded_query = URI.encode_www_form_component(query)
    url = "https://html.duckduckgo.com/html/?q=#{encoded_query}"

    begin
      html = URI.open(url, 
        "User-Agent" => USER_AGENTS.sample,
        "Accept-Language" => "en-US,en;q=0.9"
      ).read

      doc = Nokogiri::HTML(html)
      links = doc.css('a.result__a').map { |a| a['href'] }
      return links.take(max_results).uniq
    rescue => e
      puts "[!] Fehler bei google_dork: #{e.message}"
      return []
    end
  end
end
