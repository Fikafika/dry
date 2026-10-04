#!/usr/local/bin/ruby

require File.expand_path('../../../config/environment', __dir__)

@schema = Dynamic::Schema.where(name: 'Uneek').first

if @schema.nil?
  ::UneekSsoClient.sync_all!
  @schema = ::Dynamic::Schema.where(name: 'Uneek').first
end

puts "warning: theme_compiler must be started !!"

dir = File.join(Rails.root, 'tools', 'bootswatch')
themes = Dir.entries(dir).select{|f| !f.start_with?('.') && File.directory?(File.join(dir, f)) }

themes.each do |theme|
  @schema.themes.create(
    human_name: theme.titleize,
    variables: ActiveStorage::Blob.create_and_upload!(
      io: File.open(File.join(dir, theme, '_variables.scss')),
      filename: '_variables.scss',
      content_type: 'text/x-scss',
    ),
    custom: ActiveStorage::Blob.create_and_upload!(
      io: File.open(File.join(dir, theme, '_bootswatch.scss')),
      filename: '_bootswatch.scss',
      content_type: 'text/x-scss',
    )
  )
end

puts "finished"
