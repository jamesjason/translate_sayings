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

  ARABIC_TATWEEL     = /ـ/
  ARABIC_DIACRITICS  = /[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED]/
  HEBREW_DIACRITICS  = /[\u0591-\u05BD\u05BF\u05C1\u05C2\u05C4\u05C5\u05C7]/
  ZERO_WIDTH_CHARS   = /[\u200B-\u200D\u2060\uFEFF]/

  SMART_QUOTES = {
    '“' => '"', '”' => '"',
    '‘' => "'", '’' => "'"
  }.freeze

  FULLWIDTH_TO_HALFWIDTH =
    TwitterCldr::Transforms::Transformer.get('Fullwidth-Halfwidth')

  private_constant :ARABIC_MAP, :ARABIC_TATWEEL, :ARABIC_DIACRITICS,
                   :HEBREW_DIACRITICS, :ZERO_WIDTH_CHARS, :SMART_QUOTES,
                   :FULLWIDTH_TO_HALFWIDTH

  def initialize(text:)
    @text = text.to_s
  end

  def call
    normalize_text
  end

  private

  attr_reader :text

  def normalize_text
    return '' if text.empty?

    string = text.dup
    string = normalize_unicode_characters(string:)
    string = remove_invisible_and_smart_quotes(string:)
    string = remove_combining_marks(string:)
    string = normalize_semitic_characters(string:)
    normalize_whitespace_and_punctuation(string:)
  end

  def normalize_unicode_characters(string:)
    string = string.strip
    string = string.unicode_normalize(:nfkc).unicode_normalize(:nfc)
    FULLWIDTH_TO_HALFWIDTH.transform(string)
  end

  def remove_invisible_and_smart_quotes(string:)
    string = string.gsub(ZERO_WIDTH_CHARS, '')
    SMART_QUOTES.each { |from, to| string = string.gsub(from, to) }
    string
  end

  def remove_combining_marks(string:)
    string = string.unicode_normalize(:nfd)
    string = string.gsub(/\p{Mn}/, '')
    string.unicode_normalize(:nfc)
  end

  def normalize_semitic_characters(string:)
    string = string.gsub(ARABIC_TATWEEL, '')
    string = string.gsub(ARABIC_DIACRITICS, '')
    ARABIC_MAP.each { |from, to| string = string.gsub(from, to) }
    string.gsub(HEBREW_DIACRITICS, '')
  end

  def normalize_whitespace_and_punctuation(string:)
    string = string.downcase
    string = string.gsub(/\s+/, ' ')
    string = string.strip
    string.gsub(/\A[[:punct:]\s]+|[[:punct:]\s]+\z/, '')
  end
end
