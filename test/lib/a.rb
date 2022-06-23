# label-lists :: Now use tables
#
# * regular list
#
# http://github.com/jeremyevans/hanna-nouveau
#
# https://github.com/jeremyevans/hanna-nouveau
class A
  module B
    def c
    end
  end

  def d
  end
  alias e d

  class F
  end

  G = Class.new
end

class ::A::G::H
end
