#!/usr/bin/env python

import cgi
import cgitb; cgitb.enable()  # for troubleshooting
import os
from lxml import etree
import requests
import logging
from datetime import datetime, date, time

logger = logging.getLogger('sp-session-hook')
#hdlr = logging.FileHandler('/var/log/apache2/sp-session-hook.log')
hdlr = logging.FileHandler('/tmp/sp-session-hook.log')
formatter = logging.Formatter('%(asctime)s %(levelname)s %(message)s')
hdlr.setFormatter(formatter)
logger.addHandler(hdlr)
logger.setLevel(logging.INFO)


#Get query parameters
arguments = cgi.FieldStorage()
_return = arguments.getvalue('return')
_target = arguments.getvalue('target')

if _return is None or _target is None:
    print 'Status: 500 Internal Server Error'
    print
    print 'return and target query parameters are required'
else:
    #Get header parameters
    authType = os.environ.get('AUTH_TYPE')
    if authType == "shibboleth":
        shibSessionId = os.environ.get('Shib_Session_ID')
        shibAssertionCount = os.environ.get('Shib_Assertion_Count')
        if shibAssertionCount is not None:
            shibAssertion = os.environ.get('Shib_Assertion_%s' % shibAssertionCount)
            url = shibAssertion.replace('localhost', '127.0.0.1')

            #Load and parse attribute information
            res = requests.get(url, verify=False)
            doc = etree.fromstring(res.content)

            r = doc.xpath('//saml2:Issuer', namespaces={'saml2': 'urn:oasis:names:tc:SAML:2.0:assertion'})
            issuer = None
            if len(r) == 1:
                issuer = r[0].text

            r = doc.xpath('//saml2:Attribute', namespaces={'saml2': 'urn:oasis:names:tc:SAML:2.0:assertion'})
            attributes = {}
            attributeNames = []
            if len(r) > 0:
                for el in r:
                    name = el.attrib['Name']
                    values = []
                    for v in el.findall('.//saml2:AttributeValue', namespaces={'saml2': 'urn:oasis:names:tc:SAML:2.0:assertion'}):
                        values.append(v.text)
                    attributes[name] = values
                    attributeNames.append(name)

            #logger.info("Issuer=%s, Attributes=%s, xml=%s" % (issuer, attributeNames, res.content))

            base_url = 'https://clarin-aa.ms.mff.cuni.cz/aaggreg/v1/got'
            idp = issuer
            sp = ""
            now = datetime.now()
            timestamp = now.strftime("Y-m-d\TH:i:s.z\Z")
            encoded_attributes = ""
            for attr in attributeNames:
                encoded_attributes = "%s&attributes[]=%s" % (encoded_attributes, attr)
            warning = ""

            aag_url = '%s?idp=%s&sp=%s&timestamp=%s%s&warn=%s' % (base_url, idp, sp, timestamp, encoded_attributes, warning)

            logger.info(aag_url)

            #Redirect
            print 'Status: 303 See Other'
            print 'Location: %s' % _return
            print 'Content-Type: text/html'
            print
            print '<html>'
            print '  <head>'
            print '    <meta http-equiv="refresh" content="0;url=%s" />' % _return
            print '    <title>SP Session hook redirect</title>'
            print '  </head>'
            print '  <body>'
            print '    Redirecting... <a href="%s">Click here if you are not redirected</a>' % _return
            print '  </body>'
            print '</html>'
        else:
            print 'Status: 500 Internal Server Error'
            print
            print 'Shib_Assertion_%s variable not found' % shibAssertionCount
    else:
        print 'Status: 500 Internal Server Error'
        print
        print 'No shibboleth authentication found'