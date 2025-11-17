require 'rails_helper'

RSpec.describe Language, type: :model do
  subject { build(:language) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:code) }
    it { is_expected.to validate_presence_of(:name) }

    it { is_expected.to validate_uniqueness_of(:code).case_insensitive }

    it do
      expect(subject).to validate_inclusion_of(:code)
        .in_array(Language::SUPPORTED_LANGUAGES.keys)
    end
  end

  describe 'database constraints' do
    it 'enforces NOT NULL on code' do
      language = described_class.new(code: nil, name: 'English')

      expect do
        language.save(validate: false)
      end.to raise_error(ActiveRecord::NotNullViolation)
    end

    it 'enforces NOT NULL on name' do
      language = described_class.new(code: 'en', name: nil)

      expect do
        language.save(validate: false)
      end.to raise_error(ActiveRecord::NotNullViolation)
    end

    it 'enforces uniqueness of code at the database level' do
      described_class.create!(code: 'en', name: 'English')
      duplicate = described_class.new(code: 'en', name: 'British English')

      expect do
        duplicate.save(validate: false)
      end.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it 'enforces lowercase-only code via the check constraint' do
      language = described_class.new(code: 'En', name: 'English')

      expect do
        language.save(validate: false)
      end.to raise_error(ActiveRecord::CheckViolation)
    end
  end
end
