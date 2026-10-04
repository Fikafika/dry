=begin
while true
  ::UneekSsoClient.sync_all!
  break if Community.count > 0
  puts "waiting for uneek_sso seeds"
  sleep 5
end

load '/backend/tools/fake_data/uneek/create_schema.rb'
load '/backend/tools/fake_data/uneek/create_fake_data.rb'
=end
