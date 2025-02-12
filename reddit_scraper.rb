require_relative './html_to_image_service'
require 'reddit_get'

class RedditScrapper
  MAX_CHARS_PER_IMAGE = 2400
  MAX_IMAGES          = 3

  def initialize
    @subreddit = 'AITAH'
  end

  def prepare_posts
    results = collect_posts
    results.each do |post|
      chunks = generate_chunks(post)
      next if chunks.empty?
      images = generate_image_from_chunks(post, chunks)
      break
    end
  end

  # Can be called on its own in case image creation is not needed
  def collect_posts
    clean_tmp_dir
    result = RedditGet::Subreddit.collect(@subreddit)
    result[@subreddit].delete_at(0) # delete pinned post. Add more if needed
    result[@subreddit]
  end

  private

  def generate_chunks(post)
    binding.pry
    text = post['selftext'].to_s.strip
    chunks = chunk_preserving_paragraphs(text, MAX_CHARS_PER_IMAGE)
    if chunks.size > MAX_IMAGES
      puts "Post is too long (needs #{chunks.size} images). Skipping..."
      return []
    end
    chunks
  end

  def generate_image_from_chunks(post, chunks)
    chunks.each_with_index do |chunk, idx|
      title = chunks.size > 1 ? "#{post['title']} (Part #{idx + 1})" : post['title']
      HtmlToImageService.new(
        post_title: title,
        post_text: chunk
      ).generate_image
    end
  end

  def chunk_preserving_paragraphs(full_text, max_chars)
    return [] if full_text.empty?

    paragraphs = full_text.split(/\n{2,}/).map(&:strip).reject(&:empty?)
    chunks = []
    current = ''

    paragraphs.each do |para|
      if para.size > max_chars
        chunks << current unless current.empty?
        current = ''
        big_para_subchunks = chunk_paragraph_by_words(para, max_chars)
        chunks.concat(big_para_subchunks)
      else
        candidate = current.empty? ? para : (current + "\n\n" + para)
        if candidate.size <= max_chars
          current = candidate
        else
          chunks << current unless current.empty?
          current = para
        end
      end
    end

    chunks << current unless current.empty?
    chunks
  end

  def chunk_paragraph_by_words(paragraph, max_chars)
    words = paragraph.split(/\s+/)
    subchunks = []
    current_sub = ''

    words.each do |w|
      if (current_sub + ' ' + w).strip.size > max_chars
        subchunks << current_sub
        current_sub = w
      else
        current_sub = current_sub.empty? ? w : "#{current_sub} #{w}"
      end
    end
    subchunks << current_sub unless current_sub.empty?
    subchunks
  end

  def clean_tmp_dir
    FileUtils.rm_rf(Dir.glob('tmp/*'))
    FileUtils.mkdir_p('tmp')
  end
end
