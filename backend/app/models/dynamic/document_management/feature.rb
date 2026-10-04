module Dynamic
  module DocumentManagement
    module Feature; extend Dynamic::Feature
      include Dynamic::Feature::Template

      TEMPLATE = {
        human_name_fr: 'Gestion électronique de document',
        human_name_en: 'Document management system',
        mandatory: false,
        visible: false, # TODO remove
        concern_templates_attributes: [
          {
            name: 'File',
            human_name_fr: 'Fichier',
            human_name_en: 'File',
            klass_template_id: '019c431e-6b68-7bdf-994a-4184021d9383',
          },
          {
            name: 'RegularFile',
            human_name_fr: 'Fichier régulier',
            human_name_en: 'Regular file',
            klass_template_id: '019c4322-0930-7082-a47a-afb1dbccc2d9',
          },
          {
            name: 'Directory',
            human_name_fr: 'Dossier',
            human_name_en: 'Folder',
            klass_template_id: '019c4322-7a78-77ce-b325-ce82a2c015c3',
          },
        ],
        klass_templates_attributes: [
          {
            :id => '019c431e-4070-7848-8c32-08e49de6e291',
            :human_name_fr => 'Mot-clé',
            :human_name_en => 'Keyword',
            :name => 'Keyword',
            :icon => 'file-word',
            :update_menu_items => false,
            :attrs_attributes => [
              {
                :id => '019c431e-f420-73c5-8a0c-8fe560a5d346',
                :human_name_fr => 'Texte',
                :human_name_en => 'Text',
                :name => 'text',
                :type => 'String',
              },
            ],
          },
          {
            :id => '019c431e-6b68-7bdf-994a-4184021d9383',
            :human_name_fr => 'Fichier',
            :human_name_en => 'File',
            :name => 'File',
            :icon => 'file',
            :name_attribute_id => '019c431f-1748-79ff-b825-01826d0f4855',
            :photo_attachment_id => '019c431f-2eb8-7f7b-b973-8b432a01f61f',
            :attrs_attributes => [
              {
                :id => '019c431f-1748-79ff-b825-01826d0f4855',
                :human_name_fr => 'Nom',
                :human_name_en => 'Name',
                :name => 'name',
                :type => 'String',
              },
            ],
            :attachments_attributes => [
              {
                :id => '019c431f-2eb8-7f7b-b973-8b432a01f61f',
                :human_name_fr => 'Miniature',
                :human_name_en => 'Preview',
                :name => 'preview',
                :type => 'HasOne',
              },
            ],
            :associations_attributes => [
              {
                :id => '019c4321-8460-7dd7-bfea-640d2bfc4e5a',
                :human_name_fr => 'Dossier',
                :human_name_en => 'Folder',
                :name => 'directory',
                :target_klass_id => '019c4322-7a78-77ce-b325-ce82a2c015c3',
                :type => 'BelongsTo',
              },
              {
                :id => '019c4321-9fb8-765d-a858-6d85bc1c8229',
                :human_name_fr => 'Fichiers',
                :human_name_en => 'Files',
                :name => 'files',
                :target_klass_id => '019c431e-6b68-7bdf-994a-4184021d9383',
                :type => 'HasMany',
              },
              {
                :id => '019c9a72-f4d8-72d2-b7f0-207a0c89be7b',
                :human_name_fr => 'Propriétaire',
                :human_name_en => 'Owner',
                :name => 'owner',
                :target_klass_id => '019c9a7f-06b0-70d6-b4e2-b04383b048b8',
                :type => 'BelongsTo',
              },
              {
                :id => '019c4321-e9f0-76a8-a844-42c3e156aec8',
                :human_name_fr => 'Mots-clés',
                :human_name_en => 'Keywords',
                :target_klass_id => '019c431e-4070-7848-8c32-08e49de6e291',
                :name => 'keywords',
                :type => 'HasMany',
              },
            ],
          },
          {
            :id => '019c4322-0930-7082-a47a-afb1dbccc2d9',
            :human_name_fr => 'Fichier régulier',
            :human_name_en => 'Regular File',
            :plural_human_name_fr => 'Fichiers réguliers',
            :plural_human_name_en => 'Regular files',
            :superklass_id => '019c431e-6b68-7bdf-994a-4184021d9383',
            :name => 'RegularFile',
            :icon => 'file',
            :update_menu_items => false,
            :name_attribute_id => '019c431f-1748-79ff-b825-01826d0f4855',
            :photo_attachment_id => '019c431f-2eb8-7f7b-b973-8b432a01f61f',
            :attrs_attributes => [
              {
                :id => '019c4322-47b0-786e-b714-1bdf0beda7b6',
                :human_name_fr => 'Titre',
                :human_name_en => 'Title',
                :name => 'title',
                :type => 'String',
              },
              {
                :id => '019c4322-5f20-7f1a-8545-e40e1a7b5b9a',
                :human_name_fr => 'Description',
                :human_name_en => 'Description',
                :name => 'description',
                :type => 'Text',
              },
            ],
            :associations_attributes => [
              {
                :id => '019c9a70-58e0-7d76-b5a6-a5b7899bd56e',
                :human_name_fr => 'Auteurs',
                :human_name_en => 'Author',
                :target_klass_id => '019c9a7f-06b0-70d6-b4e2-b04383b048b8',
                :name => 'authors',
                :type => 'HasMany',
              },
            ],
            :attachments_attributes => [
              {
                :id => '019c4321-6908-7595-b120-4f31fa3fcc78',
                :human_name_fr => 'Fichier',
                :human_name_en => 'File',
                :name => 'asset',
                :type => 'HasOne',
              },
            ],
          },
          {
            :id => '019c4322-7a78-77ce-b325-ce82a2c015c3',
            :human_name_fr => 'Dossier',
            :human_name_en => 'Folder',
            :name => 'Directory',
            :superklass_id => '019c431e-6b68-7bdf-994a-4184021d9383',
            :icon => 'folder',
            :update_menu_items => false,
            :name_attribute_id => '019c431f-1748-79ff-b825-01826d0f4855',
            :photo_attachment_id => '019c431f-2eb8-7f7b-b973-8b432a01f61f',
          },
        ],
        dependent_klasses: {
          '019c9a7f-06b0-70d6-b4e2-b04383b048b8' => 'Contact',
        },
      }.deep_freeze

    end
  end
end
