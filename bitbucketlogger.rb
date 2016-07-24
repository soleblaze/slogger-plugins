=begin
Plugin: Bitbucket Logger
Version: 1.0
Description: Uses bitbucket RSS feed to log activity.
Author: [Soleblaze](http://github.com/soleblaze)
Configuration:
  feeds: [ "feed url 1" , "feed url 2", ... ]
  tags: "#social #coding"
Notes:
  - rss_feeds is an array of feeds separated by commas, a single feed is fine, but it should be inside of brackets `[]`
  - rss_tags are tags you want to add to every entry, e.g. "#social #coding"
=end

config = {
  'description' => ['Logs Bitbucket Activity',
                    'feeds is an array of bitbucket feeds separated by commas, a single feed is fine, but it should be inside of brackets `[]`',
                    'tags are tags you want to add to every entry, e.g. "#social #coding"'],
  'feeds' => [],
  'tags' => '#social #coding'
}
$slog.register_plugin({ 'class' => 'BitBucketLogger', 'config' => config })

class BitBucketLogger < Slogger
  def do_log
    feeds = []
    if @config.key?(self.class.name)
      @rssconfig = @config[self.class.name]
      if !@rssconfig.key?('feeds') || @rssconfig['feeds'] == [] || @rssconfig['feeds'].nil?
        @log.warn("RSS feeds have not been configured or a feed is invalid, please edit your slogger_config file.")
        return
      else
        feeds = @rssconfig['feeds']
      end
    else
      @log.warn("RSS2 feeds have not been configured or a feed is invalid, please edit your slogger_config file.")
      return
    end
    @log.info("Logging rss posts for feeds #{feeds.join(', ')}")

    feeds.each do |rss_feed|
      retries = 0
      success = false
      until success
        if parse_feed(rss_feed)
          success = true
        else
          break if $options[:max_retries] == retries
          retries += 1
          @log.error("Error parsing #{rss_feed}, retrying (#{retries}/#{$options[:max_retries]})")
          sleep 2
        end
      end

      unless success
        @log.fatal("Could not parse feed #{rss_feed}")
      end
    end
  end

  def parse_feed(rss_feed)
    tags = @rssconfig['tags'] || ''
    tags = "\n\n(#{tags})\n" unless tags == ''

    today = @timespan
    begin

      rss_content = ''
      url = URI.parse(rss_feed)
      open(url) do |f|
        rss_content = f.read

        rss = RSS::Parser.parse(rss_content, false)
        feed_items = []
        rss.items.each do |item|
          rss_date = item.date || item.updated
          item_date = Time.parse(rss_date.to_s) + Time.now.gmt_offset
          if item_date > today
            title = item.title
            feed_items.push '* ' + title.lstrip
            desc = item.description
            desc.each_line do |line|
              next unless line[/<li>/]
              commit = line.gsub!(/(<[^>]*>)|\n|\t/s) { ' ' }.lstrip
              feed_items.push '    * ' + commit.split[2..-1].join(' ')
            end
            feed_items.push ''
          else
            break
          end
        end
        if feed_items.length > 0
          options = {}
          options['content'] = "## Bitbucket activity for #{Time.now.strftime(@date_format)}:\n\n#{feed_items.join("\n")}\n#{tags}"
          sl = DayOne.new
          sl.to_dayone(options)
        end
      end
      return true
    end
  end
end
