class Exception

  def original_source_location
    @original_source_location ||= SourceLocation.new(self)
  end

end
