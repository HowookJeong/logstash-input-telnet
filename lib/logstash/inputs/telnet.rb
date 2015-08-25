# encoding: utf-8
require "logstash/inputs/base"
require "logstash/namespace"
require "stud/interval"
require "socket" # for Socket.gethostname
require "net/telnet"

# Generate a repeating message.
#
# This plugin is intented only as an example.

class LogStash::Inputs::Telnet < LogStash::Inputs::Base
  config_name "telnet"

  # If undefined, Logstash will complain, even if codec is unused.
  default :codec, "plain" 

  # The message string to use in the event.
  config :message, :validate => :string, :default => "failure"
  config :daemons, :validate => :string, :default => "localhost:9200|localhost:9300"

  # Set how frequently messages should be sent.
  #
  # The default, `60`, means send a message every 1 minute.
  config :interval, :validate => :number, :default => 60

  public
  def run(queue)
    daemons = Array.new
    daemons=@daemons.split("|");
    daemonCount=daemons.length-1

    Stud.interval(@interval) do
      for i in 0..daemonCount
        daemon = daemons.at(i).split(":");
        connectionFlag = false

        begin
          host = Net::Telnet::new({
            "Host" => daemon.at(0),
            "Port" => daemon.at(1),
            "Binmode" => false,
            "Telnetmode" => false
            }){
            |c|

            if c.match("Connected to")
              connectionFlag = true
            end
          }
        rescue
          connectionFlag = false
        end

        if connectionFlag
          @message="success"
        else
          @message="failure"
        end

        event = LogStash::Event.new("host" => daemon.at(0), "port" => daemon.at(1), "message" => @message)
        decorate(event)
        queue << event
      end # for loop
    end # loop
  end # def run

end # class LogStash::Inputs::Telnet
