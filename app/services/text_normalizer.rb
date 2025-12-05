# frozen_string_literal: true

require 'twitter_cldr'

class TextNormalizer
  ARABIC_MAP = {
    'آ' => 'ا', 'أ' => 'ا', 'إ' => 'ا', 'ٱ' => 'ا',
    'ي' => 'ی', 'ى' => 'ی',
    'ك' => 'ک',
    'ة' => 'ه',
    'ؤ' => 'و',
    'ئ' => 'ی'
  }.freeze

  ARABIC_TATWEEL = /ـ/
  ARABIC_DIACRITICS = /[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED]/
  HEBREW_DIACRITICS = /[\u0591-\u05BD\u05BF\u05C1\u05C2\u05C4\u05C5\u05C7]/

  FULLWIDTH_TO_HALFWIDTH =
    TwitterCldr::Transforms::Transformer.get('Fullwidth-Halfwidth')

  private_constant :ARABIC_MAP, :ARABIC_TATWEEL, :ARABIC_DIACRITICS,
                   :HEBREW_DIACRITICS, :FULLWIDTH_TO_HALFWIDTH

  def initialize(text:)
    @text = text.to_s
  end

  def call
    normalize
  end

  private

  attr_reader :text

  def normalize
    return '' if text.empty?

    s = text.dup

    s.strip!
    s = s.unicode_normalize(:nfkc).unicode_normalize(:nfc)

    # Fullwidth → halfwidth via TwitterCLDR
    s = FULLWIDTH_TO_HALFWIDTH.transform(s)

    # ----------- DIACRITIC REMOVAL (Ruby-native) ----------------
    # (Works for Latin, Arabic combining marks, Vietnamese, etc.)
    s = s.unicode_normalize(:nfd)
    s.gsub!(/\p{Mn}/, '') # remove ALL combining marks
    s = s.unicode_normalize(:nfc)
    # ------------------------------------------------------------

    s.gsub!(ARABIC_TATWEEL, '')
    s.gsub!(ARABIC_DIACRITICS, '')
    ARABIC_MAP.each { |from, to| s.gsub!(from, to) }

    s.gsub!(HEBREW_DIACRITICS, '')

    s = s.downcase
    s.gsub!(/\s+/, ' ')
    s.gsub!(/\A[[:punct:]\s]+|[[:punct:]\s]+\z/, '')

    s
  end
end
