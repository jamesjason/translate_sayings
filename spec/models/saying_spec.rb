require 'rails_helper'

RSpec.describe Saying, type: :model do
  subject { build(:saying) }

  describe 'associations' do
    it { is_expected.to belong_to(:language) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:text) }

    it {
      expect(subject).to validate_length_of(:text)
        .is_at_least(described_class::MINIMUM_TEXT_LENGTH)
        .is_at_most(described_class::MAXIMUM_TEXT_LENGTH)
    }

    it 'validates global, case-insensitive uniqueness of text' do
      create(:saying, text: 'actions speak louder than words')

      expect(subject).to validate_uniqueness_of(:text).case_insensitive
    end
  end

  describe 'normalization' do
    let(:language) { create(:language) }

    it 'strips leading and trailing spaces' do
      saying = described_class.create!(
        language: language,
        text: '  actions speak louder than words  '
      )

      expect(saying.text).to eq('actions speak louder than words')
    end

    it 'collapses multiple internal spaces into a single space' do
      saying = described_class.create!(
        language: language,
        text: 'actions   speak   louder    than   words'
      )

      expect(saying.text).to eq('actions speak louder than words')
    end

    it 'downcases the text' do
      saying = described_class.create!(
        language: language,
        text: 'Actions Speak LOUDER Than Words'
      )

      expect(saying.text).to eq('actions speak louder than words')
    end

    it 'applies normalization before uniqueness validation' do
      described_class.create!(
        language: language,
        text: '  Actions   Speak LOUDER than words '
      )

      dup = described_class.new(
        language: language,
        text: 'actions speak louder than words'
      )

      expect(dup).not_to be_valid
      expect(dup.errors[:text]).to include('has already been taken')
    end
  end

  describe 'database constraints' do
    let(:language) { create(:language) }

    it 'enforces NOT NULL on text' do
      saying = described_class.new(language: language, text: nil)

      expect do
        saying.save(validate: false)
      end.to raise_error(ActiveRecord::NotNullViolation)
    end

    it 'enforces NOT NULL on language_id' do
      saying = described_class.new(language_id: nil, text: 'a stitch in time saves nine')

      expect do
        saying.save(validate: false)
      end.to raise_error(ActiveRecord::NotNullViolation)
    end
  end

  describe '.search' do
    let(:language) { create(:language) }
    let!(:hello) { create(:saying, language:, text: 'Hello world') }
    let!(:help)  { create(:saying, language:, text: 'Help me') }

    before do
      create(:saying, language:, text: 'Goodbye')
    end

    it 'returns sayings that contain the term (case-insensitive)' do
      results = described_class.search(language: language, term: 'he')

      expect(results).to contain_exactly(hello, help)
    end

    it 'returns an empty relation when language is nil' do
      results = described_class.search(language: nil, term: 'he')

      expect(results).to be_empty
    end

    it 'returns an empty relation for terms shorter than 2 characters' do
      results = described_class.search(language: language, term: 'h')

      expect(results).to be_empty
    end

    it 'normalizes whitespace and case in the term' do
      results = described_class.search(language: language, term: '  HeL ')

      expect(results).to contain_exactly(hello, help)
    end

    it 'limits results to 10 records' do
      create_list(:saying, 15, language: language)
      results = described_class.search(language: language, term: 'actions')

      expect(results.size).to eq(10)
    end

    it 'selects only id and text columns' do
      result = described_class.search(language: language, term: 'he').first

      expect(result.attributes.keys.sort).to eq(%w[id text])
    end
  end

  describe '#equivalents_in' do
    it 'returns all linked sayings in the given language' do
      english = create(:language)
      persian = create(:language, :fa)
      en_greeting_a = create(:saying, language: english, text: 'hello')
      en_greeting_b = create(:saying, language: english, text: 'greeting')
      fa_greeting_a = create(:saying, language: persian, text: 'salam')
      fa_greeting_b = create(:saying, language: persian, text: 'dorood')
      create(:saying_translation, saying_a: en_greeting_a, saying_b: fa_greeting_a)
      create(:saying_translation, saying_a: fa_greeting_b, saying_b: en_greeting_b)

      expect(en_greeting_a.equivalents_in(language: persian)).to contain_exactly(fa_greeting_a)
      expect(en_greeting_b.equivalents_in(language: persian)).to contain_exactly(fa_greeting_b)
      expect(fa_greeting_a.equivalents_in(language: english)).to contain_exactly(en_greeting_a)
      expect(fa_greeting_b.equivalents_in(language: english)).to contain_exactly(en_greeting_b)
      expect(en_greeting_a.equivalents_in(language: english)).to eq([])
      expect(en_greeting_a.equivalents_in(language: nil)).to eq([])
    end
  end
end
