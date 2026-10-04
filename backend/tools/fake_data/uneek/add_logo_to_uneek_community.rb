# Ce code est a executer dans docker compose sso exec ./bin/rails c

FileUtils.mkdir_p('tmp/logos')

unless File.exist?("tmp/logos/uneek.jpeg")
  require 'open-uri'

  File.open("tmp/logos/uneek.jpeg", "wb") do |saved_file|
    URI.open("https://uneek.kosmopolead.com/system/communities/logos/4/full_cartouche_uneek.jpg", "rb") do |read_file|
      saved_file.write(read_file.read)
    end
  end
end

@uneek = Community.find_by_permalink('uneek')

@uneek.update(
  logo:  {io: File.open("tmp/logos/uneek.jpeg"), filename: 'uneek.jpeg'}
)
