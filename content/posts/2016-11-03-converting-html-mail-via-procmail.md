+++
author = "John Levon"
published = 2016-11-03T20:27:00Z
slug = "2016-11-03-converting-html-mail-via-procmail"
tags = []
title = "Converting HTML mail via procmail"
+++
All the procmail recipes I found on a quick search failed to handle
quoted-printable HTML encodings, regularly used everywhere. And those
that had quoted-printable examples used tools no longer maintained -
such as mimencode.  
  
The solution is to use Perl directly:  
  

    :0
    * ^Content-Type: text/html;
    {
    :0c
    html/
    :0fwb
    * ^Content-Transfer-Encoding: *quoted-printable
    | perl -pe 'use MIME::QuotedPrint; $_=MIME::QuotedPrint::decode($_);'
    :0fwb
    | lynx -dump -force_html -stdin
    :0fwh
    | formail -i "Content-Type: text/plain; charset=us-ascii"
    }
