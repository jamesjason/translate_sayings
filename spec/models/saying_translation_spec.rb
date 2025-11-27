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
      translation = build(:saying_translation, saying_a: saying1, saying_b: saying1)

      expect(translation).not_to be_valid
      expect(translation.errors[:base]).to include('saying_a and saying_b must be different')
    end

    context 'unique_translation_pair' do
      it 'is invalid when the same pair exists in the same order' do
        described_class.create!(saying_a: saying1, saying_b: saying2)
        duplicate_translation = described_class.new(saying_a: saying1, saying_b: saying2)

        expect(duplicate_translation).not_to be_valid
        expect(duplicate_translation.errors[:base]).to include('This translation pair already exists')
      end

      it 'is invalid when the same pair exists in reverse order' do
        described_class.create!(saying_a: saying1, saying_b: saying2)
        reversed_translation = described_class.new(saying_a: saying2, saying_b: saying1)

        expect(reversed_translation).not_to be_valid
        expect(reversed_translation.errors[:base]).to include('This translation pair already exists')
      end

      it 'allows a different pair' do
        described_class.create!(saying_a: saying1, saying_b: saying2)
        different_translation = described_class.new(saying_a: saying1, saying_b: saying3)

        expect(different_translation).to be_valid
      end

      it 'allows updating the same record' do
        translation = described_class.create!(saying_a: saying1, saying_b: saying2)
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
        duplicate_translation = described_class.new(saying_a: saying1, saying_b: saying2)

        expect do
          duplicate_translation.save(validate: false)
        end.to raise_error(ActiveRecord::RecordNotUnique)
      end

      it 'enforces uniqueness for reversed pairs at the database level' do
        described_class.create!(saying_a: saying1, saying_b: saying2)
        reversed_translation = described_class.new(saying_a: saying2, saying_b: saying1)

        expect do
          reversed_translation.save(validate: false)
        end.to raise_error(ActiveRecord::RecordNotUnique)
      end
    end
  end

  describe 'instance methods' do
    let(:language)       { create(:language) }
    let(:source_saying)  { create(:saying, language:) }
    let(:target_saying)  { create(:saying, language:) }
    let(:translation)    { create(:saying_translation, saying_a: source_saying, saying_b: target_saying) }

    describe '#accuracy_score' do
      it 'returns a positive score for a single upvote' do
        create(:translation_vote, saying_translation: translation, vote: 1)
        score = translation.accuracy_score

        expect(score).to be > 0
        expect(score).to be < 1
      end

      it 'returns a higher score when the upvote ratio is higher' do
        4.times { create(:translation_vote, saying_translation: translation, vote: 1) }
        create(:translation_vote, saying_translation: translation, vote: -1)
        translation_score = translation.accuracy_score
        other_target_saying = create(:saying, language: source_saying.language)
        other_translation = create(
          :saying_translation,
          saying_a: source_saying,
          saying_b: other_target_saying
        )
        2.times { create(:translation_vote, saying_translation: other_translation, vote: 1) }
        2.times { create(:translation_vote, saying_translation: other_translation, vote: -1) }

        other_score = other_translation.accuracy_score

        expect(translation_score).to be > other_score
      end

      it 'returns 0.0 when there are no votes' do
        expect(translation.accuracy_score).to eq(0.0)
      end
    end

    describe '#user_vote_value' do
      let(:user) { create(:user) }

      it 'returns 0 when user is nil' do
        expect(translation.user_vote_value(nil)).to eq(0)
      end

      it 'returns 0 when the user has not voted' do
        expect(translation.user_vote_value(user)).to eq(0)
      end

      it 'returns 1 when the user upvoted' do
        create(:translation_vote, user:, saying_translation: translation, vote: 1)
        expect(translation.user_vote_value(user)).to eq(1)
      end

      it 'returns -1 when the user downvoted' do
        create(:translation_vote, user:, saying_translation: translation, vote: -1)
        expect(translation.user_vote_value(user)).to eq(-1)
      end
    end

    describe '#register_vote' do
      let(:user) { create(:user) }

      it 'creates a new vote when none exists' do
        translation.register_vote(user:, value: 1)

        expect(translation.translation_votes.count).to eq(1)
        expect(translation.user_vote_value(user)).to eq(1)
      end

      it 'toggles the same vote to zero' do
        translation.register_vote(user:, value: 1)
        translation.register_vote(user:, value: 1)

        expect(translation.user_vote_value(user)).to eq(0)
      end

      it 'switches from upvote to downvote' do
        translation.register_vote(user:, value: 1)
        translation.register_vote(user:, value: -1)

        expect(translation.user_vote_value(user)).to eq(-1)
      end

      it 'switches from downvote to upvote' do
        translation.register_vote(user:, value: -1)
        translation.register_vote(user:, value: 1)

        expect(translation.user_vote_value(user)).to eq(1)
      end
    end
  end

  describe 'scopes' do
    let!(:english) { create(:language) }
    let!(:farsi)   { create(:language, :fa) }
    let!(:spanish) { create(:language, :es) }

    describe '.between_languages' do
      it 'returns translations in either direction for the selected language pair' do
        translation1 = create_translation(language1: english, language2: farsi)
        translation2 = create_translation(language1: farsi,   language2: english)
        translation3 = create_translation(language1: english, language2: spanish)
        translation4 = create_translation(language1: spanish, language2: farsi)

        results = described_class.between_languages(language_a: english, language_b: farsi)

        expect(results).to include(translation1, translation2)
        expect(results).not_to include(translation3, translation4)
      end
    end

    describe '.unreviewed_by' do
      let(:user) { create(:user) }

      it 'returns all translations when the user is nil' do
        translation1 = create(:saying_translation)
        translation2 = create(:saying_translation)

        results = described_class.unreviewed_by(nil)

        expect(results).to include(translation1, translation2)
      end

      it 'excludes translations the user has voted on' do
        translation1 = create_translation(language1: english, language2: farsi)
        translation2 = create_translation(language1: english, language2: farsi)

        create(:translation_vote, user:, saying_translation: translation1, vote: 1)

        results = described_class.unreviewed_by(user)

        expect(results).to include(translation2)
        expect(results).not_to include(translation1)
      end
    end

    describe '.random_batch' do
      it 'returns REVIEW_BATCH_SIZE translations' do
        20.times { create_translation(language1: english, language2: farsi) }

        results = described_class.random_batch
        expect(results.size).to eq(SayingTranslation::REVIEW_BATCH_SIZE)
      end
    end
  end
end
