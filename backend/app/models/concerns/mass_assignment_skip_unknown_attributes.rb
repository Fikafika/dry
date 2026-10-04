module MassAssignmentSkipUnknownAttributes; extend ActiveSupport::Concern

  def sanitize_for_mass_assignment(attributes)
    return super unless Thread.current[:skip_unknown_attributes]
    r = super
    r = r&.reject {|k, v| !respond_to?("#{k}=") }
    return r
  end

end
