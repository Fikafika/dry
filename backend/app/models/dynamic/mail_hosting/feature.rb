module Dynamic
  module MailHosting
    module Feature; extend Dynamic::Feature

      module Message
      end

      DEPENDENCIES = ['Dynamic::RecipientInfo::Feature'].freeze

      MESSAGE_ATTRS_BY_NAME = {
        subject: {
          type: 'String',
          human_name_fr: 'Sujet',
          human_name_en: 'Subject',
        },
        text: {
          type: 'Text',
          human_name_fr: 'Texte',
          human_name_en: 'Text',
        },
        imap_id: {
          type: 'String',
          human_name_fr: 'IMAP',
          human_name_en: 'IMAP',
        },
        attachments: {
          type: 'String',
          human_name_fr: 'Pièce joints',
          human_name_en: 'Attachments',
        },
        sent_at: {
          type: 'DateTime',
          human_name_fr: 'Date',
          human_name_en: 'Date',
        }
      }.freeze

      MESSAGE_ASSOCS_BY_NAME = {
        sender: {
          type: 'BelongsTo',
          human_name_fr: 'De',
          human_name_en: 'From',
        },
        recipients: {
          type: 'HasMany',
          human_name_fr: 'Pour',
          human_name_en: 'To',
        },
        carbon_copy: {
          type: 'HasMany',
          human_name_fr: 'CC',
          human_name_en: 'CC',
        },
        blind_carbon_copy: {
          type: 'HasMany',
          human_name_fr: 'CCI',
          human_name_en: 'BCC',
        }
      }.freeze

      DEFAULT_EMAIL_ASSOCIATION_ATTRS = [
        {name: 'default_recipient', skip_sheet_tab_create: true, human_name_en: 'Default recipient', human_name_fr: 'Destinataire par défaut', type: 'HasMany'},
        {name: 'default_cc', skip_sheet_tab_create: true, human_name_en: 'Default cc', human_name_fr: 'Cc par défaut', type: 'HasMany'},
        {name: 'default_bcc', skip_sheet_tab_create: true, human_name_en: 'Default bcc', human_name_fr: 'Cci par défaut', type: 'HasMany'},
      ].freeze

      def self.feature_attributes
        {
          human_name_fr: 'Messagerie',
          human_name_en: 'Messaging',
          mandatory: false,
          enabled: false,
          options_attributes: [
            {
              name: 'associations_klasses',
              human_name_en: 'Classes with associations',
              human_name_fr: 'Classes avec associations',
              type: 'String',
              coder_type: 'Dynamic::Schema::Option::Coder::Klasses',
              value: ''
            },
          ],
          concerns_attributes: [
            {
              name: 'Message',
              human_name_fr: 'Message',
              human_name_en: 'Message',
              options_attributes: [
                {
                  name: 'subject_attribute',
                  human_name_fr: 'Attribut du sujet',
                  human_name_en: 'Subject attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: nil,
                  global: false,
                },
                {
                  name: 'imap_id_attribute',
                  human_name_fr: "Attribut de l'id IMAP",
                  human_name_en: 'IMAP id attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: nil,
                  global: false,
                },
                {
                  name: 'text_attribute',
                  human_name_fr: 'Attribut du contenu',
                  human_name_en: 'Content attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: nil,
                  global: false,
                },
                {
                  name: 'sent_at_attribute',
                  human_name_fr: 'Attribut du contenu',
                  human_name_en: 'Content attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: nil,
                  global: false,
                },
                {
                  name: 'attachments_attribute',
                  human_name_fr: 'Attribut de pièces jointes',
                  human_name_en: 'Attachments attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: nil,
                  global: false,
                },
                {
                  name: 'sender_association',
                  human_name_fr: "Association de l'émetteur",
                  human_name_en: 'Sender association',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: nil,
                  global: false,
                },
                {
                  name: 'recipients_association',
                  human_name_fr: 'Association des destinataire',
                  human_name_en: 'Recipients association',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: nil,
                  global: false,
                },
                {
                  name: 'carbon_copy_association',
                  human_name_fr: 'Association des copies carbones',
                  human_name_en: 'Carbon copy association',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: nil,
                  global: false,
                },
                {
                  name: 'blind_carbon_copy_association',
                  human_name_fr: 'Association des copies carbones invisible',
                  human_name_en: 'Blind carbon copy association',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: nil,
                  global: false,
                },
              ]
            },
          ]
        }
      end

      def self.load(schema)
        message_klass = schema.features.detect {|f| f.name == 'Dynamic::MailHosting::Feature'}.concerns.detect {|o| o.name == 'Message'}.klass
        klasses_associated_to_message = message_klass.associations_as_target.preload(:owner_klass).map{|a| a.owner_klass.const_absolute_name }
        schema.const.send(:define_singleton_method, 'klasses_associated_to_message') do
          return klasses_associated_to_message
        end

        Dynamic::MailHosting::Rule.mount(schema)
        Dynamic::MailHosting::Condition.mount(schema)
        Dynamic::MailHosting::SyncState.mount(schema)
      end

      def self.after_enabled(feature)
        DEPENDENCIES.each do |d|
          dependency = feature.schema.features.find_by!(name: d)
          unless feature.schema.feature_enabled?(d)
            feature.errors.add :enabled, :dependent, name: dependency.human_name
            raise ActiveRecord::RecordInvalid.new(feature)
          end
        end

        self.create_klasses(feature)
        self.add_default_association_sheet_tab(feature)
      end

      def self.after_disabled(feature)
        self.remove_default_association_sheet_tab(feature)
      end

      def self.create_klasses(feature)
        message_concern = feature.concerns.detect {|c| c.name == 'Message'}
        message_klass = message_concern.klass
        unique_email_klass = unique_email_schema_klass(feature)

        unless message_klass
          message_klass = feature.schema.klasses.create_with(
            name: 'MailHostingMessage',
            human_name_fr: 'Message (e-mail)',
            human_name_en: 'E-mail Message',
            icon: 'mail-bulk'
          ).find_or_create_by!(name: 'MailHostingMessage')
          message_concern.update!(klass: message_klass)
        end

        create_message_attributes(message_klass, message_concern)
        create_message_associations(message_klass, message_concern, unique_email_klass)
        create_default_associations(feature, message_klass, unique_email_klass)

        require_indexed_options = {only: [], include: {}}
        message_concern.options.each do |o|
          if o.name.end_with?('_attribute')
            require_indexed_options[:only] << o.value.name
          elsif o.name.end_with?('_association')
            # FIXME address and owner could be renamed by user
            require_indexed_options[:include][o.value.name] = {
              'only' => ['id', 'created_at', 'updated_at', 'type', 'deleted_at', 'address'],
              'include' => { 'owner' => {'only' => ['id', 'created_at', 'updated_at', 'type', 'deleted_at', 'polymorphic_name']}}
            }
          end
        end

        update_options_for_indexed_json(message_klass, require_indexed_options)

        if message_klass.schema.feature_enabled?('Dynamic::Elasticsearch::Feature')
          message_klass.elasticsearch_put_mapping
        end
      end

      def self.create_message_attributes(message_klass, message_concern)
        options_attrs = message_concern.options.select {|o| o.name.end_with?('_attribute')}
        options_attrs.each do |opt|
          next if opt.value
          attr_name = opt.name.gsub(/_attribute$/, '')
          attr = message_klass.attrs.create_with(MESSAGE_ATTRS_BY_NAME[attr_name.to_sym].merge(name: attr_name)).find_or_create_by!(name: attr_name)
          opt.update!(value: attr)
        end
      end

      def self.create_message_associations(message_klass, message_concern, unique_email_klass)
        options_assocs = message_concern.options.select {|o| o.name.end_with?('_association')}
        assoc_names = []
        options_assocs.each do |opt|
          next if opt.value
          assoc_name = opt.name.gsub(/_association$/, '')
          attrs = MESSAGE_ASSOCS_BY_NAME[assoc_name.to_sym]
          assoc_names << assoc_name unless assoc_name == 'sender'
          assoc = message_klass.associations.create_with(attrs.merge(target_klass: unique_email_klass)).find_or_create_by!(name: assoc_name)
          opt.update!(value: assoc)
        end

        receivers_assoc = message_klass.associations.create_with(
          type: 'HasMany',
          formula: "#{assoc_names.join(' + ')}",
          target_klass: unique_email_klass,
          human_name_fr: 'Récepteurs',
          human_name_en: 'Receivers',
        ).find_or_create_by!(name: 'receivers')

        messages_assoc = unique_email_klass.associations.create_with(
          human_name_en: 'Messages',
          human_name_fr: 'Messages',
          type: 'HasMany',
          target_klass: message_klass,
          inverse_of: receivers_assoc
        ).find_or_create_by!(name: 'messages')

        receivers_assoc.update!(inverse_of: messages_assoc)
      end

      def self.update_options_for_indexed_json(message_klass, required_options)
        options = message_klass.options_for_indexed_json
        options['only'] |= required_options[:only]
        options['include'] ||= {}

        required_options[:include].each do |k, v|
          if options['include'].has_key?(k)
            options['include'][k]['only'] |= v['only']
            options['include'][k]['include']['owner'] ||= {}
            options['include'][k]['include']['owner']['only'] |= v['include']['owner']['only']
          else
            options['include'][k] = v
          end
        end

        message_klass.update!(options_for_indexed_json: options)
      end

      def self.create_default_associations(feature, message_klass, unique_email_klass)
        associations_klasses = feature.options.detect{|o| o.name == 'associations_klasses'}.value
        email_klass = email_schema_klass(feature)

        associations_klasses&.each do |klass|
          DEFAULT_EMAIL_ASSOCIATION_ATTRS.each do |association_attrs|
            klass.associations.create_with(
              association_attrs.merge(target_klass: email_klass)
            ).find_or_create_by!(name: association_attrs[:name])
          end
          klass.associations.create_with(
            skip_sheet_tab_create: true,
            human_name_en: 'Message',
            human_name_fr: 'Message',
            type: 'HasMany',
            target_klass: message_klass
          ).find_or_create_by!(name: 'messages')
        end
      end

      def self.email_schema_klass(feature)
        communication_feature = feature.schema.features.find_by!(name: 'Dynamic::Communication::Feature') # Dependency of RecipientInfo
        return communication_feature.concerns.detect {|c| c.name == 'Email'}.klass
      end

      def self.unique_email_schema_klass(feature)
        recipient_feature = feature.schema.features.find_by!(name: 'Dynamic::RecipientInfo::Feature')
        email_address_concern = recipient_feature.concerns.find_by(name: 'EmailAddress')
        return email_address_concern.klass
      end

      def self.add_default_association_sheet_tab(feature)
        apply_to_associations_created_on_klasses(feature) do |association|
          if association_tab(feature.schema, association).count == 0
            association.update_default_layouts_create
          end
        end
      end

      def self.remove_default_association_sheet_tab(feature)
        apply_to_associations_created_on_klasses(feature) do |association|
          association.update_default_layouts_destroy
        end
      end

      def self.apply_to_associations_created_on_klasses(feature)
        message_klass = feature.concerns.detect{|c| c.name == 'Message'}.klass
        default_associations_mails_names = DEFAULT_EMAIL_ASSOCIATION_ATTRS.map{|a| a[:name]}
        assoc_klasses = feature.options.detect{|o| o.name == 'associations_klasses'}.value

        assoc_klasses&.each do |klass|
          query = klass.associations.where(name: default_associations_mails_names)

          if message_klass
            query = query.or(klass.associations.where(target_klass: message_klass))
          end

          query.each do |assoc|
            yield assoc
          end
        end
      end

      def self.association_tab(schema, association)
        subquery = Dynamic::Layout.with_action(:edit).where(
          schema_id: schema.id,
          klass_name: association.owner_klass.const_absolute_name,
          default: true
        )
        query = Dynamic::Layout::Element.joins(:layout).merge(subquery)
        query = query.where(component: 'Crm::Sheet::TabBar::Tab').where(["component_params::json->>'association_id'=?", association.id])
        return query
      end

    end
  end
end
