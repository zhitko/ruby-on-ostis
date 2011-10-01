# -*- coding: utf-8 -*-

unless $:.include? File.dirname(__FILE__)
  $:.unshift(File.dirname(__FILE__))
  $:.unshift File.expand_path('../',File.dirname(__FILE__))
end

require "test/unit"

require 'sc_memory'

class ScMemoryTest < Test::Unit::TestCase

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    # Do nothing
    @mem = Sc::ScMemory.instance
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.
  def teardown
    @mem.mem_clear
  end

  def test_add_elements
    n1 = @mem.create_el(:sc_node, :sc_const)[0]
    n2 = @mem.create_el(:sc_node, :sc_const)[0]
    a1 = @mem.gen3_f_a_f(n1, [:sc_arc, :sc_const], n2)[0]

  end
end