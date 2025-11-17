require 'rails_helper'

RSpec.describe Saying, type: :model do
  subject { build(:saying) }

  describe 'associations' do
    it { is_expected.to belong_to(:language) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:text) }
    it { is_expected.to validate_length_of(:text).is_at_least(described_class::MINIMUM_TEXT_LENGTH) }

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
end
