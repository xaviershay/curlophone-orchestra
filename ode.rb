require 'midiator'

musicians = ['localhost:4567']

notes = %w(
  E E F G G F E D C C D E E D D -
  E E F G G F E D C C D E D C C -
)

harmony = %w(
  C C D E E D C B A A B C C B B - 
  C C D E E D C B A A B C B A G -
)

notes.each do |note|
  puts note
  sleep 0.5
end
