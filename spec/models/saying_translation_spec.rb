require 'rails_helper'

RSpec.describe SayingTranslation, type: :model do
  subject { build(:saying_translation) }

  describe 'associations' do
    it { is_expected.to belong_to(:saying_a).class_name('Saying') }
    it { is_expected.to belong_to(:saying_b).class_name('Saying') }
  end

  describe 'custom validations' do
    let(:language) { create(:language) }
    let(:saying1)  { create(:saying, language:, text: 'actions speak louder than words') }
    let(:saying2)  { create(:saying, language:, text: 'a stitch in time saves nine') }
    let(:saying3)  { create(:saying, language:, text: 'better late than never') }

    it 'is invalid when saying_a and saying_b are the same' do
      translation = build(
        :saying_translation,
        saying_a: saying1,
        saying_b: saying1
      )

      expect(translation).not_to be_valid
      expect(translation.errors[:base]).to include('saying_a and saying_b must be different')
    end

    context 'unique_translation_pair (unordered uniqueness)' do
      it 'is invalid when the exact same pair already exists (same order)' do
        described_class.create!(
          saying_a: saying1,
          saying_b: saying2
        )

        duplicate = described_class.new(
          saying_a: saying1,
          saying_b: saying2
        )

        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:base]).to include('This translation pair already exists')
      end

      it 'is invalid when the same pair exists in reverse order' do
        described_class.create!(
          saying_a: saying1,
          saying_b: saying2
        )

        reverse = described_class.new(
          saying_a: saying2,
          saying_b: saying1
        )

        expect(reverse).not_to be_valid
        expect(reverse.errors[:base]).to include('This translation pair already exists')
      end

      it 'allows a different pair' do
        described_class.create!(
          saying_a: saying1,
          saying_b: saying2
        )

        different_pair = described_class.new(
          saying_a: saying1,
          saying_b: saying3
        )

        expect(different_pair).to be_valid
      end

      it 'does not block updating the same record' do
        translation = described_class.create!(
          saying_a: saying1,
          saying_b: saying2
        )

        translation.updated_at = Time.current
        expect(translation).to be_valid
        expect(translation.save).to be true
      end
    end

    context 'database constraints' do
      it 'enforces NOT NULL on saying_a_id' do
        translation = described_class.new(saying_a: nil, saying_b: saying2)

        expect do
          translation.save(validate: false)
        end.to raise_error(ActiveRecord::NotNullViolation)
      end

      it 'enforces NOT NULL on saying_b_id' do
        translation = described_class.new(saying_a: saying1, saying_b: nil)

        expect do
          translation.save(validate: false)
        end.to raise_error(ActiveRecord::NotNullViolation)
      end

      it 'enforces no self-translation at the database level' do
        translation = described_class.new(saying_a: saying1, saying_b: saying1)

        expect do
          translation.save(validate: false)
        end.to raise_error(ActiveRecord::CheckViolation)
      end

      it 'enforces uniqueness for the same pair at the database level' do
        described_class.create!(saying_a: saying1, saying_b: saying2)

        duplicate = described_class.new(saying_a: saying1, saying_b: saying2)

        expect do
          duplicate.save(validate: false)
        end.to raise_error(ActiveRecord::RecordNotUnique)
      end

      it 'enforces uniqueness for reversed pairs at the database level' do
        described_class.create!(saying_a: saying1, saying_b: saying2)
        reversed = described_class.new(saying_a: saying2, saying_b: saying1)

        expect do
          reversed.save(validate: false)
        end.to raise_error(ActiveRecord::RecordNotUnique)
      end
    end
  end
end
