# lib/tasks/populate_database.thor

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
        src_text = row[source_code].to_s.strip
        tgt_text = row[target_code].to_s.strip

        next if src_text.empty? || tgt_text.empty?

        src_saying = Saying.find_or_create_by!(language_id: source_language.id, text: src_text)
        sayings_created += 1 if src_saying.previous_changes.key?('id')

        tgt_saying = Saying.find_or_create_by!(language_id: target_language.id, text: tgt_text)
        sayings_created += 1 if tgt_saying.previous_changes.key?('id')

        a_id, b_id = [src_saying.id, tgt_saying.id].sort
        link = SayingTranslation.find_or_create_by!(saying_a_id: a_id, saying_b_id: b_id)
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
