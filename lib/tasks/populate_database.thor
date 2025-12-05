# lib/tasks/populate_database.thor

require 'thor'
require 'csv'
require 'fileutils'

require_relative '../../config/environment'

class PopulateDatabase < Thor
  desc 'sayings',
       'Populate sayings and saying_translations from CSV files in data/saying_translations'

  # --- Helper method: use model’s normalization pipeline exactly ---
  no_commands do
    def normalized_for_lookup(raw_text)
      tmp = Saying.new(text: raw_text)
      tmp.valid?  # triggers before_validation callbacks
      tmp.text    # return the final normalized text Rails will try to save
    end
  end
  # ----------------------------------------------------------------

  def sayings
    dir = File.join(Dir.pwd, 'data', 'saying_translations')
    unless Dir.exist?(dir)
      say "Directory not found: #{dir}", :red
      exit(1)
    end

    files = Dir.glob(File.join(dir, '*.csv'))
    if files.empty?
      say "No CSV files found in #{dir}", :yellow
      return
    end

    total_sayings_created = 0
    total_links_created   = 0

    files.each do |path|
      basename = File.basename(path)
      match = basename.match(/\A([a-z]+)_to_([a-z]+)\.csv\z/)

      unless match
        say "Skipping #{basename} (filename does not match SOURCE_to_TARGET.csv)", :yellow
        next
      end

      source_code = match[1]
      target_code = match[2]

      source_language = Language.find_by(code: source_code)
      target_language = Language.find_by(code: target_code)

      if source_language.nil? || target_language.nil?
        say "Skipping #{basename} (missing Language records for #{source_code} or #{target_code})", :yellow
        next
      end

      say "Processing #{basename} (#{source_code} → #{target_code})…"

      sayings_created = 0
      links_created   = 0

      CSV.foreach(path, headers: true) do |row|
        src_text_raw = row[source_code].to_s.strip
        tgt_text_raw = row[target_code].to_s.strip

        # Skip if empty or missing translation
        next if src_text_raw.empty? || tgt_text_raw.empty?

        # Normalize for lookup using model’s real normalization logic
        src_norm = normalized_for_lookup(src_text_raw)
        tgt_norm = normalized_for_lookup(tgt_text_raw)

        # --- Source saying ---
        src_saying = Saying.find_by(language_id: source_language.id, text: src_norm)
        unless src_saying
          src_saying = Saying.create!(
            language_id: source_language.id,
            text: src_text_raw # model will normalize it correctly
          )
          sayings_created += 1
        end

        # --- Target saying ---
        tgt_saying = Saying.find_by(language_id: target_language.id, text: tgt_norm)
        unless tgt_saying
          tgt_saying = Saying.create!(
            language_id: target_language.id,
            text: tgt_text_raw
          )
          sayings_created += 1
        end

        # --- Create SayingTranslation link ---
        a_id, b_id = [src_saying.id, tgt_saying.id].sort

        link = SayingTranslation.find_or_create_by!(
          saying_a_id: a_id,
          saying_b_id: b_id
        )
        links_created += 1 if link.previous_changes.key?('id')
      end

      total_sayings_created += sayings_created
      total_links_created   += links_created

      say "  Created #{sayings_created} sayings and #{links_created} links from #{basename}.", :green
    end

    say ''
    say "Done. Created #{total_sayings_created} sayings and #{total_links_created} saying_translations in total.",
        :green
  end
end
