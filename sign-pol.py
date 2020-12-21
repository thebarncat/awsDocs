#!/usr/bin/env python

import base64
import hmac, hashlib
import json

# content length is max file size in bytes
json_pol = {"expiration": "2020-01-01T00:00:00Z",
  "conditions": [ 
    {"bucket": "hello.thebarncat.net"}, 
    ["starts-with", "$key", "uploads/"],
    {"acl": "private"},
    {"success_action_redirect": "http://hello.thebarncat.net/success.html"},
    ["starts-with", "$Content-Type", ""],
    ["content-length-range", 0, 5242880]
  ]
}

#pol_doc = json.dumps(json_pol)
s = json.dumps(json_pol)

# Base64-encode 
policy = base64.b64encode(s.encode('utf-8'))
print('POLICY: ', policy)
print

key = 'Wkimrr10TVUD3zpeEpho63qnonsqpv/fciBLaFkb'
# Calculate a signature value (SHA-1 HMAC) from the encoded policy document using your AWS Secret Key
#signature = base64.b64encode(hmac.new(key, policy, hashlib.sha1).digest())
#signature = base64.b64encode(hmac.new(key.encode('utf-8'), policy, hashlib.sha256).digest())
signature = base64.b64encode(hmac.new(key.encode('utf-8'), policy, hashlib.sha1).digest())

print ('SIGNATURE: ', signature)
print
