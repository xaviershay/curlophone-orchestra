require 'midiator'
require 'net/http'
require 'dnssd'
require 'set'

musicians = Set.new #['localhost:4000'] #, 'localhost:4001', 'localhost:4002']

class Service < Struct.new(:name, :target, :port, :description)
end

def discover(timeout=1)
  waiting_thread = Thread.current

  dns = DNSSD.browse "_http._tcp" do |reply|
    DNSSD.resolve reply.name, reply.type, reply.domain do |resolve_reply|
      if resolve_reply.text_record['curlophone']
        service = Service.new(reply.name,
                                 resolve_reply.target,
                                 resolve_reply.port,
                                 resolve_reply.text_record['description'].to_s)
        begin
          yield service
        rescue Done
          waiting_thread.run
        end
      end
    end
  end

  puts "Cattle call, who will play my tune? Starting in #{timeout} seconds..."
  sleep timeout
  dns.stop
end

discover do |service|
  musicians << service
end
musicians = musicians.to_a
puts "#{musicians.size} musicians are present:"
musicians.each do |muso|
  puts "  #{muso.target}"
end

puts
puts "Time to \\m/"


class Part
  attr_accessor :options

  def initialize(options)
    self.options = options
  end

  def notes
    options[:notes]
  end

  def volume
    options[:volume]
  end

  def channel
    options[:channel]
  end
end
notes = Part.new(:notes => %w(
  E - E - F - G - G - F - E - D - C - C - D - E - E - - D D6 - - -
  E - E - F - G - G - F - E - D - C - C - D - E - D - - C C6 - - -
))

harmony = Part.new(:notes => %w(
  C - C - D - E - E - D - C - B, - A, - A, - B, - C - C - - B, B,6 - - -
  C - C - D - E - E - D - C - B, - A, - A, - B, - C - B, - - G, G,6 - - -
))

bass = Part.new(:notes => %w(
  C,,10 - - - - - - - C,,10 - - - - - - - F,,10 - - - - - - - C,,10 - - - G,,6 - - -
  C,,10 - - - - - - - C,,10 - - - - - - - F,,10 - - - - - - - G,,10 - - - C,,6 - - -
))

contra = Part.new(:volume => 65, :notes => %w(
  C' B C' G A B C' E'      G' A' G' F' E' D' C' G
  C' D' C' E' D' F' E' G'  F' G' E' D' C G A B
  C' B C' G A B C' E'      G' A' G' F' E' D' C' G
  C' D' C' E' D' F' E' G'  F' G' E' D' E'6 - - -
))

drums = Part.new(:channel => 9, :notes => %w(
  C,, - D,, - C,, - D,, - C,, - D,, - C,, - D,, - 
  C,, - D,, - C,, - D,, - C,, - D,, - C,, - D,, D,,
  C,, - D,, - C,, - D,, - C,, - D,, - C,, - D,, - 
  C,, - D,, - C,, - D,, - C,, - D,, - A, - - - 
))

disco_drums = Part.new(:channel => 9, :notes => %w(
  C,, Fs,, D,, Fs,, C,, Fs,, D,, Fs,, C,, Fs,, D,, Fs,, C,, Fs,, D,, Fs,, 
  C,, Fs,, D,, Fs,, C,, Fs,, D,, Fs,, C,, Fs,, D,, Fs,, C,, Fs,, D,, D,,
  C,, Fs,, D,, Fs,, C,, Fs,, D,, Fs,, C,, Fs,, D,, Fs,, C,, Fs,, D,, Fs,, 
  C,, Fs,, D,, Fs,, C,, Fs,, D,, Fs,, C,, Fs,, D,, Fs,, A, - - -
))
  
parts = [notes, harmony, bass, contra, drums]
part_index = 0

# Setup volumes
musicians.each_with_index do |muso, muso_index|
  part = parts[muso_index % parts.length]
  if part.volume
    fork do
      `wget -q -O- #{muso.target}:#{muso.port}/volume/#{part.volume}`
    end
  end
  if part.channel
    fork do
      `wget -q -O- #{muso.target}:#{muso.port}/channel/#{part.channel}`
    end
  end
end
(0..notes.notes.length-1).each do |note_index|
  musicians.each_with_index do |muso, muso_index|
    note = parts[muso_index % parts.length].notes[note_index]
    next if note == '-' 

    octave = 4 - note.gsub(/[^,]/, '').size + note.gsub(/[^']/, '').size
    pitch = note.gsub(/[^A-Za-z]/, '')
    duration = note.gsub(/[^0-9]/, '').to_i
    duration = 3 if duration == 0

    #puts "#{pitch}#{octave}"
    fork do
      `wget -q -O- #{muso.target}:#{muso.port}/#{pitch}#{octave}/#{duration}`
    end
  end
  sleep 0.2
end
sleep 0.5
