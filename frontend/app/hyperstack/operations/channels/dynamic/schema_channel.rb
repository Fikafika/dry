return unless RUBY_ENGINE == 'opal'

r = Dynamic::Schema.includes(Dynamic::Schema.includes_for_load)
r.__cable__.subscribe(user_id: nil) do |data, options|
  Dynamic::Schema.stale_all_records(data) if data
end
