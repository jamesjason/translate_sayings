module ApplicationHelper
  def language_flag(language:, size: 36)
    image_tag(
      "flags/#{language.code}.png",
      alt: "Equivalent saying in #{language.name}",
      class: 'inline-block object-cover rounded-md shadow-sm border border-slate-300',
      style: "height: #{size}px; width: #{size * 1.5}px;"
    )
  end
end
