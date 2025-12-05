require 'thor'
require 'csv'
require 'json'
require 'net/http'
require 'uri'
require 'openssl'
require 'fileutils'

require_relative '../../config/environment'

class Translate < Thor
  desc 'sayings',
       'Translate proverbs from one language to another using OpenAI, ' \
       'reading from data/sayings/SOURCE_LANG.csv and writing to ' \
       'data/saying_translations/SOURCE_LANG_to_TARGET_LANG.csv'

  method_option :source_language,
                type: :string,
                aliases: '-s',
                required: true,
                desc: 'Source language code (e.g. en, fa, fr)'

  method_option :target_language,
                type: :string,
                aliases: '-t',
                required: true,
                desc: 'Target language code (e.g. fa, en, fr)'

  method_option :limit,
                type: :numeric,
                default: nil,
                desc: 'Only process the first N sayings'

  method_option :dry_run,
                type: :boolean,
                default: false,
                desc: 'Do not write CSV; just print examples'

  method_option :override,
                type: :boolean,
                default: false,
                desc: 'Re-translate even if a non-empty translation already exists'

  MAX_BATCH_SIZE = 40
  MODEL_NAME     = 'gpt-5.1'.freeze
  OPENAI_TIMEOUT = 60

  def sayings
    ensure_api_key!

    source_language = options[:source_language].to_s.downcase
    target_language = options[:target_language].to_s.downcase
    override        = options[:override]

    if source_language == target_language
      say 'ERROR: source_language and target_language must be different.', :red
      exit(1)
    end

    source_path = File.join(Dir.pwd, 'data', 'sayings', "#{source_language}.csv")
    unless File.exist?(source_path)
      say "ERROR: Source CSV not found at #{source_path}", :red
      exit(1)
    end

    source_sayings = []
    CSV.foreach(source_path, headers: true) do |row|
      txt = row[source_language].to_s.strip
      source_sayings << txt unless txt.empty?
    end

    if options[:limit]
      limit = options[:limit].to_i
      source_sayings = source_sayings.first(limit)
    end

    say "Loaded #{source_sayings.size} sayings from #{source_language}."

    target_dir  = File.join(Dir.pwd, 'data', 'saying_translations')
    FileUtils.mkdir_p(target_dir)
    target_path = File.join(target_dir, "#{source_language}_to_#{target_language}.csv")

    existing_translated_rows = []
    existing_map             = {}
    existing_order           = []

    confidence_col = 'confidence'

    if File.exist?(target_path)
      say "Found existing translations at #{target_path}; reusing them where possible."

      CSV.foreach(target_path, headers: true) do |row|
        src = row[source_language].to_s.strip
        tgt = row[target_language].to_s.strip
        next if src.empty?

        conf_raw = row[confidence_col]
        conf = conf_raw.to_i
        conf = nil if conf <= 0 || conf > 10
        existing_map[src] = [tgt, conf]

        existing_order << src unless existing_order.include?(src)
      end

      if override
        say 'Override mode enabled: existing translations may be replaced with new ones.', :yellow
      else
        seen = {}
        existing_order.each do |src|
          next unless source_sayings.include?(src)

          tgt, conf = existing_map[src]
          next if tgt.to_s.strip.empty?
          next if seen[src]

          existing_translated_rows << [src, tgt, conf]
          seen[src] = true
        end
      end
    end

    existing_translated_srcs = existing_translated_rows.to_set(&:first)

    to_translate =
      if override
        source_sayings
      else
        source_sayings.reject { |src| existing_translated_srcs.include?(src) }
      end

    say "Sayings needing translation this run: #{to_translate.size}"

    new_pairs = [] # [[src, tgt, conf]]

    unless to_translate.empty?
      batches       = to_translate.each_slice(MAX_BATCH_SIZE).to_a
      total_batches = batches.size

      batches.each_with_index do |batch, idx|
        say ''
        say "Translating batch #{idx + 1} / #{total_batches} (#{batch.size} items)…", :blue

        batch_pairs = translate_batch(batch, source_language, target_language)

        say "  -> Got #{batch_pairs.size} mapped items", :green

        if options[:dry_run]
          batch_pairs.first(5).each do |src, tgt, conf|
            say "SRC (#{source_language}): #{src}"
            say "TGT (#{target_language}): #{tgt.empty? ? '(no proverb found)' : tgt}"
            say "CONF: #{conf}"
            say ''
          end
        end

        new_pairs.concat(batch_pairs)
      end
    end

    new_map = {} # src => [tgt, conf]
    new_pairs.each do |src, tgt, conf|
      new_map[src] = [tgt, conf]
    end

    final_rows = []

    unless override
      seen_src = {}
      existing_translated_rows.each do |src, tgt, conf|
        next if seen_src[src]

        final_rows << [src, tgt, conf]
        seen_src[src] = true
      end
    end

    already_in_final = final_rows.to_set(&:first)

    source_sayings.each do |src|
      next if already_in_final.include?(src)

      tgt  = ''
      conf = 1

      if new_map.key?(src)
        tgt, conf = new_map[src]
      elsif existing_map.key?(src)
        tgt, conf = existing_map[src]
      end

      conf = conf.to_i
      conf = 1 if conf <= 0
      conf = 10 if conf > 10

      final_rows << [src, tgt, conf]
    end

    if final_rows.size != source_sayings.size
      say "WARNING: final row count (#{final_rows.size}) does not match source sayings (#{source_sayings.size}).",
          :yellow
    end

    say ''
    if options[:dry_run]
      say "[DRY RUN] Would write #{final_rows.size} rows to #{target_path}.", :yellow
      return
    end

    say "Writing translations to #{target_path}…"

    CSV.open(target_path, 'w') do |csv|
      csv << [source_language, target_language, confidence_col]
      final_rows.each do |src, tgt, conf|
        csv << [src, tgt, conf]
      end
    end

    say "Done. Wrote #{final_rows.size} rows (#{source_sayings.size} input sayings).", :green
  end

  no_commands do
    def translate_batch(batch, source_language, target_language)
      prompt = build_translation_prompt(batch, source_language, target_language)
      uri    = URI('https://api.openai.com/v1/chat/completions')

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      http.read_timeout = OPENAI_TIMEOUT

      body_hash = {
        model: MODEL_NAME,
        messages: [
          {
            role: 'system',
            content: system_instructions(source_language, target_language)
          },
          { role: 'user', content: prompt }
        ],
        temperature: 0,
        response_format: { type: 'json_object' }
      }

      req = Net::HTTP::Post.new(uri.request_uri)
      req['Authorization'] = "Bearer #{openai_api_key}"
      req['Content-Type']  = 'application/json'
      req.body = body_hash.to_json

      begin
        res = http.request(req)
      rescue StandardError => e
        say "WARNING: OpenAI request failed (#{e.class}: #{e.message}). Treating batch as empty.", :yellow
        return []
      end

      unless res.is_a?(Net::HTTPSuccess)
        say "WARNING: OpenAI returned HTTP #{res.code} for batch. Treating batch as empty.", :yellow
        return []
      end

      begin
        outer   = JSON.parse(res.body)
        content = outer.dig('choices', 0, 'message', 'content')
        json    = JSON.parse(content)
      rescue StandardError => e
        say "WARNING: Failed to parse OpenAI JSON for batch (#{e.class}: #{e.message}).", :yellow
        return []
      end

      items = json['items']
      unless items.is_a?(Array)
        say 'WARNING: Unexpected JSON structure for batch; treating as empty.', :yellow
        return []
      end

      items.map do |item|
        src  = item['source'].to_s.strip
        tgt  = item['target'].to_s.strip
        conf = item['confidence'].to_i

        next if src.empty?

        unless tgt.empty?
          tgt = tgt.gsub(/\A["'“”‘’]+/, '').gsub(/["'“”‘’]+\z/, '')
          tgt = tgt.sub(/[.…]+$/, '').strip
        end

        conf = 1 if conf <= 0
        conf = 10 if conf > 10

        [src, tgt, conf]
      end.compact
    end

    def system_instructions(source_language, target_language)
      [
        "You are a bilingual expert in #{Language.name_for(code: source_language)} (#{source_language}) ",
        "and #{Language.name_for(code: target_language)} (#{target_language}) proverbs.",
        'Your job is to map proverbs from the source language to REAL, well-established proverbs in the target "\
        "language.',
        'NEVER provide literal, word-for-word translations.',
        'If you do not know a widely used proverb in the target language that matches the meaning,',
        'return an empty string for "target" for that item.',
        '',
        'Example of correct mapping (from English to Farsi):',
        'English: "too many cooks spoil the broth"',
        'Farsi:   "آشپز که دوتا شد آش یا شور می‌شود یا بی‌نمک"',
        '',
        'You must also assign a "confidence" rating between 1 and 10 for each item, indicating how confident you "\
        "are in the match.',
        '10 means extremely confident; 1 means very uncertain.',
        '',
        'This demonstrates the exact kind of culturally correct and meaning-preserving mapping you must perform.'
      ].join(' ')
    end

    def build_translation_prompt(batch, source_language, target_language)
      numbered = batch.map.with_index(1) { |s, i| "#{i}. #{s}" }.join("\n")

      <<~PROMPT
        We are building a high-quality parallel corpus of proverbs.

        Source language: #{Language.name_for(code: source_language)} (#{source_language})
        Target language: #{Language.name_for(code: target_language)} (#{target_language})

        For each of the source-language proverbs below:

        - Return ONE target-language proverb or saying that:
          * Expresses the SAME meaning or moral.
          * Is a REAL, widely used proverb in natural #{Language.name_for(code: target_language)}.
          * Is something native speakers of the target language would actually say in that situation.
        - Do NOT give a literal translation of the words.
        - If you are not confident that there is a well-known proverb that matches,
          set "target" to the empty string "" for that item.
        - Also include a "confidence" rating from 1 to 10 indicating how certain you are that the target proverb is a good match.
          * 10 = extremely confident; 1 = very uncertain.
        - The target proverb must contain ONLY the proverb text:
          * No quotes
          * No numbering
          * No explanations
          * No extra commentary
          * No trailing period unless it is truly part of the proverb

        Return ONLY valid JSON in this exact format:

        {
          "items": [
            { "source": "...exact source text...", "target": "...target-language proverb or empty string...", "confidence": 7 },
            { "source": "...", "target": "...", "confidence": 10 }
          ]
        }

        Do NOT include keys other than "items".
        Do NOT include any text before or after the JSON.

        Here are the source proverbs:

        #{numbered}
      PROMPT
    end

    def openai_api_key
      Rails.application.credentials.dig(:openai, :api_key) ||
        ENV.fetch('OPENAI_API_KEY', nil)
    end

    def ensure_api_key!
      return unless openai_api_key.nil? || openai_api_key.strip.empty?

      say 'ERROR: No OpenAI API key found in credentials or ENV.', :red
      exit(1)
    end
  end
end
