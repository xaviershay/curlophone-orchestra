require 'rack'
require 'midiator'
require 'mongrel'
require 'dnssd'


class Curlophone
  include MIDIator::Notes

  def initialize
    @midi = MIDIator::Interface.new
    @midi.use :dls_synth
    @volume = 100
  end

  def call(env)
    req = Rack::Request.new(env)
 
    if req.path_info == '/'
      note = MiddleC
    elsif req.path_info =~ /\/volume\/\d+/
      @volume = req.path_info[/\/volume\/(\d+)/, 1].to_i
    else
      note_with_octave = req.path_info[1..-1]
      if MIDIator::Notes.const_defined?(note_with_octave)
        note = MIDIator::Notes.const_get(note_with_octave)
      else
        note = MiddleC
      end
    end
    @midi.play note, 0.3, 0, @volume

    Rack::Response.new.finish do |res|
      res.write("Curlophone!")
    end
  end
end

unless Kernel.const_defined?("DNSSD_BROADCAST")
  tr = DNSSD::TextRecord.new
  tr['description'] = "Curlophone!"
  tr['curlophone'] = 'true' # distinguish from other servers

  name = 'curlophone'
  port = ARGV[0].to_i
  puts port
  DNSSD.register(name, "_http._tcp", 'local', port, tr.encode) do |rr|
    puts "Registered #{name} on port #{port}. Starting service."
  end
  DNSSD_BROADCAST = true
end

Rack::Handler::Mongrel.run(Curlophone.new, :Port => ARGV[0] || 2000)
