require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:suggested_translations).dependent(:destroy) }
    it { is_expected.to have_many(:translation_votes).dependent(:destroy) }
  end

  describe 'validations' do
    it { is_expected.to validate_inclusion_of(:role).in_array(described_class::ROLES) }
    it { is_expected.to validate_uniqueness_of(:uid).scoped_to(:provider).allow_nil }
  end

  describe 'callbacks' do
    it 'normalizes email before validation' do
      user = create(:user, email: '  TEST@Email.COM  ')
      expect(user.email).to eq('test@email.com')
    end

    it 'sets default role on create' do
      user = create(:user, role: nil)
      expect(user.role).to eq(described_class::USER_ROLE)
    end
  end

  describe '.authenticate_via_google' do
    let(:provider) { 'google_oauth2' }
    let(:uid) { 'abc123' }
    let(:email) { 'test@example.com' }
    let(:name) { 'John Doe' }

    context 'when a user exists with provider + uid' do
      it 'does not create a new user' do
        create(:user, provider:, uid:)

        expect do
          described_class.authenticate_via_google(
            provider:, uid:, email:, name:
          )
        end.not_to change(described_class, :count)
      end

      it 'returns the existing user' do
        existing_user = create(:user, provider:, uid:)

        user = described_class.authenticate_via_google(
          provider:, uid:, email: existing_user.email, name:
        )

        expect(user).to eq(existing_user)
      end
    end

    context 'when a user exists with the same email but no provider/uid' do
      it 'does not create a new user' do
        create(:user, email:, provider: nil, uid: nil)

        expect do
          described_class.authenticate_via_google(
            provider:, uid:, email:, name:
          )
        end.not_to change(described_class, :count)
      end

      it 'updates provider + uid' do
        existing_user = create(:user, email:, provider: nil, uid: nil)

        described_class.authenticate_via_google(
          provider:, uid:, email:, name:
        )

        existing_user.reload
        expect(existing_user.provider).to eq(provider)
        expect(existing_user.uid).to eq(uid)
      end

      it 'returns the existing user' do
        existing_user = create(:user, email:, provider: nil, uid: nil)

        user = described_class.authenticate_via_google(
          provider:, uid:, email:, name:
        )

        expect(user).to eq(existing_user)
      end
    end

    context 'when no matching user exists' do
      it 'creates a new user' do
        expect do
          described_class.authenticate_via_google(
            provider:, uid:, email:, name:
          )
        end.to change(described_class, :count).by(1)
      end

      it 'sets all attributes correctly' do
        user = described_class.authenticate_via_google(
          provider:, uid:, email:, name:
        )

        expect(user).to be_persisted
        expect(user.email).to eq(email)
        expect(user.provider).to eq(provider)
        expect(user.uid).to eq(uid)
        expect(user.name).to eq(name)
        expect(user.role).to eq(described_class::USER_ROLE)
      end
    end
  end

  describe '#admin?' do
    it 'returns true when role is admin' do
      user = build(:user, :admin)
      expect(user.admin?).to be(true)
    end

    it 'returns false when role is user' do
      user = build(:user)
      expect(user.admin?).to be(false)
    end
  end
end
