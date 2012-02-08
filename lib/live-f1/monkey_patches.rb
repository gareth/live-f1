# Ruby 1.9 allows you to alter the encoding of a string, something that's not
# possible in Ruby 1.8. Since we use those methods in live-f1 we stub them out
# for people running Ruby 1.8
if RUBY_VERSION =~ /^1\.8/
  class String
    def force_encoding *args
      self
    end

    def encode *args
      self
    end
  end
end
