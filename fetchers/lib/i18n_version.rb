class I18nVersion

  include Singleton

  @@i18n_version = nil
  cattr_accessor :i18n_version

  class << self
    def set!(i18n_version)
      @@i18n_version = i18n_version
    end

    def value
      @@i18n_version
    end

    def ==(other)
      @@i18n_version == other
    end

    alias :equal? :==
    alias :eql? :==

  end
end
