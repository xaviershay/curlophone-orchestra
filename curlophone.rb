require 'sinatra'
require 'midiator'

midi = MIDIator::Interface.new
midi.use :dls_synth

include MIDIator::Notes
OCTAVE = '4'

get '/' do
  midi.play MiddleC
  "Curlophone!"
end

get '/:note' do
  note_with_octave = params[:note] + OCTAVE # "C4"
  if MIDIator::Notes.const_defined?(note_with_octave)
    note = MIDIator::Notes.const_get(note_with_octave)
  else
    note = MiddleC
  end

  midi.play note
end
