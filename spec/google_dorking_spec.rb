require_relative './../modules/google_dorking'  # Pfad anpassen

RSpec.describe GoogleDorking do
  describe '.google_dork' do
    it 'liefert gültige URLs für eine Custom Query zurück' do
      query = 'site:example.com "login"'
      limit = 5

      results = GoogleDorking.google_dork(query, limit)

      expect(results).to be_an(Array)
      expect(results.length).to be <= limit

      results.each do |url|
        expect(url).to be_a(String)
        expect(url).to match(/\Ahttps?:\/\/.+/)
      end
    end
  end
end
