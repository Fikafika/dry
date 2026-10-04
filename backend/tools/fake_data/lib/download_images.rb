def download_logos
  return if  File.directory?('tmp/logos')
  puts "download logos"

  require 'open-uri'

  FileUtils.mkdir_p('tmp/logos')

  13.times do |i|
    File.open("tmp/logos/#{i + 1}.png", "wb") do |saved_file|
      URI.open("https://pigment.github.io/fake-logos/logos/medium/color/#{i + 1}.png", "rb") do |read_file|
        saved_file.write(read_file.read)
      end
    end
  end
end

def clean_logos
  FileUtils.rm_r('tmp/logos')
end

def fake_logo
  {io: File.open("tmp/logos/#{rand(1..13)}.png"), filename: 'logo.png'}
end

# --------------------------------------------------------------------

def download_avatars(count = 50)
  return if File.directory?('tmp/avatars')

  puts "download avatars"

  require 'open-uri'
  require 'faker'

  FileUtils.mkdir_p('tmp/avatars')

  error_count = 0
  count.times do |i|
    File.open("tmp/avatars/#{i + 1}.png", "wb") do |saved_file|
      a = Faker::Avatar.image
      begin
        URI.open(a, "rb") do |read_file|
          saved_file.write(read_file.read)
        end
      rescue OpenURI::HTTPError => e
        puts e.message
        a = Faker::Avatar.image
        error_count += 1
        retry if error_count <= 10
      end
    end
  end
end

def clean_avatars
  FileUtils.rm_r('tmp/avatars')
end

def fake_avatar(count = 50)
  {io: File.open("tmp/avatars/#{rand(1..count)}.png"), filename: 'avatar.png'}
end
