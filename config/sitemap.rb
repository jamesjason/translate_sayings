SitemapGenerator::Sitemap.default_host = 'https://translatesayings.com'

SitemapGenerator::Sitemap.compress = false

SitemapGenerator::Sitemap.create do
  add contribute_path, changefreq: 'monthly', priority: 0.5

  Language.find_each do |language|
    add browse_path(code: language.code), changefreq: 'weekly', priority: 0.7

    if language.code == 'en'
      ('A'..'Z').each do |letter|
        add browse_path(code: language.code, letter: letter),
            changefreq: 'weekly',
            priority: 0.6
      end
    end
  end

  Saying.distinct.pluck(:slug).each do |slug|
    lastmod = Saying.where(slug: slug).maximum(:updated_at)

    add saying_path(slug),
        lastmod: lastmod,
        changefreq: 'monthly',
        priority: 0.9
  end
end
