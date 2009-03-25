require 'midiator'
require 'net/http'

musicians = ['localhost:4565', 'localhost:4567', 'localhost:4568', 'localhost:4569']

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

musicians.collect! do |muso|
  tokens = muso.split(':')
  Net::HTTP.new(tokens[0], tokens[1])
end
(0..notes.length-1).each do |note_index|
  musicians.each_with_index do |muso, muso_index|
    note = parts[muso_index % parts.length][note_index]
    next if note == '-' 

    octave = 4 - note.gsub(/[^,]/, '').size + note.gsub(/[^']/, '').size
    pitch = note.gsub(/[^A-Z]/, '')

    puts "#{pitch}#{octave}"
    muso.get("/#{pitch}#{octave}")
  end
  sleep 0.3
end
