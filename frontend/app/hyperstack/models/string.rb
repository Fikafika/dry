class String

  def classify_permalink
    self.gsub(/([a-zA-Z`])[a-z]*/){|match| match.capitalize}.gsub(/[-_\s]/, '')
  end

end
