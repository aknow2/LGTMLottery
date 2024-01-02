# frozen_string_literal: true

require 'octokit'
require 'json'

token = ENV['GITHUB_TOKEN']
pattern = ENV['PATTERN']

class ImageLottery
  def initialize(path)
    @images = only_jpg_files(path)
  end

  def hit
    "https://raw.githubusercontent.com/aknow2/LGTMLottery/main/#{@images.sample}"
  end

  private

  def only_jpg_files(path)
    Dir.glob("#{path}/**/*").select { |file| File.file?(file) && file.downcase.end_with?('.jpg') }
  end
end

class ActionsEvent
  def initialize(event_loader: -> { {} })
    @event_data = event_loader.call
  end

  def pr_or_issue_number
    if @event_data['issue']
      @event_data['issue']['number']
    elsif @event_data['pull_request']
      @event_data['pull_request']['number']
    end
  end

  def comment_body
    comment = @event_data['comment']
    comment['body'] if comment
  end

  def repository
    repository = @event_data['repository']
    repository['full_name'] if repository
  end
end

def event_data_from_file
  event_path = ENV['GITHUB_EVENT_PATH']
  JSON.parse(File.read(event_path))
end

class CommentPatternValidator
  def initialize(pattern_str: String, action_event: ActionsEvent)
    @pattern = Regexp.new(pattern_str)
    @action_event = action_event
  end

  def should_post_image?
    comment_body = @action_event.comment_body
    has_number = !@action_event.pr_or_issue_number.nil?
    comment_body&.match(@pattern) && has_number
  end
end

if __FILE__ == $PROGRAM_NAME
  event = ActionsEvent.new(event_loader: -> { event_data_from_file })
  validator = CommentPatternValidator.new(pattern_str: pattern, action_event: event)

  if validator.should_post_image?
    client = Octokit::Client.new(access_token: token)
    lottery = ImageLottery.new('images')

    repo = event.repository
    item_number = event.pr_or_issue_number
    client.add_comment(repo, item_number, "![image](#{lottery.hit})")
  end
end
