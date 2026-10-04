ActiveSupport.on_load(:dynamic_merge_setting) do

  concerning :Permissions do
    included do
      include UneekPermission::ControlledKlass
    end
  end

  def as_deep_json(options = {})
    super(default_includes_for_as_deep_json(options))
  end

  def default_includes_for_as_deep_json(options)
    if options['include']
      ['record_to_merges', 'result_record'].each do |assoc|
        if options['include'][assoc].to_s == '1'
          options['include'][assoc] = {
            include: includes_for_klass(self.result_record_klass)
          }
        end
      end
    end
    return options
  end

  def includes_for_klass(klass)
    return {} unless klass
    result = {}
    klass.reflect_on_all_associations.each do |r|
      next unless r.try(:schema_association_id) && !r.name.end_with?('_with_deleted')
      result[r.name] = 1
    end
    klass.reflect_on_all_attachments.each do |r|
      case r.macro
      when :has_one_attached
        result[r.name] = {
          except: ['record'],
          include: {
            attachment: {
              only: [],
              include: {
                signed_id: 1,
                filename: 1,
                blob: {
                  only: [
                    'content_type',
                    'byte_size',
                    'checksum',
                  ],
                  include: {
                    signed_id: 1,
                    filename: 1,
                  },
                },
              },
            },
          },
        }
      when :has_many_attached
        result[r.name] = {
          except: ['record'],
          include: {
            attachments: {
              only: [],
              include: {
                signed_id: 1,
                filename: 1,
                blob: {
                  only: [
                    'content_type',
                    'byte_size',
                    'checksum',
                  ],
                  include: {
                    signed_id: 1,
                    filename: 1,
                  },
                },
              },
            },
          },
        }
      end
    end
    return result
  end

end
