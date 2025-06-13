require 'rspec'

describe 'Wraith-OSINT Systemtest (Terminal CLI)' do
  let(:main_file) { 'main.rb' }

  def run_command(*inputs)
    output = `ruby ./modules/reverse_ip_lookup.rb 8.8.8.8`
    IO.popen("ruby #{main_file}", "r+") do |io|
      inputs.each { |line| io.puts line }
      io.close_write
      output = io.read
    end
    output
  end

  it 'führt Portscanner mit gültiger IP und kleinem Portbereich aus' do
    output = run_command("1", "scan 127.0.0.1 10 20-21 false", "0")
    expect(output).to include("Scanning 127.0.0.1 ports 20-21")
    expect(output).to match(/\d+ \(.*\)/) # Ergebniszeile
  end

  it 'führt Reverse DNS mit gültiger IP aus' do
    output = run_command("1", "dns 8.8.8.8", "0")
    expect(output).to include("Reverse DNS")
  end

  it 'führt Portscanner mit common-Ports aus' do
    output = run_command("1", "common", "127.0.0.1", "10", "0")
    expect(output).to include("21 (")
    expect(output).to include("443 (")
  end

  it 'führt Portscanner mit random Ports aus' do
    output = run_command("1", "random 127.0.0.1 5 3", "0")
    expect(output).to include(" (") # Irgendein offener oder geschlossener Port
  end

  it 'exportiert Ergebnisse in eine Datei' do
    filename = "test_export.txt"
    output = run_command("1", "scan 127.0.0.1 10 80-80 false", "export #{filename}", "0")
    expect(File).to exist(filename)
    content = File.read(filename)
    expect(content).to include("Results for 127.0.0.1")
    File.delete(filename) # cleanup
  end

  it 'führt reverse_ip_lookup.rb direkt mit IP aus' do
    output = IO.popen("ruby -r './modules/reverse_ip_lookup.rb' -e 'ReverseIPLookup.run(\"8.8.8.8\")'") { |io| io.read }
    expect(output).to include("Gefundene Domains").or include("⚠️ Keine Domains gefunden")
  end
end
