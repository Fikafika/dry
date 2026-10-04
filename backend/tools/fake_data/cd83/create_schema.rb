#!/usr/local/bin/ruby

require File.expand_path('../../../config/environment', __dir__)

@schema = ::Dynamic::Schema.where(name: 'Cd83').first

if @schema.nil?
  begin
    ::UneekSsoClient.sync_all!
  rescue
    raise 'Sso must be started and a first authentication must have been made before running this script'
  end
  Dynamic::Schema.loaded_schemas.values.map(&:unload) # TODO when loaded too soon it crashes in form creation. how this can be fixed properly ?
  @schema = ::Dynamic::Schema.where(name: 'Cd83').first

  raise 'a community for Cd83 must be created in sso' unless @schema
end

puts 'create schema'

@schema.update(JSON.parse(File.read(File.expand_path('./cd83.json', __dir__))))

puts 'finished'
