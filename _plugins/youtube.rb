# Copyright (c) 2014-2016 Tarun jangra
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the 'Software'), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so. The Software doesn't include files with .md extension.
# That files you are not allowed to copy, distribute, modify, publish, or sell.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'net/http'
require 'uri'

module Yegor
  class YoutubeBlock < Liquid::Tag
    def initialize(tag, markup, tokens)
      super
      opts = markup.strip.split(/\s+/, 2)
      @id = opts[0].strip
      @flags = opts[1].strip unless opts[1].nil?
    end

    def render(context)
      "<iframe class='video #{@flags unless @flags.nil?}'" \
      " src='https://www.youtube.com/embed/#{@id}?controls=2' allowfullscreen='true'></iframe>\n\n"
    end
  end

  module Youtube
    def youtube(list)
      key = ENV['YOUTUBE_API_KEY'] # configured in .travis.yml
      return if key.nil?
      '<div class="youtube"><ul>' +
      list.map do |id|
        uri = URI.parse("https://www.googleapis.com/youtube/v3/videos?id=#{id}&part=snippet,statistics&key=#{key}")
        json = JSON.parse(Net::HTTP.get(uri))
        item = json['items'][0]
        snippet = item['snippet']
        "<li><a href='https://www.youtube.com/watch?v=#{id}'>" \
          "<img src='#{snippet['thumbnails']['medium']['url']}'/></a>" \
          "#{snippet['title']}; " \
          "#{Time.parse(snippet['publishedAt']).strftime('%-d %B %Y')}; " \
          "#{item['statistics']['viewCount']} views; #{item['statistics']['likeCount']} likes" \
          "</li>"
      end.join('') +
      '</ul></div>'
    end
  end
end

Liquid::Template.register_filter(Yegor::Youtube)
Liquid::Template.register_tag('youtube', Yegor::YoutubeBlock)
