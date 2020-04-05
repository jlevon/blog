+++
author = "John Levon"
published = 2009-03-26T02:43:00.004000Z
slug = "2009-03-26-outputting-xml-in-standard-python"
tags = []
title = "Outputting XML in standard Python"
+++
Is it really this ugly? I expected something like this:  
  

    doc = xmldoc()
    doc.start('foo', { 'id': 'blah' })
    doc.start('sub')
    doc.text('subtext')
    doc.close('sub')
    doc.close('foo')
    print doc

  
  
and I thought I had it in
[SimpleXMLWriter](http://effbot.org/zone/xml-writer.htm). However, I
have to jump hoops to get it to output to a string, and it doesn't have
any pretty-print. I tried using ElementTree, but that also doesn't
pretty print! libxml2 is horribly low-level. lxml seems to do pretty
printing, but it's still just as ugly as the best option I've found so
far, xml.dom.minidom:  
  

    from xml.dom.minidom import Document
    foo = doc.createElement('foo')
    foo.setAttribute('id', 'blah')
    doc.appendChild(foo)
    sub = doc.createElement('sub')
    sub.appendChild(doc.createTextNode('subtext'))
    foo.appendChild(sub)

  
  
Yuck! If I'm building up a document, I almost always want to append
directly at the last point: why do I have to keep track of all these
elements by hand? I presume I'm missing some small standard helper
module, but \#python didn't know about it. Anyone?
