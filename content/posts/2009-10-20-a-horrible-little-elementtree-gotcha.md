+++
published = 2009-10-20T16:42:00.003000+01:00
slug = "2009-10-20-a-horrible-little-elementtree-gotcha"
tags = []
title = "A horrible little ElementTree gotcha"
+++
What does this print:  

    from lxml import etree
    doc = etree.fromstring('<a><b><c/></b></a>')
    newdoc = etree.ElementTree(doc.find('b'))
    print newdoc.xpath('/b/c')[0].xpath('/a')

  

  
The answer is: `[<Element a at 817548c>]`. The first point to note is
that `xpath()` against an element is only relative to that element: any
absolute XPaths enumerate from the top of the containing tree. The
second point is that the shallow copying of `etree` means that
`_Element::xpath`, unlike `_ElementTree::xpath`, evaluates absolute
paths from the top of the original underlying tree! So even though
there's no `<a>` in `newdoc`, an absolute XPath on a child element can
still reach it.  
Yuck.
