require 'test/unit'
require 'stringio'

# Test for issue JIRA-2506
# Fails with an EOF error in JRuby 1.1.1, works in MRI 1.8.6
# Author: steen.lehmann@gmail.com

class TestUnmarshal < Test::Unit::TestCase

  def testUnmarshal
    dump = ''
    dump << Marshal.dump("hey")
    dump << Marshal.dump("there")

    result = "none"
    StringIO.open(dump) do |f|
      result = Marshal.load(f)
      assert_equal "hey", result, "first string unmarshalled"      
      result = Marshal.load(f)
    end
    assert_equal "there", result, "second string unmarshalled"
  rescue EOFError
    flunk "Unmarshalling failed with EOF error at " + result + " string."
  end

  # TYPE_IVAR from built-in class
  class C
    def _dump(depth)
      "foo"
    end

    def self._load(str)
      new
    end
  end

  def test_ivar_in_built_in_class
    (o = "").instance_variable_set("@ivar", C.new)
    assert_nothing_raised do
      Marshal.load(Marshal.dump(o))
    end
  end

  # JRUBY-5123: nested TYPE_IVAR from _dump
  class D
    def initialize(ivar = nil)
      @ivar = ivar
    end

    def _dump(depth)
      str = ""
      str.instance_variable_set("@ivar", @ivar)
      str
    end

    def self._load(str)
      new(str.instance_variable_get("@ivar"))
    end
  end

  def test_ivar_through_s_dump
    o = D.new(D.new)
    assert_nothing_raised do
      Marshal.load(Marshal.dump(o))
    end
  end
end
