module SubstructApplicationController
  include Substruct
  include LoginSystem

  def self.included(base)
    base.class_eval do
      def cache
        $cache ||= SimpleCache.new 1.hour
      end
    end
  end
end
