require 'net/imap'

class GoogleImap
  GMAIL_TRASH = '[Gmail]/Trash'

  def initialize(username, password, host, port, use_ssl)
    try_again = 2
    begin
      @imap = Net::IMAP.new host, port, use_ssl
      @imap.login username, password
      @imap
    rescue Exception=>e
      if (try_again -= 1) > 0
        retry
      else
        raise e
      end
    end
  end

  def select_folder(folder)
    @imap.select folder
  end

  def get_unread_uids
    @imap.uid_search(["NOT", "DELETED"])
  end

  def fetch(set, attr)
    @imap.uid_fetch set, attr
  end

  def fetch_with_message_id(set,attr)
    @imap.fetch set,attr
  end

  def responses
    @imap.responses
  end

  def expunge
    @imap.expunge
  rescue Exception => f
    puts "expunge caught exception #{f}"
  end

  def disconnect
    @imap.expunge
    @imap.logout
    @imap.disconnect
  end

  def delete_message(uid)
    @imap.uid_copy(uid, GMAIL_TRASH)
    @imap.uid_store(uid, "+FLAGS", [:Deleted])
  end

  def label(uid, label)
    create_mailbox(label)
    @imap.uid_copy(uid, label)
  end

  def create_mailbox(mailbox)
    unless @imap.list("", mailbox)
      @imap.create(mailbox)
    end
  end

  def getquotaroot
    iqs = @imap.getquotaroot '[Gmail]' # folder doesn't seem to matter as we go to the top of the chain
    iqs.detect{|q| q.mailbox.blank?}
  end

  def take_out_the_trash
    select_folder GMAIL_TRASH
    week_ago = Date.today - 7
    @imap.uid_search(["BEFORE", week_ago.strftime("%d-%b-%Y")]).each do |uid|
      @imap.uid_store(uid, "+FLAGS", [:Deleted])
    end
  end

  private

  def method_missing(method_name, *args)
    return  @imap.send(method_name, *args) if @imap.respond_to?(method_name)
    super(method_name, *args)
  end
end
