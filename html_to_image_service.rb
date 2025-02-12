require 'grover'
require 'erb'
require 'fileutils'

class HtmlToImageService
  def initialize(post_title:, post_text:)
    @post_title = sanitize_encoding(post_title)
    @post_text  = sanitize_encoding(post_text)
  end

  def generate_image
    # 1. Build the HTML from a template or inline
    html = render_template

    # 2. Use Grover to render PDF or image
    grover = Grover.new(html, **{
                          full_page: true, # capture the entire rendered content
                          viewport: {
                            width: 600, # make it narrower if you want, e.g. 600 px
                            height: 1 # minimal height so Puppeteer expands as needed
                          },
                          scale: 1
                          # omit :format so it doesn't force A4 or letter
                        })
    screenshot = grover.to_png

    # 3. Save the screenshot to a file
    file_path = File.join(Dir.pwd, 'tmp', "post-#{Time.now.to_i}.png")
    File.binwrite(file_path, screenshot)
    file_path
  end

  private

  def sanitize_encoding(text)
    text.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')
  end

  def render_template
    template = <<~ERB
           <html>
        <head>
          <meta charset="UTF-8">
          <style>
            html, body {
              margin: 0;
              padding: 0;
            }

            .post-container {
              /* If you want a border or padding, do it here */
              border: 1px solid #ddd;
              padding: 20px;
              max-width: 600px;       /* so lines don't stretch too wide */
              margin: 0 auto;         /* center horizontally */
              box-sizing: border-box;
            }
            .title {
              font-weight: bold;
              font-size: 18px;
              margin-bottom: 10px;
            }
            .content {
              font-size: 14px;
              white-space: pre-wrap;
            }
          </style>
        </head>
        <body>
          <div class="post-container">
            <div class="title"><%= @post_title %></div>
            <div class="content"><%= @post_text %></div>
          </div>
        </body>
      </html>

    ERB

    ERB.new(template).result(binding)
  end
end
