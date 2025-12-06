class ApplicationController < ActionController::Base
  include MetaTags::ControllerHelper

  before_action :set_default_meta_tags

  allow_browser versions: :modern
  stale_when_importmap_changes

  def authenticate_user!
    return super if user_signed_in?

    respond_to do |format|
      format.html { super }
      format.json { render json: { error: 'unauthenticated' }, status: :unauthorized }
    end
  end

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || super
  end

  def after_sign_up_path_for(resource)
    stored_location_for(resource) || super
  end

  private

  def set_default_meta_tags
    set_meta_tags(
      site: 'Translate Sayings',
      reverse: true,
      separator: ' — ',
      description: 'Search for a saying in one language and find the closest matching saying in another.',
      keywords: 'translate sayings, proverb translation, idioms, multilingual proverbs',
      robots: 'index, follow',
      og: {
        type: 'website',
        site_name: 'Translate Sayings',
        url: root_url,
        image: view_context.image_url('logo.png')
      },
      twitter: {
        card: 'summary_large_image',
        image: view_context.image_url('logo.png')
      }
    )
  end
end
