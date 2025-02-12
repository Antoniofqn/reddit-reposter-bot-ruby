require 'x'
require 'x/media_uploader'
require 'pry'
require 'dotenv'

Dotenv.load

class TwitterPosterService
  def initialize
    @api_key = ENV['TWITTER_API_KEY']
    @api_key_secret = ENV['TWITTER_API_SECRET']
    @access_token = ENV['TWITTER_USER_ACCESS_TOKEN']
    @access_token_secret = ENV['TWITTER_USER_ACCESS_TOKEN_SECRET']
  end

  def login
    X::Client.new(
      api_key: @api_key,
      api_key_secret: @api_key_secret,
      access_token: @access_token,
      access_token_secret: @access_token_secret
    )
  end

  def post_image
    client = login

    file_paths = get_file_paths

    media_ids = file_paths.map do |file_path|
      media = X::MediaUploader.upload(
        client:,
        file_path:,
        media_category: 'tweet_image'
      )
      media['id']
    end

    tweet_body = {
      text: 'AITAH?',
      media: { media_ids: }
    }

    client.post('tweets', tweet_body.to_json)
  end

  def me
    x_client = login
    x_client.get('users/me')
  end

  def get_file_paths
    Dir.glob("#{Dir.pwd}/tmp/*.png")
  end
end
