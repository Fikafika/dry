module ClassifyPermalink
  def classify_permalink
    #self.gsub(/([a-zA-Z`])[a-z]*/){|match| match.capitalize}.gsub(/[-_\s]/, '') # code from frontend
    I18n.transliterate(self).gsub(/[^[:alpha:][0-9]\s]/, ' ').titleize.gsub(/\s/, '')
  end

  def modulify_permalink
    self.gsub('-', '/').classify
  end
end

String.include(ClassifyPermalink)
