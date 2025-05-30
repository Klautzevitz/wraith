require 'socket'
require 'thread'
require 'sinatra'
require 'json'
require 'ipaddr'

MAX_THREADS = 33773
SCAN_RESULTS = []
$scan_mutex = Mutex.new

# Sinatra Webserver Setup
set :bind, '0.0.0.0'
set :port, 5000

module PortScanner
  def self.scan_port(ip, port, result_queue, banner_grab = false)
    begin
      socket = Socket.new(:INET, :STREAM)
      socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_RCVTIMEO, [1, 0].pack("l_2"))
      sockaddr = Socket.sockaddr_in(port, ip)

      if socket.connect_nonblock(sockaddr, exception: false) == :wait_writable
        IO.select(nil, [socket], nil, 1)
      end

      service = Socket.getservbyport(port) rescue "Unknown"
      banner_data = nil

      if banner_grab
        socket.write("HEAD / HTTP/1.1\r\n\r\n")
        banner_data = socket.readpartial(1024).strip rescue nil
      end

      result_queue << [port, service, banner_data]
    rescue
      # ignore closed ports
    ensure
      socket&.close
    end
  end

  def self.port_scanner(ip, ports, num_threads, banner_grab = false)
    num_threads = [num_threads, MAX_THREADS].min
    result_queue = Queue.new
    threads = []

    ports.each do |port|
      threads << Thread.new do
        scan_port(ip, port, result_queue, banner_grab)
      end
      sleep(0.002) while Thread.list.count > num_threads
    end

    threads.each(&:join)
    results = []
    results << result_queue.pop until result_queue.empty?
    results
  end

  def self.reverse_dns(ip)
    begin
      Socket.gethostbyaddr(IPAddr.new(ip).hton).first
    rescue
      "No PTR record found"
    end
  end

  def self.valid_ip?(ip)
    !!IPAddr.new(ip) rescue false
  end

  def self.ask(prompt)
    print prompt
    gets.strip
  end

  def self.run
    puts "\nPort Scanner Befehle:"
    puts "  scan [IP] [THREADS] [PORTS] [BANNER]"
    puts "  dns [IP]"
    puts "  common"
    puts "  random [IP] [THREADS] [COUNT]"
    puts "  export [FILENAME]"
    puts "  exit"

    loop do
      print "\nwraith-osint> "
      input = gets&.strip
      return if input.nil? || input.downcase == 'exit'

      parts = input.split
      command = parts[0]

      case command
      when "scan"
        if parts.length < 4
          puts "Usage: scan [IP] [THREADS] [PORTS] [BANNER (true/false)]"
          next
        end

        ip, threads, range = parts[1], parts[2].to_i, parts[3]
        unless valid_ip?(ip)
          puts "❌ Ungültige IP-Adresse: #{ip}"
          next
        end
        banner = parts[4] == 'true'
        port_start, port_end = range.split("-").map(&:to_i)
        ports = (port_start..port_end).to_a

        if ports.size > 2000
          puts "⚠️ Bitte nicht mehr als 2000 Ports gleichzeitig scannen."
          next
        end

        puts "Scanning #{ip} ports #{port_start}-#{port_end}..."
        results = port_scanner(ip, ports, threads, banner)

        $scan_mutex.synchronize { SCAN_RESULTS << [ip, results] }

        results.each do |port, service, banner_data|
          line = "#{port} (#{service})"
          line += " - #{banner_data}" if banner_data
          puts line
        end

      when "dns"
        ip = parts[1]
        puts "Reverse DNS: #{reverse_dns(ip)}"

      when "common"
        ip = ask("IP-Adresse: ")
        unless valid_ip?(ip)
          puts "❌ Ungültige IP-Adresse: #{ip}"
          next
        end
        threads = ask("Threads: ").to_i
        ports = [21,22,23,25,53,80,110,135,139,443,445,1433,3306,3389]
        results = port_scanner(ip, ports, threads)
        results.each { |p,s,_| puts "#{p} (#{s})" }

      when "random"
        ip, threads, count = parts[1], parts[2].to_i, parts[3].to_i
        unless valid_ip?(ip)
          puts "❌ Ungültige IP-Adresse: #{ip}"
          next
        end
        ports = (1..65535).to_a.sample(count)
        results = port_scanner(ip, ports, threads)
        results.each { |p,s,_| puts "#{p} (#{s})" }

      when "export"
        file = parts[1]
        File.open(file, 'w') do |f|
          SCAN_RESULTS.each do |ip, results|
            f.puts "Results for #{ip}:"
            results.each do |port, service, banner_data|
              line = "#{port} (#{service})"
              line += " - #{banner_data}" if banner_data
              f.puts line
            end
            f.puts
          end
        end
        puts "Exported to #{file}"

      else
        puts "Unbekannter Befehl. help für Übersicht."
      end
    end
  end
end

# Sinatra API Endpoint
post '/scan' do
  begin
    request_data = JSON.parse(request.body.read)
    ip = request_data["ip"]
    if !PortScanner.valid_ip?(ip)
      status 400
      return { error: "Invalid IP address" }.to_json
    end

    ports = request_data["ports"] || [80, 443]
    threads = request_data["threads"] || 100
    banner = request_data["banner"] || false

    if ports.size > 2000
      status 400
      return { error: "Too many ports requested" }.to_json
    end

    results = PortScanner.port_scanner(ip, ports, threads, banner)
    content_type :json
    { ip: ip, open_ports: results }.to_json
  rescue => e
    status 400
    { error: e.message }.to_json
  end
end

# Optional health check endpoint
get '/health' do
  content_type :json
  { status: 'ok' }.to_json
end