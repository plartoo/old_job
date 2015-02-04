require 'ruby-debug'

$:.unshift File.join(File.dirname(__FILE__))
require 'google_imap'
require 'mechanize'


USERNAME = "postfix@xxxx.com"
PASSWORD = "630SSiittmm"
HOST = "imap.gmail.com"
PORT = "993"
USE_SSL = true
@imap = GoogleImap.new USERNAME, PASSWORD, HOST, PORT, USE_SSL

SOURCE_MAILBOX = 'INBOX'
TARGET_MAILBOX = 'Processed'

TEMPLATE_1 = "Unsubscribe 1"



def extract_sender_address(envelope)
  envelope.from[0].mailbox + '@' + envelope.from[0].host
end

def extract_sender_name(envelope)
  envelope.from[0].name
end

def extract_receiver_address(envelope)
  envelope.to[0].mailbox + '@' + envelope.to[0].host
end

def get_envelope(uid)
  puts uid
  @imap.uid_fetch(uid, "ENVELOPE")[0].attr["ENVELOPE"]
end

def get_response(receiver, sender)
  TEMPLATE_1
end

def process_unread_messages(source, target)
  @imap.select_folder source
  @imap.create_mailbox(target)

  ## IMPORTANT: we should deal with 'uid' as opposed to 'message_id'
  ## because the latter is just the index of a message in the mailbox
  ## and can change as we move messages around mailboxes
  @imap.uid_search(['NOT','SEEN']).each do |uid|
    envelope = get_envelope(uid)
    from = extract_sender_address(envelope)
    to = extract_receiver_address(envelope)
    response = get_response(to, from)

    move_messages(uid, target)
  end
  @imap.expunge
end


def move_messages(uid, target)
  puts "moving  #{uid}"
  @imap.uid_store(uid, '+FLAGS', [:Seen])
  @imap.uid_copy(uid, target)
  @imap.uid_store(uid, '+FLAGS', [:Deleted])
end

def move_read_messages(source,target)
  @imap.select_folder source
  @imap.create_mailbox(target)

  @imap.search(['SEEN']).each do |msg_id|
    @imap.copy(msg_id, target)
    @imap.store(msg_id, '+FLAGS', [:Deleted])
  end
  @imap.expunge
end


process_unread_messages(SOURCE_MAILBOX,TARGET_MAILBOX)
@imap.disconnect

