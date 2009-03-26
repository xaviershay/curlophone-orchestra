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
      puts resolve_reply.text_record.inspect
      puts reply.inspect
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

  puts "Gathering for up to #{timeout} seconds..."
  sleep timeout
  dns.stop
end

discover do |service|
  musicians << service
end
musicians = musicians.to_a
puts musicians.inspect

notes = %w(
  E - E - F - G - G - F - E - D - C - C - D - E - E - - D D - - -
  E - E - F - G - G - F - E - D - C - C - D - E - D - - C C - - -
)

harmony = %w(
  C - C - D - E - E - D - C - B, - A, - A, - B, - C - C - - B, B, - - -
  C - C - D - E - E - D - C - B, - A, - A, - B, - C - B, - - A, G, - - -
)

bass = %w(
  C,, - - - - - - - G,, - - - - - - - C,, - - - - - - - G,, - - - - - - -
  C,, - - - - - - - G,, - - - - - - - C,, - - - - - - - G,, - - C,, C,, - - -
)

contra = %w(
  C' B C' G A B C' E'      G' A' G' F' E' D' C' G
  C' D' C' E' D' F' E' G'  F' G' E' D' C G A B
  C' B C' G A B C' E'      G' A' G' F' E' D' C' G
  C' D' C' E' D' F' E' G'  F' G' E' D' C - - -
)
parts = [notes, harmony, bass, contra]
part_index = 0

#musicians.collect! do |muso|
#  Net::HTTP.new(muso.target, muso.port)
#end
(0..notes.length-1).each do |note_index|
  musicians.each_with_index do |muso, muso_index|
    note = parts[muso_index % parts.length][note_index]
    next if note == '-' 

    octave = 4 - note.gsub(/[^,]/, '').size + note.gsub(/[^']/, '').size
    pitch = note.gsub(/[^A-Z]/, '')

    puts "#{pitch}#{octave}"
    fork do
      `curl #{muso.target}:#{muso.port}/#{pitch}#{octave} &`
    end
    #muso.get("/#{pitch}#{octave}")
  end
  sleep 0.2
end
