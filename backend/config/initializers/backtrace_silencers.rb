# Be sure to restart your server when you modify this file.

# You can add backtrace silencers for libraries that you're using but don't wish to see in your backtraces.
# Rails.backtrace_cleaner.add_silencer { |line| line =~ /my_noisy_library/ }

# You can also remove all the silencers if you're trying to debug a problem that might stem from framework code.

return unless Rails.logger.debug? || ENV["BACKTRACE"]

Rails.backtrace_cleaner.remove_filters!
Rails.backtrace_cleaner.remove_silencers!

app_dirs_pattern = /\A#{Rails.root}\/?(app|config|lib|test|\(\w*\))/.freeze
bundle_path = Bundler.bundle_path.to_s.freeze
bundle_bundler_gems_path = "#{bundle_path}/bundler/gems".freeze
bundle_gems_path_prefix = "#{bundle_path}/gems/".freeze
authorized_gems = [
  'devise',
  'warden',
  'activerecord-session_store',
  'dynamic_record',
  'as_deep_json',
  'dynamic-form',
  'dynamic-layout',
  'dynamic-elasticsearch',
  'dynamic-datatable',
  'dynamic-cascade',
  'dynamic-import',
  'dynamic-builder',
  'model_dependency',
  'dynamic-formula',
  'uneek-formula',
  'dynamic-workflow',
  'document_converter',
  'dynamic-doc_gen',
  'elasticsearch-rails-utils',
  'sidekiq-batch-join',
  'app_path_prefix',
  'activerecord-through_polymorphic',
  'activerecord-uuid_support',
  'dynamic-naming',
  'uneek_permission',
].map(&:freeze).freeze

Rails.backtrace_cleaner.add_silencer do |line|
  !line.start_with?(bundle_bundler_gems_path) && \
  line !~ app_dirs_pattern && \
  authorized_gems.none?{|g| line.start_with?(g) || line.start_with?("#{bundle_gems_path_prefix}#{g}")}
end
