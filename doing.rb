=begin
Plugin: doing yesterday logger
Version: 0.1
Description: Logs output for doing yesterday --totals
Author: [soleblaze](https://github.com/soleblaze)
Configuration:
  doing_tags: #doing
Notes:
=end

config = {
  'description' => ['doing plugin',
                    'Adds doing yesterday to dayone' ],
  'doing_tags' => '#doing'
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

    tags = config['doing_tags'] || ''
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
    unless output.nil? or output == "\n\n"
      sl = DayOne.new
      sl.to_dayone(options)
    end

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
