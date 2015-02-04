require File.dirname(__FILE__) + '/test_helper'
require 'i18n_version'

class I18nVersionTest < Test::Unit::TestCase

  def setup
    @i18n_version = 'us'
    I18nVersion.set! @i18n_version
  end

  def test_set_correctly_sets_version
    assert_equal @i18n_version, I18nVersion.value
  end

  def test_equality_methods_return_correct_bool
    assert I18nVersion == @i18n_version
    assert I18nVersion.eql? @i18n_version
    assert I18nVersion.equal? @i18n_version

    assert !(I18nVersion == "not us i18n_version")
    assert !I18nVersion.eql?("not us i18n_version")
    assert !I18nVersion.equal?("not us i18n_version")
  end

end
