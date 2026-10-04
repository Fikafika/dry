#!/usr/local/bin/ruby

require File.expand_path('../../../config/environment', __dir__)

@schema = Dynamic::Schema.where(name: 'Uneek').first

if @schema.nil?
  ::UneekSsoClient.sync_all!
  @schema = ::Dynamic::Schema.where(name: 'Uneek').first
end

@Contact = @schema.klasses.where(name: 'Contact').first
@Account = @schema.klasses.where(name: 'Account').first

@schema.load

require 'faker'
require File.expand_path('../lib/download_images', __dir__)
require 'progress_bar'

Faker::Config.locale = 'fr'

download_logos
download_avatars


def fake_emails_attributes
  [
    {
      address: Faker::Internet.email,
      tag: 'Home',
    }
  ]
end

def fake_phones_attributes
  [
    {
      number: Faker::PhoneNumber.phone_number,
    }
  ]
end

def fake_addresses_attributes
  [
    {
      street: Faker::Address.street_address,
      second_street: Faker::Address.secondary_address,
      delivery_mention: Faker::Address.mail_box,
      zip_code: Faker::Address.zip_code,
      city: Faker::Address.city,
      country: Faker::Address.country,
      latitude: Faker::Address.latitude,
      longitude: Faker::Address.longitude,
    }
  ]
end

puts "create accounts" # ----------------------------------------------------------

@count = ARGV[0] ? ARGV[0].to_i : 1000

@account_count = @count

bar = ProgressBar.new(@account_count)

::ModelDependency.with_dependencies_computed_later do

  @account_count.times do
    @account = D::Uneek::Account.create!(
      name: Faker::Company.name,
      logo: fake_logo,
    )

    @account.emails.create!(fake_emails_attributes)
    @account.phones.create!(fake_phones_attributes)
    @account.addresses.create!(fake_addresses_attributes)

    bar.increment!
  end

end

puts "create contacts" # ----------------------------------------------------------

@contact_count = @count

bar = ProgressBar.new(@contact_count)

::ModelDependency.with_dependencies_computed_later do

  @contact_count.times do

    gender = rand(0..1) == 0 ? 'Female' : 'Male'

    @contact = D::Uneek::Contact.create!(
      first_name: Faker::Name.send("#{gender.underscore}_first_name"),
      last_name: Faker::Name.last_name,
      gender: gender,
      civility: gender == 'Male' ? 'Mr.' : 'Mrs.',
      photo: fake_avatar,
      company: D::Uneek::Account.limit(1).order("RANDOM()").first,
    )
    @contact.emails.create!(fake_emails_attributes)
    @contact.phones.create!(fake_phones_attributes)
    @contact.addresses.create!(fake_addresses_attributes)

    bar.increment!
  end

end

ModelDependency::GroupingWorker.new.perform

puts "finished"
