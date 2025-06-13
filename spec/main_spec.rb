require 'rspec'

# This line loads your main application script.
# For this to work correctly and not run the interactive CLI:
# 1. `main.rb` must be located in the directory above this `spec` directory (project root).
# 2. All files required by `main.rb` (e.g., `ani.rb`, `modules/*.rb`) must exist
#    at their expected relative paths from `main.rb`.
# 3. CRITICAL: The `main.rb` script must guard its main execution calls
#    (e.g., `animate_and_run_main`, `main()`) with an `if __FILE__ == $0` block.
#    As mentioned above, the provided `main.rb` has unguarded calls at its very end
#    which MUST be fixed.
begin
  require_relative './../main'
rescue LoadError => e
  # This block helps diagnose if main.rb or its dependencies can't be found.
  # RSpec will typically report this clearly anyway.
  abort "ERROR: Failed to load './main.rb'. Ensure the file exists and its internal requires are correct.\nOriginal error: #{e.message}"
end


describe 'OSINT Tool (main.rb)' do

  # Test the get_system_info method
  # This assumes get_system_info is a top-level method in main.rb
  describe '#get_system_info' do
    # `subject` calls the method. If `get_system_info` is not defined, this will raise NoMethodError.
    subject(:system_info) { get_system_info } # This calls the global method from main.rb

    it 'returns an array' do
      expect(system_info).to be_an(Array)
    end

    it 'returns an array with 4 elements' do
      expect(system_info.size).to eq(4)
    end

    it 'returns os, arch, user, and ip as strings' do
      # This checks if all elements in the array are strings.
      # Note: Etc.getlogin can sometimes be problematic in minimal CI environments,
      # but the test reflects what the method returns.
      # The `|| '127.0.0.1'` in get_system_info ensures ip is always a string.
      expect(system_info).to all(be_a(String))
    end
  end

  # Test for global constants
  describe 'Global Constants' do
    it 'RED is defined as a non-empty string' do
      expect(defined?(RED)).to eq('constant'), "Constant RED is not defined."
      expect(RED).to be_a(String)
      expect(RED).not_to be_empty
    end

    it 'ORANGE is defined as a non-empty string' do
      expect(defined?(ORANGE)).to eq('constant'), "Constant ORANGE is not defined."
      expect(ORANGE).to be_a(String)
      expect(ORANGE).not_to be_empty
    end

    it 'RESET is defined as a non-empty string' do
      expect(defined?(RESET)).to eq('constant'), "Constant RESET is not defined."
      expect(RESET).to be_a(String)
      expect(RESET).not_to be_empty # e.g., "\033[0m" is not empty
    end

    it 'HEADER is defined as a non-empty string' do
      expect(defined?(HEADER)).to eq('constant'), "Constant HEADER is not defined."
      expect(HEADER).to be_a(String)
      expect(HEADER).not_to be_empty
    end
  end

  # Test for the existence of other key methods
  # Top-level methods in a script are defined as private methods of Object.
  describe 'Method Definitions' do
    it 'defines #show_menu' do
      expect(Object.private_method_defined?(:show_menu)).to be true
    end

    it 'defines #execute_module' do
      expect(Object.private_method_defined?(:execute_module)).to be true
    end

    it 'defines #main (the command-line loop)' do
      expect(Object.private_method_defined?(:main)).to be true
    end
  end
end