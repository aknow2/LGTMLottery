require 'octokit'
require 'json'

token = ENV['GITHUB_TOKEN']
pattern = ENV['PATTERN']


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

class ActionsEvent

    def initialize(event_loader: lambda)
      @event_data = event_loader.call
    end

    def get_pr_or_issue_number
      if @event_data['issue']
        @event_data['issue']['number']
      elsif @event_data['pull_request']
        @event_data['pull_request']['number']
      end
    end

    def get_comment_body
      comment = @event_data['comment']
      comment['body'] if comment
    end

    def get_repository
      repository = @event_data['repository']
      repository['full_name'] if repository
    end

end

def get_event_data_from_file
  event_path = ENV['GITHUB_EVENT_PATH']
  JSON.parse(File.read(event_path))
end

class CommentPatternValidator

  def initialize(pattern_str: String, action_event: ActionsEvent)
    @pattern = Regexp.new(pattern_str)
    @action_event = action_event
  end

  def should_post_image?
    comment_body = @action_event.get_comment_body
    comment_body && comment_body.match(@pattern)
  end

end

if __FILE__ == $0
  event = ActionsEvent.new(lambda { get_event_data_from_file })
  validator = CommentPatternValidator.new(pattern, event)

  if validator.should_post_image?
    client = Octokit::Client.new(access_token: token)
    lottery = ImageLottery.new('images')

    image = lottery.hit
    client.add_comment(repo, item_number, '![image](#{lottery.hit})')
  end
end
