# :main:LiveF1

# =Formula 1 live timing
# 
# The LiveF1 library allows realtime parsing of data from the F1 live
# timing stream. It connects to the binary stream and turns it into a series of
# objects describing the stream
# 
# ==Basics
# 
# The live timing service is primarily used to control the live timing Java
# applet at http://www.formula1.com/services/live_timing. However, the richness
# of the data it provides means that the stream could be used to provide a much
# deeper view of a session than the applet itself provides. This library
# provides the very basic toolkit allowing such an application to be built using
# Ruby, but when using it it's important to remember the service was built
# around this one visual use.
# 
# The StreamParser consists of a sequence of binary packets describing every visual
# change on the live timing screen. For example, if a packet arrives saying that
# a car's sector 1 time is "38.3" it will usually be accompanied by a packet
# saying that the same car's sector 2 time is "" - i.e. clearing the previous
# lap's sector 2 time. However, there is no guarantee of the order these packets
# will be generated. This gives a lot of flexibility to the server over how the
# information is displayed, but makes it potentially very annoying when processing
# the data.
# 
# The stream generates packets from the start of every practice, qualifying and
# race session. However anyone connecting to the stream after the start of a
# session doesn't get sent the entire packet history. Instead, keyframes
# containing the current live timing state are regularly generated throughout a
# session, and new connections are given the latest keyframe followed by the
# packets generated since that keyframe.
# 
# ==Usage
# 
#     LiveF1::StreamParser.new.run
# 
module LiveF1

  # :stopdoc:
  VERSION = '0.1.0'
  LIBPATH = ::File.expand_path(::File.dirname(__FILE__)) + ::File::SEPARATOR
  PATH = ::File.dirname(LIBPATH) + ::File::SEPARATOR
  # :startdoc:

  # Returns the version string for the library.
  #
  def self.version
    VERSION
  end

  # Returns the library path for the module. If any arguments are given,
  # they will be joined to the end of the libray path using
  # <tt>File.join</tt>.
  #
  def self.libpath( *args )
    args.empty? ? LIBPATH : ::File.join(LIBPATH, args.flatten)
  end

  # Returns the lpath for the module. If any arguments are given,
  # they will be joined to the end of the path using
  # <tt>File.join</tt>.
  #
  def self.path( *args )
    args.empty? ? PATH : ::File.join(PATH, args.flatten)
  end

  # Utility method used to require all files ending in .rb that lie in the
  # directory below this file that has the same name as the filename passed
  # in. Optionally, a specific _directory_ name can be passed in such that
  # the _filename_ does not have to be equivalent to the directory.
  #
  def self.require_all_libs_relative_to( fname, dir = nil )
    dir ||= ::File.basename(fname, '.*')
    search_me = ::File.expand_path(
        ::File.join(::File.dirname(fname), dir, '**', '*.rb'))

    Dir.glob(search_me).sort.each {|rb| require rb}
  end

end  # module LiveF1

LiveF1.require_all_libs_relative_to(__FILE__)

# EOF
