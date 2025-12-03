require 'rails_helper'

RSpec.describe TranslationVote, type: :model do
  subject(:vote) { described_class.new(user:, saying_translation: translation, vote: 0) }

  let(:user)        { create(:user) }
  let(:translation) { create(:saying_translation) }

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:saying_translation) }
  end

  describe 'validations' do
    it do
      expect(subject)
        .to validate_inclusion_of(:vote)
        .in_array([-1, 0, 1])
        .with_message(
          I18n.t(
            'activerecord.errors.models.translation_vote.attributes.vote.invalid_vote'
          )
        )
    end

    it 'validates uniqueness of user per translation' do
      create(:translation_vote, user:, saying_translation: translation)

      duplicate = described_class.new(
        user:,
        saying_translation: translation,
        vote: 1
      )

      expect(duplicate).not_to be_valid

      expect(duplicate.errors[:user_id]).to include(
        I18n.t(
          'activerecord.errors.models.translation_vote.attributes.user_id.already_voted'
        )
      )
    end
  end

  describe 'instance helpers' do
    let(:translation_vote) { create(:translation_vote) }

    it 'knows when it is an upvote' do
      translation_vote.vote = 1
      expect(translation_vote.upvoted?).to be(true)
      expect(translation_vote.downvoted?).to be(false)
      expect(translation_vote.neutral?).to be(false)
    end

    it 'knows when it is a downvote' do
      translation_vote.vote = -1
      expect(translation_vote.upvoted?).to be(false)
      expect(translation_vote.downvoted?).to be(true)
      expect(translation_vote.neutral?).to be(false)
    end

    it 'knows when it is neutral' do
      translation_vote.vote = 0
      expect(translation_vote.upvoted?).to be(false)
      expect(translation_vote.downvoted?).to be(false)
      expect(translation_vote.neutral?).to be(true)
    end

    describe '#upvote!' do
      it 'sets the vote to +1' do
        expect { translation_vote.upvote! }
          .to change(translation_vote, :vote)
          .from(0).to(1)
      end
    end

    describe '#downvote!' do
      it 'sets the vote to -1' do
        expect { translation_vote.downvote! }
          .to change(translation_vote, :vote)
          .from(0).to(-1)
      end
    end

    describe '#clear_vote!' do
      it 'sets the vote back to 0' do
        translation_vote.update!(vote: -1)

        expect { translation_vote.clear_vote! }
          .to change(translation_vote, :vote)
          .from(-1).to(0)
      end
    end
  end
end
