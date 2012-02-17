module LiveF1
	class RaceStream
		attr_reader :source

		# Takes the same initialization as its underlying StreamParser
		def initialize source = nil, &block # :yields: source
			@source = StreamParser.new(source, &block)
		end

		def run opts = {}, &block
			opts = {
				# :yields => [RaceStream::Event]
				:yields => [LiveF1::Packet]
			}.merge(opts)

			source.run do |is_live, packet|
				yield packet if opts[:yields].any? { |y| y === packet }
			end
		end
	end

	class Event
	end
end