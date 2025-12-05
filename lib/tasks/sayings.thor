require_relative '../../config/environment'

class Sayings < Thor
  desc 'backfill_slugs_for_english_sayings', 'Backfill unique slugs for English sayings only'
  def backfill_slugs_for_english_sayings
    say('Backfilling slugs for English sayings...', :green)

    english = Language.find_by!(code: 'en')

    Saying.where(language: english, slug: nil).find_each do |saying|
      base = saying.text.to_s.parameterize

      if base.blank?
        say("Skipping saying #{saying.id}: cannot derive slug", :yellow)
        next
      end

      slug = base
      suffix = 2

      while Saying.exists?(slug: slug)
        slug = "#{base}-#{suffix}"
        suffix += 1
      end

      begin
        saying.update_columns(slug: slug) # rubocop:disable Rails/SkipsModelValidations
        say("OK  #{saying.id} → #{slug}", :green)
      rescue StandardError => e
        say("FAILED #{saying.id}: #{e.message}", :red)
      end
    end

    say('Slug backfill complete.', :green)
  end

  desc 'backfill_slugs_for_non_english_sayings',
       'Assign non-English sayings the slug of their English equivalent'
  def backfill_slugs_for_non_english_sayings
    say('Backfilling slugs for non-English sayings...', :green)

    english = Language.find_by!(code: 'en')

    Saying.where.not(language: english).where(slug: nil).find_each do |saying|
      english_equivalent =
        saying.linked_sayings.find { |s| s.language_id == english.id }

      unless english_equivalent
        say("SKIP #{saying.id}: No English equivalent found", :yellow)
        next
      end

      if english_equivalent.slug.blank?
        say("SKIP #{saying.id}: English saying #{english_equivalent.id} has no slug", :red)
        next
      end

      saying.update_columns(slug: english_equivalent.slug) # rubocop:disable Rails/SkipsModelValidations
      say("OK #{saying.id} → #{english_equivalent.slug}", :green)
    rescue StandardError => e
      say("ERROR processing saying #{saying.id}: #{e.class} – #{e.message}", :red)
      say("      #{e.backtrace.first}", :red)
      next
    end

    say('Non-English slug backfill complete.', :green)
  end

  desc 'capitalize_first_letter',
       'Capitalizes only the first letter of all English sayings'
  method_option :dry_run, type: :boolean, default: true, desc: 'Preview changes without saving'

  def capitalize_first_letter
    dry = options[:dry_run]

    english = Language.find_by!(code: 'en')
    sayings = Saying.where(language: english)

    say "Found #{sayings.count} English sayings.", :yellow
    say dry ? 'Running in DRY RUN mode — no changes will be saved.' : 'Applying updates...', :cyan

    updated = 0

    sayings.find_each do |saying|
      next if saying.text.blank?

      original = saying.text
      fixed = original.sub(/\A([a-z])/) { ::Regexp.last_match(1).upcase }

      next if fixed == original

      say "ID #{saying.id}: \"#{original}\" → \"#{fixed}\"", :blue

      if dry
        updated += 1
        next
      end

      saying.update_columns(text: fixed) # rubocop:disable Rails/SkipsModelValidations
      updated += 1
    end

    say dry ? "DRY RUN complete. #{updated} sayings WOULD be updated." : "Done. Updated #{updated} English sayings.",
        :green
  end
end
