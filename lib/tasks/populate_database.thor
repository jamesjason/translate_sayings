require 'thor'
require 'csv'
require 'fileutils'
require_relative '../../config/environment'

class PopulateDatabase < Thor
  desc 'sayings',
       'Populate sayings and saying_translations from CSV files in data/saying_translations'

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
        say "Skipping #{basename} (filename must be SOURCE_to_TARGET.csv)", :yellow
        next
      end

      source_code = match[1]
      target_code = match[2]

      source_language = Language.find_by!(code: source_code)
      target_language = Language.find_by!(code: target_code)

      say "Processing #{basename} (#{source_code} → #{target_code})…"

      sayings_created = 0
      links_created   = 0

      CSV.foreach(path, headers: true) do |row|
        src_raw = row[source_code].to_s
        tgt_raw = row[target_code].to_s

        next if src_raw.strip.empty? || tgt_raw.strip.empty?

        src_norm = normalized_lookup_value(text: src_raw)
        tgt_norm = normalized_lookup_value(text: tgt_raw)

        # ============================================================
        # SOURCE SAYING
        # ============================================================
        begin
          src_saying = Saying.find_by(language_id: source_language.id, text: src_norm)

          unless src_saying
            src_saying = Saying.create!(
              language_id: source_language.id,
              text: src_raw
            )
            sayings_created += 1
          end
        rescue ActiveRecord::RecordInvalid => e
          say "\n❌ ERROR inserting SOURCE saying", :red
          say "  File: #{basename}"
          say "  Language: #{source_language.code}"
          say "  Raw text: #{src_raw.inspect}"
          say "  Normalized lookup text: #{src_norm.inspect}"
          say "  Error: #{e.message}", :red
          say '  Existing conflicting saying:', :yellow

          existing = Saying.find_by(language_id: source_language.id, text: src_norm)
          say "    id: #{existing&.id}"
          say "    text: #{existing&.text.inspect}"
          say "    normalized_text: #{existing&.normalized_text.inspect}"

          raise e
        end

        # ============================================================
        # TARGET SAYING
        # ============================================================
        begin
          tgt_saying = Saying.find_by(language_id: target_language.id, text: tgt_norm)

          unless tgt_saying
            tgt_saying = Saying.create!(
              language_id: target_language.id,
              text: tgt_raw
            )
            sayings_created += 1
          end
        rescue ActiveRecord::RecordInvalid => e
          say "\n❌ ERROR inserting TARGET saying", :red
          say "  File: #{basename}"
          say "  Language: #{target_language.code}"
          say "  Raw text: #{tgt_raw.inspect}"
          say "  Normalized lookup text: #{tgt_norm.inspect}"
          say "  Error: #{e.message}", :red
          say '  Existing conflicting saying:', :yellow

          existing = Saying.find_by(language_id: target_language.id, text: tgt_norm)
          say "    id: #{existing&.id}"
          say "    text: #{existing&.text.inspect}"
          say "    normalized_text: #{existing&.normalized_text.inspect}"

          raise e
        end

        # ============================================================
        # LINK RECORD
        # ============================================================
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

  no_commands do
    def normalized_lookup_value(text:)
      saying = Saying.new(text:)

      saying.send(:normalize_text_fields)

      saying.text
    end
  end
end
