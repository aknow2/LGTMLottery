# frozen_string_literal: true

require 'octokit'
require 'json'

token = ENV['GITHUB_TOKEN']
pattern = ENV['PATTERN']

class ImageLottery
  def initialize(path)
    @images = load_json(path)
  end

  def hit
    @images.sample
  end

  private

  def load_json(path)
    File.open(path) do |file|
      JSON.parse(file.read)
    end
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

def create_comment(image)
  "![image](#{image['image_url']})\r\n  #{image['credit']}\r\n  creator: [#{image['creator']}](#{image['link_to_creator']})"
end

if __FILE__ == $PROGRAM_NAME

  event = ActionsEvent.new(event_loader: -> { event_data_from_file })
  validator = CommentPatternValidator.new(pattern_str: pattern, action_event: event)

  if validator.should_post_image?
    lottery = ImageLottery.new('./images.json')

    image = lottery.hit
    comment = create_comment(image)

    client = Octokit::Client.new(access_token: token)
    repo = event.repository
    item_number = event.pr_or_issue_number
    client.add_comment(repo, item_number, comment)
  end
end
