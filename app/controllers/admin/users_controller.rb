module Admin
  class UsersController < BaseController
    def index
      @users = User
               .includes(:suggested_translations, :translation_votes)
               .order(created_at: :desc)
    end

    def show
      @user = User.find(params[:id])

      @suggested_translations =
        @user.suggested_translations
             .includes(:source_language, :target_language)
             .order(created_at: :desc)

      @translation_votes =
        @user.translation_votes
             .includes(saying_translation: %i[saying_a saying_b])
             .order(created_at: :desc)
    end
  end
end
