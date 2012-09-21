# encoding: utf-8
module LiveF1

	# The live timing data stream consists of sequential Packets of data, each
	# describing a useful (or not-so-useful) event
	#
	# Packets are generated by StreamParser#run
	class Packet
		class InvalidPacket < StandardError # :nodoc:
		end

		# Packets which include Decryptable indicate their data isn't plaintext in
		# the stream and needs to be decrypted as they are parsed
		module Decryptable # :nodoc:
		end

		# Packets can be divided into 4 different classes, depending on how you
		# determine the length of the Packet once you have its Header.
		# 
		# See the protocol document for more information
		#--
		# TODO: Document protocol
		module Type # :nodoc:
			module Special # :nodoc:
				def length
					0
				end
			end

			module Short # :nodoc:
				def length
					l = (header.data >> 3)
					l == 0x0f ? 0 : l
				end
			end

			module Long # :nodoc:
				def length
					header.data
				end
			end

			module Timestamp # :nodoc:
				def length
					2
				end
			end
		end

		attr_reader :header, :data

		# Consumes a packet from the given stream and returns it.
		# 
		# Note that this might not be instantaneous if the stream is waiting on data
		# from the server.
		def self.from_stream stream # :nodoc:
			header = Header.new(stream)
			header.packet
		end

		# Returns an empty Packet of the correct type as determined by the given
		# Header
		# 
		# Used internally by the stream processing code
		def self.from_header header # :nodoc:
			packet = case header.car?
			when true  then Car.from_header header
			when false then Sys.from_header header
			else raise InvalidPacket.new("Couldn't calculate car data from header")
			end
		end

		def initialize header
			@header = header
		end

		# Provides a string representation of this packet
		def to_s
			data
		end

		# Provides the string representation of this packet along with its class
		def inspect
			"%-20s %s" % [self.class.name.split("::")[-2..-1]*("/"), to_s]
		end

		# Sets the contents of this packet to the specified data.
		# 
		# Non-nil data can only be set once.
		def data= new_data
			raise ArgumentError, "Cannot change packet data once set" unless @data.nil?
			@data = new_data
		end

		# Packet::Car is a namespace for Packet classes with data relating to a specific car
		class Car < Packet
			# The type field of any Header with a car number will indicate the type
			# of car Packet it represents, as specified by these constants
			module Type # :nodoc:
				CAR_POSITION_UPDATE  = 0
				RACE_POSITION        = 1
				RACE_NUMBER          = 2
				RACE_DRIVER          = 3
				RACE_GAP             = 4
				RACE_INTERVAL        = 5
				RACE_LAP_TIME        = 6
				RACE_SECTOR_1        = 7
				RACE_PIT_LAP_1       = 8
				RACE_SECTOR_2        = 9
				RACE_PIT_LAP_2       = 10
				RACE_SECTOR_3        = 11
				RACE_PIT_LAP_3       = 12
				RACE_NUM_PITS        = 13
				LAST_RACE_ATOM       = 14
				CAR_POSITION_HISTORY = 15
				CAR_LAST_PACKET      = 16 # TODO: Check whether this is impossible to achieve
			end
			include Type

			def self.from_header header # :nodoc:
				case header.packet_type
				when CAR_POSITION_UPDATE then PositionUpdate
				when RACE_POSITION then RacePosition
				when RACE_NUMBER then RaceNumber
				when RACE_DRIVER then RaceDriver
				when RACE_GAP then RaceGap
				when RACE_INTERVAL then RaceInterval
				when RACE_LAP_TIME then RaceLapTime
				when RACE_SECTOR_1 then RaceSector1
				when RACE_PIT_LAP_1 then RacePitLap1
				when RACE_SECTOR_2 then RaceSector2
				when RACE_PIT_LAP_2 then RacePitLap2
				when RACE_SECTOR_3 then RaceSector3
				when RACE_PIT_LAP_3 then RacePitLap3
				when RACE_NUM_PITS then RaceNumPits
				when LAST_RACE_ATOM then LastRaceAtom
				when CAR_POSITION_HISTORY then PositionHistory
				when CAR_LAST_PACKET then CarLastPacket
				else
					raise InvalidPacket.new("Unexpected car packet type #{header.packet_type}")
				end.new header
			end

			# A numeric representation of the car number as referenced by the live timing system.
			# 
			# Note that this is not the car's official number, that is given in the
			# RaceNumber packet associated with this car.
			def car
				header.car
			end

			def heading # :nodoc:
				"Car #{"%02d" % car}"
			end

			def to_s # :nodoc:
				"#{heading} - #{super}"
			end

			class PositionUpdate < Car
				include Packet::Type::Special
			end

			class RacePosition < Car
				include Packet::Type::Short
				include Decryptable
			end

			class RaceNumber < Car
				include Packet::Type::Short
				include Decryptable
			end

			class RaceDriver < Car
				include Packet::Type::Short
				include Decryptable
			end

			class RaceGap < Car
				include Packet::Type::Short
				include Decryptable
			end

			class RaceInterval < Car
				include Packet::Type::Short
				include Decryptable
			end

			class RaceLapTime < Car
				include Packet::Type::Short
				include Decryptable
			end

			class RaceSector1 < Car
				include Packet::Type::Short
				include Decryptable
			end

			class RacePitLap1 < Car
				include Packet::Type::Short
				include Decryptable
			end

			class RaceSector2 < Car
				include Packet::Type::Short
				include Decryptable
			end

			class RacePitLap2 < Car
				include Packet::Type::Short
				include Decryptable
			end

			class RaceSector3 < Car
				include Packet::Type::Short
				include Decryptable
			end

			class RacePitLap3 < Car
				include Packet::Type::Short
				include Decryptable
			end

			class RaceNumPits < Car
				include Packet::Type::Short
				include Decryptable
			end

			class LastRaceAtom < Car
				include Packet::Type::Short
				include Decryptable
			end

			class PositionHistory < Car
				include Packet::Type::Long
				include Decryptable

				def to_s
					"#{heading} - " + data.split(//).map { |s| "%02d" % s.bytes.to_a[0] }.join(",")
				end
			end

			class LastPacket < Car
				include Packet::Type::Short
				include Decryptable
			end
		end

		# Packet::Sys is a namespace for Packet classes with data *not* relating
		# to a specific car (system packets)
		class Sys < Packet
			# The type field of any Header without a car number will indicate the
			# type of system Packet it represents, as specified by these constants
			module Type # :nodoc:
				# 0?
				EVENT_START = 1
				KEY_FRAME   = 2
				# 3?
				COMMENTARY   = 4
				# 5?
				NOTICE       = 6
				TIMESTAMP    = 7
				# 8?
				WEATHER      = 9
				SPEED        = 10
				TRACK_STATUS = 11
				COPYRIGHT    = 12
				LAST_PACKET  = 13
				# 14?
				# 15?
			end
			include Type

			def self.from_header header # :nodoc:
				case header.packet_type
				when EVENT_START then EventStart
				when KEY_FRAME then KeyFrame
				when COMMENTARY then Commentary
				when NOTICE then Notice
				when TIMESTAMP then Timestamp
				when WEATHER then Weather
				when SPEED then Speed
				when TRACK_STATUS then TrackStatus
				when COPYRIGHT then Copyright
				else
					raise InvalidPacket.new("Unexpected system packet type #{header.packet_type}")
				end.new header
			end

			# The EventStart packet is generated at the start of any practice,
			# qualifying or race event
			class EventStart < Sys
				include Packet::Type::Short

				EVENT_TYPES = {
					1 => :race,
					2 => :practice,
					3 => :qualifying
				}

				# Returns a symbol indicating the type of event started by this Packet
				def event_type
					EVENT_TYPES[
						data.bytes.to_a[0]
					]
				end

				# Returns the session number used internally by the live timing system to identify this event
				def session_number
					data[1..-1].to_i
				end

				def to_s # :nodoc:
					"Session %d, %s" % [session_number, event_type.to_s.capitalize]
				end
			end

			# The KeyFrame packet is generated whenever a new keyframe file has been generated on the server.
			# 
			# Keyframe files contain a snapshot of the live timing state at the
			# point they were generated. New connections to the stream are only
			# sent packets generated since the last keyframe, they are expected to
			# use the contents of the latest keyframe to initialise their data.
			class KeyFrame < Sys
				include Packet::Type::Short

				# Indicates the identifying number of the keyframe
				def number
					data.reverse.unpack("B*").first.to_i(2)
				end

				def to_s
					"Keyframe #{number}"
				end

			end

			# Commentary packets contain the commentary provided by the
			# live timing stream.
			# 
			# Each packet contains a maximum of 125 bytes of commentary. A
			# commentary string longer than this will be transmitted in successive
			# Commentary packets with the final one having a specific bit set
			#--
			# TODO: Find out what the first byte of data represents.
			class Commentary < Sys
				include Packet::Type::Long
				include Decryptable

				# Is this the last line of this commentary string?
				# 
				# If not, the next packet should also be a Commentary packet continuing this text
				def terminal?
					data.bytes.to_a[1] == 1
				end
				
        # Returns the line of commentary, which may only be a partial line if
        # this commentary was split over multiple packets
				def line
          # The commentary packet encoding is all messed up. Its UTF-8 characters
          # have been treated as Windows-1252 and then reconverted back to UTF-8.
          # This is where we try and undo that.
					data[2..-1].force_encoding("UTF-8").encode("Windows-1252").force_encoding("UTF-8")
				end

				def to_s
					"%s%s" % [line, (terminal? ? "" : "…")]
				end
			end

			# Indicates a human-readable service-level notice.
			# 
			# Commonly used between race weekends to indicate the start of the following session
			class Notice < Sys
				include Packet::Type::Long
				include Decryptable
				
				# Returns the text of the relevant notice
				def notice
					data
				end
			end

			# Once a session is in progress, Timestamp packets are generated at
			# regular intervals to indicate how long has passed since the start of
			# the session
			class Timestamp < Sys
				include Packet::Type::Timestamp
				include Decryptable

				# Returns the number of seconds since the start of the session, as
				# indicated by this packet
				def timestamp
					data.unpack("v").first
				end

				def to_s
					timestamp.to_s
				end

			end

			# Weather packets are used to indicate the state of various metrics including some unrelated to weather conditions.
			# 
			# It's not clear what all of the metrics returned by the service represent
			#--
			# TODO: Investigate and document the unknown metrics
			class Weather < Sys
				include Packet::Type::Short
				include Decryptable

				# An incomplete mapping of numeric IDs to metric descriptions
				METRICS = {
					8 => "Wet/dry",                 # 0 for dry, 1 for wet
					17 => "Track temperature",      # in ˚C
					18 => "Air temperature",        # in ˚C
					21 => "Humidity",               # in %
					28 => "Wind speed",             # in m/s
					31 => "Wind direction",         # in degrees clockwise from north
					54 => "Air pressure",           # in mBar
					56 => "Session time remaining", # as a h:mm:ss string
				}

				# Returns the numeric identifier for the relevant metric
				def metric
					header.data.to_i
				end

				def to_s # :nodoc:
					"Weather: #{METRICS[metric] || "Unknown"} - #{data}"
				end
			end

			# Speed packets contain information about the top 6 recorded driver
			# speeds through the 4 speed traps on the lap (at the end of each of
			# the 3 sectors, and at the dedicated speed trap)
			class Speed < Sys
				include Packet::Type::Long
				include Decryptable

				# Indicates which trap has generated this packet.
				# 
				# 1-3:: The end of the corresponding lap sector
				# 4::   The dedicated speed trap
				def trap
					data.bytes.to_a[0]
				end

				# Returns an array of up to 6 [driver,speed] pairs, indicating the
				# new top 6 speeds through the trap.
				# 
				# driver:: The 3-letter driver abbrevaition
				# speed::  The recorded speed in KPH
				def speeds
					data[1..-1].scan(/(\w+)\r(\d+)/)
				end

				def to_s # :nodoc:
					s = [
						"Trap #{trap}",
						("#{speeds.inspect}" unless speeds.empty?),
						("#{data[1..-1].inspect}" if speeds.empty?)
					]
					s.compact * " - "
				end
			end

			# Indicates a change in the track status (e.g. yellow flag, red flag)
			#--
			# TODO: Documentation
			class TrackStatus < Sys
				include Packet::Type::Short
				include Decryptable

				def to_s
					"Data #{header.data} - #{data}"
				end

			end

			# Represents the copyright string governing ownership of the data provided by the stream
			class Copyright < Sys
				include Packet::Type::Long
				
				# Returns the copyright string associated with the packet
				def copyright
					data
				end
			end
		end

		# Represents the Header of a live timing Packet
		# 
		# The live timing data stream consists of sequential binary packets. Since
		# these packets are variable-length, a fixed-length header is sent in front
		# of each packet. From the header, you can determine which kind of packet is
		# being sent, and how many bytes of data it contains.
		class Header

			attr_reader :packet, :data, :packet_type, :car

			# Consumes a header from the given stream and returns it with the
			# associated packet also consumed and initialised
			# 
			# Note that this might not be instantaneous if the stream is waiting on data
			# from the server.
			def initialize stream
				header_data = stream.read_bytes 2

				raise "Expected 2 bytes from #{stream.inspect}, got #{header_data.to_s.length}" unless header_data.to_s.length == 2
        
				header_bits = header_data.to_s.reverse.unpack("B*").first
				(_, @data, @packet_type, @car = header_bits.match(/^(.{7})(.{4})(.{5})$/).to_a.map { |s| s.to_i(2) }) or raise "Header too short"

				@packet = Packet.from_header self
				packet_data = stream.read_bytes @packet.length
				@packet.data = @packet.is_a?(Decryptable) ? stream.decrypt(packet_data) : packet_data
			end

			def car?
				car > 0
			end
		end

	end
end