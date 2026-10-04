ActiveSupport.on_load(:dynamic_merge_value) do

  private

  def compute_hash_for_deep_json(options = {}, secure = true)
    if options['include'] && options['include']['value'].to_s == '1' && self.field.value_type == :attachment
      options['include']['value'] = {
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
        }
      }.with_indifferent_access
    end
    super(options, secure)
  end

end
