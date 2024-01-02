require 'octokit'

token = ENV['GITHUB_TOKEN']
repo = ENV['GITHUB_REPOSITORY']
item_number = ENV['ITEM_NUMBER']


class ImageLottery

  def initialize(path)
    @images = get_only_jpg_files(path)
  end

  private def get_only_jpg_files(path)
    new_jpg_images = []
    files = Dir.entries(path).reject { |f| f== '.' || f == '..'}
    files.each do |file|
      full_path = File.join(path, file)
      if File.directory?(full_path)
        new_jpg_images += get_only_jpg_files(full_path)
      else
        new_jpg_images << full_path if full_path.include?(".jpg")
      end
    end
    new_jpg_images
  end

  def hit
    path = 'https://raw.githubusercontent.com/aknow2/LGTMLottery/main/' + @images.shuffle.first
    return path
  end

end

if __FILE__ == $0
  event_path = ENV['GITHUB_EVENT_PATH']
  event_data = JSON.parse(File.read(event_path))

  puts "Event Data:"
  puts JSON.pretty_generate(event_data)
  client = Octokit::Client.new(access_token: token)
  lottery = ImageLottery.new("images")

  image = lottery.hit
  client.add_comment(repo, item_number, "![image](#{lottery.hit})")
end
