require_relative './reddit_scraper'
require_relative './twitter_poster_service'

RedditScrapper.new.collect_posts
TwitterPosterService.new.post_image
