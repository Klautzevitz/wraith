require 'socket'
require 'etc'
require 'json'
require 'rbconfig'
require_relative 'ani'
require_relative './modules/port_scanner'
require_relative './modules/reverse_ip_lookup'
require_relative './modules/domain_recon'
require_relative './modules/email_sniffer'
require_relative './modules/social_media'
require_relative './modules/num_info'
require_relative './modules/ip_geolocation'
require_relative './modules/google_dorking'

RED = "\033[1;31m"
ORANGE = "\033[38;5;214m"
RESET = "\033[0m"

def get_system_info
  os = RbConfig::CONFIG['host_os']
  arch = RbConfig::CONFIG['host_cpu']
  user = Etc.getlogin
  ip = Socket.ip_address_list.detect(&:ipv4_private?)&.ip_address || '127.0.0.1'
  [os, arch, user, ip]
end

os, arch, user, ip = get_system_info

HEADER = <<~HEREDOC

  #{RED}
  ██╗    ██╗██████╗  █████╗ ██╗████████╗██╗  ██╗               ██████╗ ███████╗██╗███╗   ██╗████████╗
  ██║    ██║██╔══██╗██╔══██╗██║╚══██╔══╝██║  ██║              ██╔═══██╗██╔════╝██║████╗  ██║╚══██╔══╝
  ██║ █╗ ██║██████╔╝███████║██║   ██║   ███████║    █████╗    ██║   ██║███████╗██║██╔██╗ ██║   ██║   
  ██║███╗██║██╔══██╗██╔══██║██║   ██║   ██╔══██║    ╚════╝    ██║   ██║╚════██║██║██║╚██╗██║   ██║   
  ╚███╔███╔╝██║  ██║██║  ██║██║   ██║   ██║  ██║              ╚██████╔╝███████║██║██║ ╚████║   ██║   
   ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝   ╚═╝   ╚═╝  ╚═╝               ╚═════╝ ╚══════╝╚═╝╚═╝  ╚═══╝   ╚═╝   

  #{ORANGE}OPEN SOURCE INTELLIGENCE TOOL
  Creator: Kydoimoz & Klautzevitz
  Github: https://github.com/Kydoimoz
  Version: 1.0

  #{RED}============================================================================================================

  #{RED}OS: #{os.ljust(40)}User: #{user.ljust(40)}
  #{RED}System Architecture: #{arch.ljust(40)}Local IP Address: #{ip}
HEREDOC

def show_menu
  puts HEADER
  puts "#{RED}Select one of the following options [1 - 10]:"
  puts ""
  puts "#{ORANGE}============================================================================================================#{RED}"
  puts ""
  puts "[ #{ORANGE}1#{RED} ] Port Scanner                         #{ORANGE}:#{RED} Sniff IP address of a domain"
  puts "[ #{ORANGE}2#{RED} ] Reverse IP Lookup                    #{ORANGE}:#{RED} Perform a reverse IP lookup"
  puts "[ #{ORANGE}3#{RED} ] Domain Reconnaissance                #{ORANGE}:#{RED} Gather all domain info"
  puts "[ #{ORANGE}4#{RED} ] Reverse Email Lookup                 #{ORANGE}:#{RED} Info about an email"
  puts "[ #{ORANGE}5#{RED} ] Social Media Sniffer                 #{ORANGE}:#{RED} Info from social media"
  puts "[ #{ORANGE}6#{RED} ] Reverse Phone Lookup                 #{ORANGE}:#{RED} Phone number lookup"
  puts "[ #{ORANGE}7#{RED} ] IP Geolocation Lookup                #{ORANGE}:#{RED} Geolocation of IP"
  puts "[ #{ORANGE}8#{RED} ] Google Dork Hacking                  #{ORANGE}:#{RED} Exploit Google search"
  puts "[ #{ORANGE}0#{RED} ] Exit"
end

def execute_module(choice)
  modules = {
    "1" => "port_scanner",
    "2" => "reverse_ip_lookup",
    "3" => "domain_recon",
    "4" => "email_sniffer",
    "5" => "social_media",
    "6" => "num_info",
    "7" => "ip_geolocation",
    "8" => "google_dorking",
  }

  if modules.key?(choice)
    mod_name = modules[choice]
    begin
      require_relative "modules/#{mod_name}"
      case choice
      when "1"
        PortScanner.run
      when "4"
        run_module
      when "2"
        print "\nEnter target IP: "
        ip = gets.chomp
        data = (choice == "2" ? ReverseIPLookup.run(ip) : get_ip_geolocation(ip))
        puts JSON.pretty_generate(data) if data
      when "7"
        print "\nEnter target IP: "
        ip = gets.chomp
        data = (choice == "2" ? ReverseIPLookup.run(ip) : get_ip_geolocation(ip))
        puts JSON.pretty_generate(data) if data
      when "3"
        print "\nEnter target domain: "
        domain = gets.chomp
        output = gather_all_domain_info(domain)
        puts output
      when "5"
        print "\nEnter full name of the target: "
        name = gets.chomp
        gather_info(name)
      when "6"
        print "Enter phone number (e.g. +1 800 555 5555): "
        number = gets.chomp
        info = phone_number_info(number)
        puts info
      when "8"
        system("python ./modules/google_dorking.py")
      end
    rescue => e
      puts "#{RED}Error running #{mod_name}: #{e.class} - #{e.message}#{RESET}"
      puts e.backtrace.join("\n")
    end
  else
    puts "#{RED}Invalid selection, please choose a valid option.#{RESET}"
  end
end

def main
    begin
      loop do
        show_menu
        print "#{RED}Enter choice: "
        input = gets
        if input.nil?
          puts "\n❌ Keine Eingabe erkannt. Beende..."
          break
        end
        choice = input.chomp
        break if choice == "0"
        execute_module(choice)
      end
    rescue Interrupt
      puts "\nProgram interrupted. Shutting down..."
    end
  end

# Aufruf (falls Datei direkt ausgeführt wird)
if __FILE__ == $0
  animate_and_run_main()
  main
end