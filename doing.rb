=begin
Plugin: My New Logger
Description: Brief description (one line)
Author: [My Name](My URL)
Configuration:
  option_1_name: [ "example_value1" , "example_value2", ... ]
  option_2_name: example_value
Notes:
  - multi-line notes with additional description and information (optional)
=end

config = {
  'description' => ['doing plugin',
                    'Adds doing yesterday to dayone' ],
  'tags' => '#doing'
}
$slog.register_plugin({ 'class' => 'DoingLogger', 'config' => config })

class DoingLogger < Slogger
  def do_log
    if @config.key?(self.class.name)
      config = @config[self.class.name]
    else
       @log.warn("Doing has not been configured.")
       return
    end
    @log.info("Logging doing time tracking for yesterday")

    tags = config['tags'] || ''
    tags = "\n\n#{tags}\n" unless @tags == ''
    output = %x{doing yesterday --totals}

    # Perform necessary functions to retrieve posts

    # create an options array to pass to 'to_dayone'
    # all options have default fallbacks, so you only need to create the options
    # you want to specify
    options = {}
    options['content'] = "## Doing Yesterday\n\n#{output}#{tags}"
    options['datestamp'] = Time.now.utc.iso8601
    options['starred'] = true
    options['uuid'] = %x{uuidgen}.gsub(/-/,'').strip

    # Create a journal entry
    # to_dayone accepts all of the above options as a hash
    # generates an entry base on the datestamp key or defaults to "now"
    sl = DayOne.new
    sl.to_dayone(options)

    # To create an image entry, use `sl.to_dayone(options) if
    # sl.save_image(imageurl,options['uuid'])`
    # save_image takes an image path and a uuid that must be identical the one
    # passed to to_dayone
    # save_image returns false if there's an error

  end

  def helper_function(args)
    # add helper functions within the class to handle repetitive tasks
  end
end
