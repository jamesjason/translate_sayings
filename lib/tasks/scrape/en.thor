require 'thor'
require 'nokogiri'
require 'csv'
require 'fileutils'
require 'net/http'
require 'uri'
require 'openssl'
require 'json'

require_relative '../../../config/environment'

class Scrape < Thor
  desc 'en',
       'Scrape English sayings and merge into data/sayings/en.csv'

  method_option :skip_openai,
                type: :boolean,
                default: false,
                desc: 'Skip OpenAI normalization and save all cleaned sayings as-is'

  method_option :dry_run,
                type: :boolean,
                default: false,
                desc: 'Show counts and a sample but do not write CSV'

  MAX_BATCH_SIZE = 40
  MODEL_NAME     = 'gpt-4.1-mini'.freeze
  OPENAI_TIMEOUT = 60

  def en
    data_path = File.join(Dir.pwd, 'data', 'sayings', 'en.csv')
    say "Using data file: #{data_path}"

    existing = load_existing(data_path)
    say "Existing sayings: #{existing.size}"

    scraped = []

    say 'Scraping Wiktionary: Category:English_proverbs…'
    wiktionary_start = 'https://en.wiktionary.org/wiki/Category:English_proverbs'
    scraped += scrape_wiktionary_proverbs(wiktionary_start)

    say 'Scraping Wikipedia: List_of_proverbial_phrases…'
    scraped += scrape_wikipedia_proverbial_phrases

    say 'Scraping Phrases.org.uk: 680 English proverbs…'
    scraped += scrape_phrases_org_proverbs

    say "Scraped sayings (raw, before cleaning and deduplication): #{scraped.size}"

    all = existing + scraped

    cleaned =
      all.map { |s| clean_text(s) }
         .map(&:strip)
         .reject(&:empty?)
         .reject { |s| noise?(saying: s) }
         .uniq
         .sort

    say "Merged total (cleaned, deduped) sayings: #{cleaned.size}"

    if options[:skip_openai]
      say('Skipping OpenAI normalization (skip_openai=true).', :yellow)
      final_sayings = cleaned
    else
      ensure_api_key!

      say ''
      say "Normalizing & validating sayings with OpenAI (model: #{MODEL_NAME}, batch size: #{MAX_BATCH_SIZE})…", :blue
      final_sayings = normalize_sayings_with_openai(cleaned)

      say ''
      say 'OpenAI normalization summary:', :green
      say "  Canonical sayings kept: #{final_sayings.size}"
      say "  Discarded (non-proverbs / noise): #{cleaned.size - final_sayings.size}"
    end

    if options[:dry_run]
      say ''
      say '[DRY RUN] Not writing CSV. Sample sayings that would be saved:', :yellow
      final_sayings.first(20).each { |s| say "  - #{s}" }
      return
    end

    say 'Writing CSV…'
    write_csv(data_path, final_sayings)

    say 'Done!'
  end

  private

  no_commands do
    def load_existing(path)
      return [] unless File.exist?(path)

      rows = CSV.read(path, headers: true)
      return [] unless rows.headers&.include?('saying')

      rows['saying'].compact.map(&:to_s)
    end

    def write_csv(path, sayings)
      FileUtils.mkdir_p(File.dirname(path))

      CSV.open(path, 'w') do |csv|
        csv << ['en']
        sayings.each do |s|
          csv << [s]
        end
      end
    end

    def clean_text(text)
      s = text.to_s.encode('UTF-8', invalid: :replace, undef: :replace, replace: '').strip
      s = s.gsub(/\[[^\]]*\]/, '')
      s = s.sub(/\s*\([^()]*\)\s*$/, '')
      s = s.gsub(/\A[^[:alnum:]]+/, '')
      s = s.gsub(/[^[:alnum:]]+\z/, '')
      s = s.gsub(/\A["'“”‘’]+/, '').gsub(/["'“”‘’]+\z/, '')
      s = s.gsub(/\s+/, ' ')
      s.downcase
    end

    def noise?(saying:)
      down = saying.downcase

      prefixes = [
        'appendix:',
        'list of ',
        'english proverbs center',
        'english proverbs explained',
        'proverbium.org',
        'see also',
        'external links',
        'references',
        'list of english-language metaphors',
        'list of idioms attributed to shakespeare',
        'list of idioms of improbability',
        'list of latin phrases'
      ]

      return true if prefixes.any? { |p| down.start_with?(p) }
      return true if down.include?('archived from the original')
      return true if down.include?('better source needed')
      return true if down.include?('citation needed')

      if down.split.size <= 3 &&
         (down.start_with?('every cloud') ||
          down.start_with?('bird in the hand'))
        return true
      end

      false
    end

    def fetch_page(url)
      say "Fetching: #{url}"
      uri = URI.parse(url)

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE if http.use_ssl?
      http.read_timeout = 30

      res = http.get(uri.request_uri)

      raise "HTTP error #{res.code} when fetching #{url}" unless res.is_a?(Net::HTTPSuccess)

      Nokogiri::HTML(res.body)
    end

    def scrape_wiktionary_proverbs(start_url)
      sayings = []
      current_url = start_url

      while current_url
        doc = fetch_page(current_url)
        sayings.concat extract_wiktionary_sayings(doc)

        next_link = doc.css('#mw-pages a').find { |a| a.text.include?('next page') }
        current_url = next_link ? URI.join(current_url, next_link['href']).to_s : nil
      end

      sayings
    end

    def extract_wiktionary_sayings(doc)
      doc.css('#mw-pages li a').map { |a| a.text.to_s }
    end

    def scrape_wikipedia_proverbial_phrases
      url = 'https://en.wikipedia.org/wiki/List_of_proverbial_phrases'
      doc = fetch_page(url)

      doc.css('.mw-parser-output > ul li')
         .map { |li| li.text.to_s }
    end

    def scrape_phrases_org_proverbs
      url = 'https://www.phrases.org.uk/meanings/proverbs.html'
      doc = fetch_page(url)

      sayings = []

      h1 = doc.at_xpath(
        "//h1[contains(translate(normalize-space(.), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), " \
        "'a list of 680 english proverbs')]"
      )
      return [] unless h1

      node = h1
      while (node = node.next_sibling)
        break if node.text.to_s.downcase.include?('related articles')

        next unless node.element? || node.text?

        if node.element?
          node.xpath('.//text()').each do |t|
            line = t.text.strip
            sayings << line unless line.empty?
          end
        elsif node.text?
          line = node.text.strip
          sayings << line unless line.empty?
        end
      end

      sayings.reject! do |s|
        d = s.downcase
        d.start_with?("here's a list of most of the commonly-used english proverbs") ||
          d.start_with?('heres a list of most of the commonly-used english proverbs')
      end

      sayings
    end

    def openai_api_key
      Rails.application.credentials.dig(:openai, :api_key) || ENV.fetch('OPENAI_API_KEY', nil)
    end

    def ensure_api_key!
      key = openai_api_key
      return unless key.nil? || key.strip.empty?

      say 'ERROR: No OpenAI API key configured.', :red
      say 'Set credentials.openai.api_key or ENV["OPENAI_API_KEY"].', :red
      exit(1)
    end

    def normalize_sayings_with_openai(sayings)
      canonical = []

      batches = sayings.each_slice(MAX_BATCH_SIZE).to_a
      total_batches = batches.size

      batches.each_with_index do |batch, idx|
        say ''
        say "Validating batch #{idx + 1} / #{total_batches} (#{batch.size} items)…", :blue

        begin
          batch_canonical = openai_normalize_batch(batch)
        rescue StandardError => e
          say "WARNING: OpenAI call failed for this batch (#{e.class}: #{e.message}); treating batch as invalid.",
              :yellow
          batch_canonical = []
        end

        canonical.concat(batch_canonical)

        say "  -> Canonical in this batch: #{batch_canonical.size}", :green
      end

      canonical.map(&:strip).reject(&:empty?).uniq.sort
    end

    def build_normalization_prompt(batch)
      data = batch.map(&:strip).reject(&:empty?)

      <<~PROMPT
        You will receive a list of English proverbs/sayings.

        Your job: CLEAN EACH PROVERB WITHOUT CHANGING ITS WORDING OR MEANING.

        Allowed cleanup:
        • remove leading/trailing quotation marks
        • remove leading/trailing punctuation (“.” “,” “;” “—” etc.)
        • normalize whitespace
        • convert smart quotes to normal ASCII quotes
        • remove trailing commentary such as:
            - "— proverb"
            - "(USA)", "(idiom)", "(Biblical)", "(English proverb)", etc.
            - "[citation needed]" or other bracketed notes
            - extra text after a dash (e.g., " — explanation")
        • remove URLs or reference numbers

        NOT allowed:
        • do NOT rewrite the proverb
        • do NOT convert it to a different phrasing
        • do NOT choose a “canonical” version
        • do NOT merge variants
        • do NOT fill in missing words
        • do NOT explain or translate anything

        If you are unsure whether something is part of the proverb or extra text:
        - keep the proverb wording
        - remove only obvious metadata / notes.

        Return ONLY valid JSON in this exact structure:

        {
          "items": [
            { "original": "…original text exactly as given…", "cleaned": "…cleaned proverb…" }
          ]
        }

        Here are the items to clean:

        #{data.map { |s| "- #{s}" }.join("\n")}
      PROMPT
    end

    def openai_normalize_batch(batch)
      prompt = build_normalization_prompt(batch)

      uri = URI.parse('https://api.openai.com/v1/chat/completions')
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      http.read_timeout = OPENAI_TIMEOUT

      request_body = {
        model: MODEL_NAME,
        messages: [
          {
            role: 'system',
            content: 'You are a careful linguist who knows common English proverbs and sayings.'
          },
          {
            role: 'user',
            content: prompt
          }
        ],
        temperature: 0,
        response_format: { type: 'json_object' }
      }

      req = Net::HTTP::Post.new(uri.request_uri)
      req['Content-Type'] = 'application/json'
      req['Authorization'] = "Bearer #{openai_api_key}"
      req.body = JSON.dump(request_body)

      res = http.request(req)

      raise "OpenAI HTTP #{res.code} #{res.message}: #{res.body[0, 200]}" unless res.is_a?(Net::HTTPSuccess)

      json = JSON.parse(res.body)
      content = json.dig('choices', 0, 'message', 'content')
      raise 'No content in OpenAI response' unless content

      parsed = JSON.parse(content)
      items = parsed['items']
      raise "Unexpected JSON structure from OpenAI: #{parsed.inspect[0, 200]}" unless items.is_a?(Array)

      items.map do |item|
        cleaned = item['cleaned'].to_s.strip
        cleaned.empty? ? nil : cleaned
      end.compact
    end
  end
end
