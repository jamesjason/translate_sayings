require 'rails_helper'

RSpec.describe SuggestedTranslation, type: :model do
  subject { build(:suggested_translation) }

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:source_language).class_name('Language') }
    it { is_expected.to belong_to(:target_language).class_name('Language') }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:source_saying_text) }
    it { is_expected.to validate_presence_of(:target_saying_text) }
    it { is_expected.to validate_presence_of(:status) }

    it do
      expect(subject).to validate_length_of(:source_saying_text)
        .is_at_least(Saying::MINIMUM_TEXT_LENGTH)
        .is_at_most(Saying::MAXIMUM_TEXT_LENGTH)
    end

    it do
      expect(subject).to validate_length_of(:target_saying_text)
        .is_at_least(Saying::MINIMUM_TEXT_LENGTH)
        .is_at_most(Saying::MAXIMUM_TEXT_LENGTH)
    end

    it 'validates allowed enum values' do
      expect(described_class.statuses.keys)
        .to contain_exactly('pending_review', 'approved', 'rejected')
    end
  end

  describe 'normalization' do
    let(:user) { create(:user) }
    let(:en)   { create(:language, code: 'en') }
    let(:fa)   { create(:language, code: 'fa') }

    it 'normalizes whitespace and case on both fields' do
      st = described_class.create!(
        user: user,
        source_language: en,
        target_language: fa,
        source_saying_text: '  Actions   SPEAK  ',
        target_saying_text: '  GOod   DEedS  '
      )

      expect(st.source_saying_text).to eq('actions speak')
      expect(st.target_saying_text).to eq('good deeds')
    end
  end

  describe 'database constraints' do
    let(:user) { create(:user) }
    let(:en)   { create(:language, code: 'en') }
    let(:fa)   { create(:language, code: 'fa') }

    it 'enforces NOT NULL on source_saying_text' do
      st = described_class.new(
        user: user,
        source_language: en,
        target_language: fa,
        source_saying_text: nil,
        target_saying_text: 'hello'
      )

      expect { st.save(validate: false) }.to raise_error(ActiveRecord::NotNullViolation)
    end

    it 'enforces NOT NULL on target_saying_text' do
      st = described_class.new(
        user: user,
        source_language: en,
        target_language: fa,
        source_saying_text: 'hello',
        target_saying_text: nil
      )

      expect { st.save(validate: false) }.to raise_error(ActiveRecord::NotNullViolation)
    end

    it 'enforces NOT NULL on user_id' do
      st = described_class.new(
        user_id: nil,
        source_language: en,
        target_language: fa,
        source_saying_text: 'hello',
        target_saying_text: 'salam'
      )

      expect { st.save(validate: false) }.to raise_error(ActiveRecord::NotNullViolation)
    end

    it 'enforces NOT NULL on source_language_id' do
      st = described_class.new(
        user: user,
        source_language_id: nil,
        target_language: fa,
        source_saying_text: 'hello',
        target_saying_text: 'salam'
      )

      expect { st.save(validate: false) }.to raise_error(ActiveRecord::NotNullViolation)
    end

    it 'enforces NOT NULL on target_language_id' do
      st = described_class.new(
        user: user,
        source_language: en,
        target_language_id: nil,
        source_saying_text: 'hello',
        target_saying_text: 'salam'
      )

      expect { st.save(validate: false) }.to raise_error(ActiveRecord::NotNullViolation)
    end
  end
end
