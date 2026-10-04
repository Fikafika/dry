class HideMessageTabOnMailHostingState < ActiveRecord::Migration[6.0]
  def up
    Dynamic::Schema.find_each do |schema|
      mail_hosting_feature = schema.features.find_by(name: 'Dynamic::MailHosting::Feature')
      next unless mail_hosting_feature

      if mail_hosting_feature.enabled?
        message_klass = mail_hosting_feature.options.detect{|o| o.name == "message_klass"}.value

        next unless message_klass

        Dynamic::MailHosting::Feature.create_default_associations(mail_hosting_feature)

        Dynamic::MailHosting::Feature.add_default_association_sheet_tab(mail_hosting_feature)
      else
        Dynamic::MailHosting::Feature.remove_default_association_sheet_tab(mail_hosting_feature)
      end

    end
  end

  def down
    Dynamic::Schema.find_each do |schema|
      mail_hosting_feature = schema.features.find_by(name: 'Dynamic::MailHosting::Feature')
      next unless mail_hosting_feature

      # readd tab if it is removed on disabled feature only
      Dynamic::MailHosting::Feature.add_default_association_sheet_tab(mail_hosting_feature) unless mail_hosting_feature.enabled?
    end
  end
end
