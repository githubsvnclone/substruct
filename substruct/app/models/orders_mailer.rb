class OrdersMailer < ActionMailer::Base
  @@bcc = ['someaddress@somewhere.com']
  @@from = "Your Orders <orders@somewhere.com>"
  @@host = 'Substruct'

  def receipt(order, email_text)
    @subject = "Thank you for your order! (\##{order.order_number})"
    @body       = {:order => order, :email_text => email_text}
    @recipients = order.order_user.email_address
		@bcc        = @@bcc
		@from       = @@from
    @sent_on    = Time.now
    @headers    = {}
  end

  def reset_password(customer)
    @subject = "Password reset for #{@@host}"
    @body       = {:customer => customer}
    @recipients = customer.email_address
		@bcc        = @@bcc
		@from       = @@from
    @sent_on    = Time.now
    @headers    = {}
  end

  def failed(order)
    @subject = "An order has failed on the site"
    @body       = {:order => order}
		@recipients = @@bcc
		@from       = @@from
    @sent_on    = Time.now
    @headers    = {}
  end
  
end
