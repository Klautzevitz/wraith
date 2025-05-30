require 'whois'
require 'resolv'
require 'dnsruby'
require 'json'
require 'date'
require 'ruby-progressbar'

R = "\033[1;31m"
O = "\033[38;5;214m"

def datetime_format(obj)
  obj.is_a?(Time) ? obj.strftime("%Y-%m-%d %H:%M:%S") : obj
end

def domain_lookup(domain)
  client = Whois::Client.new
  record = client.lookup(domain)
  parser = record.parser

  registrar_name = begin
    parser.registrar.name
  rescue
    "N/A"
  end

  {
    "domain_name"     => parser.domain,
    "registrar"       => registrar_name,
    "creation_date"   => datetime_format(parser.created_on),
    "expiration_date" => datetime_format(parser.expires_on),
    "updated_date"    => datetime_format(parser.updated_on),
    "status"          => parser.status || [],
    "org"             => parser.registrant_contacts&.first&.organization || "N/A",
    "state"           => parser.registrant_contacts&.first&.state || "N/A",
    "country"         => parser.registrant_contacts&.first&.country || "N/A"
  }
rescue => e
  puts "#{R}❗ Fehler bei WHOIS: #{e.message}"
  {}
end

def get_ip_addresses(domain)
  Resolv.getaddresses(domain)
rescue
  []
end

def get_dns_records(domain, type)
  resolver = Dnsruby::Resolver.new
  records = resolver.query(domain, type).answer.map(&:to_s)
  records.empty? ? "No #{type} records found." : records
rescue Dnsruby::NXDomain, Dnsruby::ServFail
  "No #{type} records found."
rescue Dnsruby::ResolvTimeout
  "Timeout while retrieving #{type} records."
end

def gather_all_domain_info(domain)
  puts "\n🔍 Sammle Informationen für Domain: #{domain}\n"
  bar = ProgressBar.create(title: 'Domain Recon', total: 5, format: '%t [%B] %p%%')

  whois_data   = domain_lookup(domain)
  bar.increment

  ip_addresses = get_ip_addresses(domain)
  bar.increment

  mx_records   = get_dns_records(domain, "MX")
  bar.increment

  ns_records   = get_dns_records(domain, "NS")
  bar.increment

  txt_records  = get_dns_records(domain, "TXT")
  bar.increment

  registered = !whois_data["creation_date"].nil?

  output = <<~INFO
    #{R}
    [+] Domain Information for #{domain}:

    [*] WHOIS Information:
    #{O} ----------------------------------------#{R}
    Domain Name: #{whois_data["domain_name"] || 'N/A'}
    Registrar: #{whois_data["registrar"]}
    Creation Date: #{whois_data["creation_date"]}
    Expiration Date: #{whois_data["expiration_date"]}
    Updated Date: #{whois_data["updated_date"]}
    Status: #{Array(whois_data["status"]).join(', ')}

    Domain Registered: #{registered}

    [*] Registrar Information:
    #{O} ----------------------------------------#{R}
    Registrar: #{whois_data["registrar"]}

    [*] Contact Information:
    #{O} ----------------------------------------#{R}
    Organization: #{whois_data["org"]}
    State: #{whois_data["state"]}
    Country: #{whois_data["country"]}

    [*] IP Addresses:
    #{O} ----------------------------------------#{R}
    #{ip_addresses.any? ? ip_addresses.join(', ') : 'No IP addresses found.'}

    [*] MX Records:
    #{O} ----------------------------------------#{R}
    #{mx_records.is_a?(String) ? mx_records : mx_records.join(', ')}

    [*] NS Records:
    #{O} ----------------------------------------#{R}
    #{ns_records.is_a?(String) ? ns_records : ns_records.join(', ')}

    [*] TXT Records:
    #{O} ----------------------------------------#{R}
    #{txt_records.is_a?(String) ? txt_records : txt_records.join(', ')}
  INFO

  output
end
