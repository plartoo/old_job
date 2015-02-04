require 'test_helper'

class DepartmentsTest < Test::Unit::TestCase
  
  def test_departments
    assert_equal(0, Department[:womens], "existing department")
    assert_equal(nil, Department[:notadept], "non-existant department")
  end

end
