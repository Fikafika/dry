module FindByIdOrName; extend ActiveSupport::Concern

  def find_by_id_or_name(scope, id_or_name, transform_method = nil)
    if id?(id_or_name)
      scope.find(id_or_name)
    else
      case transform_method
        when String, Symbol
          scope.find_by!(name: id_or_name&.send(transform_method))
        when Proc
          scope.find_by!(name: transform_method.call(id_or_name))
        else
          scope.find_by!(name: id_or_name)
      end
    end
  end

  def id?(str)
    !!(str =~ /(?:\A\d+\Z)|(?:\A[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}\Z)/)
  end

end
