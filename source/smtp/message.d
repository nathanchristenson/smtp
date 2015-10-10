module smtp.message;

import std.string;
import std.uuid;
import std.datetime;

import smtp.attachment;
import smtp.utils;

/++
Struct that holds an email address and, optionally, a name associated with 
that email address.
+/
struct Mailbox 
{
        string address;
        string name;
}

/++
A struct that represents a valid email message.

Currently provides:
        Access to headers: From, To, Date, Content-Type, and Reply-To
        Provides default values for Date and Content-Type
        Multi-part messages for attachments

SmtpClient.send uses SmtpMessage to compose, format and send email via SMTP.
+/
struct SmtpMessage 
{
        static string boundary;                                 // Parts delmiter in multipart message
        // Email headers
        Mailbox messageFrom;                                    // Specifies name/address of a sender
        Mailbox[] messageTo;                                    // Array of Recipients that holds recipients
        Mailbox[] messageBcc;                                   // Array of email addresses to BCC
        SysTime messageDatestamp;                               // Message date and time, defaults to when message creates
        string contentType          =   "text/plain";           // message content type, default to 'text/plain'
        string charSet              =   "utf-8";                // character set, default to 'UTF-8'
        string replyTo;                                         // Setting "Reply To" helps make message chains
        string messageSubject;                                  // Message subject
        // Email message body
        string messageBody;                                     // Message text (body)
        //Email attachements
        SmtpAttachment[] attachments;                           // Attachments to message

        /++
        Initializes a boundary for parts in multipart/mixed message type.

        The boundary is a random sequence of chars that divides the message
        into parts: message and attachment(s).
        +/
        static this() {
                boundary = randomUUID().toString();
        }

        /++
        Add attachments to the `SmtpMessage`.
        +/
        void attach(SmtpAttachment[] a...) {
                attachments ~= a;
        }

        /++
        Fills in the cc field for messages.
        
        If there is more than one recipient, this will show all other recipients
        on the cc line, so everyone knows who is on the list.
        
        Might want to make this optional - there are cases in which you don't
        want everyone to know. But then you should use BCC, yes?
        +/
        private string cc() const {
                string tCc = "Cc:\"%s\" <%s>\r\n";
                string cc = "";
                if (messageTo.length > 1) {
                        foreach(recipient; messageTo) {
                                cc ~= format(tCc, recipient.name, recipient.address);
                        }
                } else {
                        cc = "";
                }
                return cc;
        }

        /++
        Builds message representation in case we have multipart/mixed MIME-type
        of the message to send.
        +/
        private string messageWithAttachments() const {
                const string crlf = "\r\n";
                return "Content-Type: text/plain; charset=utf-8" ~ crlf
                        ~ crlf
                        ~ messageBody ~ crlf
                        ~ crlf ~ "--" ~ SmtpMessage.boundary ~ crlf;
        }

        /++
        Partly converts attachments to string for SMTP protocol representation
        +/
        private string attachmentsToString() const {
                string result = "";
                foreach(ref a; attachments) {
                        result ~= a.toString(boundary);
                }
                return result[0..$ - 2] ~ ".\r\n";
        }

        /++
        Function for setting email Date header - which cannot be set as default 
        because SysTime won't work at compile time.
        
        This will set the date header as of the time this function is called if
        the date has not yet been sent.
        +/
        private string dateMessage() const {
                string tDate = "Date: %s\r\n";
                if (messageDatestamp is SysTime.init)
                {
                        messageDatestamp = Clock.currTime();
                }
                return(format(tDate, writeUFC2822DateHeader(messageDatestamp)));
        }
        /++
        Converts message into ready-to-send string representation that 
        can be sent via SMTP.
        +/
        string toString() const {
                const string tFrom            = "From: \"%s\" <%s>\r\n";
                const string tTo              = "To: \"%s\" <%s>\r\n";
                const string tSubject         = "Subject: %s\r\n";
                const string mime             = "MIME-Version: 1.0\r\n";
                const string tContentType     = "Content-Type: %s; charset= %s\r\n";
                const string tMultipart       = "Content-Type: multipart/mixed; boundary=\"%s\"\r\n";
                const string tReplyTo         = "Reply-To:%s\r\n";
                const string crlf             = "\r\n";

                // For messages without attachements
                if (!attachments.length) {
                        return format(tFrom, messageFrom.name, messageFrom.address)
                        ~ format(tTo, messageTo[0].name, messageTo[0].address)
                                ~ cc()
                                ~ format(tSubject, messageSubject)
                                ~ dateMessage()
                                ~ mime
                                ~ format(tContentType, contentType, charSet)
                                ~ format(tReplyTo, replyTo)
                                ~ crlf
                                ~ messageBody ~ "." ~ crlf;
                } else {
                // For messages with attachments
                        return format(tFrom, messageFrom.name, messageFrom.address)
                                ~ format(tTo, messageTo[0].name, messageTo[0].address)
                                ~ cc()
                                ~ format(tSubject, messageSubject)
                                ~ dateMessage
                                ~ mime
                                ~ format(tMultipart, boundary)
                                ~ format(tReplyTo, replyTo) ~ crlf
                                ~ "--" ~ boundary ~ crlf
                                ~ messageWithAttachments()
                                ~ attachmentsToString();
                }
        }
}
