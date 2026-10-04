namespace :deploy do

  desc "check if application properly eager load hyperstack models"
  task :check_eager_load => :environment do
    Rails.application.eager_load!
  end

end
