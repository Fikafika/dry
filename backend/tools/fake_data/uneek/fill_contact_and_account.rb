#!/usr/local/bin/ruby

require File.expand_path('../../../config/environment', __dir__)

::UneekSsoClient.sync_all!
@schema = Dynamic::Schema.where(name: 'Uneek').first


@schema.load

# create one account:
D::Uneek::Account.create(name: 'Carrot Corp')

# create 500 contacts:
def contact_attr(i)
    hash = {
        first_name: "toto_#{i}",
        last_name: "le lapinou_#{i}",
        address: "#{i}, rue des carottes",
        email: "toto_#{i}.le_lapinou@plusdecarottes.fr",
        zip_code: "44#{i}",
    }
    return hash
end

@contact = D::Uneek::Contact

i = 0
max = 500
while i < max  do
    @contact.create(contact_attr(i))
    i +=1
end


puts "finished"
