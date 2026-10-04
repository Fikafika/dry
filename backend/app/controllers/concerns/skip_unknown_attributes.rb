module SkipUnknownAttributes

  def skip_unknown_attributes
    old = Thread.current[:skip_unknown_attributes]
    Thread.current[:skip_unknown_attributes] = true
    yield
  ensure
    Thread.current[:skip_unknown_attributes] = old
  end

end
