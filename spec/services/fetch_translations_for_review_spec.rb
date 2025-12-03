require 'rails_helper'

RSpec.describe FetchTranslationsForReview do
  let(:user) { create(:user) }

  let!(:english) { create(:language) }
  let!(:farsi)   { create(:language, :fa) }
  let!(:spanish) { create(:language, :es) }

  describe '#call' do
    it 'returns correctly mapped translations with accurate votes' do
      translation1 = create_translation(
        language1: english, text1: 'hello',
        language2: farsi,   text2: 'salam'
      )
      translation2 = create_translation(
        language1: farsi,   text1: 'salam2',
        language2: english, text2: 'hello2'
      )
      create(:translation_vote, user:, saying_translation: translation1, vote: 1)
      create(:translation_vote, saying_translation: translation2, vote: 1)
      create(:translation_vote, saying_translation: translation2, vote: 1)
      create(:translation_vote, saying_translation: translation2, vote: -1)

      results = described_class.new(
        user:,
        language_a: english,
        language_b: farsi
      ).call

      expect(results).to contain_exactly(
        a_hash_including(
          id: translation2.id,
          saying_a: 'hello2',
          saying_b: 'salam2',
          upvotes: 2,
          downvotes: 1,
          user_vote: 0
        )
      )
    end

    context 'ordering rules' do
      it "puts Language::DEFAULT_SOURCE_LANGUAGE first when it's present" do
        create_translation(
          language1: farsi,   text1: 'salam',
          language2: english, text2: 'hello'
        )

        translations = described_class.new(
          user:,
          language_a: farsi,
          language_b: english
        ).call

        result = translations.first
        expect(result[:saying_a]).to eq('hello')
        expect(result[:saying_b]).to eq('salam')
      end

      it 'uses user-selected order when default source language is not present' do
        create_translation(
          language1: spanish, text1: 'hola',
          language2: farsi,   text2: 'salam'
        )

        translations = described_class.new(
          user:,
          language_a: farsi,
          language_b: spanish
        ).call

        result = translations.first
        expect(result[:saying_a]).to eq('salam')
        expect(result[:saying_b]).to eq('hola')
      end
    end

    context 'unreviewed filtering' do
      it 'excludes translations the user has already voted on' do
        translation1 = create_translation(language1: farsi, language2: spanish)
        translation2 = create_translation(language1: farsi, language2: spanish)

        create(:translation_vote, user:, saying_translation: translation1, vote: 1)

        translations = described_class.new(
          user:,
          language_a: farsi,
          language_b: spanish
        ).call

        ids = translations.pluck(:id)
        expect(ids).to include(translation2.id)
        expect(ids).not_to include(translation1.id)
      end

      context 'when user is nil' do
        it 'returns all translations without filtering' do
          translation1 = create_translation(language1: english, language2: farsi)
          translation2 = create_translation(language1: farsi, language2: english)

          translations = described_class.new(
            user: nil,
            language_a: english,
            language_b: farsi
          ).call

          ids = translations.pluck(:id)
          expect(ids).to include(translation1.id, translation2.id)
        end
      end
    end

    context 'batch size' do
      it 'returns at most REVIEW_BATCH_SIZE translations' do
        20.times { create_translation(language1: english, language2: farsi) }

        results = described_class.new(
          user:,
          language_a: english,
          language_b: farsi
        ).call

        expect(results.size).to eq(SayingTranslation::REVIEW_BATCH_SIZE)
      end
    end

    context 'empty result' do
      it 'returns an empty array when no matching translations exist' do
        results = described_class.new(
          user:,
          language_a: farsi,
          language_b: english
        ).call

        expect(results).to eq([])
      end
    end
  end
end
