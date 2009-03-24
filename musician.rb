require 'rack'
require 'midiator'
require 'music_player'

alias :L :lambda

class Player
  include MIDIator::Notes
  include AudioToolbox

  attr_accessor :current_part
  
  def initialize
    reset(:drums)
  end

  def reset(part = current_part)
    @player.stop if @player

    self.current_part = part
    @player   = MusicPlayer.new
    @sequence = MusicSequence.new
    @track    = @sequence.tracks.new
    event = ExtendedTempoEvent.new(:bpm => 600)
    event.add(0.0, @sequence.tracks.tempo)
    @track.add(0.0, MIDIProgramChangeMessage.new(:channel => 10, :program => 26))
    @track.add(0.0, MIDIControlChangeMessage.new(:channel => 10, :number => 32, :value => 1))
    @track.add(0.0, MIDIProgramChangeMessage.new(:channel => 1, :program => 17))
    @track.add(0.0, MIDIProgramChangeMessage.new(:channel => 2, :program => 33))
    # Use the following call sequence to use an alternate midi destination.
    # Hopefully a more complete interface will be implemented soon. MIDI
    # destinations are referenced by their index beginning at 0.
    # See also CoreMIDI::get_number_of_destinations().
    # 
    #@sequence.midi_endpoint = CoreMIDI.get_destination(ARGV.shift.to_i)
    @player.sequence = @sequence
  
    parts = {
      :drums => L{
        (0..1).each do |bar|
          kick1(bar * 24 + 0)
          kick1(bar * 24 + 5)
          snare(bar * 24 + 6)
          kick1(bar * 24 + 9)
          kick1(bar * 24 + 15)
          snare(bar * 24 + 18)

          (0..3).each do |beat|
            #hihat(beat * 6)
            hihat(bar * 24 + beat * 6 + 3)
            #hihat(beat * 6 + 5)
          end
        end
      },
      :bass => L{
        duration = 3
        @track.add(0,
          MIDINoteMessage.new(:note     => 43,
                              :velocity => 80,
                              :channel  => 2,
                              :duration => duration))
        @track.add(6,
          MIDINoteMessage.new(:note     => 53,
                              :velocity => 80,
                              :channel  => 2,
                              :duration => duration))
        @track.add(9,
          MIDINoteMessage.new(:note     => 55,
                              :velocity => 80,
                              :channel  => 2,
                              :duration => duration))
      },
      :organ => L{
        def note(beat, pitch, duration = 1)
          @track.add(beat,
            MIDINoteMessage.new(:note     => pitch,
                                :velocity => 80,
                                :channel  => 1,
                                :duration => duration))
        end

        note(3, A3)
        note(3, Eb4)
        note(3, F4)
        note(3, Ab4)

        note(9, A3, 12)
        note(9, Eb4, 12)
        note(9, F4, 12)
        note(9, Ab4, 12)
      }
    }[part].call
    
    @track.length = 48
    @track.loop_info = { :duration => @track.length, :number => 0 }
  end

  def drum(beat, note)
    @track.add(beat,
      MIDINoteMessage.new(:note     => note,
                          :velocity => 80,
                          :channel  => 10,
                          :duration => 0.1))
  end
  
  def kick1(beat)
    drum(beat, 35)
  end
  
  def kick2(beat)
    drum(beat, 36)
  end
  
  def snare(beat)
    drum(beat, 40)
  end

  def hihat(beat)
    drum(beat, 44)
  end

  def call(env)
    req = Rack::Request.new(env)
 
    case req.path_info
    when '/track/drums'
      reset(:drums)
    when '/track/bass'
      reset(:bass)
    when '/track/organ'
      reset(:organ)
    when '/go'
      @player.start
    when '/stop'
      @player.stop
      reset
    end
 
    # Default content-type is text/html
    # Default status is 200
    Rack::Response.new.finish do |res|
       res.write(req.path_info) 
    end
  end
end

Rack::Handler::WEBrick.run(Player.new, :Port => ARGV[0] || 2000)
