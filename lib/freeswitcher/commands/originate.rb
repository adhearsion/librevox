
module FreeSwitcher
  module Commands
    class Originate
      attr_accessor :originator, :target, :application, :application_arguments
      attr_reader :fs_socket, :target_options, :application_options

      def initialize(fs_socket, args = {})
        # These are options that will precede the target address
        @target_options = args[:target_options] || {:ignore_early_media => true}
        raise "#{@target_options} must be a hash" unless @target_options.kind_of?(Hash)
        
        @fs_socket = fs_socket # This socket must support say and <<
        @target = args[:target] # The target address to call
        # The origination extension
        @originator = args[:originator]

        # or application to attach the target caller to, and arguments for the application
        @application = args[:application]
        @application_arguments = args[:application_arguments]

        # These are options that will precede the application as modifiers
        @application_options = args[:application_options] || {}
        raise "#{@application_options} must be a hash" unless @application_options.kind_of?(Hash)
        
        @target_options[:origination_caller_id_number] = args[:caller_id_number] || FreeSwitcher::DEFAULT_CALLER_ID_NUMBER
        @target_options[:origination_caller_id_name] = args[:caller_id_name] || FreeSwitcher::DEFAULT_CALLER_ID_NAME
        @target_options[:originate_timeout] = args[:timeout] || @target_options[:timeout] || 15
      end

      # Send the command to the event socket, using bgapi by default.
      def run(api_method = :bgapi)
        orig_command = "%s %s" % [api_method, command_text]
        Log.debug "saying #{orig_command}"
        @fs_socket.say(orig_command)
      end

      # This method builds the API command to send to the freeswitch event socket
      def command_text
        target_opts = @target_options.map { |k,v| "%s=%s" % [k, v] }.join(",")
        if @originator
          orig_command = "originate {#{target_opts.join(',')}}#{@target} #{@originator}"
        elsif @application and @application_arguments
          application_opts = @application_options.map { |k,v| "%s=%s" % [k, v] }.join(",")
          orig_command = "originate {#{target_opts}}#{@target} '&#{@application}({#{application_opts}}#{@application_arguments})'"
        else
          raise "Invalid originator or application"
        end
      end
    end

    register(:originate, Originate)
  end
end
