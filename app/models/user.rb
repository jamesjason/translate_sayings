class User < ApplicationRecord
  USER_ROLE = 'user'.freeze
  ADMIN_ROLE = 'admin'.freeze
  ROLES = [USER_ROLE, ADMIN_ROLE].freeze

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:google_oauth2]

  has_many :suggested_translations, dependent: :destroy
  has_many :translation_votes, dependent: :destroy

  before_validation :normalize_email
  before_validation :set_default_role, on: :create

  validates :uid, uniqueness: { scope: :provider }, allow_nil: true
  validates :role,
            presence: true,
            inclusion: { in: ROLES }

  def self.authenticate_via_google(provider:, uid:, email:, name:)
    user = find_or_initialize_by(provider:, uid:)
    return user if user.persisted?

    # Merge Google credentials for existing users
    if (existing_user = find_by(email:))
      existing_user.update!(provider:, uid:)
      return existing_user
    end

    create!(
      provider:,
      uid:,
      email:,
      name:,
      password: Devise.friendly_token,
      role: USER_ROLE
    )
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end

  def set_default_role
    self.role ||= USER_ROLE
  end
end
