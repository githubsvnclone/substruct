module Substruct
  module Version
    MAJOR  = 1
    MINOR  = 2
    TINY   = 'a'
    STRING = [MAJOR, MINOR, TINY].join('.').freeze
  end
end