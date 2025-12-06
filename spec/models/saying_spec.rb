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

    it 'validates uniqueness of text scoped to language' do
      english = create(:language)
      spanish = create(:language, :es)
      saying_text = 'actions speak louder than words'
      create(:saying, language: english, text: saying_text)
      duplicate_saying = build(:saying,
                               language: english,
                               text: saying_text)
      spanish_saying = build(:saying,
                             language: spanish,
                             text: saying_text)

      expect(duplicate_saying).not_to be_valid
      expect(duplicate_saying.errors[:text]).to include('has already been taken')
      expect(spanish_saying).to be_valid
    end
  end

  describe 'normalization' do
    let(:language) { create(:language) }

    it 'strips leading and trailing spaces' do
      saying = create(:saying, language:, text: '  Hello world  ')

      expect(saying.text).to eq('Hello world')
    end

    it 'collapses multiple internal spaces into a single space' do
      saying = create(:saying, language:, text: 'Hello    world   from  Ruby')

      expect(saying.text).to eq('Hello world from Ruby')
    end

    it 'applies normalization before uniqueness validation' do
      create(:saying, language:, text: '  Hello   world ')

      dup = described_class.new(
        language: language,
        text: 'Hello world'
      )

      expect(dup).not_to be_valid
      expect(dup.errors[:text]).to include('has already been taken')
    end

    it 'computes normalized_text using the full TextNormalizer' do
      saying = create(:saying, language:, text: '  Hélló   WÖRLD  ')

      expect(saying.normalized_text).to eq(
        TextNormalizer.new(text: '  Hélló   WÖRLD  ').call
      )
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
      saying = described_class.new(language_id: nil, text: 'hello')

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

    it 'returns sayings matching the normalized query' do
      results = described_class.search(language:, term: '  HeL ')
      expect(results).to contain_exactly(hello, help)
    end

    it 'returns an empty relation when language is nil' do
      expect(described_class.search(language: nil, term: 'he')).to be_empty
    end

    it 'returns an empty relation for terms shorter than 2 characters' do
      expect(described_class.search(language:, term: 'h')).to be_empty
    end

    it 'limits results to 10 records' do
      create_list(:saying, 15, language:)
      results = described_class.search(language:, term: 'act')
      expect(results.size).to eq(10)
    end

    it 'selects only id and text columns' do
      result = described_class.search(language:, term: 'he').first
      expect(result.attributes.keys.sort).to eq(%w[id text])
    end
  end

  describe '.find_canonical_by' do
    let!(:english) { create(:language) }
    let!(:persian) { create(:language, :fa) }

    context 'when an English saying exists with the slug' do
      it 'returns the English saying' do
        create(:saying, language: persian, slug: 'abc', text: 'سلام دنیا')
        english_saying = create(:saying, language: english, slug: 'abc', text: 'hello world')

        expect(described_class.find_canonical_by(slug: 'abc')).to eq(english_saying)
      end
    end

    context 'when no English saying exists with the slug' do
      let!(:persian_saying) { create(:saying, language: persian, slug: 'xyz', text: 'سلام') }

      it 'returns the non-English saying' do
        expect(described_class.find_canonical_by(slug: 'xyz')).to eq(persian_saying)
      end
    end

    context 'when no saying exists with the slug' do
      it 'returns nil' do
        expect(described_class.find_canonical_by(slug: 'missing')).to be_nil
      end
    end
  end

  describe '#equivalents_in' do
    it 'returns all linked sayings in the given language' do
      english = create(:language)
      persian = create(:language, :fa)
      en_a = create(:saying, language: english, text: 'hello')
      en_b = create(:saying, language: english, text: 'greeting')
      fa_a = create(:saying, language: persian, text: 'salam')
      fa_b = create(:saying, language: persian, text: 'dorood')

      create(:saying_translation, saying_a: en_a, saying_b: fa_a)
      create(:saying_translation, saying_a: fa_b, saying_b: en_b)

      expect(en_a.equivalents_in(language: persian)).to contain_exactly(fa_a)
      expect(en_b.equivalents_in(language: persian)).to contain_exactly(fa_b)
      expect(fa_a.equivalents_in(language: english)).to contain_exactly(en_a)
      expect(fa_b.equivalents_in(language: english)).to contain_exactly(en_b)
      expect(en_a.equivalents_in(language: english)).to eq([])
      expect(en_a.equivalents_in(language: nil)).to eq([])
    end
  end
end
