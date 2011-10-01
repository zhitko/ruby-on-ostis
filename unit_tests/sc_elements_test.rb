# -*- coding: utf-8 -*-

unless $:.include? File.dirname(__FILE__)
  $:.unshift(File.dirname(__FILE__))
  $:.unshift File.expand_path('../src/',File.dirname(__FILE__))
end

require "test/unit"
require "sc_elements"

class ScElementsTest < Test::Unit::TestCase

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    # Do nothing
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.
  def teardown
    # Do nothing
  end

  def test_create_elements
    assert_not_nil(n1 = Sc::ScElement.new(),"Failed on create simple element")
    assert_not_nil(n2 = Sc::ScNode.new(:sc_group,:SC_CONST),"Failed on create node")
    assert_not_nil(Sc::ScArc.new(n1, n2, :sc_group,:SC_CONST),"Failed on create arc")
  end

  def test_create_uniq_keynodes
    n1 = Sc::ScNode.new '/test/node1', :sc_const
    assert_instance_of(Sc::ScNode,Sc::ScElement.new('/test/node1'),"Failed on type keynode check")
    assert_equal(n1, Sc::ScNode.new('/test/node1',:sc_node),"Failed on get existing keynode")
  end

  def test_content
    raise 'Test not done'
  end
end