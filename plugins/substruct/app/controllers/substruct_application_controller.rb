module SubstructApplicationController
  include Substruct
  include LoginSystem

  def self.included(base)
    base.class_eval do
      model :user
      model :cart
      model :order_line_item
      model :order_shipping_type

      def cache
        $cache ||= SimpleCache.new 1.hour
      end
    end
  end
end
