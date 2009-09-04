require 'rubygems'
require 'rack'
require 'midiator'
require 'mongrel'
require 'dnssd'

class Curlophone
  include MIDIator::Notes

  def initialize
    @midi = MIDIator::Interface.new
    @midi.use :dls_synth
    @channel = 0
    @volume = 100
  end

  def call(env)
    req = Rack::Request.new(env)
 
    if req.path_info == '/'
      note = MiddleC
    elsif req.path_info =~ /\/volume\/\d+/
      @volume = req.path_info[/\/volume\/(\d+)/, 1].to_i
    elsif req.path_info =~ /\/channel\/\d+/
      @channel = req.path_info[/\/channel\/(\d+)/, 1].to_i
      puts "Channel: #{@channel}"
    else
      note_with_octave, duration = req.path_info[1..-1].split('/')
      duration ||= 3
      
      if MIDIator::Notes.const_defined?(note_with_octave)
        note = MIDIator::Notes.const_get(note_with_octave)
      else
        note = MiddleC
      end
    end
    #puts [@channel, note, duration].inspect
    @midi.play note, duration.to_i * 0.1, @channel, @volume

    Rack::Response.new.finish do |res|
      res.write("Curlophone!")
    end
  end
end

port = (ARGV[0] || 4321).to_i

unless Kernel.const_defined?("DNSSD_BROADCAST")
  DNSSD.register('curlophone', "_curlophone._tcp", 'local', port) do |rr|
    puts "Curlophone in tune, listening on port #{port}"
  end
  DNSSD_BROADCAST = true
end

Rack::Handler::Mongrel.run(Curlophone.new, :Port => port)
