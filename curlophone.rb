require 'sinatra'
require 'midiator'

midi = MIDIator::Interface.new
midi.use :dls_synth

include MIDIator::Notes

get '/' do
  midi.play MiddleC
  "Curlophone!"
end

get '/:note' do
  note_with_octave = params[:note] 
  if MIDIator::Notes.const_defined?(note_with_octave)
    note = MIDIator::Notes.const_get(note_with_octave)
  else
    note = MiddleC
  end

#  midi.play note
  puts note
end
