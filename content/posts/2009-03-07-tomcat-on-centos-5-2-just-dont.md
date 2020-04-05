+++
author = "John Levon"
published = 2009-03-07T19:10:00.004000Z
slug = "2009-03-07-tomcat-on-centos-5-2-just-dont"
tags = []
title = "Tomcat on Centos 5.2: just don't"
+++
If you were thinking of trying to use CentOS 5.2's tomcat packages:
don't. You just get a silent 400 Bad request error on the holding page
for no reason. Download it from upstream, and use that directly. It's
very poorly documented, sadly, so to get started:  
  

1.  Install the Sun JRE and set $JAVA\_HOME appropriately - gcj is ...
    lacking
2.  Grab the Tomcat 'core' tarball and unpack it in place
3.  edit conf/tomcat-users.xml to add a user that has the 'manager' role
4.  start Tomcat with ./bin/startup.sh
5.  Go to http://yourhost:8080/ and log in to "status" with the manager
    user you added
6.  This will list any of the apps you installed (by dumping their .war
    file in webapps/)

I also set up a virtual host with Apache (for OpenGrok) like this:  
  
&lt;VirtualHost \*.80&gt;  
ServerName grok.example.org  
ProxyPreserveHost On  
ProxyPass / http://example.org:8080/  
ProxyPassReverse / http://example.org:8080/  
&lt;/VirtualHost&gt;
