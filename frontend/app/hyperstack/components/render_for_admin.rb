module RenderForAdmin

  def self.included(base)
    return if base.singleton_class.included_modules.include?(ClassMethods)
    base.singleton_class.prepend(ClassMethods)
  end

  module ClassMethods
    def render(&block)
      super do
        observe ::User.current
        if ::User.current.connected?
          observe schema = ::Dynamic::Schema.load(self.match.params[:schema_id])
          if schema&.loaded?
            if ::User.current.admin?(self.match.params[:schema_id])
              instance_exec(&block)
            else
              DIV(class: 'p-2') do
                DIV(class: 'alert alert-warning') do
                  ::I18n.t("activerecord.exceptions.unauthorized")
                end
              end
            end
          end
        end
      end
    end
  end
end